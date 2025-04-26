begin;

-- Create currencies table
create table if not exists public.currencies (
  id uuid default uuid_generate_v4() primary key,
  code text not null unique,
  symbol text not null,
  name text not null,
  created_at timestamptz default now() not null
);

-- Insert popular currencies
insert into public.currencies (code, symbol, name)
values
  ('USD', '$', 'US Dollar'),
  ('EUR', '€', 'Euro'),
  ('GBP', '£', 'British Pound'),
  ('JPY', '¥', 'Japanese Yen'),
  ('CAD', 'C$', 'Canadian Dollar'),
  ('AUD', 'A$', 'Australian Dollar'),
  ('CHF', 'Fr', 'Swiss Franc'),
  ('CNY', '¥', 'Chinese Yuan'),
  ('INR', '₹', 'Indian Rupee'),
  ('BRL', 'R$', 'Brazilian Real'),
  ('ZAR', 'R', 'South African Rand'),
  ('NGN', '₦', 'Nigerian Naira'),
  ('MXN', '$', 'Mexican Peso'),
  ('SEK', 'kr', 'Swedish Krona'),
  ('NZD', 'NZ$', 'New Zealand Dollar'),
  ('SGD', 'S$', 'Singapore Dollar'),
  ('HKD', 'HK$', 'Hong Kong Dollar'),
  ('NOK', 'kr', 'Norwegian Krone'),
  ('KRW', '₩', 'South Korean Won'),
  ('TRY', '₺', 'Turkish Lira')
ON CONFLICT (code) DO UPDATE
SET symbol = EXCLUDED.symbol, 
    name = EXCLUDED.name;

-- Add RLS policy for anonymous read access to currencies
alter table public.currencies enable row level security;

create policy "Currencies are viewable by everyone"
  on public.currencies
  for select
  using (true);

commit;
