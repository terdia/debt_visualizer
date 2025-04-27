begin;

-- Drop existing functions and types
drop function if exists public.handle_updated_at();
drop function if exists public.handle_new_user();
drop function if exists public.verify_purchase(uuid, text, text, text, text);
drop type if exists public.purchase_verification_result;

-- Create updated_at trigger function
create function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Create new user trigger function
create function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, email)
    values (new.id, new.email);
    return new;
end;
$$ language plpgsql security definer;

-- Create purchase verification type and function
create type purchase_verification_result as (
    is_valid boolean,
    subscription_id text,
    expires_at timestamptz
);

create function public.verify_purchase(
    p_user_id uuid,
    p_purchase_id text,
    p_product_id text,
    p_platform text,
    p_receipt text
) returns purchase_verification_result
security definer
set search_path = public
language plpgsql
as $$
declare
    v_result purchase_verification_result;
    v_expires_at timestamptz;
begin
    -- Validate platform
    if p_platform not in ('ios', 'android') then
        raise exception 'Invalid platform';
    end if;

    -- In a real implementation, you would verify the receipt with Apple/Google here
    -- For now, we'll assume it's valid and set a 30-day expiration
    v_expires_at := now() + interval '30 days';

    -- Insert or update subscription
    insert into public.subscriptions (
        user_id,
        status,
        platform,
        store_subscription_id,
        current_period_start,
        current_period_end
    )
    values (
        p_user_id,
        'active',
        p_platform,
        p_purchase_id,
        now(),
        v_expires_at
    )
    on conflict (user_id) do update
    set
        status = 'active',
        store_subscription_id = excluded.store_subscription_id,
        current_period_start = excluded.current_period_start,
        current_period_end = excluded.current_period_end;

    -- Return result
    v_result.is_valid := true;
    v_result.subscription_id := p_purchase_id;
    v_result.expires_at := v_expires_at;

    return v_result;
end;
$$;

commit;
