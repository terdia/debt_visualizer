begin;

-- Drop existing triggers
drop trigger if exists handle_updated_at on public.subscriptions;
drop trigger if exists handle_updated_at on public.debt_profiles;
drop trigger if exists handle_updated_at on public.profiles;
drop trigger if exists on_auth_user_created on auth.users;

-- Enable Row Level Security
alter table public.profiles enable row level security;
alter table public.debt_profiles enable row level security;
alter table public.subscriptions enable row level security;

-- Create policies for profiles
create policy "Users can view own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- Create policies for debt_profiles
create policy "Users can view own debt profiles"
    on public.debt_profiles for select
    using (auth.uid() = user_id);

create policy "Users can insert own debt profiles"
    on public.debt_profiles for insert
    with check (auth.uid() = user_id);

create policy "Users can update own debt profiles"
    on public.debt_profiles for update
    using (auth.uid() = user_id);

create policy "Users can delete own debt profiles"
    on public.debt_profiles for delete
    using (auth.uid() = user_id);

-- Create policies for subscriptions
create policy "Users can view own subscriptions"
    on public.subscriptions for select
    using (auth.uid() = user_id);

-- Create triggers
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

create trigger handle_updated_at
    before update on public.profiles
    for each row execute procedure public.handle_updated_at();

create trigger handle_updated_at
    before update on public.debt_profiles
    for each row execute procedure public.handle_updated_at();

create trigger handle_updated_at
    before update on public.subscriptions
    for each row execute procedure public.handle_updated_at();

commit;
