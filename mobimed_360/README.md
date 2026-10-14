# MobiMed-360 — Cross-Platform Healthcare Application

> *"MobiMed is an application to help you to reach the best global doctors and can book appointment for live consultant and purchase the medicine online the nearest medical store & find the nearest pathology & online services from Hospital."*

---

## 📚 Project Documentation Index

| # | Document | Description |
| :--- | :--- | :--- |
| **01** | [**Product Requirements (`01_PRODUCT_REQUIREMENTS.md`)**](./docs/01_PRODUCT_REQUIREMENTS.md) | Vision, exact 5 Wireframe Views (`First View` to `Fifth View`), 5 Stakeholder Personas (`Patient`, `Doctor`, `Hospital`, `Pathology`, `Medi-Store`), and KPIs. |
| **02** | [**Technical Requirements (`02_TECHNICAL_REQUIREMENTS.md`)**](./docs/02_TECHNICAL_REQUIREMENTS.md) | Jev AI tech selection (Flutter + LiveKit WebRTC + PostGIS + Stripe/Razorpay), lightweight binary budgets, and system architecture. |
| **03** | [**Security & Access (`03_SECURITY_AND_ACCESS.md`)**](./docs/03_SECURITY_AND_ACCESS.md) | Google (`\|G\|`) & Apple (`\|A\|`) OAuth2, Mobile OTP, `Appointments` route guard (*"If login then open, otherwise ask to login"*), and 5-Role RBAC matrix. |
| **04** | [**Front-End Architecture (`04_FRONTEND_ARCHITECTURE.md`)**](./docs/04_FRONTEND_ARCHITECTURE.md) | Wireframe-to-widget mapping (`(@)` $\rightarrow$ `(P)`, `\|\|\|` $\rightarrow$ `\|*\|`, `< Services` flyout, 3s splash timer), state machine, and folder structure. |
| **05** | [**Backend Architecture (`05_BACKEND_ARCHITECTURE.md`)**](./docs/05_BACKEND_ARCHITECTURE.md) | PostgreSQL + PostGIS ER diagram, `ST_DWithin` nearest Medi-Store/Pathology/Hospital query, and REST/WebSocket API endpoints. |
| **06** | [**Feature Tickets (`06_FEATURE_TICKETS.md`)**](./docs/06_FEATURE_TICKETS.md) | Sprint-ready engineering backlog (`MM-101` through `MM-206`) with story points, priorities, and acceptance criteria. |

---

## 📱 Wireframe Views Implemented (`Views 1–5`)

1. **First View (`3-Sec Splash`)**: Displays `MobiMed-360` header with `(@)` and `|||` icons and centered `"Welcome To MobiMed 360"`, disappearing automatically after 3 seconds.
2. **Second View (`Home & Discovery`)**: Displays the MobiMed-360 mission statement and quick access to Global Doctors, Nearest Medi-Store, Nearest Pathology, and Hospital Online Services.
3. **Third View (`||| -> |*| Hamburger Menu & < Services Flyout`)**: Opens `Home`, `< Services` (expanding `Doctors`, `Medi-store`, `Pathology`, `Hospital`), `Appointments` (**auto-checks login state and prompts login if unauthenticated**), `About`, and `Support`.
4. **Fourth View (`(@) -> (P) 5-Role Switcher`)**: Opens the role selector (`> Patient`, `> Doctor`, `> Hospital`, `> Pathology`, `> Medi-Store`).
5. **Fifth View (`SignUp / Login Modal`)**: Dismissible (`*`) modal with `Continue with |G| |A| or Mobile Number` and `Login` action.

---

## 🚀 Quick Start

### 1. Run the Instant Interactive 5-View Prototype (Web / Mobile Browser)
Open [`web_preview/index.html`](./web_preview/index.html) in any browser:
```powershell
Start-Process "C:\Users\Admin\.gemini\antigravity\scratch\mobimed_360\web_preview\index.html"
```

### 2. Run the Native Cross-Platform Flutter App ([`lib/main.dart`](./lib/main.dart))
```powershell
flutter pub get
flutter run
```
