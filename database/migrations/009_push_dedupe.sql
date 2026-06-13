-- 009 — Push tekrarını önle: yalnızca cihaz token'ı olan kullanıcılara yaz

create or replace function public.fn_enqueue_push_for_company(
  _company_id uuid,
  _title text,
  _body text,
  _data jsonb default '{}'
)
returns void as $$
begin
  insert into public.push_queue (recipient_id, title, body, data)
  select distinct p.id, _title, _body, _data
  from public.profiles p
  inner join public.device_tokens dt on dt.user_id = p.id
  where p.company_id = _company_id;
end;
$$ language plpgsql security definer;
