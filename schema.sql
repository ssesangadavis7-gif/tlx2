-- Run this whole file in Supabase: SQL Editor > New query > Run.
-- Admin email already set to ssesangadavis7@gmail.com (it must match your user in Authentication > Users).
create or replace function is_admin() returns boolean language sql stable as $$
  select coalesce(auth.jwt()->>'email','') = 'ssesangadavis7@gmail.com'
$$;

create table if not exists categories(id bigint generated always as identity primary key, name text unique not null, grp text not null);
create table if not exists products(id uuid primary key default gen_random_uuid(), name text not null, category text not null, description text default '', price numeric, status text not null default 'Ask availability', image_url text, created_at timestamptz default now());
create table if not exists settings(id int primary key default 1 check(id=1), phone text default '', whatsapp text default '', email text default '', about text);
create table if not exists enquiries(id bigint generated always as identity primary key, name text not null, phone text not null, message text not null, created_at timestamptz default now());
create table if not exists service_requests(id bigint generated always as identity primary key, name text not null, phone text not null, location text not null, service text not null, message text default '', status text default 'New', created_at timestamptz default now());

alter table categories enable row level security;
alter table products enable row level security;
alter table settings enable row level security;
alter table enquiries enable row level security;
alter table service_requests enable row level security;

-- Public can read the catalogue; only the admin can change it
drop policy if exists "read categories" on categories;
create policy "read categories" on categories for select using (true);
drop policy if exists "admin categories" on categories;
create policy "admin categories" on categories for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists "read products" on products;
create policy "read products" on products for select using (true);
drop policy if exists "admin products" on products;
create policy "admin products" on products for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists "read settings" on settings;
create policy "read settings" on settings for select using (true);
drop policy if exists "admin settings" on settings;
create policy "admin settings" on settings for all to authenticated using (is_admin()) with check (is_admin());

-- Anyone can submit forms; only the admin can read or manage them
drop policy if exists "submit enquiries" on enquiries;
create policy "submit enquiries" on enquiries for insert to anon, authenticated with check (length(name)<=100 and length(phone)<=40 and length(message)<=2000);
drop policy if exists "admin enquiries" on enquiries;
create policy "admin enquiries" on enquiries for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists "submit requests" on service_requests;
create policy "submit requests" on service_requests for insert to anon, authenticated with check (length(name)<=100 and length(phone)<=40 and length(message)<=2000);
drop policy if exists "admin requests" on service_requests;
create policy "admin requests" on service_requests for all to authenticated using (is_admin()) with check (is_admin());

-- Image storage
insert into storage.buckets(id,name,public) values('product-images','product-images',true) on conflict do nothing;
drop policy if exists "read images" on storage.objects;
create policy "read images" on storage.objects for select using (bucket_id='product-images');
drop policy if exists "admin add images" on storage.objects;
create policy "admin add images" on storage.objects for insert to authenticated with check (bucket_id='product-images' and is_admin());
drop policy if exists "admin change images" on storage.objects;
create policy "admin change images" on storage.objects for update to authenticated using (bucket_id='product-images' and is_admin());
drop policy if exists "admin delete images" on storage.objects;
create policy "admin delete images" on storage.objects for delete to authenticated using (bucket_id='product-images' and is_admin());

-- Starter data (no prices or stock invented)
insert into categories(name,grp) values
('LED bulbs','Electrical appliances'),('Electrical switches','Electrical appliances'),('Socket outlets','Electrical appliances'),('Plugs and adaptors','Electrical appliances'),('Electrical cables','Electrical appliances'),('Circuit breakers','Electrical appliances'),('Insulation tape','Electrical appliances'),('Lamp holders','Electrical appliances'),
('Solar lamps','Solar products'),('Solar lighting systems','Solar products'),('Solar panels','Solar products'),('Solar batteries','Solar products'),('Charge controllers','Solar products')
on conflict do nothing;
insert into products(name,category,description) select name,name,'Quality '||lower(name)||' for homes and businesses. Ask us about brands, sizes and ratings.' from categories where not exists (select 1 from products);
insert into settings(id,about) values(1,'TLX ENTERPRISES is a retail shop and technical service provider in Magamaga Trading Centre, Mayuge District. We supply electrical appliances, accessories and solar products, and offer electrical installation, maintenance and repair for households, landlords, tenants, electricians, builders and small businesses.') on conflict do nothing;
