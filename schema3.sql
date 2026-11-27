-- 1. Public directory of readers so users can find & request each other
create table if not exists public.reader_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  full_name text not null,
  avatar_url text,
  bio text,
  updated_at timestamptz default now()
);

alter table public.reader_profiles enable row level security;

create policy "Anyone can view reader profiles"
  on public.reader_profiles for select using (true);

create policy "Users insert own reader profile"
  on public.reader_profiles for insert with check (auth.uid() = id);

create policy "Users update own reader profile"
  on public.reader_profiles for update using (auth.uid() = id);

-- 2. Reader connection requests (pending / accepted)
create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.reader_profiles(id) on delete cascade,
  receiver_id uuid not null references public.reader_profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz default now(),
  unique (sender_id, receiver_id)
);

alter table public.friend_requests enable row level security;

create policy "Users view own requests"
  on public.friend_requests for select
  using (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "Users send requests"
  on public.friend_requests for insert
  with check (auth.uid() = sender_id and sender_id <> receiver_id);

create policy "Receivers accept requests"
  on public.friend_requests for update
  using (auth.uid() = receiver_id);

create policy "Users delete or decline requests"
  on public.friend_requests for delete
  using (auth.uid() = sender_id or auth.uid() = receiver_id);

-- 3. Direct messages between accepted readers
create table if not exists public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.reader_profiles(id) on delete cascade,
  receiver_id uuid not null references public.reader_profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz default now()
);

alter table public.direct_messages enable row level security;

create policy "Users read own messages"
  on public.direct_messages for select
  using (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "Accepted readers send messages"
  on public.direct_messages for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.friend_requests fr
      where fr.status = 'accepted'
        and (
          (fr.sender_id = auth.uid() and fr.receiver_id = receiver_id)
          or (fr.receiver_id = auth.uid() and fr.sender_id = receiver_id)
        )
    )
  );

-- 4. Enable live Realtime updates for requests & messages
alter publication supabase_realtime add table public.friend_requests;
alter publication supabase_realtime add table public.direct_messages;
