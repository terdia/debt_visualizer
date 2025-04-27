begin;

-- Create subscription_features table
create table if not exists public.subscription_features (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    description text not null,
    icon_name text not null,
    priority integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz default now() not null,
    updated_at timestamptz default now() not null
);

-- Add RLS policies
alter table public.subscription_features enable row level security;

-- Allow public read access to subscription features
create policy "Anyone can read subscription features" 
on public.subscription_features 
for select 
to authenticated, anon
using (true);

-- Only allow admins to insert, update, delete
create policy "Only admins can insert subscription features" 
on public.subscription_features 
for insert 
to authenticated
with check (exists (
    select 1 from public.profiles 
    where profiles.id = auth.uid() and profiles.email = 'terdia4christ@gmail.com'
));

create policy "Only admins can update subscription features" 
on public.subscription_features 
for update 
to authenticated
using (exists (
    select 1 from public.profiles 
    where profiles.id = auth.uid() and profiles.email = 'terdia4christ@gmail.com'
));

create policy "Only admins can delete subscription features" 
on public.subscription_features 
for delete
to authenticated
using (exists (
    select 1 from public.profiles 
    where profiles.id = auth.uid() and profiles.email = 'terdia4christ@gmail.com'
));

-- Insert initial subscription features
insert into public.subscription_features (title, description, icon_name, priority) values 
('Unlimited Profiles', 'Create and compare as many debt profiles as you need with no limits', 'collections_bookmark', 1),
('Advanced Comparison', 'Compare different debt repayment strategies and see their long-term impact', 'analytics', 2),
('Data Export', 'Export your debt data and reports in multiple formats', 'download', 3),
('Cloud Sync', 'Sync your debt data across multiple devices by upgrading to Debt Visualizer Premium', 'sync', 4),
('Premium Education', 'Access exclusive financial education content and debt management strategies', 'school', 5);

commit;
