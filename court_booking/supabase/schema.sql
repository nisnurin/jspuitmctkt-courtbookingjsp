create extension if not exists pgcrypto;
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null,
  court text not null check (court in ('kolej','kampus')),
  booking_date date not null,
  hour smallint not null check (hour between 0 and 23),
  sport text not null,
  booker_name text not null,
  phone text not null,
  created_by uuid default auth.uid(),
  created_at timestamptz default now(),
  unique (court, booking_date, hour)  -- blocks double booking
);
create index on public.bookings (booking_date);
alter table public.bookings enable row level security;
create policy "committee read"   on public.bookings for select to authenticated using (true);
create policy "committee insert" on public.bookings for insert to authenticated with check (true);
create policy "committee delete" on public.bookings for delete to authenticated using (true);
