-- Clinical data collection is intentionally disabled until an operator completes
-- regional compliance and provider verification. This schema supports bookings.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table public.providers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id),
  category text not null check (category in ('Doctors','Pharmacy','Labs','Hospitals')),
  name text not null check (length(name) between 1 and 160),
  detail text not null default '',
  facility text not null,
  country_code text not null check (country_code ~ '^[A-Z]{2}$'),
  currency text not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
  price_cents integer not null check (price_cents >= 0),
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  verified boolean not null default false,
  available_beds integer not null default 0 check (available_beds between 0 and 10000),
  created_at timestamptz not null default now()
);
create index providers_owner on public.providers(owner_id);
create index providers_directory on public.providers(category,country_code) where verified;
alter table public.providers enable row level security;
create policy public_verified_providers on public.providers for select to anon, authenticated
using (verified or owner_id = (select auth.uid()));
-- Only administrators can insert providers, set their owner or verify them.
grant select on public.providers to anon, authenticated;
grant update(available_beds) on public.providers to authenticated;
create policy owner_capacity on public.providers for update to authenticated
using (owner_id = (select auth.uid()) and verified and category='Hospitals')
with check (owner_id = (select auth.uid()) and verified and category='Hospitals');

create table public.slots (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers(id),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  check (ends_at > starts_at),
  unique(provider_id,starts_at)
);
create index slots_provider on public.slots(provider_id,starts_at);
alter table public.slots enable row level security;
create policy discover_slots on public.slots for select to anon, authenticated
using (exists(select 1 from public.providers p where p.id=provider_id and p.verified));
create policy owner_slots on public.slots for all to authenticated
using (exists(select 1 from public.providers p where p.id=provider_id and p.owner_id=(select auth.uid()) and p.verified))
with check (starts_at>now() and exists(select 1 from public.providers p where p.id=provider_id and p.owner_id=(select auth.uid()) and p.verified));
grant select on public.slots to anon, authenticated;
grant insert,delete on public.slots to authenticated;

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references auth.users(id) on delete cascade,
  provider_id uuid not null references public.providers(id),
  slot_id uuid not null references public.slots(id),
  starts_at timestamptz not null,
  status text not null default 'requested' check(status in ('requested','confirmed','completed','cancelled')),
  created_at timestamptz not null default now()
);
create unique index one_active_slot on public.appointments(slot_id) where status <> 'cancelled';
create unique index patient_one_time on public.appointments(patient_id,starts_at) where status <> 'cancelled';
create index appointments_provider on public.appointments(provider_id);
alter table public.appointments enable row level security;
create policy participant_appointments on public.appointments for select to authenticated
using (patient_id=(select auth.uid()) or exists(select 1 from public.providers p where p.id=provider_id and p.owner_id=(select auth.uid()) and p.verified));
grant select on public.appointments to authenticated;
-- No direct client INSERT/UPDATE permissions. RPC checks slot, time and actor.

create table public.products (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers(id),
  name text not null,
  price_cents integer not null check(price_cents >= 0),
  stock integer not null default 0 check(stock >= 0),
  prescription_required boolean not null default false
);
create index products_provider on public.products(provider_id);
alter table public.products enable row level security;
create policy discover_products on public.products for select to anon,authenticated
using (exists(select 1 from public.providers p where p.id=provider_id and p.verified));
create policy manage_inventory on public.products for update to authenticated
using (exists(select 1 from public.providers p where p.id=provider_id and p.owner_id=(select auth.uid()) and p.verified and p.category='Pharmacy'))
with check (exists(select 1 from public.providers p where p.id=provider_id and p.owner_id=(select auth.uid()) and p.verified and p.category='Pharmacy'));
grant select on public.products to anon, authenticated;
grant update(stock) on public.products to authenticated;

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references auth.users(id) on delete cascade,
  total_cents integer not null check(total_cents>=0),
  currency text not null,
  status text not null default 'requested' check(status in ('requested','paid','cancelled','fulfilled')),
  created_at timestamptz not null default now()
);
create index orders_patient on public.orders(patient_id);
alter table public.orders enable row level security;
create policy own_orders on public.orders for select to authenticated using(patient_id=(select auth.uid()));
grant select on public.orders to authenticated;
create table public.order_items (
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id),
  quantity integer not null check(quantity between 1 and 99),
  unit_cents integer not null check(unit_cents >= 0),
  primary key(order_id,product_id)
);
create index order_items_product on public.order_items(product_id);
alter table public.order_items enable row level security;
create policy own_order_items on public.order_items for select to authenticated
using(exists(select 1 from public.orders o where o.id=order_id and o.patient_id=(select auth.uid())));
grant select on public.order_items to authenticated;

-- SECURITY DEFINER is confined to the non-exposed private schema. Every call
-- checks auth.uid(); fixed search_path prevents object shadowing.
create function private.require_user() returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid := auth.uid();
begin
  if uid is null or not exists(select 1 from auth.users where id=uid) then
    raise exception 'Authentication required' using errcode='28000';
  end if;
  return uid;
end $$;
revoke all on function private.require_user() from public,anon;
grant execute on function private.require_user() to authenticated;

create function private.book_slot(selected_slot uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid := private.require_user(); slot public.slots; result uuid;
begin
  select s.* into slot from public.slots s join public.providers p on p.id=s.provider_id
  where s.id=selected_slot and p.verified and s.starts_at > now() for update of s;
  if not found then raise exception 'Slot unavailable'; end if;
  insert into public.appointments(patient_id,provider_id,slot_id,starts_at)
  values(uid,slot.provider_id,slot.id,slot.starts_at) returning id into result;
  return result;
end $$;
revoke all on function private.book_slot(uuid) from public,anon;
grant execute on function private.book_slot(uuid) to authenticated;
create function public.book_slot(selected_slot uuid) returns uuid language sql security invoker set search_path='' as $$select private.book_slot(selected_slot)$$;
revoke all on function public.book_slot(uuid) from public,anon;
grant execute on function public.book_slot(uuid) to authenticated;

create function private.set_booking(booking_id uuid, new_status text) returns void language plpgsql security definer set search_path='' as $$
declare uid uuid := private.require_user(); booking public.appointments; is_owner boolean;
begin
  select * into booking from public.appointments where id=booking_id for update;
  if not found then raise exception 'Booking unavailable'; end if;
  select exists(select 1 from public.providers where id=booking.provider_id and owner_id=uid and verified) into is_owner;
  if not ((booking.patient_id=uid and new_status='cancelled') or (is_owner and new_status in ('confirmed','completed','cancelled'))) then raise exception 'Not authorized' using errcode='42501'; end if;
  if booking.status in ('completed','cancelled') then raise exception 'Booking is already closed'; end if;
  if new_status='completed' and booking.starts_at>now() then raise exception 'Appointment has not started'; end if;
  update public.appointments set status=new_status where id=booking_id;
end $$;
revoke all on function private.set_booking(uuid,text) from public,anon;
grant execute on function private.set_booking(uuid,text) to authenticated;
create function public.set_booking(booking_id uuid,new_status text) returns void language sql security invoker set search_path='' as $$select private.set_booking(booking_id,new_status)$$;
revoke all on function public.set_booking(uuid,text) from public,anon;
grant execute on function public.set_booking(uuid,text) to authenticated;

create function private.create_order(items jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid := private.require_user(); item record; product record; order_currency text; amount bigint := 0; result uuid; count_items int;
begin
  if jsonb_typeof(items)<>'array' or jsonb_array_length(items) not between 1 and 30 then raise exception 'Invalid cart'; end if;
  select count(distinct value->>'product_id') into count_items from jsonb_array_elements(items);
  if count_items<>jsonb_array_length(items) then raise exception 'Duplicate product'; end if;
  -- Fixed product lock order avoids cart deadlocks; all updates roll back on error.
  for item in select (value->>'product_id')::uuid as id,(value->>'quantity')::int as qty from jsonb_array_elements(items) order by 1 loop
    if item.qty is null or item.qty not between 1 and 99 then raise exception 'Invalid quantity'; end if;
    select pr.*,p.currency into product from public.products pr join public.providers p on p.id=pr.provider_id
      where pr.id=item.id and p.verified and p.category='Pharmacy' for update of pr;
    if not found or product.prescription_required or product.stock<item.qty then raise exception 'Product unavailable or prescription required'; end if;
    if order_currency is not null and order_currency<>product.currency then raise exception 'Use one currency per order'; end if;
    order_currency := product.currency;
    amount := amount + product.price_cents::bigint * item.qty;
  end loop;
  if amount>2147483647 then raise exception 'Order total exceeds limit'; end if;
  insert into public.orders(patient_id,total_cents,currency) values(uid,amount,order_currency) returning id into result;
  for item in select (value->>'product_id')::uuid as id,(value->>'quantity')::int as qty from jsonb_array_elements(items) loop
    insert into public.order_items(order_id,product_id,quantity,unit_cents) select result,id,item.qty,price_cents from public.products where id=item.id;
    update public.products set stock=stock-item.qty where id=item.id;
  end loop;
  return result;
end $$;
revoke all on function private.create_order(jsonb) from public,anon;
grant execute on function private.create_order(jsonb) to authenticated;
create function public.create_order(items jsonb) returns uuid language sql security invoker set search_path='' as $$select private.create_order(items)$$;
revoke all on function public.create_order(jsonb) from public,anon;
grant execute on function public.create_order(jsonb) to authenticated;

-- Data is not seeded with fictional verified providers. Admin onboarding is required.

create table public.deletion_requests (
  user_id uuid primary key references auth.users(id) on delete cascade,
  requested_at timestamptz not null default now(),
  status text not null default 'pending' check(status in ('pending','completed'))
);
alter table public.deletion_requests enable row level security;
create policy own_deletion_request on public.deletion_requests for all to authenticated
using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
grant select,insert on public.deletion_requests to authenticated;
grant update(user_id) on public.deletion_requests to authenticated;

create function private.cancel_order(selected_order uuid) returns void language plpgsql security definer set search_path='' as $$
declare uid uuid := private.require_user(); item record; order_status text;
begin
  select status into order_status from public.orders where id=selected_order and patient_id=uid for update;
  if not found or order_status<>'requested' then raise exception 'Order cannot be cancelled'; end if;
  for item in select product_id,quantity from public.order_items where order_id=selected_order order by product_id loop
    update public.products set stock=stock+item.quantity where id=item.product_id;
  end loop;
  update public.orders set status='cancelled' where id=selected_order;
end $$;
revoke all on function private.cancel_order(uuid) from public,anon;
grant execute on function private.cancel_order(uuid) to authenticated;
create function public.cancel_order(selected_order uuid) returns void language sql security invoker set search_path='' as $$select private.cancel_order(selected_order)$$;
revoke all on function public.cancel_order(uuid) from public,anon;
grant execute on function public.cancel_order(uuid) to authenticated;


alter table public.order_items add column status text not null default 'requested'
  check(status in ('requested','fulfilled','cancelled'));
create policy pharmacy_order_items on public.order_items for select to authenticated
using(exists(select 1 from public.products pr join public.providers p on p.id=pr.provider_id
  where pr.id=product_id and p.owner_id=(select auth.uid()) and p.verified and p.category='Pharmacy'));

create function private.fulfill_item(selected_order uuid,selected_product uuid) returns void language plpgsql security definer set search_path='' as $$
declare uid uuid := private.require_user(); order_status text;
begin
  select status into order_status from public.orders where id=selected_order for update;
  if not found or order_status<>'requested' then raise exception 'Order unavailable'; end if;
  if not exists(select 1 from public.products pr join public.providers p on p.id=pr.provider_id
    where pr.id=selected_product and p.owner_id=uid and p.verified and p.category='Pharmacy') then
    raise exception 'Not authorized' using errcode='42501';
  end if;
  update public.order_items set status='fulfilled' where order_id=selected_order and product_id=selected_product and status='requested';
  if not found then raise exception 'Item unavailable'; end if;
  if not exists(select 1 from public.order_items where order_id=selected_order and status<>'fulfilled') then
    update public.orders set status='fulfilled' where id=selected_order;
  end if;
end $$;
revoke all on function private.fulfill_item(uuid,uuid) from public,anon;
grant execute on function private.fulfill_item(uuid,uuid) to authenticated;
create function public.fulfill_item(selected_order uuid,selected_product uuid) returns void language sql security invoker set search_path='' as $$select private.fulfill_item(selected_order,selected_product)$$;
revoke all on function public.fulfill_item(uuid,uuid) from public,anon;
grant execute on function public.fulfill_item(uuid,uuid) to authenticated;

create or replace function private.cancel_order(selected_order uuid) returns void language plpgsql security definer set search_path='' as $$
declare uid uuid := private.require_user(); item record; order_status text;
begin
  select status into order_status from public.orders where id=selected_order and patient_id=uid for update;
  if not found or order_status<>'requested' or exists(select 1 from public.order_items where order_id=selected_order and status<>'requested') then raise exception 'Order cannot be cancelled'; end if;
  for item in select product_id,quantity from public.order_items where order_id=selected_order order by product_id loop
    update public.products set stock=stock+item.quantity where id=item.product_id;
  end loop;
  update public.order_items set status='cancelled' where order_id=selected_order;
  update public.orders set status='cancelled' where id=selected_order;
end $$;
