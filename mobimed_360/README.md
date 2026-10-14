# MobiMed 360

A responsive Flutter healthcare application for phones, tablets and web, with Android and iOS projects. The default build is a clearly labelled, local demonstration. A separate connected build supports Supabase accounts, verified-provider discovery, available-slot bookings, order requests and provider operations.

**Status:** runnable demo and configurable connected application; not a deployed clinical service or store submission. No paid accounts or services have been created. Video consultations, clinical documents and live online payments remain disabled.

## Run the preview

```powershell
X:\MobiMed-360\.tools\flutter\bin\flutter.bat run -d chrome
```

The built web app can be served locally:

```powershell
python -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Open http://127.0.0.1:8765. Install it from the browser's app/install menu where supported. The web shell caches public assets only; authenticated backend responses are never cached. Offline connected bookings require a network connection. Demo data lasts for the running app session.

## Connected build

Create a free Supabase project, apply the migration in `supabase/migrations`, configure Auth and onboard verified providers. Then:

```powershell
flutter run -d chrome --dart-define=DEMO_MODE=false --dart-define-from-file=config/backend.json
```

Copy `config/backend.example.json` to `config/backend.json` and set the project URL and **publishable** key. Never use a service-role key in the app. Sessions are memory-only. Clinical record collection is disabled.

The account's Cross-Question organization was confirmed to be on the Free plan. Cloud project provisioning could not be completed: the connector's required `get_cost` tool is unavailable and the CLI has no authenticated access token. No unrelated project was modified.

## Features

- Medical visual theme, editable app icon, phone bottom navigation and tablet navigation rail.
- Searchable doctors, pharmacy essentials, diagnostic and hospital service directories.
- Demo date/time selection, duplicate-time checks, appointment cancellation, cart quantities, order history and data reset.
- Four demo provider workspaces; connected workspaces require server-assigned ownership and verified providers.
- Connected email registration/sign-in, recovery, published-slot requests, cancellation, pharmacy inventory and hospital capacity updates.
- Database row-level security, atomic bookings, server-priced orders, stock rollback, deletion request capture and multiple currency minor units.
- Optional Stripe **test-only** checkout adapter. It rejects live keys and never marks an order paid.
- Android/iOS/web configuration and validation workflows. Android release builds require real upload-key configuration.

## Validation

```powershell
flutter analyze
flutter test
cd supabase/tests
npm ci
npm test
```

Database tests use in-memory PostgreSQL through PGlite with mocked Supabase identity functions. They exercise RLS, unauthorized access, duplicate booking, server pricing, stock and cancellation. They do not validate hosted Auth, SMTP, deployment, concurrent network requests or clinical compliance.

## Documentation

- `docs/07_PONYTAIL_AUDIT.md`: requested complexity audit.
- `docs/08_IMPLEMENTATION_REVIEW.md`: review of all original requirements and implementation status.
- `docs/09_RELEASE.md`: free release path, backend setup, signing and remaining launch gates.
- `docs/01` through `docs/06`: original requirements, retained as source documents. Claims of an encrypted live stream, sub-8-MB app size or completed payment integration are not verified release claims.
- `docs/original-main.dart.txt` and `docs/original-preview.html.txt`: archived prototype sources.
