-- ==============================================================================
-- CHESSGO DATABASE SCHEMA FOR SUPABASE
-- Run this script in the Supabase SQL Editor (Dashboard > SQL Editor)
-- ==============================================================================

-- 1. Profiles Table
create table if not exists public.profiles (
    id uuid references auth.users on delete cascade primary key,
    username text unique,
    display_name text,
    avatar_url text,
    elo_rating integer default 1200 not null,
    wins integer default 0 not null,
    losses integer default 0 not null,
    draws integer default 0 not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Index for leaderboard queries
create index if not exists idx_profiles_elo on public.profiles (elo_rating desc);

-- 2. Matches Table (Online games)
create table if not exists public.matches (
    id uuid default gen_random_uuid() primary key,
    white_id uuid references public.profiles(id) on delete set null,
    black_id uuid references public.profiles(id) on delete set null,
    fen text not null default 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    pgn text default '',
    last_move text,
    status text default 'waiting' not null, -- 'waiting', 'in_progress', 'checkmate', 'resigned', 'timeout', 'draw', 'abandoned'
    winner_id uuid references public.profiles(id) on delete set null,
    time_control_seconds integer default 300 not null,
    white_time_left_ms integer default 300000 not null,
    black_time_left_ms integer default 300000 not null,
    current_turn text default 'w' not null, -- 'w' or 'b'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_matches_status on public.matches (status);
create index if not exists idx_matches_players on public.matches (white_id, black_id);

-- 3. Private Game Rooms Table
create table if not exists public.rooms (
    code text primary key,
    host_id uuid references public.profiles(id) on delete cascade not null,
    guest_id uuid references public.profiles(id) on delete set null,
    time_control_seconds integer default 300 not null,
    status text default 'open' not null, -- 'open', 'playing', 'closed'
    match_id uuid references public.matches(id) on delete set null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_rooms_status on public.rooms (status);

-- 4. Matchmaking Queue Table
create table if not exists public.matchmaking_queue (
    id uuid default gen_random_uuid() primary key,
    player_id uuid references public.profiles(id) on delete cascade unique not null,
    elo_rating integer default 1200 not null,
    time_control_seconds integer default 300 not null,
    match_id uuid references public.matches(id) on delete cascade,
    status text default 'searching' not null, -- 'searching', 'matched', 'cancelled'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

alter table public.profiles enable row level security;
alter table public.matches enable row level security;
alter table public.rooms enable row level security;
alter table public.matchmaking_queue enable row level security;

-- Profiles Policies
create policy "Allow public read of profiles"
    on public.profiles for select
    using (true);

create policy "Users can update their own profile"
    on public.profiles for update
    using (auth.uid() = id);

create policy "Users can insert their own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

-- Matches Policies
create policy "Allow public read of matches"
    on public.matches for select
    using (true);

create policy "Allow authenticated users to create matches"
    on public.matches for insert
    with check (auth.role() = 'authenticated');

create policy "Allow players to update their matches"
    on public.matches for update
    using (auth.uid() = white_id or auth.uid() = black_id);

-- Rooms Policies
create policy "Allow public read of rooms"
    on public.rooms for select
    using (true);

create policy "Allow authenticated users to create rooms"
    on public.rooms for insert
    with check (auth.uid() = host_id);

create policy "Allow host or guest to update rooms"
    on public.rooms for update
    using (auth.uid() = host_id or auth.uid() = guest_id);

create policy "Allow host to delete rooms"
    on public.rooms for delete
    using (auth.uid() = host_id);

-- Matchmaking Queue Policies
create policy "Allow read on matchmaking queue"
    on public.matchmaking_queue for select
    using (true);

create policy "Allow player to insert into matchmaking queue"
    on public.matchmaking_queue for insert
    with check (auth.uid() = player_id);

create policy "Allow player to update their matchmaking queue entry"
    on public.matchmaking_queue for update
    using (true);

create policy "Allow player to delete their queue entry"
    on public.matchmaking_queue for delete
    using (auth.uid() = player_id);

-- ==============================================================================
-- AUTOMATIC PROFILE CREATION TRIGGER ON USER SIGNUP
-- ==============================================================================

create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, username, display_name, avatar_url, elo_rating)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
        coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
        coalesce(new.raw_user_meta_data->>'avatar_url', ''),
        1200
    )
    on conflict (id) do nothing;
    return new;
end;
$$ language plpgsql security definer;

-- Trigger definition
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- ==============================================================================
-- REALTIME REPLICATION ENABLEMENT
-- ==============================================================================

-- Enable realtime for tables
alter publication supabase_realtime add table public.matches;
alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.matchmaking_queue;
