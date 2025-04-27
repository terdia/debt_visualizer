begin;

-- Add new Stripe columns and external_id for cross-platform subscription mapping
alter table public.subscriptions
    add column if not exists stripe_customer_id text,
    add column if not exists stripe_subscription_id text,
    add column if not exists external_id text;

-- Extend acceptable values for the platform column
alter table public.subscriptions
    drop constraint if exists subscriptions_platform_check;

alter table public.subscriptions
    add constraint subscriptions_platform_check
        check (platform in ('ios', 'android', 'apple', 'google', 'stripe'));

commit;
