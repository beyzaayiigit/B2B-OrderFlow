// Supabase Edge Function — sipariş Excel (.xlsx) + gömülü ürün görseli (exceljs)
//
// Deploy: supabase functions deploy generate-order-excel
// Secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY (otomatik)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import ExcelJS from 'npm:exceljs@4.4.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!

const SIZE_LABELS = ['S', 'M', 'L', 'XL', 'XXL'] as const
const EXCEL_NOTES_EMPTY =
  'Sipariş notu henüz girilmedi. Alıcı tarafında sipariş oluştururken veya takip detayından eklenebilir.'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

type OrderLine = {
  color_name: string
  size: string
  qty: number
  color_total_qty: number
}

type ColorVariant = {
  color_name: string
  image_url: string | null
  sort_order: number | null
}

function jsonError(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function thinBorder(): Partial<ExcelJS.Borders> {
  return {
    top: { style: 'thin' },
    left: { style: 'thin' },
    bottom: { style: 'thin' },
    right: { style: 'thin' },
  }
}

function labelStyle(): Partial<ExcelJS.Style> {
  return {
    font: { bold: true },
    fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFFF00' } },
    alignment: { horizontal: 'center', vertical: 'middle', wrapText: true },
    border: thinBorder(),
  }
}

function valueStyle(): Partial<ExcelJS.Style> {
  return {
    alignment: { horizontal: 'center', vertical: 'middle', wrapText: true },
    border: thinBorder(),
  }
}

/** Başlık satırındaki kod / tarih değerleri (sarı + kalın). */
function headerValueStyle(): Partial<ExcelJS.Style> {
  return labelStyle()
}

function tableHeaderStyle(): Partial<ExcelJS.Style> {
  return labelStyle()
}

function footerRedStyle(): Partial<ExcelJS.Style> {
  return {
    font: { bold: true, color: { argb: 'FFFF0000' } },
    alignment: { horizontal: 'center', vertical: 'middle' },
    border: thinBorder(),
  }
}

function footerYellowStyle(): Partial<ExcelJS.Style> {
  return {
    fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFFF00' } },
    alignment: { horizontal: 'center', vertical: 'middle' },
    border: thinBorder(),
  }
}

function setCell(
  sheet: ExcelJS.Worksheet,
  row: number,
  col: number,
  value: ExcelJS.CellValue,
  style: Partial<ExcelJS.Style>,
): void {
  const cell = sheet.getCell(row, col)
  cell.value = value
  cell.style = style
}

function formatDateTr(iso: string): string {
  const d = new Date(iso)
  const dd = String(d.getUTCDate()).padStart(2, '0')
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0')
  const yyyy = d.getUTCFullYear()
  return `${dd}.${mm}.${yyyy}`
}

function formatIntTr(n: number): string {
  return n.toLocaleString('tr-TR')
}

function buildColorBreakdown(lines: OrderLine[]): Map<string, number> {
  const totals = new Map<string, number>()
  for (const line of lines) {
    const color = (line.color_name ?? '').trim()
    if (!color) continue
    const t = line.color_total_qty ?? 0
    if (t > 0) totals.set(color, t)
  }
  return totals
}

function buildSizeRatios(
  lines: OrderLine[],
  colorName: string,
): number[] {
  const ratios = new Map<string, number>()
  for (const line of lines) {
    if ((line.color_name ?? '').trim() !== colorName) continue
    const size = (line.size ?? '').trim()
    const qty = line.qty ?? 0
    if (size && qty > 0) ratios.set(size, qty)
  }
  return SIZE_LABELS.map((s) => ratios.get(s) ?? 0)
}

function pickImageUrl(
  variants: ColorVariant[],
  colorsInOrder: string[],
): string | null {
  for (const color of colorsInOrder) {
    const target = color.trim()
    for (const v of variants) {
      if ((v.color_name ?? '').trim() === target) {
        const url = (v.image_url ?? '').trim()
        if (url.startsWith('http')) return url
      }
    }
  }
  for (const v of variants) {
    const url = (v.image_url ?? '').trim()
    if (url.startsWith('http')) return url
  }
  return null
}

function imageExtension(
  url: string,
  contentType: string,
): 'jpeg' | 'png' | 'gif' {
  const ct = contentType.toLowerCase()
  if (ct.includes('png')) return 'png'
  if (ct.includes('gif')) return 'gif'
  const lower = url.toLowerCase()
  if (lower.endsWith('.png')) return 'png'
  if (lower.endsWith('.gif')) return 'gif'
  return 'jpeg'
}

async function downloadImage(
  url: string,
): Promise<{ buffer: Uint8Array; extension: 'jpeg' | 'png' | 'gif' } | null> {
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(15000) })
    if (!res.ok) {
      console.warn(`Image HTTP ${res.status} for ${url}`)
      return null
    }
    const buf = new Uint8Array(await res.arrayBuffer())
    if (buf.length === 0 || buf.length > 5_000_000) return null
    const ext = imageExtension(url, res.headers.get('content-type') ?? '')
    console.log(`Image downloaded: ${buf.length} bytes, ext=${ext}`)
    return { buffer: buf, extension: ext }
  } catch (e) {
    console.warn(`Image download failed: ${e}`)
    return null
  }
}

async function buildWorkbook(params: {
  productCode: string
  productName: string
  orderedAt: string
  buyerNote: string | null
  orderedByName: string
  buyerCompanyName: string
  colorBreakdown: Map<string, number>
  sizeRatiosByColor: Map<string, number[]>
  image: { buffer: Uint8Array; extension: 'jpeg' | 'png' | 'gif' } | null
}): Promise<Uint8Array> {
  const workbook = new ExcelJS.Workbook()
  const sheet = workbook.addWorksheet('Sipariş')

  const colWidths = [20, 18, 12, 10, 10, 10, 10, 10]
  colWidths.forEach((w, i) => {
    sheet.getColumn(i + 1).width = w
  })

  const dateStr = formatDateTr(params.orderedAt)
  const notesBody =
    params.buyerNote?.trim() ||
    EXCEL_NOTES_EMPTY
  const imgCaption = `Ürün: ${params.productCode}\n${params.productName}`

  const imageRowStart = 3
  const imageRowEnd = 11
  const captionRow = 12
  const tableTop = 14

  // Row 1 — model kodu + tarih (değerler de sarı + kalın)
  setCell(sheet, 1, 1, 'MODEL KODU', labelStyle())
  setCell(sheet, 1, 2, params.productCode, headerValueStyle())
  setCell(sheet, 1, 3, 'SİPARİŞ TARİHİ', labelStyle())
  sheet.mergeCells(1, 4, 1, 8)
  setCell(sheet, 1, 4, dateStr, headerValueStyle())

  // Row 2 — model adı
  setCell(sheet, 2, 1, 'MODEL İSMİ', labelStyle())
  sheet.mergeCells(2, 2, 2, 8)
  setCell(sheet, 2, 2, params.productName, {
    ...valueStyle(),
    font: { bold: true },
  })

  // Notlar (sol) + görsel alanı (sağ) — satır yükseklikleri sabit
  sheet.mergeCells(imageRowStart, 1, imageRowEnd, 3)
  setCell(sheet, imageRowStart, 1, notesBody, {
    ...valueStyle(),
    alignment: { horizontal: 'center', vertical: 'middle', wrapText: true },
    font: { size: 11 },
  })

  sheet.mergeCells(imageRowStart, 4, imageRowEnd, 8)
  for (let r = imageRowStart; r <= imageRowEnd; r++) {
    sheet.getRow(r).height = 22
  }

  if (params.image) {
    const imageId = workbook.addImage({
      buffer: params.image.buffer,
      extension: params.image.extension,
    })
    // Hücre aralığına sığdır (piksel taşması yok); exceljs col/row 0-tabanlı
    sheet.addImage(imageId, {
      tl: { col: 3.08, row: imageRowStart - 0.92 },
      br: { col: 7.92, row: imageRowEnd - 0.08 },
      editAs: 'oneCell',
    })
  } else {
    setCell(sheet, imageRowStart, 4, imgCaption, {
      alignment: { horizontal: 'center', vertical: 'middle', wrapText: true },
      fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2F2F2' } },
      font: { size: 11 },
      border: thinBorder(),
    })
  }

  // Görsel varken ürün özeti altta, tablonun hemen üstünde (görselle çakışmaz)
  sheet.mergeCells(captionRow, 4, captionRow, 8)
  sheet.getRow(captionRow).height = 28
  setCell(sheet, captionRow, 4, params.image ? imgCaption : '', {
    alignment: { horizontal: 'center', vertical: 'middle', wrapText: true },
    fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2F2F2' } },
    font: { size: 10, bold: true },
    border: thinBorder(),
  })
  const headers = ['SİPARİŞ VEREN', 'RENK', 'ADET', ...SIZE_LABELS]
  headers.forEach((h, c) => {
    setCell(sheet, tableTop, c + 1, h, tableHeaderStyle())
  })

  const colors = [...params.colorBreakdown.entries()]
  const orderer = params.orderedByName || params.buyerCompanyName

  colors.forEach(([colorName, adet], i) => {
    const r = tableTop + 1 + i
    const sizes = params.sizeRatiosByColor.get(colorName) ?? [0, 0, 0, 0, 0]

    setCell(sheet, r, 1, i === 0 ? orderer : '', valueStyle())
    setCell(sheet, r, 2, colorName.toUpperCase(), valueStyle())
    setCell(sheet, r, 3, adet, valueStyle())
    sizes.forEach((q, s) => {
      setCell(sheet, r, 4 + s, q, valueStyle())
    })
  })

  const footerRow = tableTop + 1 + colors.length
  sheet.mergeCells(footerRow, 1, footerRow, 2)
  setCell(sheet, footerRow, 1, 'TOPLAM ADET', footerRedStyle())

  const total = [...params.colorBreakdown.values()].reduce((a, b) => a + b, 0)
  setCell(sheet, footerRow, 3, formatIntTr(total), footerRedStyle())
  for (let c = 4; c <= 8; c++) {
    setCell(sheet, footerRow, c, '', footerYellowStyle())
  }

  const out = await workbook.xlsx.writeBuffer()
  return new Uint8Array(out)
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return jsonError(405, 'Yalnızca POST desteklenir.')
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return jsonError(401, 'Oturum gerekli.')
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return jsonError(400, 'Geçersiz JSON gövdesi.')
  }

  const producerOrderNo = (body.producer_order_no as string | undefined)?.trim()
  const orderId = (body.order_id as string | undefined)?.trim()

  if (!producerOrderNo && !orderId) {
    return jsonError(400, 'producer_order_no veya order_id gerekli.')
  }

  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  })
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser()
  if (userError || !user) {
    return jsonError(401, 'Geçersiz oturum.')
  }

  const { data: profile, error: profileError } = await admin
    .from('profiles')
    .select('company_id, role')
    .eq('id', user.id)
    .maybeSingle()

  if (profileError || !profile) {
    return jsonError(403, 'Profil bulunamadı.')
  }

  const orderSelect = `
    id,
    buyer_order_no,
    producer_order_no,
    buyer_note,
    ordered_at,
    buyer_company_id,
    producer_company_id,
    catalog_models (
      code,
      name,
      catalog_color_variants ( color_name, image_url, sort_order )
    ),
    order_lines ( color_name, size, qty, color_total_qty ),
    buyer_company:companies!buyer_company_id ( name ),
    ordered_by:profiles!created_by ( full_name )
  `

  let orderQuery = admin.from('orders').select(orderSelect)
  if (producerOrderNo) {
    orderQuery = orderQuery.eq('producer_order_no', producerOrderNo)
  } else {
    orderQuery = orderQuery.eq('id', orderId!)
  }

  const { data: order, error: orderError } = await orderQuery.maybeSingle()

  if (orderError || !order) {
    return jsonError(404, 'Sipariş bulunamadı.')
  }

  const companyId = profile.company_id as string
  const role = profile.role as string
  const buyerCo = order.buyer_company_id as string
  const producerCo = order.producer_company_id as string

  if (role === 'buyer' && buyerCo !== companyId) {
    return jsonError(403, 'Bu siparişe erişim yok.')
  }
  if (role === 'producer' && producerCo !== companyId) {
    return jsonError(403, 'Bu siparişe erişim yok.')
  }
  if (role !== 'buyer' && role !== 'producer') {
    return jsonError(403, 'Yetkisiz rol.')
  }

  const model = order.catalog_models as {
    code: string
    name: string
    catalog_color_variants: ColorVariant[]
  } | null

  const lines = (order.order_lines ?? []) as OrderLine[]
  const colorBreakdown = buildColorBreakdown(lines)
  const colorsInOrder = [...colorBreakdown.keys()]

  const sizeRatiosByColor = new Map<string, number[]>()
  for (const color of colorsInOrder) {
    sizeRatiosByColor.set(color, buildSizeRatios(lines, color))
  }

  const variants = model?.catalog_color_variants ?? []
  const imageUrl = pickImageUrl(variants, colorsInOrder)
  const image = imageUrl ? await downloadImage(imageUrl) : null

  const buyerCompany = order.buyer_company as { name?: string } | null
  const orderedBy = order.ordered_by as { full_name?: string } | null
  const orderedByName =
    (orderedBy?.full_name as string | undefined)?.trim() ||
    buyerCompany?.name ||
    'Alıcı'

  const xlsx = await buildWorkbook({
    productCode: model?.code ?? '?',
    productName: model?.name ?? 'Model',
    orderedAt: order.ordered_at as string,
    buyerNote: order.buyer_note as string | null,
    orderedByName,
    buyerCompanyName: buyerCompany?.name ?? 'Alıcı',
    colorBreakdown,
    sizeRatiosByColor,
    image,
  })

  const safeName = ((order.producer_order_no as string) || 'siparis')
    .replace(/[^\w\-]+/g, '_')

  return new Response(xlsx, {
    status: 200,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="Siparis_${safeName}.xlsx"`,
    },
  })
})
