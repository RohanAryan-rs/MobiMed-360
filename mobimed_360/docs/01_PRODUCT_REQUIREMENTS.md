# Product Requirements Document (PRD) — MobiMed-360

**Product Name:** MobiMed-360  
**Target Platforms:** Android, iOS, Web (PWA), Windows, macOS, Linux  
**Primary Objective:** A lightweight, ultra-reliable cross-platform healthcare application connecting patients with global doctors for live consultations, nearest medical stores for online medicine purchases, nearest pathology labs for diagnostics, and hospital online services.

---

## 1. Product Vision & Value Proposition
> *"MobiMed is an application to help you to reach the best global doctors and can book appointment for live consultant and purchase the medicine online the nearest medical store & find the nearest pathology & online services from Hospital."*

MobiMed-360 unifies five healthcare stakeholders (**Patient**, **Doctor**, **Hospital**, **Pathology**, and **Medi-Store**) into a single lightweight application with unauthenticated browsing for discovery and strict authentication guards for transactional actions (such as opening **Appointments** or completing **Checkout**).

---

## 2. Core User Flows & Wireframe Views

### View 1: Splash View (`First View`)
* **Behavior:** Displays immediately on app launch and automatically transitions after **3 seconds** (`3000ms`) to View 2.
* **Layout:**
  * Persistent top bar showing `MobiMed-360` brand on the left, Profile/Role icon `(@)` and Hamburger Menu icon `|||` on the right.
  * Centered welcome typography: **"Welcome To MobiMed 360"**.

### View 2: Home & Mission View (`Second View`)
* **Behavior:** Default landing screen after the 3-second splash transition.
* **Layout:**
  * Displays the MobiMed-360 mission statement and quick-action entry cards for:
    1. **Global Doctors & Live Consultant Booking**
    2. **Nearest Medi-Store (Online Medicine Purchase)**
    3. **Nearest Pathology Labs (Test Booking & Reports)**
    4. **Hospital Online Services (OPD, ICU/Bed Availability, Emergency)**

### View 3: Primary Navigation & Cascading Services Menu (`Third View`)
* **Trigger:** Tapping the top-right Hamburger Menu icon `|||` toggles its state to `|*|` and opens the primary dropdown menu:
  * **Home**
  * **`< Services`** (Hovering or tapping expands a secondary flyout sub-menu on the left):
    * `Doctors`
    * `Medi-store`
    * `Pathology`
    * `Hospitals & Emergency`
  * **Appointments** *(Auth Guard Rule: **If logged in, open Appointments screen; otherwise, automatically open the Fifth View Login/SignUp modal**)*
  * **About**
  * **Support**

### View 4: Multi-Role Portal Selector (`Fourth View`)
* **Trigger:** Tapping the top-right Profile/Role icon `(@)` changes its active state to `(P)` and opens the 5-Role Portal dropdown:
  * `> Patient`
  * `> Doctor`
  * `> Hospital`
  * `> Pathology`
  * `> Medi-Store`
* **Behavior:** Selecting any of the 5 roles opens the role-specific authentication/registration modal (View 5) or switches to that role's dashboard if already authenticated.

### View 5: Unified SignUp / Login Modal (`Fifth View`)
* **Trigger:** Opened when a user selects a role in View 4, or when an unauthenticated user clicks a protected route like **Appointments** in View 3.
* **Layout:**
  * Dismissible modal card with top-right close button (`*`).
  * **SignUp / Continue with:**
    * `|G|` **Google OAuth 2.0 Sign-In**
    * `|A|` **Apple ID Sign-In**
  * **Divider:** `or`
  * **Mobile Number Input:** Phone number field with OTP verification (`Mobile Number` + underline input).
  * **Primary Action:** `Login` button.

---

## 3. Stakeholder Personas & Portal Capabilities

| Role (`(P)` Menu) | Key Capabilities |
| :--- | :--- |
| **1. Patient** | Search global doctors, book & join live video consultations, buy medicines from nearest Medi-Store, book home sample collection from nearest Pathology, book Hospital OPD/services, pay via unified checkout. |
| **2. Doctor** | Manage availability schedule, view upcoming patient appointment queue, host live HD WebRTC video consultations, issue digital e-prescriptions. |
| **3. Hospital** | Publish real-time ICU/Ward bed availability, manage department OPD slots, handle emergency dispatch & cashless insurance requests. |
| **4. Pathology** | List diagnostic test packages, assign phlebotomists for home sample collection, upload verified PDF pathology reports. |
| **5. Medi-Store** | Manage local pharmacy inventory, verify uploaded patient prescriptions (`Rx`), fulfill 30-minute hyperlocal medicine deliveries. |

---

## 4. Success Metrics (KPIs)
* **Splash-to-Interactive Time:** $\le 3.0\text{ seconds}$ (strictly matching First View spec).
* **App Binary Size:** $< 8\text{ MB}$ on Android/iOS; $< 500\text{ KB}$ initial bundle on Web PWA.
* **Live Video Call Connection Time:** $< 1.5\text{ seconds}$ via WebRTC.
* **Nearest Store/Lab Geo-Query Latency:** $< 120\text{ ms}$ p95.
