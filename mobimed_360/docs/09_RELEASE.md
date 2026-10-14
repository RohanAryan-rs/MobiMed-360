# Release path under the free-only constraint

## Free distribution now

Build the web preview with `flutter build web --release`. Host the resulting `build/web` directory on an HTTPS static host using its free plan. The ZIP in `dist` is a static deployment artifact; it does not create a hosting account. Browser installation requires HTTPS (localhost is allowed for testing). Offline caching covers public application assets only and depends on an initial online visit.

For Android, a debug APK is a local testing artifact, not a Play Store submission. Install on a trusted test device after enabling installation from your chosen source. No store account is needed for local testing. Check the actual current Android distribution rules before publicly distributing an APK.

For iPhone/iPad, use the web app and Add to Home Screen. Native iOS compilation and signing require macOS/Xcode. A free Apple ID supports limited personal device testing; App Store distribution normally requires a paid program membership.

Official release/account sources checked October 14, 2026:
- Apple Developer Program: https://developer.apple.com/programs/ — normally USD 99/year; eligible organizations may qualify for a waiver.
- Google Play account registration: https://support.google.com/googleplay/android-developer/answer/6112435 — USD 25 one-time registration fee.
- Flutter deployment: https://docs.flutter.dev/deployment

## Supabase Free setup

The existing Cross-Question organization is Free. The connected project's creation was not completed because the required connector cost tool is unavailable; CLI credentials are also absent. No paid project was created or any existing database changed.

1. In your own Supabase dashboard, choose Cross-Question, verify Free plan and free-project capacity, and create MobiMed in an appropriate region. Select the region for the operator's data requirements; there is no single worldwide medical-data jurisdiction.
2. Apply `supabase/migrations/20261014153931_initial_care_schema.sql` to the new project's SQL editor. This is an initial schema, not an idempotent upgrade script.
3. Enable email confirmation, a 12-character password minimum, 15-minute JWT expiry and appropriate signup abuse controls. Configure site/redirect URLs for the actual HTTPS host. Mirror applicable values from `supabase/config.toml` into the hosted dashboard; the local config file does not configure a hosted project by itself.
4. Configure an SMTP provider and sender identity within its free quota. Supabase's default mailer only permits authorized team email recipients and is unsuitable for unrestricted public signup. Never disable verification as a workaround.
5. Obtain the project URL and publishable key; copy `config/backend.example.json` to `config/backend.json`. Never put a service-role/secret key in frontend config.
6. Create provider accounts through Auth; the operator inserts licensed providers with the actual `owner_id`, country, service category, currency, price and `verified=true` only after verification. Currency amounts are stored in the currency's smallest unit despite legacy column names ending in `_cents`.
7. Add non-prescription product catalog rows through an authorized operator account. Providers can publish their own slots and update only permitted fields. The public directory is deliberately empty until real providers exist.
8. Run the connected build:

```powershell
flutter build web --release --dart-define=DEMO_MODE=false --dart-define-from-file=config/backend.json
```

9. Test with two real test accounts, run Supabase security/performance advisors, and verify that cross-user access is denied on the hosted project. Local PGlite checks are not a substitute for those hosted checks.

Free plan limits include database/storage/egress quotas and inactivity pausing. Do not claim clinical production availability or healthcare compliance from use of the free plan. Consult https://supabase.com/pricing and https://supabase.com/docs/guides/platform/free-project-pausing.

## Payments

Stripe is the proposed international provider where the operator's business country and healthcare activity are supported. Standard pricing has no setup/monthly fee, but live processing has transaction and potentially currency/cross-border fees. A marketplace paying multiple providers also needs appropriate payout/onboarding design.

Sources: https://stripe.com/global and https://stripe.com/pricing.

The included function supports **test mode only**. It refuses `sk_live_` keys, reads an authenticated user's own order under RLS, uses the database total and sends only a generic test-order label. It never marks an order paid, fulfills an order or processes real money.

To test after backend setup:
1. Set private function secrets `STRIPE_TEST_SECRET_KEY`, `SUPABASE_PUBLISHABLE_KEY`, and `APP_ORIGIN` (the real HTTPS origin). Keep all secrets outside source control.
2. Deploy `stripe-test-checkout` with Supabase CLI. Its `verify_jwt=false` gateway setting is intentional: the handler verifies the Bearer session with Auth itself before accessing data under RLS.
3. Set `STRIPE_TEST_MODE=true` in the connected build configuration. An order's test-payment button opens hosted Stripe checkout. Use Stripe test card data only.
4. A return URL does not prove payment. Implement and test signed webhooks, amount/currency verification, idempotent fulfillment and refunds before any future live payment rollout.

Current free connected checkout requests orders and lets payment be arranged directly with the provider. It never promises cash on delivery, shipping or successful payment.

## Android signing and store release later

The provisional application ID is `com.mobimed.mobimed_360`; confirm the operator's final identifier before first store submission. Copy `android/key.properties.example` to ignored `android/key.properties` and configure an operator-owned upload key. Release builds refuse missing signing configuration; debug signing is never used as a release fallback.

```powershell
flutter build appbundle --release --dart-define=DEMO_MODE=false --dart-define-from-file=config/backend.json
```

Do not upload the current demonstration as a completed clinical app. Store launch also requires a privacy-policy URL, support contact, account-deletion web route, operator/legal entity, accurate health/data-safety declarations, app screenshots, device testing and enabled live features. Deletion requests must be monitored and processed, not merely recorded.

Sources: https://developer.apple.com/app-store/review/guidelines/ ; https://developer.apple.com/support/offering-account-deletion-in-your-app/ ; https://support.google.com/googleplay/android-developer/answer/16679511 ; https://support.google.com/googleplay/android-developer/answer/13327111.

## iOS release later

Open `ios/Runner.xcworkspace` on macOS, select the operator's team and final bundle ID, configure appropriate entitlements for enabled integrations, and archive with Xcode or `flutter build ipa`. The CI job checks compilation without code signing only; it has not run from this local workspace. No IPA or App Store submission is claimed from Windows.

## Remaining scope before a full clinical service

Live video and prescriptions, secure pathology reports, Rx verification, addresses/delivery, nearest-location queries, provider fulfillment, translations, provider jurisdictions, clinical consent/retention and service contracts remain required. They cannot be replaced by success messages or free demo data. The operator must choose supported territories and backend/service configurations before those features can go live.
