# Feature Tickets & Sprint Backlog — MobiMed-360

## Epic 1: Core Shell, Splash & Navigation Wireframes (`Views 1–5`)

| Ticket ID | Title | Priority | Story Points | Acceptance Criteria |
| :--- | :--- | :---: | :---: | :--- |
| **MM-101** | **First View: 3-Second Auto-Disappearing Splash Screen** | P0 | 2 | • Shows `MobiMed-360` header with `(@)` and `\|\|\|` icons.<br>• Displays centered `"Welcome To MobiMed 360"`.<br>• Automatically transitions to Second View after exactly `3000ms`. |
| **MM-102** | **Second View: Home Mission & Service Discovery Hub** | P0 | 3 | • Displays the MobiMed-360 mission pitch.<br>• Provides instant cards for Global Doctors, Nearest Medi-Store, Nearest Pathology, and Hospital Online Services. |
| **MM-103** | **Third View: Hamburger Menu (`\|\|\|` $\rightarrow$ `\|*\|`) & Cascading `< Services` Flyout** | P0 | 5 | • Tapping `\|\|\|` switches icon to `\|*\|` and opens menu (`Home`, `< Services`, `Appointments`, `About`, `Support`).<br>• Hovering/tapping `< Services` opens left sub-menu (`Doctors`, `Medi-store`, `Pathology`, `Hospital/etc`).<br>• Clicking `Appointments` checks auth state: **if logged in, opens Appointments; otherwise opens View 5 Login Modal**. |
| **MM-104** | **Fourth View: 5-Role Profile Dropdown (`(@)` $\rightarrow$ `(P)`)** | P0 | 3 | • Tapping `(@)` switches icon to `(P)` and displays `> Patient`, `> Doctor`, `> Hospital`, `> Pathology`, `> Medi-Store`.<br>• Selecting a role opens the View 5 Login/SignUp Modal pre-configured for that role. |
| **MM-105** | **Fifth View: Unified SignUp / Login Modal (`\|G\| \|A\|` & Mobile OTP)** | P0 | 5 | • Displays modal with `*` close button.<br>• Supports `SignUp Continue with |G| |A|` (Google & Apple OAuth) `or Mobile Number` input + `Login` CTA.<br>• Resumes pending route (e.g., `Appointments`) immediately upon login. |

---

## Epic 2: Healthcare Verticals & Unified Checkout

| Ticket ID | Title | Priority | Story Points | Acceptance Criteria |
| :--- | :--- | :---: | :---: | :--- |
| **MM-201** | **Global Doctors Directory & Live WebRTC Video Consult Room** | P0 | 8 | • Filter global doctors by specialty & language.<br>• Book Live Consultant slot.<br>• Join HD WebRTC video call with Mic/Cam/Hangup controls, live chat, and digital E-Prescription. |
| **MM-202** | **Nearest Medi-Store Online Medicine E-Commerce** | P0 | 5 | • Sort medical stores by GPS distance (`km`).<br>• Search medicines, upload Doctor Rx scan, add to cart. |
| **MM-203** | **Nearest Pathology Lab Booking & Smart PDF Reports** | P1 | 5 | • Book home blood/sample collection from nearest NABL pathology lab.<br>• View verified digital pathology report values in-app. |
| **MM-204** | **Hospital Online Services & ICU/OPD Tracker** | P1 | 5 | • View real-time ICU/Ward bed availability and book Hospital OPD priority passes online. |
| **MM-205** | **Multi-Payment Checkout Gateway** | P0 | 5 | • Unified cart for medicines, pathology tests, and doctor/hospital bookings.<br>• Pay via UPI, Credit/Debit Card, Apple/Google Pay, or Cash on Delivery. |
| **MM-206** | **Stakeholder Portals (`Doctor`, `Hospital`, `Pathology`, `Medi-Store`)** | P1 | 8 | • Role-specific management views when logged in under `Doctor`, `Hospital`, `Pathology`, or `Medi-Store` roles. |
