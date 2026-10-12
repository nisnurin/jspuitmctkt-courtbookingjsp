-- =====================================================================
--  JSP Court Booking · UiTM Kuala Terengganu
--  Run this whole file once in: Supabase Dashboard > SQL Editor > New query
-- =====================================================================

create extension if not exists btree_gist;

create table if not exists public.bookings (
  id           uuid primary key default gen_random_uuid(),
  court        text    not null check (court in ('Court Kolej', 'Court Kampus')),
  booking_date date    not null,
  start_hour   integer not null check (start_hour between 0 and 23),  -- inclusive
  end_hour     integer not null check (end_hour between 1 and 24),    -- exclusive (24 = midnight)
  sport        text    not null,
  name         text    not null,
  phone        text    not null,
  note         text,
  created_by   uuid default auth.uid() references auth.users (id) on delete set null,
  created_at   timestamptz not null default now(),

  constraint valid_range check (end_hour > start_hour),

  -- Prevents double booking: same court + same date + overlapping hours is rejected.
  constraint no_overlap exclude using gist (
    court with =,
    booking_date with =,
    int4range(start_hour, end_hour) with &&
  )
);

create index if not exists bookings_date_idx on public.bookings (booking_date, court);

-- Only signed-in JSP committee members (created by you in Supabase) can use the data.
alter table public.bookings enable row level security;

drop policy if exists "jsp read"   on public.bookings;
drop policy if exists "jsp insert" on public.bookings;
drop policy if exists "jsp update" on public.bookings;
drop policy if exists "jsp delete" on public.bookings;
drop policy if exists "public availability read" on public.bookings;

create policy "jsp read"   on public.bookings for select to authenticated using (true);
create policy "public availability read" on public.bookings for select to anon using (true);
create policy "jsp insert" on public.bookings for insert to authenticated with check (true);
create policy "jsp update" on public.bookings for update to authenticated using (true) with check (true);
create policy "jsp delete" on public.bookings for delete to authenticated using (true);

-- Anonymous clients can read availability fields only; identity and notes remain private.
revoke select on public.bookings from anon;
grant select (court, booking_date, start_hour, end_hour) on public.bookings to anon;
