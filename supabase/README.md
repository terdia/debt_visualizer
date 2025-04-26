# Supabase Setup for Debt Visualizer

## Database Structure

### Tables
1. `profiles`
   - User profiles linked to auth.users
   - Stores email and timestamps

2. `debt_profiles`
   - Main debt tracking table
   - Stores debt details, payments, and progress
   - Linked to user profiles

3. `subscriptions`
   - Tracks premium subscriptions
   - Handles both iOS and Android platforms
   - Stores subscription status and period

## Security
- Row Level Security (RLS) enabled on all tables
- Users can only access their own data
- Secure policies for CRUD operations

## Database Functions
1. `verify_purchase`
   - Validates in-app purchases
   - Supports both App Store and Play Store
   - Updates subscription status
   - Returns verification result with expiration date

## Setup Instructions

1. Create a new Supabase project:
   ```bash
   supabase init
   ```

2. Apply migrations:
   ```bash
   supabase db push
   ```

3. Test database functions:
   ```sql
   -- Test purchase verification
   select * from verify_purchase(
       'user_id_here',
       'purchase_id',
       'product_id',
       'ios',
       'receipt_data'
   );
   ```

4. Set up environment variables in Supabase dashboard:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`

5. Configure auth providers in Supabase dashboard:
   - Enable Email/Password sign-in
   - Set up password policies
   - Configure email templates

## In-App Purchase Setup

### iOS
1. Configure products in App Store Connect
2. Set up App Store Server API
3. Generate API keys
4. Update verification logic in Edge Function

### Android
1. Configure products in Play Console
2. Set up Google Play Developer API
3. Generate service account
4. Update verification logic in Edge Function

## Testing
1. Test database migrations:
   ```bash
   supabase db reset
   ```

2. Test database functions:
   ```sql
   -- As authenticated user
   set local role authenticated;
   set local request.jwt.claims to '{"sub": "user_id"}';
   
   -- Test purchase verification
   select * from verify_purchase(
       'user_id',
       'purchase_id',
       'product_id',
       'ios',
       'receipt_data'
   );
   ```

3. Test RLS policies:
   ```sql
   -- Test as authenticated user
   set local role authenticated;
   set local request.jwt.claims to '{"sub": "user_id"}';
   
   -- Try to access data
   select * from debt_profiles;
   ```
