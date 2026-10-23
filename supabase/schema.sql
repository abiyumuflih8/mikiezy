-- Mikiezy initial Supabase schema.
-- Public tables are protected with owner-based RLS for authenticated users.

create extension if not exists pgcrypto;

create type public.money_direction as enum ('income', 'expense');
create type public.transaction_kind as enum ('sale', 'income', 'expense', 'adjustment');
create type public.sale_unit as enum (
  'pcs',
  'pack',
  'carton',
  'bungkus',
  'porsi',
  'gelas',
  'kilo',
  'botol',
  'buah'
);
create type public.price_segment as enum ('retail', 'wholesale');
create type public.sync_status as enum ('local_only', 'queued', 'synced', 'conflict');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  business_name text not null default 'Usaha Saya',
  owner_name text,
  phone text,
  pin_enabled boolean not null default true,
  biometric_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  name text not null,
  balance bigint not null default 0,
  is_primary boolean not null default false,
  sync_version bigint not null default 1,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, local_id)
);

create table public.ledger_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  name text not null,
  direction public.money_direction not null,
  is_system boolean not null default false,
  sync_version bigint not null default 1,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, local_id)
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  name text not null,
  category text not null default 'Lain-lain',
  cost_price bigint not null default 0,
  retail_price bigint not null default 0,
  wholesale_price bigint not null default 0,
  pack_size integer not null default 12,
  carton_size integer not null default 48,
  stock_pcs numeric(18, 3) not null default 0,
  sync_version bigint not null default 1,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, local_id)
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  kind public.transaction_kind not null,
  wallet_id uuid references public.wallets(id),
  category_id uuid references public.ledger_categories(id),
  amount bigint not null default 0,
  discount bigint not null default 0,
  note text not null default '',
  raw_voice_text text,
  ocr_source text,
  sync_status public.sync_status not null default 'queued',
  sync_version bigint not null default 1,
  occurred_at timestamptz not null default now(),
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, local_id)
);

create table public.transaction_lines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  product_id uuid references public.products(id),
  product_name text not null,
  quantity numeric(18, 3) not null default 1,
  unit public.sale_unit not null default 'pcs',
  unit_multiplier integer not null default 1,
  unit_price bigint not null default 0,
  cost_price bigint not null default 0,
  segment public.price_segment not null default 'retail',
  created_at timestamptz not null default now()
);

create table public.transaction_attachments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  bucket_id text not null default 'transaction-evidence',
  object_path text not null,
  mime_type text,
  ocr_text text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.ledger_categories enable row level security;
alter table public.products enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_lines enable row level security;
alter table public.transaction_attachments enable row level security;

create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

create policy "profiles_insert_own" on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = id);

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "wallets_owner_select" on public.wallets
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "wallets_owner_insert" on public.wallets
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "wallets_owner_update" on public.wallets
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "wallets_owner_delete" on public.wallets
  for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "categories_owner_all" on public.ledger_categories
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "products_owner_all" on public.products
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "transactions_owner_all" on public.transactions
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "transaction_lines_owner_all" on public.transaction_lines
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "transaction_attachments_owner_all" on public.transaction_attachments
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

insert into storage.buckets (id, name, public)
values ('transaction-evidence', 'transaction-evidence', false)
on conflict (id) do nothing;

create policy "evidence_owner_read" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'transaction-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "evidence_owner_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'transaction-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "evidence_owner_update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'transaction-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'transaction-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "evidence_owner_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'transaction-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
