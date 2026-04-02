# WellxPetsSDK — UI/UX & Product Audit

**Project:** WellxPetsSDK Flutter Module
**Audit Date:** 2026-04-02
**Platform:** iOS / Android (Flutter)
**Comparison Baseline:** FureverApp (iOS native, Swift/SwiftUI)

---

## Executive Summary

The WellxPetsSDK is a Flutter-based pet health management module at **late-alpha / early-beta** stage. It implements ~65% of the iOS FureverApp's features but at ~40% of the visual sophistication. Core flows (add pet, BCS scan, vet chat, document management) are structurally present after recent P0/P1 fixes, but several screens lack polish, error handling, and loading states. The SDK is functional enough for internal testing but not production-ready for end users.

**Overall Product Readiness: 5/10 (Late Alpha)**

---

## 1. Screen Inventory

### Core Screens (lib/src/screens/)

| Screen | File | Purpose | Status |
|--------|------|---------|--------|
| Home | `home/home_screen.dart` | Pet dashboard, locked score card, daily plan, explore section | Functional |
| Add Pet | `pets/add_pet_screen.dart` | Create new pet with photo, breed, weight, DOB | Functional (photo upload has error handling now) |
| Edit Pet | `pets/edit_pet_screen.dart` | Modify pet details | Functional |
| Pet Detail | `pets/pet_detail_screen.dart` | Pet profile with health summary, nav to sub-features | Functional |
| Health Dashboard | `health/health_dashboard_screen.dart` | Biomarkers, score breakdown, medication tab with FAB | Functional (score now persists) |
| BCS Scan Flow | `track/track_bcs_flow.dart` | Camera → AI body condition scoring | Functional (now saves via BCSService) |
| Track Screen | `track/track_screen.dart` | Health tracking hub: BCS, urine, wellness, blood panel | Functional |
| Vet Chat (Dr. Layla) | `chat/vet_chat_screen.dart` | AI-powered veterinary chat with health context | Functional (chat history no longer resets) |
| Documents / Wallet | `wallet/wallet_screen.dart` | Upload, view, categorize pet documents | Functional (upload now sends file bytes) |
| Reports | `report/report_screen.dart` | Health report with PDF export | Functional (PDF generation implemented) |
| Travel | `travel/travel_screen.dart` | Pet travel readiness by country | Functional (placeholder landscape images) |
| Venues | `venues/venues_screen.dart` | Pet-friendly venues list | Functional (placeholder images) |
| Medications | `medications/medications_screen.dart` | Medication list with supply tracking | Functional |
| Wellness Survey | `health/wellness_survey_screen.dart` | 6-question health survey | New — Functional |
| OCR Scan | `track/ocr_scan_screen.dart` | Blood panel document scanning | Present (UI only) |
| Settings | `settings/settings_screen.dart` | App settings | Basic |
| Onboarding | `onboarding/onboarding_screen.dart` | First-time user flow | Basic |

### Navigation Routes (navigation/navigation_router.dart)

All screens are connected via go_router. Routes include: `/home`, `/pets/add`, `/pets/:id`, `/pets/:id/edit`, `/health`, `/track`, `/track/bcs`, `/chat`, `/wallet`, `/reports`, `/travel`, `/venues`, `/medications/:petId`, `/ocr-scan`, `/wellness-survey`, `/settings`, `/onboarding`.

---

## 2. User Journey Analysis

### 2.1 Onboarding → Add Pet → Unlock Score
- **Flow:** Onboarding → Home (empty state: "Add Your First Pet") → Add Pet → Home (locked score card) → Take Body Photo → BCS Scan → Score Unlocks
- **Status:** Complete after P0 fixes
- **Issues:**
  - No guided tutorial or tooltips for first-time users
  - The transition from "locked score" to "unlocked score" is not animated or celebrated
  - No breed/species auto-complete — manual text entry only

### 2.2 Health Check (BCS Scan)
- **Flow:** Home "Take Body Photo" → Camera → AI analysis → BCS result → Saved to Supabase
- **Status:** Fixed in P0 — BCSService now persists results
- **Issues:**
  - No progress indicator during AI analysis (can take several seconds)
  - No retry mechanism if camera fails
  - BCS result display could show comparison to previous scans

### 2.3 Vet Chat (Dr. Layla)
- **Flow:** Home "Ask Dr. Layla" → Chat screen with health context in system prompt
- **Status:** Functional — chat history no longer resets on provider rebuild
- **Issues:**
  - Full medical history sent in every system prompt (privacy concern flagged in security audit)
  - No typing indicator while waiting for AI response
  - No image sharing capability (unlike iOS version which has PhotosPicker)
  - Chat history is in-memory only — lost on app restart

### 2.4 Document Management
- **Flow:** Home "Upload a Document" or Pet Detail → Wallet → Upload via camera/gallery → Categorize → Stored in Supabase
- **Status:** Fixed in P0 — file bytes now actually sent to Supabase storage
- **Issues:**
  - No file size limit (security concern)
  - No preview for uploaded documents
  - No search/filter for documents
  - Category selection is basic — no custom categories

### 2.5 Reports & Export
- **Flow:** Reports tab → View health summary → Export as PDF
- **Status:** Fixed in P0 — PDF generation implemented with pet info, score, pillars, biomarkers, meds, records
- **Issues:**
  - PDF is basic text layout — no branding, charts, or visual design
  - No option to email or share directly to vet
  - No historical trend data in reports

### 2.6 Travel & Venues
- **Flow:** Home Explore section → Travel or Venues screen
- **Status:** Functional with placeholder images
- **Issues:**
  - Travel data appears to be hardcoded/mock — no real API for travel requirements
  - Venue data similarly mock — no real venue database or location-based search
  - Images are from picsum.photos (placeholder service) — not real destination/venue photos
  - No map integration for venues

---

## 3. UI Consistency Audit

### 3.1 Color Palette
- **Primary:** Dark navy (#1A1A2E style) for headers and cards
- **Accent:** Various — not fully standardized
- **Issue:** 50+ uses of `withOpacity()` (deprecated) scattered across files
- **Issue:** Colors are hardcoded in individual screens rather than from a centralized theme
- **Recommendation:** Create a `WellxTheme` extension with standardized color tokens

### 3.2 Typography
- **Headers:** Generally consistent sizing
- **Body text:** Mostly default Material Design
- **Issue:** No custom font family — uses system default
- **Issue:** No text style constants — sizes/weights defined inline per screen
- **Recommendation:** Define a `WellxTextStyles` class for consistent typography

### 3.3 Spacing & Layout
- **Padding:** Generally 16px horizontal, varies vertically
- **Issue:** Inconsistent spacing between sections across screens
- **Recommendation:** Standardize with spacing constants (4, 8, 12, 16, 24, 32)

### 3.4 Button Styles
- **Primary:** Dark filled buttons
- **Secondary:** Outlined buttons
- **Issue:** Button corner radius varies between screens
- **Issue:** Some screens use ElevatedButton, others use custom InkWell wrappers

### 3.5 Card Styles
- **Home cards:** Rounded with shadow — good
- **List cards:** Mixed styles across screens
- **Issue:** Card elevation and border radius not standardized

---

## 4. iOS Feature Parity

### Features in iOS FureverApp NOT in Flutter SDK:

| Feature | iOS Status | Flutter Status | Gap |
|---------|-----------|---------------|-----|
| Photo sharing with Dr. Layla (PhotosPicker) | ✅ Full | ❌ Missing | High |
| Health score animation (circular progress) | ✅ Animated | ⚠️ Basic | Medium |
| Confidence/accuracy meter | ✅ Full | ❌ Missing | Medium |
| WellX Drive integration | ✅ Full | ❌ Missing (separate project) | N/A |
| Analytics tracking (17 events) | ✅ Full | ❌ Missing | High |
| Custom fonts & brand typography | ✅ Full | ❌ System default | Medium |
| Pull-to-refresh on lists | ✅ Full | ❌ Missing | Low |
| Haptic feedback on actions | ✅ Full | ❌ Missing | Low |
| Push notifications | ✅ Full | ❌ Missing | High |
| Offline mode / data caching | ✅ Partial | ❌ None | High |

### Features in Flutter SDK NOT in iOS:

| Feature | Flutter Status | iOS Status |
|---------|---------------|-----------|
| Wellness Survey (6 questions) | ✅ New | ❌ Missing |
| Medications supply tracking | ✅ Full | ⚠️ Basic |
| OCR blood panel scan | ✅ UI present | ❌ Missing |
| PDF report export | ✅ Full | ❌ Missing |

**Feature Parity Rating: ~55%** (up from ~40% before P0/P1 fixes)

---

## 5. Accessibility Audit

| Area | Status | Details |
|------|--------|---------|
| Semantic labels | ❌ Missing | No `Semantics` widgets on interactive elements |
| Color contrast | ⚠️ Partial | Dark cards on white background = good. Small text on colored backgrounds = needs check |
| Touch targets | ⚠️ Partial | Most buttons meet 44x44 minimum. Some icon buttons may be too small |
| Screen reader | ❌ Not tested | No `Semantics` tree, no `ExcludeSemantics` where needed |
| Dynamic text size | ❌ Missing | Hardcoded font sizes — won't respect system accessibility settings |
| Keyboard navigation | ❌ Not tested | No `FocusNode` management |

**Accessibility Rating: 2/10** — Significant work needed for WCAG compliance

---

## 6. Performance Concerns

| Area | Concern | Severity |
|------|---------|----------|
| Riverpod rebuilds | Vet chat provider was causing cascading rebuilds (now fixed) | Fixed |
| Image loading | Using `Image.network` without caching — re-downloads on every rebuild | Medium |
| Large lists | Need to verify `ListView.builder` usage in medications, documents, venues | Low |
| PDF generation | Synchronous on main thread — could freeze UI for large reports | Medium |
| Supabase queries | No pagination on pet lists, health records, documents | Medium |
| Memory | Photo picker results (file bytes) held in memory during upload — large files could cause OOM | Medium |

---

## 7. Product Completeness Rating

### Fully Functional (End-to-End):
1. ✅ Add/edit pet with photo
2. ✅ BCS body condition scan with persistence
3. ✅ AI vet chat (Dr. Layla) with health context
4. ✅ Document upload with file bytes to Supabase
5. ✅ PDF report export
6. ✅ Medication tracking with supply bars
7. ✅ Wellness survey
8. ✅ Health score calculation and persistence
9. ✅ Daily plan / task list on home

### Partially Implemented (UI present, limited backend):
1. ⚠️ Travel readiness (mock data, no real API)
2. ⚠️ Venues (mock data, no location services)
3. ⚠️ OCR blood panel scanning (UI present, analysis unclear)
4. ⚠️ Settings screen (basic, limited options)
5. ⚠️ Onboarding (basic, no skip/progress tracking)

### Missing Entirely:
1. ❌ Push notifications
2. ❌ Offline mode / data caching
3. ❌ Analytics/event tracking
4. ❌ Insurance module integration
5. ❌ Social features / pet community
6. ❌ Vet appointment booking
7. ❌ Medication reminders (scheduled notifications)
8. ❌ Multi-pet switching UX (must go back to home)
9. ❌ Data export (user data portability)
10. ❌ Account deletion flow

---

## 8. Critical UX Issues to Fix Before Beta

### P0 — Must Fix:
1. **No loading states on API calls** — User has no feedback during Supabase operations
2. **No error states** — Network failures show raw exception text in SnackBars
3. **No empty states** — Some screens show blank white when no data exists
4. **Chat history lost on restart** — Users expect conversation persistence

### P1 — Should Fix:
1. **No image caching** — Every scroll re-fetches network images
2. **No pull-to-refresh** — Users can't manually refresh data
3. **Travel/Venues use placeholder images** — Looks unfinished
4. **PDF report has no visual design** — Plain text, no charts or branding
5. **No analytics** — Can't measure user behavior or feature adoption

### P2 — Nice to Have:
1. Custom WellX font family
2. Micro-animations and transitions
3. Haptic feedback on key actions
4. Dark mode support
5. iPad / tablet responsive layout

---

## 9. Recommendations for Engineering Team

1. **Create a design system** — Centralize all colors, typography, spacing, and component styles in a `wellx_theme.dart` file
2. **Add loading/error/empty state widgets** — Build reusable `WellxLoadingState`, `WellxErrorState`, `WellxEmptyState` components
3. **Implement image caching** — Use `cached_network_image` package throughout
4. **Add analytics** — Integrate Supabase Analytics or Mixpanel, mirror the 17 events from iOS
5. **Persist chat history** — Store conversation in Supabase, load on screen open
6. **Add Semantics** — Wrap all interactive elements for accessibility
7. **Proxy Anthropic calls** — Move AI API calls server-side to protect the API key
8. **Replace mock data** — Travel and venue data need real API backends
9. **Add pagination** — All list queries should use cursor-based pagination
10. **Integration tests** — Add Flutter integration tests for each core user journey

---

*Report generated 2026-04-02. All findings based on source code review of WellxPetsSDK main branch and comparison with FureverApp iOS codebase.*
