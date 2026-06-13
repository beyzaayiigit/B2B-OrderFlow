// Supabase Edge Function — push_queue → FCM (tek kayıt / webhook başına bir gönderim)
//
// Kurulum: Firebase secrets + Database Webhook (push_queue INSERT → send-push)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') ?? ''
const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL') ?? ''
const FIREBASE_PRIVATE_KEY = (Deno.env.get('FIREBASE_PRIVATE_KEY') ?? '').replace(/\\n/g, '\n')

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  const binaryDer = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0))
  return crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
}

function base64url(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = base64url(new TextEncoder().encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })))
  const payload = base64url(
    new TextEncoder().encode(
      JSON.stringify({
        iss: FIREBASE_CLIENT_EMAIL,
        sub: FIREBASE_CLIENT_EMAIL,
        aud: 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
      }),
    ),
  )

  const key = await importPrivateKey(FIREBASE_PRIVATE_KEY)
  const sig = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${payload}`)),
  )
  const jwt = `${header}.${payload}.${base64url(sig)}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  const json = await res.json()
  return json.access_token
}

async function sendFcm(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
) {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data,
          android: {
            priority: 'high',
            notification: { sound: 'default', channel_id: 'textileflow_orders' },
          },
          apns: {
            headers: { 'apns-priority': '10' },
            payload: {
              aps: {
                alert: { title, body },
                sound: 'default',
              },
            },
          },
        },
      }),
    },
  )
  return { status: res.status, body: await res.text() }
}

type QueueRow = {
  id: string
  recipient_id: string
  title: string
  body: string
  data: Record<string, unknown> | null
  sent: boolean
}

/** Database Webhook gövdesinden push_queue satır id'si. */
function queueIdFromWebhook(body: Record<string, unknown>): string | null {
  const record = body.record as Record<string, unknown> | undefined
  if (record?.id && typeof record.id === 'string') return record.id
  return null
}

async function processOneQueueItem(
  supabase: ReturnType<typeof createClient>,
  accessToken: string,
  queueId: string,
): Promise<boolean> {
  // Önce "gönderildi" işaretle — paralel webhook çağrılarında çift gönderimi engeller
  const { data: claimed, error: claimErr } = await supabase
    .from('push_queue')
    .update({ sent: true })
    .eq('id', queueId)
    .eq('sent', false)
    .select('id, recipient_id, title, body, data')
    .maybeSingle()

  if (claimErr || !claimed) {
    return false // zaten işlendi veya yok
  }

  const item = claimed as QueueRow

  const { data: tokens } = await supabase
    .from('device_tokens')
    .select('fcm_token')
    .eq('user_id', item.recipient_id)

  if (!tokens?.length) {
    return true
  }

  const dataPayload: Record<string, string> = {}
  if (item.data) {
    for (const [k, v] of Object.entries(item.data)) {
      dataPayload[k] = String(v)
    }
  }

  const sentTokens = new Set<string>()
  for (const t of tokens) {
    if (sentTokens.has(t.fcm_token)) continue
    sentTokens.add(t.fcm_token)
    try {
      await sendFcm(accessToken, t.fcm_token, item.title, item.body, dataPayload)
    } catch (e) {
      console.error(`FCM gönderim hatası: ${e}`)
    }
  }

  return true
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  if (!FIREBASE_PROJECT_ID || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PRIVATE_KEY) {
    return new Response(
      JSON.stringify({ ok: false, error: 'Firebase secrets eksik' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }

  const body = (await req.json().catch(() => ({}))) as Record<string, unknown>
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  let accessToken: string
  try {
    accessToken = await getAccessToken()
  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, error: `OAuth hatası: ${e}` }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }

  // Webhook: yalnızca tetikleyen satır (çift bildirim önlemi)
  const webhookQueueId = queueIdFromWebhook(body)
  if (webhookQueueId) {
    const processed = await processOneQueueItem(supabase, accessToken, webhookQueueId)
    return new Response(
      JSON.stringify({ ok: true, mode: 'webhook', queue_id: webhookQueueId, processed }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  }

  // Manuel / toplu: en fazla 20 bekleyen satır, her biri ayrı claim
  const { data: pending } = await supabase
    .from('push_queue')
    .select('id')
    .eq('sent', false)
    .order('created_at', { ascending: true })
    .limit(20)

  let sent = 0
  for (const row of pending ?? []) {
    if (await processOneQueueItem(supabase, accessToken, row.id)) sent++
  }

  return new Response(
    JSON.stringify({ ok: true, mode: 'batch', processed: sent }),
    { headers: { 'Content-Type': 'application/json' } },
  )
})
