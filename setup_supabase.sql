-- INTERPRETER DASHBOARD PRO — schéma initial Supabase
-- À exécuter une seule fois dans SQL Editor du NOUVEAU projet.
-- Ce script n'utilise aucune clé secrète.

create extension if not exists pgcrypto;

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Mon espace professionnel',
  created_at timestamptz not null default now()
);

create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner','admin','member')),
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name text not null, email text, phone text, organization text, address text,
  created_at timestamptz not null default now()
);
create table if not exists public.missions (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  title text not null, client_id uuid references public.clients(id) on delete set null,
  start_date date not null, end_date date not null, daily_rate numeric(14,2) not null default 0,
  billable_days integer not null default 1, total_amount numeric(14,2) not null default 0,
  language_pair text, location text, status text default 'planned', notes text,
  created_at timestamptz not null default now(), check (end_date >= start_date)
);
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  invoice_number text not null, client_id uuid references public.clients(id) on delete set null,
  mission_id uuid references public.missions(id) on delete set null,
  issue_date date not null, due_date date, amount numeric(14,2) not null default 0,
  status text default 'draft', notes text, created_at timestamptz not null default now(),
  unique(workspace_id, invoice_number)
);
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  invoice_id uuid references public.invoices(id) on delete set null,
  client_id uuid references public.clients(id) on delete set null,
  payment_date date not null, amount numeric(14,2) not null default 0,
  method text, reference text, notes text, created_at timestamptz not null default now()
);
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  label text not null, expense_date date not null, category text, amount numeric(14,2) not null default 0,
  notes text, created_at timestamptz not null default now()
);

create or replace function public.create_workspace(p_name text default 'Mon espace professionnel')
returns uuid language plpgsql security definer set search_path = public
as $$
declare new_workspace_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select wm.workspace_id into new_workspace_id
  from public.workspace_members wm where wm.user_id = auth.uid() limit 1;
  if new_workspace_id is not null then return new_workspace_id; end if;
  insert into public.workspaces(name) values (coalesce(nullif(trim(p_name),''),'Mon espace professionnel')) returning id into new_workspace_id;
  insert into public.workspace_members(workspace_id,user_id,role) values (new_workspace_id,auth.uid(),'owner');
  return new_workspace_id;
end;
$$;
revoke all on function public.create_workspace(text) from public;
grant execute on function public.create_workspace(text) to authenticated;

alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.clients enable row level security;
alter table public.missions enable row level security;
alter table public.invoices enable row level security;
alter table public.payments enable row level security;
alter table public.expenses enable row level security;

drop policy if exists "members can view own memberships" on public.workspace_members;
create policy "members can view own memberships" on public.workspace_members for select to authenticated using (user_id = auth.uid());
drop policy if exists "members can view their workspace" on public.workspaces;
create policy "members can view their workspace" on public.workspaces for select to authenticated using (exists (select 1 from public.workspace_members m where m.workspace_id = id and m.user_id = auth.uid()));

-- Chaque utilisateur authentifié ne voit et ne modifie que les données de ses espaces.
do $$
declare t text;
begin
  foreach t in array array['clients','missions','invoices','payments','expenses'] loop
    execute format('drop policy if exists %I on public.%I', 'workspace members manage ' || t, t);
    execute format('create policy %I on public.%I for all to authenticated using (exists (select 1 from public.workspace_members m where m.workspace_id = %I.workspace_id and m.user_id = auth.uid())) with check (exists (select 1 from public.workspace_members m where m.workspace_id = %I.workspace_id and m.user_id = auth.uid()))', 'workspace members manage ' || t, t, t, t);
  end loop;
end $$;

-- Index utiles pour les filtres et tris de l'application.
create index if not exists clients_workspace_idx on public.clients(workspace_id);
create index if not exists missions_workspace_start_idx on public.missions(workspace_id,start_date desc);
create index if not exists invoices_workspace_created_idx on public.invoices(workspace_id,created_at desc);
create index if not exists payments_workspace_created_idx on public.payments(workspace_id,created_at desc);
create index if not exists expenses_workspace_created_idx on public.expenses(workspace_id,created_at desc);

grant usage on schema public to authenticated;
grant select on public.workspaces, public.workspace_members to authenticated;
grant select, insert, update, delete on public.clients, public.missions, public.invoices, public.payments, public.expenses to authenticated;
