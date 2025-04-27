begin;

-- Drop tables if they exist
drop table if exists public.subscriptions;
drop table if exists public.debt_profiles;
drop table if exists public.profiles;

-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- Create profiles table
create table public.profiles (
    id uuid references auth.users on delete cascade not null primary key,
    email text unique not null check (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    created_at timestamptz default now() not null,
    updated_at timestamptz default now() not null
);

-- Create debt_profiles table
create table public.debt_profiles (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    name text not null,
    description text,
    total_debt decimal not null check (total_debt >= 0),
    interest_rate decimal not null check (interest_rate >= 0),
    monthly_payment decimal not null check (monthly_payment > 0),
    amount_paid decimal not null default 0 check (amount_paid >= 0 and amount_paid <= total_debt),
    hourly_wage decimal check (hourly_wage > 0),
    currency jsonb not null default '{"code": "USD", "symbol": "$"}',
    created_at timestamptz default now() not null,
    updated_at timestamptz default now() not null
);

-- Create subscriptions table
create table public.subscriptions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null unique,
    status text not null check (status in ('active', 'canceled', 'past_due')),
    platform text not null check (platform in ('ios', 'android')),
    store_subscription_id text not null,
    current_period_start timestamptz not null,
    current_period_end timestamptz not null,
    created_at timestamptz default now() not null,
    updated_at timestamptz default now() not null
);

commit;
