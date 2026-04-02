# FureverApp iOS — Complete Feature & UI Inventory

> **Purpose:** Exhaustive, spec-level documentation of every screen, component, service, and design token in the FureverApp iOS codebase.
> **Target reader:** Flutter developer replicating the exact UI.
> **Source:** `/Users/vaibhavkashyap/FureverApp/FureverApp/` (Swift/SwiftUI, Xcode project)
> **Generated:** 2026-04-02

---

## Table of Contents

1. [Design System — FureverTheme](#1-design-system--fureverTheme)
2. [App Architecture & Entry Point](#2-app-architecture--entry-point)
3. [Navigation System](#3-navigation-system)
4. [Authentication Screens](#4-authentication-screens)
5. [Onboarding Flow](#5-onboarding-flow)
6. [Main Tab Bar](#6-main-tab-bar)
7. [Home Screen](#7-home-screen)
8. [AI Vet Chat (Layla)](#8-ai-vet-chat-layla)
9. [Health Dashboard](#9-health-dashboard)
10. [Health Overview Tab](#10-health-overview-tab)
11. [Health Timeline Tab](#11-health-timeline-tab)
12. [Medical Records Tab](#12-medical-records-tab)
13. [Medications Tab](#13-medications-tab)
14. [Walk Sessions Tab](#14-walk-sessions-tab)
15. [More Health Tab](#15-more-health-tab)
16. [Track (Check) Screen](#16-track-check-screen)
17. [WellX Drive Feature](#17-wellx-drive-feature)
18. [Reports / Lab Upload Screen](#18-reports--lab-upload-screen)
19. [Wallet / Records Screen](#19-wallet--records-screen)
20. [Credits & Coin System](#20-credits--coin-system)
21. [Shelter & Impact Screens](#21-shelter--impact-screens)
22. [Travel Screen](#22-travel-screen)
23. [Venues Screen](#23-venues-screen)
24. [Voice Assistant Screen](#24-voice-assistant-screen)
25. [Subscription Paywall](#25-subscription-paywall)
26. [Settings & Profile Screens](#26-settings--profile-screens)
27. [Pet Management Screens](#27-pet-management-screens)
28. [Score Reveal & Explainer Modals](#28-score-reveal--explainer-modals)
29. [Shared Components & Utility Views](#29-shared-components--utility-views)
30. [Analytics Event Catalog](#30-analytics-event-catalog)
31. [Health Score Algorithm](#31-health-score-algorithm)
32. [Backend & Data Models](#32-backend--data-models)

---

## 1. Design System — FureverTheme

**File:** `/Utils/Theme.swift`
**Style:** "Furever Luxe" — Ink + Glass hybrid, editorial serif typography, off-white base.

### 1.1 Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#f7f7f5` | App-wide background |
| `cardSurface` | `#ffffff` | Card fills |
| `flatCardFill` | `#f2f2f0` | Flat (no-shadow) cards |
| `border` | `rgba(0,0,0,0.07)` | Card borders, 1px strokes |
| `inkPrimary` | `#161718` | Hero dark moments, primary buttons |
| `inkSecondary` | `#1e2020` | Secondary dark elements |
| `textPrimary` | `#171a17` | All primary text |
| `textSecondary` | `#5a5f5a` | Subtitles, secondary labels |
| `textTertiary` | `#9a9f9a` | Captions, helper text |
| `lightGreen` | `#68d391` | Positive states, positive gradient endpoint |
| `midGreen` | `#38a169` | Main brand green |
| `deepGreen` | `#276749` | Deep accent |
| `scoreGreen` | `#48bb78` | Health score – good |
| `scoreOrange` | `#ed8936` | Health score – moderate |
| `scoreRed` | `#fc8181` | Health score – poor |
| `scoreBlue` | `#63b3ed` | Score ring – blue band |
| `coral` | `#fc7c6e` | Alerts, errors, destructive |
| `amberWatch` | `#f6ad55` | Warnings |
| `brassGold` | `#c9a84c` | Premium, coins, section accents |
| `gold` | `#f6c90e` | Celebration confetti |
| `aiTeal` | `#4fd1c5` | AI Vet (Layla) icon color |
| `alertGreen` | `#38a169` | Active/success status pills |
| `alertRed` | `#e53e3e` | Critical alerts |
| `bloodImmunity` | `#9f7aea` | Dental/blood category |
| `cream` | `#faf9f6` | Travel/venue search bars |

**Computed colors:**
- `scoreColor(score:)` — score ≥ 75 → `scoreGreen`; ≥ 50 → `scoreOrange`; < 50 → `scoreRed`
- `scoreLabel(score:)` — ≥ 90 → "Excellent"; ≥ 75 → "Good"; ≥ 60 → "Fair"; ≥ 40 → "Needs Attention"; else "Needs Care"
- `pillarColor(for: name)` — Organ Strength → `scoreBlue`; Inflammation → `coral`; Metabolic → `amberWatch`; Body & Activity → `midGreen`; Wellness & Dental → `brassGold`
- `pillarIcon(for: name)` — Organ Strength → `"heart.circle.fill"`; Inflammation → `"flame.fill"`; Metabolic → `"chart.line.uptrend.xyaxis"`; Body & Activity → `"figure.walk"`; Wellness & Dental → `"tooth.fill"`

**Gradients:**
- `inkGradient` — `inkPrimary` → `inkSecondary`, topLeading → bottomTrailing (used in score reveal)
- `scoreRingGradient` — `scoreRed` → `scoreOrange` → `scoreGreen` (BiomarkerArcGauge)

### 1.2 Typography Scale

All fonts use SwiftUI `.font()` extensions on `Font`:

| Token | Size | Weight | Design |
|-------|------|--------|--------|
| `heroDisplay` | 48pt | black | serif |
| `displayTitle` | 34pt | bold | serif |
| `heading` | 26pt | bold | serif |
| `subheading` | 20pt | semibold | serif |
| `bodyLarge` | 17pt | regular | default |
| `bodyMedium` | 15pt | regular | default |
| `bodySmall` | 13pt | regular | default |
| `chipText` | 12pt | semibold | rounded |
| `smallLabel` | 11pt | medium | rounded |
| `tinyLabel` | 10pt | semibold | rounded |
| `buttonLabel` | 17pt | bold | rounded |
| `monoScore` | 42pt | black | monospaced |

**Navigation bar (global UIKit override):**
- Background: white
- Title: `#171a17`, 17pt bold system
- Large title: `#171a17`, 34pt serif
- Shadow: none

### 1.3 Spacing Scale (4pt grid)

| Token | Value |
|-------|-------|
| `xs` | 4pt |
| `sm` | 8pt |
| `md` | 12pt |
| `lg` | 16pt |
| `xl` | 24pt |
| `xxl` | 32pt |

### 1.4 Card Styles (View Modifiers)

| Modifier | Fill | Shadow | Border | Corner Radius |
|----------|------|--------|--------|---------------|
| `fureverCard` | white | `black 0.06 / r:12 / y:4` | 1px `border` color | 20 |
| `flatCard` | `flatCardFill` | none | none | 16 |
| `glassCard` | `.ultraThinMaterial` | `black 0.08 / r:16` | 1px `white 0.3` | 20 |
| `elevatedCard` | white | `black 0.10 / r:16 / y:6` | 1px `border` | 20 |

### 1.5 Animation Presets

| Name | Curve | Parameters |
|------|-------|-----------|
| `cardAppear` | spring | response:0.5, dampingFraction:0.8 |
| `buttonPress` | spring | response:0.3, dampingFraction:0.9 |
| `tabSwitch` | spring | response:0.4, dampingFraction:0.85 |
| `scoreReveal` | spring | response:0.8, dampingFraction:0.7 |
| `scoreFill` | spring | response:1.0, dampingFraction:0.65 |
| `shimmer` | linear | duration:1.5, repeatForever |
| `breathe` | easeInOut | duration:2.0, repeatForever autoreverses |
| `staggeredAppear(index)` | spring(0.5,0.8) | delay: index × 0.06 |
| `gentleBounce` | spring | response:0.4, dampingFraction:0.6 |

### 1.6 Haptics

| Method | Pattern |
|--------|---------|
| `FureverHaptics.buttonTap()` | UIImpactFeedbackGenerator(.light) |
| `FureverHaptics.selection()` | UISelectionFeedbackGenerator |
| `FureverHaptics.success()` | UINotificationFeedbackGenerator(.success) |
| `FureverHaptics.warning()` | UINotificationFeedbackGenerator(.warning) |
| `FureverHaptics.scoreReveal()` | UIImpactFeedbackGenerator(.heavy) |

### 1.7 Button Styles

**`PressScaleButtonStyle`:** `scaleEffect(0.97)` on press, spring animation.
**`FureverPrimaryButton`:** Black fill (`inkPrimary`), white text, height 52pt, capsule shape, shadow `black 0.15 / r:12 / y:4`.

### 1.8 Input Style

**`FureverInputStyle` (`.fureverInput` modifier):**
- Background: white
- Corner radius: 14
- Border: 1px `border` color normally; 1.5px `inkPrimary` when focused
- Padding: horizontal 14pt, vertical 13pt
- Placeholder text: `textTertiary`

---

## 2. App Architecture & Entry Point

**Entry file:** `/FureverApp/FureverAppApp.swift`
**ContentView:** `/FureverApp/ContentView.swift`

### 2.1 App Entry (`@main`)

`FureverAppApp: App`
- `@StateObject authViewModel: AuthViewModel`
- `@StateObject router: NavigationRouter`
- `@StateObject notificationRouter: NotificationRouter.shared`
- Injects all three as `.environmentObject` into `ContentView`
- `.preferredColorScheme(.light)` — forces light mode globally
- On `.active` scene phase: calls `AnalyticsService.shared.newSession()`, `.track(.appOpen)`, checks admin notifications
- On `.background` scene phase: calls `AnalyticsService.shared.track(.appBackground)`, `.flush()`
- On app launch task: validates streak via `StreakManager.shared.validateStreak()`
- Polls `NotificationService.shared.pollTimer` every 30s for admin notifications
- Deep-links from notification taps route through `notificationRouter.$pendingDestination` → `router.navigate(to:)`

### 2.2 Content View Routing

```
ContentView:
  authViewModel.isLoading → SplashScreenView
  authViewModel.isAuthenticated:
    needsOnboarding → OnboardingView (+ petViewModel env)
    else → MainTabView
  else → LoginView
```

---

## 3. Navigation System

**File:** `/Services/NavigationRouter.swift`

### 3.1 AppDestination Enum

16 destinations with presentation styles:

| Destination | Icon | Color | Presentation |
|-------------|------|-------|--------------|
| `.bcsCheck` | `camera.fill` | scoreGreen | .fullScreen |
| `.wellnessCheck` | `heart.text.square.fill` | brassGold | .fullScreen |
| `.urineCheck` | `drop.fill` | scoreBlue | .fullScreen |
| `.medications` | `pills.fill` | amberWatch | .sheet |
| `.scoreBreakdown` | `chart.bar.fill` | midGreen | .sheet |
| `.uploadDocument` | `doc.text.viewfinder` | coral | .tab(1) |
| `.records` | `folder.fill` | deepGreen | .tab(4) |
| `.venues` | `mappin.and.ellipse` | lightGreen | .sheet |
| `.chatLayla` | `stethoscope` | aiTeal | .tab(2) |
| `.reports` | `doc.text.magnifyingglass` | midGreen | .tab(1) |
| `.healthChecks` | `heart.circle.fill` | scoreGreen | .tab(3) |
| `.addPet` | `plus.circle.fill` | brassGold | .sheet |
| `.travel` | `airplane.departure` | scoreBlue | .sheet |
| `.symptomLogger` | `waveform.path.ecg` | coral | .sheet |
| `.healthTimeline` | `clock.arrow.circlepath` | midGreen | .sheet |

### 3.2 NavigationRouter (`@MainActor, ObservableObject`)

Published properties:
- `selectedTab: Int` — drives tab switching
- `pendingSheet: AppDestination?` — triggers `.sheet` presentation
- `pendingFullScreen: AppDestination?` — triggers `.fullScreenCover`

`navigate(to:)` behavior:
- Clears pending presentations first
- `.tab(n)` → `withAnimation(.tabSwitch) { selectedTab = n }` immediately
- `.sheet` → `DispatchQueue.main.asyncAfter(+0.1)` sets `pendingSheet`
- `.fullScreen` → `DispatchQueue.main.asyncAfter(+0.1)` sets `pendingFullScreen`
- Always calls `FureverHaptics.buttonTap()`

---

## 4. Authentication Screens

### 4.1 Login View

**File:** `/Views/Auth/LoginView.swift`

**Layout (top to bottom):**
1. **Hero dog image** — `Image("dog-hero-login")`, `scaleEffect(2.0)`, `offset(160, -130)`, clipped with `UnevenRoundedRectangle` (all corners 40pt), occupies top ~45% of screen
2. **Glass brand card** — `.ultraThinMaterial` fill, white shadow radius:16 + 32, rounded top corners
3. Brand icon (40×40pt rounded rect, `inkPrimary` fill) + "Furever" text (22pt semibold serif, `textPrimary`)
4. **Sign In with Apple** button — `.black` style, height 52pt, `cornerRadius:14`
5. "or" divider (1px `border` lines + "or" text centered)
6. Email field (`.fureverInput` modifier)
7. Password field (secure, `.fureverInput` modifier)
8. **"Forgot password?"** link button (12pt, `textTertiary`)
9. **FureverPrimaryButton** "Sign In" (height 52pt, `inkPrimary` fill, capsule, spinner overlay when loading)
10. Error message text (12pt coral, centered)
11. Rate-limit countdown — shows "Try again in Xs" badge (coral bg, white text)
12. Footer: "Don't have an account? **Sign up**" link

**State:**
- `@State email`, `password`, `isLoading`, `rateLimitCooldown`
- Rate limit timer managed in `AuthViewModel.startCooldown(seconds:60)`
- Error messages localized in `AuthViewModel.friendlyError(_:)`:
  - Rate limited → "Too many attempts. Please wait a minute before trying again."
  - Invalid credentials → "Incorrect email or password. Please try again."
  - Already registered → "Looks like this email is already taken. Try signing in instead."
  - Weak password → "Password is too weak. Please use at least 6 characters."
  - Invalid email → "Please enter a valid email address."

**Analytics:** `.track(.signIn, properties: ["method": "apple"])` on Apple sign-in.

### 4.2 Sign Up View

**File:** `/Views/Auth/SignUpView.swift`

**Layout:**
1. Black circle header (72×72pt, `inkPrimary` fill, `person.fill` icon 28pt white)
2. **Sign Up with Apple** button (`.black`, height 52)
3. "or" divider
4. First name + Last name fields in `fureverCard` group
5. Email field in `fureverCard` group
6. Password + Confirm password fields:
   - Password match indicator: if passwords match → `checkmark.circle.fill` (lightGreen 14pt); mismatch → `exclamationmark.triangle.fill` (coral 12pt) + "Passwords don't match" text
7. **FureverPrimaryButton** "Create Account"
8. Error message (coral)
9. Footer: "Already have an account? **Sign in**" link

---

## 5. Onboarding Flow

**File:** `/Views/Onboarding/OnboardingView.swift`

**Structure:** 4-step `TabView` with `.page` style, paging animation.

**Step indicator (top):**
- Row of 4 step icons connected by horizontal lines
- Active step: filled circle with white icon
- Inactive: `flatCardFill` circle with `textTertiary` icon
- Step icons: `pawprint.fill` / `pencil.line` / `heart.fill` / `doc.text.fill`
- Connector lines: 1pt `border` color

**Steps:**
1. **Welcome** — Hero text, app value proposition
2. **Your Pet** — Pet name, species picker, breed picker, date of birth, gender, weight
3. **Wellness** — Brief wellness questions
4. **Records** — Upload first document CTA

**Navigation:** "Continue" / "Back" buttons. Final step → sets `needsOnboarding = false`.

---

## 6. Main Tab Bar

**File:** `/Views/MainTabView.swift`

### 6.1 Custom Floating Tab Bar

**Container:** Full-screen `ZStack` with content area + floating bar overlay
**Content area padding:** `.padding(.bottom, 80)` to clear the tab bar

**Tab Bar itself:**
- Position: `VStack { Spacer(); tabBar }` pinned to bottom
- Background: `inkPrimary` capsule fill
- Shadow: `black 0.25 / radius:20 / y:8`
- Padding: horizontal 20pt, bottom 20pt
- Height: ~60pt, horizontal padding: 8pt inside capsule

**5 Tabs:**

| Index | Label | Icon | Role |
|-------|-------|------|------|
| 0 | Home | `house.fill` / `house` | Main feed |
| 1 | Reports | `doc.text.fill` / `doc.text` | Lab reports |
| 2 | Layla (center) | Gradient circle | AI Vet chat |
| 3 | Check | `checkmark.circle.fill` / `checkmark.circle` | Health checks |
| 4 | Records | `folder.fill` / `folder` | Documents |

**Active tab indicator:** White capsule bg 40×28pt using `matchedGeometryEffect(id: "tabIndicator")`

**Tab icon styling:**
- Active: white icon + `white capsule` bg
- Inactive: `white opacity:0.45` icon

**Tab labels:** 9pt semibold rounded, white (active) / `white 0.45` (inactive)

**Center Layla button (tab 2):**
- Size: 46×46pt circle
- Active: `LinearGradient(lightGreen→midGreen, topLeading→bottomTrailing)`
- Inactive: `white opacity:0.12` gradient equivalent
- Icon: `stethoscope` 22pt white
- No label shown

**Badge:** Coral 8pt circle, `offset(10, -8)` from icon, shown when `healthAlerts.count > 0`

**Analytics:** Tracks `tabSwitched` with `tab_index` property on every tab switch

**Sheets triggered from MainTabView:**
- `pendingSheet` from router → `AppDestination`-routed sheets
- `pendingFullScreen` → fullScreenCover

---

## 7. Home Screen

**File:** `/Views/Home/HomeView.swift`

### 7.1 Layout

`NavigationView` with large serif title.
`ScrollView` content in `LazyVStack(spacing: 0)`.

**Header area (inside NavigationView):**
- Greeting text (`"Good morning"` / `"Good afternoon"` / `"Good evening"` by hour)
- Pet name in greeting: `"[greeting], [petName]'s parent"` style
- Navigation bar trailing: avatar button (circle 36pt with initials or photo) → SettingsView sheet

**Section order (top to bottom):**
1. **Health Score Card** — `CircularScoreView` + score delta
2. **Daily Plan Card** — `DailyPlanCard`
3. **Proactive Insights** (if any) — insight cards
4. **FureverImpact Section** — shelter impact preview
5. **Quick Actions row** — horizontal scroll pills

### 7.2 Health Score Card

- White `fureverCard`, padding 20
- `CircularScoreView(score: healthScore, size: 120)` on the left
- Score delta badge: `"+N from last check"` or `"-N from last check"` in `scoreGreen` / `coral` capsule
- Score label (e.g. "Excellent") in `textSecondary`
- "View breakdown" → opens `ScoreExplainerView` sheet

**Score Reveal Logic:**
- Shows `ProgressiveScoreRevealView` fullScreenCover on first-ever score OR if it's a new day AND score changed ≥ 3 points
- Stored in `UserDefaults` as `lastRevealedScore_<petId>` + `lastRevealDate_<petId>`
- Score delta stored as `previousHealthScore_<petId>`

### 7.3 Daily Plan Card

**File:** `/Views/Home/DailyPlanCard.swift`

**Card structure:**
- Header: "TODAY'S PLAN" section header + progress text `"N/M completed"`
- Progress ring: 36×36pt, lineWidth 3, gradient `midGreen → lightGreen`
- Progress bar: 4pt height capsule, same gradient
- Task list (vertical, pinned timeline)

**Task row anatomy:**
- Left: timeline connector (1pt vertical line between rows, colored dot for step)
- Icon circle: 36×36pt, `priority.tintColor opacity:0.12` bg, priority icon
- Title + subtitle text block
- Coin reward: `"+N ⭐"` text, `brassGold`, 11pt semibold rounded
- Completion: checkmark circle or toggle checkbox

**Priority colors:**
- `.urgent` → `coral`
- `.important` → `amberWatch`
- `.routine` → `midGreen`

**Toggling:** `FureverHaptics.selection()` on toggle. Persisted in `UserDefaults` keyed by `daily_completed_<petId>_<yyyy-MM-dd>`.

**Animation:** `spring(response: 0.5, dampingFraction: 0.8)` on completion toggle.

**Tap behavior:** Tapping a task → `NavigationRouter.navigate(to: task.destination)`. Chat tasks pre-populate `chatPrompt` in VetChatView.

### 7.4 Daily Plan Generation (DailyPlanService)

`DailyPlanService.generatePlan(pet:medications:biomarkers:healthScore:latestBCS:latestWellness:symptoms:)` returns sorted `[DailyTask]`:

**Priority order (urgent → important → routine):**

*Urgent (alert category):*
- Active symptoms (up to 3) → chat with Layla auto-prompt
- Low medication supply (< 15% of total, ≤ 3 days = .urgent, ≤ 15% = .important)
- Flagged biomarkers (first 2) → chat with Layla auto-prompt

*Important (healthCheck / care):*
- Overdue BCS (> 30 days since last, or never done) — `coinReward: 10`
- Overdue wellness survey (> 14 days) — `coinReward: 5`
- Weak pillar action (pillar score < 65)

*Routine (activity / medication / care):*
- Morning walk — `coinReward: 5`, toggleable
- Daily medications (up to 4, or "Daily supplements" if none) — `coinReward: 5`, toggleable
- Evening walk — `coinReward: 5`, toggleable
- Chat with Layla (every even day of year or if flagged markers) — `coinReward: 10`, toggleable
- Upload record (every 4th day of year) — `coinReward: 10`, toggleable

**Walk subtitles by weight:**
- < 10 kg → "Target: 20 min · 1.5 km"
- 10–25 kg → "Target: 30 min · 3 km"
- 25–45 kg → "Target: 45 min · 5 km"
- > 45 kg → "Target: 35 min · 3.5 km"

---

## 8. AI Vet Chat (Layla)

**File:** `/Views/Vet/VetChatView.swift`
**ViewModel:** `/ViewModels/VetChatViewModel.swift`

### 8.1 Header

- "Layla" name in 17pt semibold
- "Online" text in 11pt `textSecondary` with `PulsingDot` (animated green circle, 6pt, breathing opacity)
- Health data status pill: `"N biomarkers · M meds"` capsule, `aiTeal 0.1` bg, `aiTeal` text 11pt semibold
- Trash button (top-right): clears chat history + confirmation

### 8.2 Message Bubbles

**User bubble:**
- Background: `inkPrimary`
- Text: white, 15pt
- Corner radius: 18pt with bottom-right = 4pt (chat-bubble style)
- Padding: 12×14pt
- Alignment: trailing (right side)
- Photo attachment (if `imageData`): rounded image above text

**Assistant bubble:**
- Background: white, shadow `black 0.06 / r:8 / y:2`
- Border: 1px `border` color
- Text: `textPrimary`, 15pt, with `ActionTagParser` markdown rendering (bold, italic, lists)
- Corner radius: 18pt with bottom-left = 4pt
- Alignment: leading (left side)
- Width: max 85% of screen width

**Streaming bubble:** Same as assistant, but text streams character-by-character from `vm.streamedText`.

**Typing indicator:** 3 bouncing dots (circles 8×8pt, `textTertiary`, staggered animation `easeInOut(0.5s)` with delays 0/0.15/0.3s, repeat forever).

### 8.3 Quick-Action Chips

Horizontal scrolling pill row above input bar:

**Health chips (always shown):**
- "Blood Work", "Check Weight", "Vaccination"

**Management chips (always shown):**
- "Medications", "Insurance Claim"

**Dynamic pillar chips (weakest pillar):**
- Weakest pillar below 65 → shows pillar-specific question chip

Chip style: `textSecondary 0.08` bg, `textPrimary` text, 10pt semibold rounded, capsule, 8×14pt padding, `border` stroke.

Tapping chip → sends pre-written message to Layla.

### 8.4 Input Bar (`ChatInputBar`)

- `TextEditor` (multiline, max 3 lines), 15pt, `flatCardFill` bg, cornerRadius:14
- Send button: `inkPrimary` circle 38×38pt, `arrow.up` icon, disabled (gray) when input empty or loading
- Photo button: `photo` icon circle (optional)
- Coin toast: `CoinEarnedToast(coins: 10)` shown after first AI response per session for `CoinAction.chatDrLayla`

### 8.5 Proactive Insights Banner

When `proactiveInsights.count > 0`, shows banner at top of message list:
- Card: `fureverCard` style
- Severity icon: 🔴 action / 🟡 watch / 🟢 info
- Title + detail text
- "Dismiss" button (X)
- "Ask Layla" button → sends insight detail as question

### 8.6 Chat History Persistence

`ChatHistoryStore` (singleton):
- Key: `furever_chat_history_<petId>`
- Max: last 50 messages
- Encoded as JSON in `UserDefaults`
- Includes `imageData` for photo messages

### 8.7 VetChatViewModel

- `@Published messages: [ChatMessage]`
- `@Published isStreaming: Bool`
- `@Published streamedText: String` — partial Claude response
- `@Published interpretation: String` — one-time health interpretation
- `@Published proactiveInsights: [ProactiveInsight]`
- Claude model: `claude-sonnet-4-6`, max_tokens: 2048
- API route: Supabase Edge Function proxy (`ClaudeProxyService.shared.callAndExtractText`)
- Conversation history: `[[String: String]]` array maintained in-memory
- `setupContext(pet:biomarkers:medications:healthAlerts:medicalRecords:walkSessions:documents:)` → builds system prompt via `VetSystemPrompt.build(petContext:)`

---

## 9. Health Dashboard

**File:** `/Views/Health/HealthDashboardView.swift`

### 9.1 Layout

`NavigationView` with title "Health"

**Pet picker (horizontal ScrollView):**
- Capsule pills, one per pet
- Active: `textPrimary` fill, white text, 12pt semibold rounded
- Inactive: `cardSurface` fill, `textPrimary` text, `border` stroke 1px opacity 0.1
- Each pill: name text, 10×14pt padding
- On tap: `petViewModel.selectPet(id)`, triggers `healthViewModel.loadAllHealth(petId:)` async

**Segmented Picker:**
- `Picker("", selection: $selectedSegment)` with `.segmented` style
- Options: "Overview" / "Timeline"
- "Overview" → `PetDetailView` with `HealthOverviewTab` active
- "Timeline" → `HealthTimelineView`

**Loading state:** `PuppyLoaderView` centered (animated puppy canvas)

---

## 10. Health Overview Tab

**File:** `/Views/Health/HealthOverviewTab.swift`

### 10.1 Sections

**Alerts Section** (if `healthAlerts.count > 0`):
- Each alert: coral `exclamationmark.triangle.fill` icon, title text, "Resolve" button
- Resolve → `healthViewModel.resolveAlert(id:)` async

**BiomarkerArcGauge:**
- 270° arc from 135° to 405°
- Track stroke: `border` color, lineWidth 14
- Angular gradient fill: `scoreRed → scoreOrange → scoreGreen`
- Center label: `inRange/total` biomarkers in `display` serif font
- Sub-label: "Biomarkers" in `tinyLabel`
- Animated with `.scoreFill` animation

**Health Area Grid:**
- `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16)`
- Each `HealthAreaCard`: pillar name, pillar icon, pillar score, color-coded progress bar

**Longevity Score:**
- 52×52pt compact `CircularScoreView`
- Score from `pet.longevityScore`
- Tapping → `ScoreExplainerView` sheet

**Quick Stats Pills (horizontal scroll):**
- Biomarkers count
- Medications count
- Records count
- Walks count
- Each pill: icon + count, `flatCardFill` bg, 8×12pt padding, cornerRadius:10

---

## 11. Health Timeline View

**File:** `/Views/Health/HealthTimelineView.swift`

### 11.1 Filter Pills

Horizontal scroll: ["All", "Symptoms", "Labs", "Vaccines", "Visits", "BCS", "Docs"]
Active: `textPrimary` fill, white text
Inactive: `flatCardFill` fill, `textSecondary` text

### 11.2 Timeline List

Grouped by day (section headers pinned: `"Today"`, `"Yesterday"`, `"Month Day, Year"`).

**Section header:** 12pt semibold uppercase, `textTertiary`, tracking 0.8. Pinned with `.listRowInsets`.

**Timeline row anatomy:**
- Left column: 32×32pt colored circle icon + 1pt vertical connector line
- Right column: title (15pt semibold), subtitle (12pt `textSecondary`), date (10pt `textTertiary`)
- Icon color = event type (biomarker → `scoreBlue`, symptom → `coral`, vaccine → `alertGreen`, visit → `midGreen`, BCS → `brassGold`, document → `amberWatch`)

**Row animation:** `.spring(response:0.4, dampingFraction:0.8).delay((dayIndex * 3 + eventIndex) * 0.04)` — staggered by position in list

**Pull-to-refresh:** `refreshable { await healthViewModel.loadAllHealth(petId:) }`

### 11.3 Events Included

- `SymptomLog` records
- `Biomarker` uploads (date of first value for each marker)
- `MedicalRecord` entries (vaccines, visits, surgeries, etc.)
- `BCSRecord` entries
- `Document` uploads

---

## 12. Medical Records Tab

**File:** `/Views/Health/MedicalRecordsTab.swift`

### 12.1 Record List

Each record card (`fureverCard`):
- Category color dot (8pt) + category label
- Title (17pt semibold), clinic + vet name, date
- Notes (if any), truncated to 3 lines with "Show more" toggle
- Diagnoses: coral capsule pills (`.statusPill` style)
- Prescribed medications: `alertGreen` capsule pills

**Category colors:**
| Category | Color |
|----------|-------|
| vaccination | lightGreen |
| surgery | coral |
| dental | bloodImmunity |
| emergency | alertRed |
| check-up / wellness | midGreen |
| other | textTertiary |

### 12.2 Add Record Sheet

`AddMedicalRecordView` — native `Form` with:
- Title (TextField)
- Date (DatePicker)
- Category (Picker: vaccination/surgery/dental/emergency/check-up/other)
- Vet name (TextField, optional)
- Clinic (TextField, optional)
- Notes (TextEditor)
- "Save Record" button → `healthViewModel.addMedicalRecord(...)`

---

## 13. Medications Tab

**File:** `/Views/Health/MedicationsTab.swift`

### 13.1 Medication Cards

Each card (`fureverCard`):
- Medication name (17pt semibold)
- Dosage + category label
- Supply progress bar (5pt height capsule):
  - Fill: ≤ 20% → `coral`; ≤ 50% → `amberWatch`; else → `midGreen` to `lightGreen` gradient
  - Track: `border` color
- Supply text: `"N days remaining"` or `"N/M days"` — urgency colors match bar
- Refill date (if set): calendar icon + date
- Instructions (if set): truncated text

**Urgency badge (top-right of card):**
- high → `coral 0.1` bg + `coral` text "Urgent"
- medium → `amberWatch 0.1` bg + `amberWatch` text "Low supply"
- else → `alertGreen 0.1` bg + `alertGreen` text "Good"

**Swipe-to-delete** (`.onDelete`) → `healthViewModel.deleteMedication(id:)`

### 13.2 Add Medication Sheet

`AddMedicationView` — native `Form`:
- Name, dosage (optional), category (optional)
- Supply total + supply remaining (Stepper + TextField)
- Urgency (Picker: high/medium/low)
- Refill date (DatePicker, optional)
- Instructions (TextEditor)
- "Add Medication" → `healthViewModel.addMedication(...)`

---

## 14. Walk Sessions Tab

**File:** `/Views/Health/WalkSessionsTab.swift`

### 14.1 Stats Summary Row

3-column row at top of tab (dividers between columns):
- **Walks:** count of sessions
- **Distance:** total km, formatted
- **Steps:** total steps, abbreviated (e.g. "12.3K")

Each column: large number in `subheading` font + small label below.

### 14.2 Walk Cards

Each card (`fureverCard`):
- `figure.walk` icon in `brassGold` (20pt)
- Date (13pt semibold) + duration text
- Steps count with `shoeprints.fill` icon
- Distance in km with `map.fill` icon

### 14.3 Add Walk Sheet

`AddWalkView` — native `Form`:
- Date (DatePicker)
- Steps (Stepper/TextField)
- Distance km (TextField)
- Duration minutes (Stepper)
- Average cadence (optional)
- "Log Walk" → `healthViewModel.addWalkSession(...)` + awards `coinAction.logWalk` coins

---

## 15. More Health Tab

**File:** `/Views/Health/MoreHealthTab.swift`

**Three sections:**

**Insurance Claims:**
- Shield icon header
- Each claim: title, amount (AED), date, status pill
- Status pill colors: "Submitted" → `scoreBlue`; "Approved" → `alertGreen`; "Rejected" → `coral`; "Processing" → `amberWatch`
- "Add Claim" button → sheet

**Biomarkers List (compact):**
- 8pt status dot + name + value + unit
- Status color: high = `coral`, low = `scoreBlue`, normal = `alertGreen`
- Status badge (capsule): `"HIGH"` / `"LOW"` / `"NORMAL"`, 10pt bold, opacity 0.12 bg

**Documents List (compact):**
- Category-colored icon (SF Symbol based on category)
- Title + file type + date
- Tap → opens `DocumentDetailView`

---

## 16. Track (Check) Screen

**File:** `/Views/Track/TrackView.swift`

### 16.1 Layout

`NavigationView` with scroll. Header: gradient hero (`inkPrimary` → `inkSecondary` or similar, full-width).

### 16.2 Health Check Journey Cards

3 cards in `VStack`, staggered animation `.spring(response:0.5, dampingFraction:0.8).delay(index * 0.15)`.

| Check | Icon | Gradient | Coins |
|-------|------|----------|-------|
| BCS (Body Condition Score) | `camera.fill` | `scoreGreen → scoreGreen.lighter` | 10 |
| Wellness Survey | `heart.text.square.fill` | `brassGold → brassGold.lighter` | 5 |
| Urine Screening | `drop.fill` | `scoreBlue → scoreBlue.lighter` | 10 |

**Card anatomy (each):**
- Gradient fill (`cornerRadius:20`)
- Icon (28pt, white)
- Title (17pt bold white)
- Description (13pt white opacity:0.8)
- Status area:
  - **Never done:** `"Start →"` button capsule (white, text in gradient color)
  - **Completed:** date + summary text in white; `"Redo"` small button

**Completion state storage:**
- BCS: `BCSStorage` (UserDefaults `bcs_history_<petId>`) — `BCSRecord` with `score`, `label`, `date`
- Wellness: `WellnessSurveyResult` (UserDefaults `wellness_result_<petId>`) — `answers: [Int]`, `date`
- Urine: `TrackUrineFlow` — urine screening flow (separate view)

### 16.3 WellX Drive Card

Below the health checks:
- Dark ink card with blue/purple gradient border
- `car.fill` icon (32pt, blue-purple gradient)
- Title "WellX Drive" + subtitle "Earn up to 30 XCoins per trip"
- Coin reward badge
- "Start Drive →" capsule button

Tapping → `.fullScreenCover` presenting `WellXDriveView`.

### 16.4 Rewards Section

- Section header "REWARDS"
- Compact coin balance row
- "See all" link → `CreditsWalletView`

---

## 17. WellX Drive Feature

### 17.1 Drive Idle View (`DriveIdleView`)

**File:** `/Views/Drive/WellXDriveView.swift`

**Layout:**
1. Close (×) button top-left (circle, `cardSurface` bg, `border` overlay)
2. "WellX Drive" title centered (17pt semibold)
3. Centered **Orb** (200×200pt):
   - Outer glow: `RadialGradient(blue 0.25/0.10 → purple 0.15/0.05 → clear)`, 280pt, blur:20, pulse `scaleEffect(1.08/0.96)`, `easeInOut(2.2s) repeatForever`
   - Orb body: `LinearGradient(#1f1f29 → #141418)`, `topLeading → bottomTrailing`
   - Blue/purple gradient border stroke 1.5pt
   - Shadow: `blue opacity:0.3 radius:30 y:10`
   - Center: `car.fill` icon 44pt with `LinearGradient(#8cccff → #b38cff)`
   - "Ready" or "Detecting..." text 12pt semibold rounded below icon
4. "Drive Safely," + "Earn XCoins" — 32pt bold serif; "Earn XCoins" has linear gradient `#4d99ff → #9959f2`
5. Subtitle: "Auto-detects when you reach 20 km/h.\nEarn up to 30 XCoins per trip." — 14pt regular `textSecondary`, centered, padding 40pt horizontal
6. **Coin preview pills row** (3 pills):
   - Smooth (+1): `checkmark.seal.fill` green
   - Harsh (-2): `exclamationmark.triangle.fill` coral
   - Speed (-1): `gauge.with.dots.needle.67percent` amberWatch
   - Each pill: icon + label + value, `color.opacity(0.08)` bg, `cornerRadius:14`, `color.opacity(0.2)` border
7. **"Start Drive"** primary button: `LinearGradient(#3373e6 → #7340d9)`, height 56pt, capsule, shadow `blue 0.4 r:16 y:6`
8. "Or just start driving — we'll detect it automatically" caption (12pt textTertiary)

**Animation:** `spring(response:0.6, dampingFraction:0.8).delay(0.2)` animate-in sequence

### 17.2 Drive Active View (`DriveActiveView`)

**File:** `/Views/Drive/DriveActiveView.swift`

**Full-screen HUD layout (dark background):**

**Top bar:**
- Green status dot (8pt, `#40cc72`) + "Drive Active" / "Stopping…" text — `scaleEffect(1.2/0.9)` pulse
- Duration timer (monospaced 20pt bold, `MM:SS` format) — right-aligned

**Coin counter card:**
- White card, `cornerRadius:18`, shadow `black 0.06 r:12 y:4`, 1pt `border` overlay
- 🪙 emoji in gold circle (44pt circle, `gold opacity:0.15`) — `scaleEffect(1.25/1.0)` on coin bounce
- "XCoins This Trip" label (11pt semibold rounded, `textTertiary`, tracking 0.5)
- Coin count (32pt black rounded) — `.contentTransition(.numericText())`, `scaleEffect(1.08/1.0)` on bounce
- Progress bar (80pt wide, 8pt height): `border` track + green-blue gradient fill, animated with `.spring(0.4,0.7)`
- "max 30" label above bar

**Drive Score Orb (centered):**
- Outer glow: `RadialGradient(scoreColor 0.30/0.15 → 0.20/0.08 → clear)`, 260pt, blur:18, `scaleEffect(1.06/0.96)`, `easeInOut(2.0) repeatForever`
- Ring: `AngularGradient(scoreColors + [first])`, 180pt, lineWidth:4 lineCap:round, rotate -90°
- Orb body: `LinearGradient(#1a1a24 → #121218)`, 170pt, thin gradient border stroke 1pt
- Center: score number (54pt black rounded, white, `.contentTransition(.numericText())`)
- Label: `DriveScore.label(for:)` 11pt semibold white 0.6 tracking 0.5
- Score animation: `.spring(response:0.5, dampingFraction:0.75)` on change

**Metrics row (2 cards):**
- Speed card: `speedometer` icon, `"N km/h"`, color: ≥120 → coral / ≥90 → amberWatch / else green
- Distance card: `map.fill` icon, formatted distance, `scoreBlue`
- Card: white, `cornerRadius:18`, shadow `black 0.05 r:10 y:3`, 1pt `border`

**End Trip button:**
- Coral text + `stop.fill` icon
- Height 52pt, capsule
- Background: `coral 0.08`
- Border: `coral 0.3`, 1.5pt

**Coin Animation System:**
- On coin event: bounce `spring(0.25, 0.4)` → un-bounce after 0.35s `spring(0.3, 0.7)`
- Debit flash: `coral opacity:0.15` fullscreen overlay, appears `easeInOut(0.12s)`, fades `easeOut(0.3s)` after 0.35s
- Floating label: text 28pt black rounded, credit=`#40c773` / debit=`#e1473a`; spring(0.6, 0.7) offset -60pt; fade `easeOut(0.4s) delay:0.5`; clears after 1.1s
- Haptic: credit → `FureverHaptics.success()`; debit → `FureverHaptics.warning()`

### 17.3 Drive Summary View (`DriveSummaryView`)

**File:** `/Views/Drive/DriveSummaryView.swift`

**Layout (ScrollView):**

1. **Header:** "Trip Complete" (28pt bold serif) + date ("Monday, Jan 6 at 3:42 PM") + close (×) button (38×38pt circle, `cardSurface`)
2. **Score Orb** (175pt): same dark ink + angular gradient ring (185pt) + RadialGradient glow (280pt, blur:20) — rings animate from `scaleEffect(0.6)` on appear; score count-up `easeOut(0.8s) delay:0.4s`
3. **Coin Banner** (white card, `cornerRadius:20`, gold gradient border 1.5pt):
   - 🪙 emoji circle (52pt gold-tinted bg)
   - "XCoins Earned" + `+N coins` (36pt black rounded, `LinearGradient(#e6b826 → #c78c19)`)
   - Right side: `"= N meals for shelter dogs"` (13pt bold midGreen + 10pt textTertiary)
4. **Stats grid** (3 cards, `cornerRadius:16`): Distance (`scoreBlue`), Duration (`purple #7348d9`), Top Speed (`amberWatch`)
5. **Event log** (white card, `cornerRadius:20`, max 8 events shown):
   - "EVENTS" header (11pt semibold tracking:1.1)
   - Each event: coral circle (36pt) with event icon + name + speed + coinDelta in coral
   - `"+ N more events"` if > 8
6. **Done button:** `inkPrimary` fill, white text + checkmark, height 56pt, capsule, shadow `black 0.20 r:14 y:6`

**Entry animation:** `spring(response:0.6, dampingFraction:0.8).delay(0.15)` — all sections fade+slide in together.

### 17.4 DriveManager (GPS Backend)

**File:** `/Services/DriveManager.swift`

- `CLLocationManager` with `kCLLocationAccuracyBestForNavigation`, `distanceFilter: 5m`
- `@Published state: DriveState`
- `@Published currentSpeedKmh: Double`
- `@Published currentTrip: DriveTrip?`
- `var onCoinEvent: ((DriveEventType) -> Void)?` callback to VM

**Trip start logic:**
- Speed ≥ 20 km/h for 5 consecutive seconds → transitions to `.active`
- Starting speed window buffer: last 5 `CLLocation` updates

**Trip end logic:**
- Speed < 20 km/h for 120 continuous seconds → transitions to `.stopping` countdown, then `.summary(trip)`
- Manual end via `endTripManually()`

**Event detection (during `.active`):**
- Harsh braking/acceleration: speed delta > 20 km/h in 3-second window; 4s cooldown between events
- Speeding: ≥ 120 km/h → `DriveEventType.speeding`
- Smooth interval: +1 coin every 120s with no harsh events (capped at 30 total)
- Phone usage: `UIApplication.didEnterBackgroundNotification` while `.active` → `DriveEventType.phoneUsage`

**Score deductions:**
- harshBraking: -5
- harshAcceleration: -4
- speeding: -3
- phoneUsage: -8
- smoothInterval: 0

**Coin deltas:**
- harshBraking: -2
- harshAcceleration: -2
- speeding: -1
- phoneUsage: -3
- smoothInterval: +1
- Base coins at trip start: 20
- Max 30 coins, min 0

---

## 18. Reports / Lab Upload Screen

**File:** `/Views/Report/ReportView.swift`

### 18.1 Layout

`NavigationView` large title "Lab Reports"

**Smart Upload Card:**
- Coral gradient header icon
- Title "Upload Lab Report" + subtitle
- Upload area: `doc.text.viewfinder` icon, dashed `border` stroke, dotted outline, "Tap to upload" text
- Accepts: camera / photo library / PDF document picker
- On selection → `DocumentProcessorService` with Claude Vision OCR

**DocumentProcessingOverlay** (shown while processing):
- Semi-transparent `PuppyLoaderView` overlay
- "Analyzing your report…" animated text

**After processing:**
- Biomarker dashboard section: `BiomarkerArcGauge` + count
- Health area grid: 2-column `LazyVGrid` of `HealthAreaCard`s
- Smart blood panel recommendation: suggests which markers to look for
- Watch markers: out-of-range biomarkers highlighted in coral

**Awards coins:** `CoinAction.uploadDocument` (10 coins) after successful document save. Coin toast appears.

---

## 19. Wallet / Records Screen

**File:** `/Views/Wallet/WalletView.swift`

### 19.1 Navigation

Title: "Records" (serif large title)

### 19.2 Sections

**Document filter pills:** ["All", "Lab Report", "Vaccine", "Dental", "Prescription", "X-ray", "Other"]
- Active: `textPrimary` fill, white text, capsule
- Inactive: `flatCardFill`, `textSecondary`

**Collapsible search bar:**
- Transition: `.move(edge: .top).combined(with: .opacity)`
- Background: `flatCardFill`
- Magnifying glass icon, text field, clear button

**Hero stats card** (`fureverCard`):
- 3-column layout: Documents / Labs / Vaccines counts

**DocumentProcessingOverlay:** Same as ReportView.

**Credits balance card** (compact): Current coins + "Earn more" link.

**Document list:** Cards with category icon (color-coded), title, date, file type badge.

**Pull-to-refresh:** Reloads from Supabase `documents` table.

---

## 20. Credits & Coin System

### 20.1 CreditWallet Model

**File:** `/Models/CreditModels.swift`

Fields: `creditsBalance`, `coinsBalance`, `totalCoinsEarned`, `totalCreditsPurchased`
Computed: `totalBalance = creditsBalance + coinsBalance`

### 20.2 CoinAction Enum (8 actions)

| Action | Raw Value | Coins Awarded | Repeatable |
|--------|-----------|---------------|------------|
| `dailyLogin` | "daily_login" | 5 | yes (daily) |
| `completePetProfile` | "complete_pet_profile" | 20 | no (one-time) |
| `uploadDocument` | "upload_document" | 10 | yes (daily) |
| `logWalk` | "log_walk" | 5 | yes (daily) |
| `chatDrLayla` | "chat_dr_layla" | 10 | yes (daily) |
| `healthCheck` | "health_check" | 10 | yes (daily) |
| `logSymptom` | "log_symptom" | 5 | yes (daily) |
| `driveTrip` | "drive_trip" | 20 (base) | yes (per trip) |

### 20.3 CreditService Logic

- `earnCoins(ownerId:action:referenceId:)`:
  - Repeatable actions: checks `credit_transactions` for same `owner_id` + `action_type` + today's date → skips if found
  - One-time actions: checks if `action_type` ever earned → skips if found
  - Writes to `credit_transactions` table + updates `user_wallets` via Supabase upsert
- `spendCredits(...)`: deducts credits first, then coins
- `earnCoinsForDrive(ownerId:coins:tripId:)`: bypasses daily dedup, per-trip credit

### 20.4 CreditViewModel (shared `@EnvironmentObject`)

- `wallet: CreditWallet?`
- `creditsBalance / coinsBalance / totalBalance` computed from wallet
- `earnCoins(ownerId:action:referenceId:)` → silent (no UI interruption)
- `earnCoinsForDrive(ownerId:coins:tripId:)` → DriveManager endpoint
- Tracks `coinEarned` / `coinAllocated` analytics events

### 20.5 Credits Wallet View

**File:** `/Views/Credits/CreditsWalletView.swift`

**Balance hero card** (`inkPrimary → midGreen` gradient):
- Coin balance: 48pt serif (`heroDisplay`) white
- "XCoins" label in white subheading
- Impact pills: "N shelter meals · N days of care" — `white 0.1` capsule bg
- "Help Shelter Dogs" CTA button — white text on `white 0.15` bg
- "Earn Coins" button → `EarnCoinsView` sheet

**Transaction history:**
- Grouped by date
- Each transaction: icon, description, `+N` / `-N` delta in `lightGreen` / `coral`

### 20.6 Earn Coins View

**File:** `/Views/Credits/EarnCoinsView.swift`

Lists all 8 `CoinAction`s as cards:

**Each action card (`fureverCard`):**
- Icon (SF Symbol) in colored circle
- Title + description
- Coin reward badge (`"+N ⭐"`, `brassGold`)
- Status badge:
  - Completed today → `checkmark.circle.fill` in `lightGreen` + "Done" or "Daily" or "One-time"
  - Available → "Earn" button

**Info section:** `brassGold 0.08` background, `cornerRadius:14`, explains how coins convert to shelter donations.

---

## 21. Shelter & Impact Screens

### 21.1 FureverImpact Section (Home)

**File:** `/Views/Home/FureverImpactSection.swift`

**5 sub-sections:**

1. **How It Works** — 3 step bubbles (numbered circles, `brassGold` fill) connected by dashed vertical lines:
   - "Earn XCoins by caring for your pet"
   - "Coins become real donations"
   - "Shelter dogs get food & care"

2. **Impact Stats** — 3 progress rings (56×56pt, lineWidth:5):
   - Animated `easeOut(duration:1.0).delay(0.3)` on appear
   - Stats: Meals Donated, Families Helped, Dogs Saved

3. **Milestone Progress bar** — full-width capsule bar showing community total progress toward milestone

4. **Featured Dogs carousel** — horizontal scroll of 140×100pt cards:
   - Dog photo (`CachedAsyncImage`) + name overlay
   - `cornerRadius:16`

5. **Help Shelter CTA** — `inkPrimary` fill button → `ShelterDirectoryView`

### 21.2 Shelter Directory View

**File:** `/Views/Home/ShelterDirectoryView.swift`

**Community Donation Pool card** (`fureverCard`):
- 42pt serif `totalCoins` display (brassGold gradient text)
- Progress bar: `lightGreen → midGreen` gradient, animated
- Settlement notice text (12pt textTertiary)

**Coins hero card** — user's coin balance + impact equivalency

**Filter pills:** ["All", "Dogs", "Cats", "Both"]

**Shelter cards** (`fureverCard`):
- Shelter name + location
- Needs tags: capsule pills (categories: food, medical, etc.)
- Active campaign: `coral 0.08` bg badge
- "Donate Coins" button (coral) + "Donate Directly" button (outlined)

**Donate Sheet:**
- Quick amounts: [5, 10, 25, All]
- Large donation confirmation alert: triggered if donation > 50% of balance AND > 10 coins
- Alert: "This is a significant donation of X coins to [Shelter Name]. Are you sure?"

### 21.3 Shelter Impact Card

**File:** `/Views/Home/ShelterImpactCard.swift`

- Hero image 160pt height with gradient fade (`clear → inkPrimary`) overlay
- Community pool banner
- 3-column impact stats (dog silhouette icon row)
- Featured dogs horizontal carousel (80×80pt `cornerRadius:12` cards)
- Personalized contribution line: "You've contributed N coins = N meals"

### 21.4 Shelter Dogs List

**File:** `/Views/Home/ShelterDogsListView.swift`

- Hero banner (`heart.fill` icon, `coral` gradient)
- Full-width dog cards (200pt photo height, `cornerRadius:16`)
- Dog detail sheet: 300pt photo + name + story + "Support This Dog" CTA

---

## 22. Travel Screen

**File:** `/Views/Travel/TravelView.swift`

### 22.1 Layout

Title: "Pet Travel" with `airplane.departure` icon (36pt `midGreen`)

**Search bar:** `cream` background, magnifying glass icon, `cornerRadius:12`

**Region filter pills:** Countries/regions (UAE, UK, Europe, etc.)
Active: `textPrimary` fill, white text
Inactive: `flatCardFill`

**Destinations grid:** `LazyVGrid` 2-column, destination cards with photo, country flag, country name

**Analytics:** Tracks `travelOpened` on appear.

**Sub-views:**
- `AirlineComparisonView` — airline pet policy comparison
- `DestinationDetailView` — full destination detail with requirements
- `TravelChecklistView` — travel preparation checklist
- `TravelDocWizardView` — wizard for required travel documents
- `TravelPlanCard` — summary card for saved travel plans

---

## 23. Venues Screen

**File:** `/Views/Venues/VenuesView.swift`

### 23.1 Layout

Title: "Pet-Friendly Places"

**City selector button:** Current city + `chevron.down` icon → city picker

**Search bar:** `cream` background

**Category pills:** (Parks, Cafés, Hotels, Vets, Groomers, Beaches, etc.)

**Filter toggles:**
- "Pet-friendly only" toggle
- "Open now" toggle

**Sort Menu:** Distance / Rating / Name

**Optional map section:** `MKMapView` showing venue pins (shown when `showMap` state = true)

**Discovery loading overlay:** `PuppyLoaderView` with "Finding pet-friendly places…"

**Analytics:** Tracks `venuesOpened` on appear.

---

## 24. Voice Assistant Screen

**File:** `/Views/Voice/VoiceAssistantView.swift`

### 24.1 Layout

- `VoiceOrbView` — central pulsing orb (ElevenLabs Conversational AI visualizer)
- `TranscriptOverlayView` — scrolling live transcript at bottom
- `DocumentUploadSheet` — for scanning documents via voice command
- Document processing card (when processing)

### 24.2 Data Context Loaded

On appear, loads: biomarkers, medications, health alerts, medical records, walk sessions, documents, travel plans.
All passed to voice assistant context.

### 24.3 ElevenLabs Integration

- Agent ID: `agent_8701kjqtp1nvenxsyzbfh0vcxd9g`
- `ElevenLabsService` handles WebSocket connection + audio streaming
- Conversation ends on view `onDisappear`

### 24.4 Sheets

- `CameraView` — camera capture for document scanning
- `PDFDocumentPicker` — PDF file picker

---

## 25. Subscription Paywall

**File:** `/Views/Subscription/PaywallView.swift`

### 25.1 Layout

White background.

1. **Hero image** `"dog-hero-paywall"` — 260pt height, `cornerRadius:0` (full-width), with glass card overlay (`.ultraThinMaterial`, blurred)
2. **Feature list** — 7 feature rows, each: SF Symbol icon + feature text, staggered `.cardAppear.delay(0.1)` animation
3. **Pricing section:**
   - Annual card (highlighted): "AED 199.99/year" + "Save 44%" badge + "AED 16.67/mo" equivalency
   - Monthly card: "AED 29.99/month"
   - Both from StoreKit 2 real prices (fallback to hardcoded)
4. **"Start 7-Day Free Trial"** primary button
5. "Restore Purchases" link
6. Legal footer (terms + privacy links)

**Plans:**
- Monthly: `com.furevervaibhav.app.premium.monthly` — AED 29.99/mo
- Annual: `com.furevervaibhav.app.premium.annual` — AED 199.99/yr (shown first)
- 7-day free trial on both plans

**Analytics:** `paywallViewed` on appear; `subscriptionStarted` on purchase.

---

## 26. Settings & Profile Screens

### 26.1 Settings View

**File:** `/Views/Settings/SettingsView.swift`

Sections (native `List` with `.insetGrouped` style):

- **Profile:** Avatar + name + email, edit button → `EditProfileView`
- **Subscription:** Plan badge (Free / Trial / Monthly / Annual) + plan name, days remaining, "Manage" button
- **Notifications:** Toggle → `NotificationPreferencesView`
- **AI Disclosure:** "About Layla" → `AIDisclosureView`
- **Pets:** Pet list management → `PetListView`
- **Sign Out** button (coral)
- **Delete Account** button (coral, requires confirmation alert)

### 26.2 Edit Profile View

**File:** `/Views/Settings/EditProfileView.swift`

`Form` with:
- First name, last name, phone (optional)
- "Save" → `authViewModel.updateProfile(firstName:lastName:phone:)`

### 26.3 Notification Preferences

**File:** `/Views/Settings/NotificationPreferencesView.swift`

Toggles for: daily reminders, medication alerts, streak notifications, health score updates.
Stored in `UserDefaults`.

### 26.4 AI Disclosure

**File:** `/Views/Settings/AIDisclosureView.swift`

Static informational screen explaining Layla is AI-powered, not a licensed veterinarian. Prominent disclaimer banner.

---

## 27. Pet Management Screens

### 27.1 Pet List View

**File:** `/Views/Pets/PetListView.swift`

- List of all pets with photo, name, breed, age
- "Add Pet" button → `OnboardingView` (add-pet flow)
- Swipe-to-delete → `petViewModel.deletePet(id:ownerId:)`

### 27.2 Pet Detail View

**File:** `/Views/Pets/PetDetailView.swift`

**Header:**
- Species emoji (60pt) or pet photo (`CachedAsyncImage`, circular 80pt)
- Name (`.title` bold) + breed + age
- Weight capsule badge (`brassGold 0.1` bg)

**5-tab picker** (`.page` TabView, `indexDisplayMode: .never`):
1. Overview (`HealthOverviewTab`)
2. Records (`MedicalRecordsTab`)
3. Meds (`MedicationsTab`)
4. Walks (`WalkSessionsTab`)
5. More (`MoreHealthTab`)

### 27.3 Edit Pet View

Similar to onboarding pet step — `Form` with all fields + `PhotosPicker` for pet photo.
Photo upload: `PetViewModel.uploadPhoto(from:for:)` at JPEG quality 0.8, stores to Supabase storage.

---

## 28. Score Reveal & Explainer Modals

### 28.1 Progressive Score Reveal View

**File:** `/Views/Components/ProgressiveScoreRevealView.swift`

**Full-screen modal (dark ink background + DNAHelix + frosted overlay).**

**Reveal sequence (5 phases):**

| Phase | Delay | Content | Animation |
|-------|-------|---------|-----------|
| 0 | immediate | Pet icon (64pt circle, white `dog.fill`/`cat.fill`, breathing glow ring) | `spring(0.6, 0.8)` |
| 1 | +0.5s | "[petName]'s Health Report" title | `spring(0.5, 0.8)` |
| 2 | +1.0s | Pillar bars (staggered 0.4s each, `FureverHaptics.selection()` per pillar) | `spring(0.5, 0.8)` per pillar |
| 3 | +1.0s + pillars | Overall score ring (ArcGauge 200pt, count-up `spring(1.2, 0.65)`) | `spring(0.5, 0.8)` |
| 4 | +score delay + 1.0s | Score label badge + "Continue" button, `FureverHaptics.success()` | `spring(0.4, 0.6)` |

**DNA Helix background:** `DNAHelixRevealView` — animated double helix in score color, appears at phase 1, `easeIn(1.5s)`.

**Pillar row anatomy:**
- 28×28pt icon circle (`pillarColor 0.2` bg + pillarIcon 12pt)
- Pillar name (13pt semibold white)
- Score number (15pt bold rounded, score color) with `.contentTransition(.numericText())`
- Progress bar: 6pt height, `white 0.1` track + gradient fill `scoreColor 0.6 → scoreColor`, shadow `scoreColor 0.4 r:4`

**Score badge:** Colored 10pt dot + score label text, `white 0.2` capsule bg.

### 28.2 Score Explainer View

**File:** `/Views/Components/ScoreExplainerView.swift`

Sheet explaining the 5-pillar health score model with weights, what affects each pillar, and current pet scores.

### 28.3 Empty Score Card View

**File:** `/Views/Components/EmptyScoreCardView.swift`

Shown when no health data exists yet. Placeholder with "Start your pet's health journey" CTA.

---

## 29. Shared Components & Utility Views

### 29.1 CircularScoreView

Defined in `SharedComponents.swift`.

**Layers (bottom to top):**
1. Outer glow ring: `Circle().stroke(scoreColor 0.15, lineWidth: size*0.078)`, blur:4, `BreathingGlow` animation
2. Track ring: `Circle().stroke(border, lineWidth: size*0.078)`
3. Score ring: `Circle().trim(from:0, to: score/100)`, `scoreRingGradient`, lineWidth: `size*0.078`, start: -90°
4. Glow endpoint dot: `Circle().fill(scoreGreen)`, size: `size*0.06`, blur:8, positioned at score angle
5. Center: score number (`.monoScore` font for size ≥ 100, else scaled), score label

**Compact variant (52pt):** lineWidth:6, smaller font.

**Animation:** `.scoreFill` preset on score value change.

### 29.2 Section Header (`SectionHeader`)

- 20×2pt `brassGold` bar (left accent)
- Text: uppercase, `brassGold`, `.chipText` font, tracking:1.2
- `HStack(spacing: 8)`

### 29.3 Pill Button (`PillButton`)

- Selected: `textPrimary` fill, white text
- Unselected: `flatCardFill` fill, `textPrimary` text
- Capsule shape, 8×14pt padding, `.chipText` font

### 29.4 Status Pill (`StatusPill`)

- Capsule: `color opacity:0.12` background, `color` text
- Font: `.tinyLabel` (10pt bold rounded)
- Padding: 4×8pt

### 29.5 CoinEarnedToast

**File:** `/Utils/CoinEarnedToast.swift`

**Appears:** Slides in from top (-80pt offset → +8pt offset), `opacity 0 → 1`, `spring(0.5, 0.75)`
**Auto-dismisses:** After 2.5s, `easeOut(0.3s)` fade-out + slide up, `isShowing = false` after 0.35s

**Content:**
- `star.fill` icon in `brassGold 0.15` circle (32×32pt), `brassGold` color
- `"+N coins earned!"` — `chipText` bold, `textPrimary`
- `"= N meals for shelter dogs"` — `smallLabel`, `lightGreen`
- `pawprint.fill` trailing icon (12pt, `lightGreen 0.5`)

**Card style:** `.ultraThinMaterial` + `brassGold 0.2` stroke, `cornerRadius:16`, shadow `black 0.08 r:12 y:4`

**Haptic:** `FureverHaptics.success()` on appear.

**Usage:** `.coinEarnedToast(isShowing: $show, coins: N)` view modifier.

### 29.6 CelebrationOverlay

**File:** `/Utils/CelebrationView.swift`

Confetti particle system using `Canvas` + `TimelineView(.animation(60fps))`.

**Particle physics:**
- 50 particles default, 3.0s duration
- Start position: random horizontal (10–90%), top of screen (-10–10%)
- Velocity: X ∈ [-80, 80] pt/s, Y ∈ [-350, -150] pt/s (upward burst)
- Gravity: 400 pt/s²
- Rotation: random + rotationSpeed ∈ [-8, 8] rad/s
- Size: 4–10pt, delay 0–0.4s

**Colors:** brassGold, lightGreen, midGreen, coral, gold, scoreBlue

**Shapes:** circle, rectangle (wide), 5-point star

**Fade:** alpha = max(0, 1.0 - progress * 1.2 + delay * 0.3)

**Usage:** `.celebrationOverlay(isShowing: $show)` view modifier.

### 29.7 PuppyLoaderView

**File:** `/Utils/PuppyLoaderView.swift`

Animated puppy canvas (size: 120pt, frame 300×216pt).
State machine cycles through 20 behaviors (trotting/sniffing/running/playBow/sitting/zoomies/rolling/shaking) with varied durations totalling ~40s per cycle.
All animation is deterministic from `Date.timeIntervalSinceReferenceDate` (no SwiftUI state).
Used as global loading indicator.

### 29.8 BiomarkerArcGauge

**File:** `/Views/Health/BiomarkerArcGauge.swift`

- Arc: `startAngle: 135°`, `endAngle: 405°` (270° sweep)
- Track: `border` color, lineWidth:14
- Gradient: `AngularGradient(scoreRed → scoreOrange → scoreGreen)`
- Progress: trimmed to `inRange/total` fraction
- Center: `inRange/total` in serif font
- Sub-label: "Biomarkers" in tinyLabel

### 29.9 BiomarkerListView / RangeBar

**File:** `/Views/Health/BiomarkerListView.swift`

**RangeBar:**
- Track: 6pt height, `border` fill
- 45% zone highlight: `scoreGreen opacity:0.15` (normal range visual zone)
- Marker dot: 10pt circle, status color
- Position formula: `rangeProgress = (value - min) / (max - min)` clamped, extended ±30% beyond ref range

**BiomarkerRow status colors:**
- High → `coral`
- Low → `scoreBlue`
- Normal → `alertGreen`

---

## 30. Analytics Event Catalog

**File:** `/Services/AnalyticsService.swift`

**Complete `AnalyticsEvent` enum (50 events):**

| Event | Category |
|-------|----------|
| `appOpen` | lifecycle |
| `appBackground` | lifecycle |
| `signIn` | auth |
| `signUp` | auth |
| `signOut` | auth |
| `deleteAccount` | auth |
| `petAdded` | pet |
| `petPhotoUploaded` | pet |
| `biomarkerAdded` | health |
| `medicationAdded` | health |
| `walkLogged` | health |
| `medicalRecordAdded` | health |
| `documentUploaded` | health |
| `symptomLogged` | health |
| `healthAlertResolved` | health |
| `labReportScanned` | lab |
| `ocrStarted` | lab |
| `ocrCompleted` | lab |
| `bcsStarted` | bcs |
| `bcsCompleted` | bcs |
| `wellnessSurveyStarted` | wellness |
| `wellnessSurveyCompleted` | wellness |
| `urineCheckStarted` | health |
| `urineCheckCompleted` | health |
| `healthScoreCalculated` | score |
| `scoreRevealShown` | score |
| `scoreBreakdownOpened` | score |
| `chatStarted` | chat |
| `chatMessageSent` | chat |
| `chatCleared` | chat |
| `coinEarned` | economy |
| `coinAllocated` | economy |
| `shelterDonated` | shelter |
| `shelterDirectoryOpened` | shelter |
| `subscriptionStarted` | subscription |
| `subscriptionRestored` | subscription |
| `paywallViewed` | subscription |
| `tabSwitched` | navigation |
| `travelOpened` | travel |
| `venuesOpened` | venues |
| `driveStarted` | drive |
| `driveEnded` | drive |
| `driveEventDetected` | drive |
| `voiceAssistantOpened` | voice |
| `notificationPermissionGranted` | notification |
| `streakUpdated` | streak |
| `proactiveInsightShown` | insights |
| `proactiveInsightDismissed` | insights |
| `insightActioned` | insights |
| `adminNotificationReceived` | admin |

**Infrastructure:**
- Batch queue: size 10 → auto-flush to Supabase + distribution backend
- Flush interval: 30s timer, also flushes on `.background` scene phase
- Dual-write: `POST /api/track/batch` to `https://furever-distribution.vercel.app` + Supabase `analytics_events` table
- Device info: cached as JSON (device model, OS version, app version, bundle ID)

---

## 31. Health Score Algorithm

**File:** `/Services/ScoreCalculator.swift`

### 31.1 Five Pillars

| Pillar | Weight | Biomarker Categories |
|--------|--------|---------------------|
| Organ Strength | 30% | Kidney, Liver, Cardiac |
| Inflammation | 20% | Inflammatory markers (CRP, WBC) |
| Metabolic | 20% | Glucose, Thyroid, Cholesterol |
| Body & Activity | 15% | Weight, activity metrics |
| Wellness & Dental | 15% | Wellness survey, dental markers |

### 31.2 Biomarker Severity Scoring

| Status | Center Score | Edge Score |
|--------|-------------|-----------|
| Normal | 100 | 85 |
| Slightly off | — | 65 |
| Moderately off | — | 40 |
| Severely off | — | 15 |

Linear interpolation between edge/center based on how far from reference range.

### 31.3 Trend Adjustment

- Stable in normal range: +5
- Improving trend: +8
- Deteriorating trend: -10

### 31.4 Blend Weights

| Component | Weight (normalized) |
|-----------|-------------------|
| Biomarkers | 50% |
| Wellness survey | 30% |
| Activity score | 20% |

If any component has no data, its weight redistributes to others (normalized).

### 31.5 Wellness Survey Scoring

Answer → score mapping:
- 0 (excellent) → 100
- 1 (good) → 70
- 2 (fair) → 40
- 3 (poor) → 10

### 31.6 Activity Scoring

Component weights: Frequency 40%, Duration 35%, Distance 25%.

**Breed-size activity targets:**
| Size | Weight | Duration | Distance | Frequency |
|------|--------|----------|----------|-----------|
| Small | < 10 kg | 20 min | 1.5 km | 5×/week |
| Medium | 10–25 kg | 30 min | 3.0 km | 5×/week |
| Large | 25–45 kg | 45 min | 5.0 km | 6×/week |
| Giant | > 45 kg | 35 min | 3.5 km | 5×/week |

Score per dimension = actual / target (clamped 0–100).

### 31.7 Final Score

`finalScore = Σ(pillarScore × pillarWeight)` → rounded Int, clamped 0–100.

---

## 32. Backend & Data Models

### 32.1 Supabase Tables

| Table | Purpose |
|-------|---------|
| `owners` | User profiles (id = Supabase auth UUID, lowercased) |
| `pets` | Pet records (species, breed, dob, weight, photoUrl, longevityScore) |
| `biomarkers` | Lab values with referenceMin/Max, pillar, trend[{date,value}] |
| `medications` | Medication supply tracking, refill dates |
| `medical_records` | Vet visits, vaccinations, surgeries |
| `walk_sessions` | Steps, distance, duration, cadence |
| `health_alerts` | Active health concerns (resolvable) |
| `insurance_claims` | Insurance claim tracking |
| `documents` | Uploaded files metadata |
| `symptom_logs` | User-reported symptoms with severity |
| `user_wallets` | Credits + coins balance |
| `credit_transactions` | Full audit trail of earn/spend |
| `analytics_events` | App analytics (dual-written) |
| `memberships` | StoreKit subscription status sync |
| `shelters` | Shelter directory |
| `travel_destinations` | Pet travel destination data |
| `venues` | Pet-friendly venue listings |

### 32.2 Key Model Structures

**Pet:**
```
id: String (UUID)
name, breed, species: String
dateOfBirth: String? (yyyy-MM-dd)
gender: String? ("male"/"female")
isNeutered: Bool
weight: Double? (kg)
photoUrl: String?
longevityScore: Int?
ownerId: String
microchip: String?
dubaiLicence: String?
bloodType: String?
```

**Biomarker:**
```
id, petId, name, value: Double?, unit: String?
referenceMin, referenceMax: Double?
pillar: String?
date: String (yyyy-MM-dd)
trend: [TrendPoint]? — [{date, value}]
source: String
status: computed ("high"/"low"/"normal"/"unknown")
```

**DriveTrip:**
```
id: String
startTime: Date
endTime: Date?
events: [DriveEvent]
distanceMeters, maxSpeedKmh, averageSpeedKmh: Double
coinsEarned: Int (starts 20)
driveScore: Int (starts 100)
```

**CreditWallet:**
```
id, ownerId: String
creditsBalance, coinsBalance: Int
totalCoinsEarned, totalCreditsPurchased: Int
totalBalance: computed
```

### 32.3 Claude API Configuration

- Model: `claude-sonnet-4-6`
- Max tokens: 2048
- Route: Supabase Edge Function proxy (not direct API calls from client)
- Voice: ElevenLabs Agent `agent_8701kjqtp1nvenxsyzbfh0vcxd9g`

### 32.4 Subscription Plans (StoreKit 2)

| Plan | Product ID | Price | Trial |
|------|-----------|-------|-------|
| Monthly | `com.furevervaibhav.app.premium.monthly` | AED 29.99 | 7 days |
| Annual | `com.furevervaibhav.app.premium.annual` | AED 199.99 | 7 days |

Annual savings badge: "Save 44%"
Note: `isSubscribed` defaults to `true` (app is currently free-to-use).

### 32.5 Streak System

**File:** `/Services/StreakManager.swift`

- `UserDefaults` keys: `furever_streak_count`, `furever_streak_last_active_date`, `furever_streak_longest`
- `recordActiveDay()` — called on any habit toggle or task completion
- `validateStreak()` — called on app launch; resets to 0 if > 1 day gap
- Milestones: 7, 14, 30, 60, 100, 365 days
- On milestone: fires `NotificationService.shared.fireStreakMilestone(days:)` + broadcasts via `PassthroughSubject<Int, Never>`

### 32.6 ProactiveInsightsService

**File:** `/Services/ProactiveInsightsService.swift`

Generates `ProactiveInsight` structs locally (no network call):

**Analysis modules:**
1. **Biomarker trends:** Flags out-of-range values; kidney/liver markers → severity "action"; others → "watch"; trend change > 15% → additional insight
2. **Breed screening:** Golden Retriever (≥6y) → cancer screening; Cavalier KCS (≥1y) → cardiac echo; French Bulldog → BOAS monitoring; Senior dog (≥7y) → biannual wellness; Senior cat (≥7y) → thyroid + kidney panel
3. **Medication:** Supply < 15% → "watch"; ≤ 3 days → "action"; Refill ≤ 7 days → "watch"; ≤ 2 days → "action"
4. **Activity:** No walks logged in past 7 days → "watch"
5. **Cross-markers:** BUN+Creatinine+SDMA (2+) → kidney "action"; ALT+AST+ALP (2+) → liver "action"; RBC+Hgb+Hct low (2+) → anaemia "action"

**Storage:** `UserDefaults` key `furever_proactive_insights`, JSON-encoded `[ProactiveInsight]`, per petId.
**Dismiss:** Marks `isDismissed = true` in local storage.

---

## Appendix A: Screen Flow Diagram

```
App Launch
├── SplashScreenView (auth loading)
├── LoginView → SignUpView
│   └── OnboardingView (4 steps) → MainTabView
└── MainTabView (authenticated)
    ├── Tab 0: HomeView
    │   ├── DailyPlanCard → AppDestination routing
    │   ├── FureverImpactSection → ShelterDirectoryView
    │   └── ProgressiveScoreRevealView (fullScreenCover, conditional)
    ├── Tab 1: ReportView (Lab Upload)
    │   └── OCRScanView → DocumentProcessingOverlay
    ├── Tab 2: VetChatView (Layla)
    │   └── VoiceAssistantView (voice mode)
    ├── Tab 3: TrackView
    │   ├── BCS Flow (fullScreen)
    │   ├── WellnessCheck Flow (fullScreen)
    │   ├── UrineCheck Flow (fullScreen)
    │   └── WellXDriveView (fullScreen)
    │       ├── DriveIdleView
    │       ├── DriveActiveView
    │       └── DriveSummaryView
    └── Tab 4: WalletView (Records/Wallet)
        └── DocumentDetailView

Settings (sheet from home avatar):
    ├── EditProfileView
    ├── NotificationPreferencesView
    ├── AIDisclosureView
    ├── PetListView → EditPetView
    └── PaywallView

Global sheets (NavigationRouter):
    ├── ScoreBreakdownView
    ├── MedicationsView
    ├── VenuesView
    ├── ShelterDirectoryView
    ├── TravelView
    ├── CreditsWalletView → EarnCoinsView
    └── HealthTimelineView
```

---

## Appendix B: UserDefaults Key Reference

| Key Pattern | Content |
|-------------|---------|
| `furever_chat_history_<petId>` | JSON `[ChatMessage]` (last 50) |
| `bcs_history_<petId>` | JSON `[BCSRecord]` |
| `wellness_result_<petId>` | JSON `WellnessSurveyResult` |
| `completedHabits_<petId>_<date>` | JSON `[String]` completed task IDs |
| `daily_completed_<petId>_<date>` | `[String]` completed task IDs |
| `previousHealthScore_<petId>` | Int score (for delta calculation) |
| `lastRevealedScore_<petId>` | Int score (for reveal throttle) |
| `lastRevealDate_<petId>` | String date `yyyy-MM-dd` |
| `furever_proactive_insights` | JSON `[ProactiveInsight]` |
| `furever_streak_count` | Int |
| `furever_streak_last_active_date` | Date |
| `furever_streak_longest` | Int |
| `hasShownNotificationPrompt` | Bool |
| `analytics_owner_id` | String (used by SubscriptionManager) |

---

*Document end — FureverApp iOS Feature Inventory v1.0*
