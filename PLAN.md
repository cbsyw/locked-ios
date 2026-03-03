# Locked iOS App — Development Plan

## Project Overview

**App Name:** Locked
**Purpose:** A productivity/focus app that lets users "lock" their phone to a physical location using QR codes. When locked, distracting apps are blocked via Apple's Screen Time API. To unlock, the user must physically return to the QR code location and scan it again. It tracks focus session durations and daily totals.
**Bundle ID:** `com.christianwarren.locked`
**License:** MIT
**Minimum Target:** iOS 17+ (required for SwiftData, `onChange(of:)` API)

---

## Current Project Structure

```
locked/
├── lockedApp.swift              -- App entry, routes onboarding vs home
├── ContentView.swift            -- Thin wrapper (renders HomeView) — TO BE DELETED
├── Models/
│   ├── LockState.swift          -- LockPoint struct, LockStatus enum
│   └── OnboardingStep.swift     -- OnboardingStep enum, OnboardingManager
├── Views/
│   ├── HomeView.swift           -- Main screen: status, timers, actions
│   ├── QRScannerView.swift      -- AVFoundation camera QR scanner
│   ├── QRGeneratorView.swift    -- QR code creation + share/save
│   └── Onboarding/
│       ├── OnboardingContainerView.swift
│       ├── WelcomeView.swift
│       ├── PermissionsView.swift
│       ├── CreateOrScanView.swift
│       ├── SelectAppsView.swift
│       └── CompleteView.swift
└── Services/
    ├── LockServices.swift       -- Lock/unlock state, timer, persistence
    ├── QRcodeService.swift      -- QR generation/validation (static)
    └── ScreenTimeService.swift  -- Screen Time authorization & blocking
```

---

## What Works Today

| Feature | Status |
|---------|--------|
| QR code generation (`LOCKED://` URI scheme) | Done |
| QR code scanning (AVFoundation) | Done |
| Lock/unlock state machine | Done |
| Live session timer (1-sec interval) | Done |
| Daily focus total tracking | Done |
| State persistence (UserDefaults) | Done |
| 5-step onboarding flow | Done (has a bug) |
| Screen Time authorization request | Done |
| FamilyActivityPicker integration | Done |
| QR sharing / save to Photos | Done (missing permission key) |

---

## Known Bugs

### C1: OnboardingManager Dual-Instance Bug
`lockedApp.swift` creates an `OnboardingManager` and injects it via `.environmentObject()`. But `OnboardingContainerView` creates its own separate `@StateObject private var onboardingManager = OnboardingManager()` and passes it manually to child views. Completing onboarding updates the container's copy, not the app-level one. **Result:** User is stuck on the onboarding screen until a full app restart.

### C2: Screen Time Blocking Never Activated
`ScreenTimeService` has `blockApps()` and `unblockAll()` methods, but `LockService.lock()` and `unlock()` never call them. **The core value proposition — blocking apps when locked — does not work.**

### C3: Missing `NSPhotoLibraryAddUsageDescription`
The save-to-photos function calls `UIImageWriteToSavedPhotosAlbum` but there is no privacy description in Info.plist. **Will crash at runtime on first save attempt.**

### C4: FamilyActivitySelection Lost on Restart
`ScreenTimeService.savedSelection` is an in-memory property. On app kill and relaunch, the selection is `nil`. The app has no idea which apps the user selected to block. Apple intentionally makes `FamilyActivitySelection` tokens non-serializable for privacy.

---

## Missing Features

| Feature | Current State |
|---------|---------------|
| Lock Points list view | Button exists, prints to console |
| Save QR success alert | `// TODO` in code, no feedback |
| Usage analytics | Listed in README, not implemented |
| Settings screen | Does not exist — no way to re-select apps or re-request permissions |
| App icon | All 3 slots empty |
| Accent color | Not configured |
| Proper logging | 33 `print()` statements with emoji |
| Debug guard on test buttons | "Force Unlock (Testing)" and "Test QR Scanner" visible in production UI |

---

## Architecture Decisions

### 1. Dependency Injection via Environment (replacing Singletons)

**Current problem:** `LockService` and `ScreenTimeService` use `static let shared` + `private init()`. This makes testing impossible, hides dependencies between services, and fights SwiftUI's ownership model.

**Solution:** Remove singletons. Create services at the app entry point and inject via `@EnvironmentObject`.

**New app entry point pattern:**

```swift
@main
struct LockedApp: App {
    @StateObject private var lockService: LockService
    @StateObject private var screenTimeService = ScreenTimeService()
    @StateObject private var onboardingManager = OnboardingManager()

    init() {
        let screenTime = ScreenTimeService()
        _screenTimeService = StateObject(wrappedValue: screenTime)
        _lockService = StateObject(wrappedValue: LockService(screenTimeService: screenTime))
    }

    var body: some Scene {
        WindowGroup {
            if onboardingManager.hasCompletedOnboarding {
                HomeView()
                    .environmentObject(lockService)
                    .environmentObject(screenTimeService)
            } else {
                OnboardingContainerView()
                    .environmentObject(onboardingManager)
                    .environmentObject(lockService)
                    .environmentObject(screenTimeService)
            }
        }
    }
}
```

**What this fixes:**
- OnboardingManager dual-instance bug (C1) — one instance, injected everywhere
- `ContentView.swift` wrapper — eliminated, `HomeView` referenced directly
- Services take explicit dependencies — `LockService` receives `ScreenTimeService` so blocking is wired up automatically (fixes C2)

**Files touched:**

| File | Change |
|------|--------|
| `lockedApp.swift` | Rewrite — create all services, inject via environment |
| `LockServices.swift` | Remove `static let shared`, `private init()` → `init(screenTimeService:)` |
| `ScreenTimeService.swift` | Remove `static let shared`, `private init()` → `init()` |
| `ContentView.swift` | Delete |
| `HomeView.swift` | `@StateObject private var lockService = LockService.shared` → `@EnvironmentObject var lockService: LockService` |
| `OnboardingContainerView.swift` | Remove its own `@StateObject`, use `@EnvironmentObject` |
| `SelectAppsView.swift` | `ScreenTimeService.shared` → `@EnvironmentObject var screenTimeService` |
| `CompleteView.swift` | `LockService.shared` → `@EnvironmentObject var lockService` |
| `QRCodeService` | No change — stays static/stateless, pure utility |

**LockService with explicit ScreenTimeService dependency:**

```swift
class LockService: ObservableObject {
    private let screenTimeService: ScreenTimeService

    init(screenTimeService: ScreenTimeService) {
        self.screenTimeService = screenTimeService
        // ... existing load logic
    }

    func lock(with lockPoint: LockPoint) {
        // ... existing lock logic
        screenTimeService.applyBlock()   // NOW WIRED UP
    }

    func unlock(with qrCode: String) -> Bool {
        // ... existing unlock logic
        screenTimeService.unblockAll()   // NOW WIRED UP
        return true
    }
}
```

---

### 2. SwiftData Migration (replacing UserDefaults for structured data)

**Current problem:** Lock points are JSON-encoded into UserDefaults. Daily totals stored as raw Doubles. No session history, no queryable data, no relationships, no migration support.

**Solution:** Use SwiftData for lock points and focus sessions. Keep simple preferences (`hasCompletedOnboarding`, lock status flags) in UserDefaults.

**New models:**

```swift
@Model
class LockPoint {
    @Attribute(.unique) var id: String
    var name: String
    var qrCode: String
    var createdAt: Date
    var sessions: [FocusSession]  // automatic relationship

    init(name: String, qrCode: String) {
        self.id = UUID().uuidString
        self.name = name
        self.qrCode = qrCode
        self.createdAt = Date()
        self.sessions = []
    }
}

@Model
class FocusSession {
    var id: String
    var startedAt: Date
    var endedAt: Date?
    var duration: TimeInterval
    var lockPoint: LockPoint?  // back-reference

    init(startedAt: Date, lockPoint: LockPoint) {
        self.id = UUID().uuidString
        self.startedAt = startedAt
        self.lockPoint = lockPoint
    }
}
```

**Setup in app entry point:**

```swift
.modelContainer(for: [LockPoint.self, FocusSession.self])
```

**What migrates FROM UserDefaults TO SwiftData:**

| Data | Before | After |
|------|--------|-------|
| Lock points array | JSON-encoded in UserDefaults | `@Query var lockPoints: [LockPoint]` in views |
| Session history | Not tracked (only daily total as Double) | `FocusSession` records with start/end/duration |
| Daily totals | `UserDefaults.double(forKey: "todayTotal")` | Computed from `FocusSession` records for today |

**What stays in UserDefaults:**

| Data | Why |
|------|-----|
| `hasCompletedOnboarding` | Simple boolean preference |
| `lockStatus` (isLocked, lockedAt, currentLockPointID) | Needs instant access on cold launch |

**Impact on LockService:**
- Remove `saveLockPoints()`, `loadLockPoints()` — SwiftData handles persistence
- `LockService` gets a `ModelContext` injected
- `lock(with:)` creates a new `FocusSession`
- `unlock(with:)` closes the `FocusSession` (sets `endedAt`, computes `duration`)
- Daily totals computed via `@Query` predicate: all sessions where `startedAt >= startOfToday`

---

### 3. DeviceActivityMonitor Extension (solving FamilyActivitySelection persistence)

**Current problem:** `FamilyActivitySelection` tokens are opaque and non-serializable. Apple did this intentionally for privacy. The selection is lost on app restart, so blocking can't work after a kill.

**Solution:** Create a `DeviceActivityMonitor` extension. Use a named `ManagedSettingsStore` shared between the app and extension. The store persists independently of the app lifecycle.

**Architecture:**

```
┌─────────────────────────────────┐
│  Main App (locked)              │
│                                 │
│  - User selects apps via picker │
│  - User taps "Lock" → starts   │
│    DeviceActivitySchedule       │
│  - User taps "Unlock" → stops  │
│    the schedule                 │
└───────────┬─────────────────────┘
            │ starts/stops schedule
            ▼
┌─────────────────────────────────┐
│  DeviceActivityMonitor          │
│  Extension (LockedMonitor)      │
│                                 │
│  intervalDidStart() →           │
│    Shields already applied      │
│  intervalDidEnd() →             │
│    Remove shields               │
│                                 │
│  Runs even if app is killed     │
└───────────┬─────────────────────┘
            │ reads/writes
            ▼
┌─────────────────────────────────┐
│  ManagedSettingsStore            │
│  (named: "locked-session")      │
│                                 │
│  Persists across app restarts   │
│  Shared between app + extension │
│  System-managed                 │
└─────────────────────────────────┘
```

**Implementation steps:**

**Step 1: App Group**
- Create App Group: `group.com.christianwarren.locked`
- Add to both main app and extension entitlements
- Use `UserDefaults(suiteName: "group.com.christianwarren.locked")` for shared preferences

**Step 2: Extension Target**
- Xcode: File > New > Target > Device Activity Monitor Extension
- Name: `LockedMonitor`
- Add `com.apple.developer.family-controls` entitlement
- Add to same App Group

**Step 3: Named ManagedSettingsStore**

```swift
extension ManagedSettingsStore.Name {
    static let lockedSession = Self("locked-session")
}
```

**Step 4: Monitor Extension**

```swift
class LockedMonitor: DeviceActivityMonitor {
    let store = ManagedSettingsStore(named: .lockedSession)

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Shields already applied when schedule was created
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.clearAllSettings()
    }
}
```

**Step 5: Reworked ScreenTimeService**

```swift
class ScreenTimeService: ObservableObject {
    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore(named: .lockedSession)
    private let activityCenter = DeviceActivityCenter()

    @Published var isAuthorized = false
    @Published var selection = FamilyActivitySelection()

    func applyBlock() {
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
    }

    func unblockAll() {
        store.clearAllSettings()
    }

    func startMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        do {
            try activityCenter.startMonitoring(.lockedSession, during: schedule)
        } catch {
            // handle error
        }
    }

    func stopMonitoring() {
        activityCenter.stopMonitoring([.lockedSession])
    }
}
```

**How the persistence problem is solved:**
- `FamilyActivitySelection` is held in memory
- When user selects apps, tokens are immediately written to the named `ManagedSettingsStore`
- The store persists independently — system-managed, survives app kill and reboot
- On app restart while locked: shields are already active in the store, no action needed
- On app restart while unlocked: store is already clear, no action needed
- If user tries to lock after restart with empty selection: show `FamilyActivityPicker` first

---

## Complete User Flow Map

### Flow 1: First Launch → Onboarding

```
App Launch
  → hasCompletedOnboarding == false
  → OnboardingContainerView
     ├── WelcomeView
     │     └── "Get Started" → next
     ├── PermissionsView
     │     ├── "Grant Permission" → AuthorizationCenter.requestAuthorization(.individual)
     │     │     ├── Success → auto-advance
     │     │     └── Failure → alert, "Skip for Now"
     │     └── "Skip for Now" → next
     │           ⚠️ GAP: No way to re-request later (needs Settings screen)
     ├── CreateOrScanView
     │     ├── Type name + "Generate QR" → QR displayed, save/share
     │     └── "Continue" → next (saves firstLockPoint to OnboardingManager)
     ├── SelectAppsView
     │     ├── "Select Apps" → FamilyActivityPicker
     │     │     └── selection saved to ScreenTimeService
     │     └── "Continue" → next
     └── CompleteView
           └── "Start Focusing"
                 ├── Saves firstLockPoint to SwiftData
                 ├── Sets hasCompletedOnboarding = true
                 └── Transitions to HomeView
```

### Flow 2: Normal Lock

```
HomeView (unlocked)
  → "Lock Now" → QRScannerView (mode: .lock)
  → Scan QR code
     ├── Valid LOCKED:// prefix?
     │     ├── YES → handleLockScan()
     │     │     ├── Existing LockPoint found? → use it
     │     │     └── New QR? → create LockPoint, save to SwiftData
     │     │     ├── Has apps selected?
     │     │     │     ├── YES → lock + applyBlock + startMonitoring
     │     │     │     └── NO → show FamilyActivityPicker first, then lock
     │     │     └── HomeView → locked state (red, timer, "Unlock" button)
     └── NO → "Invalid QR" alert
```

### Flow 3: Normal Unlock

```
HomeView (locked)
  → "Unlock" → QRScannerView (mode: .unlock)
  → Scan QR code
     ├── Matches current lock point?
     │     ├── YES → unlock()
     │     │     ├── Close FocusSession in SwiftData
     │     │     ├── unblockAll() — clear named store
     │     │     ├── stopMonitoring() — stop DeviceActivity schedule
     │     │     └── HomeView → unlocked state
     │     └── NO → "Wrong QR Code" alert
```

### Flow 4: App Killed While Locked

```
User force-quits app while locked
  → ManagedSettingsStore persists — apps still blocked
  → DeviceActivityMonitor extension still running
  → User reopens app
     → LockService loads lock state from UserDefaults
     → Finds LockPoint from SwiftData by ID
     → Restores locked state, timer resumes
     → Normal unlock flow when ready
```

### Flow 5: App Restart While Unlocked, Then Lock

```
User reopens app (unlocked)
  → ScreenTimeService.selection is nil (lost from memory)
  → User taps "Lock Now" → scans QR
  → Check: is selection empty?
     ├── YES → Present FamilyActivityPicker first → then lock
     └── NO → lock immediately
```

### Flow 6: Create Lock Point (from HomeView)

```
HomeView → "Create Lock Point" → QRGeneratorView
  → Type name, "Generate QR Code"
  → QR displayed with share/save
  → ⚠️ NEEDS FIX: Save LockPoint to SwiftData immediately on generation
```

### Flow 7: View Lock Points (NOT YET IMPLEMENTED)

```
HomeView → "My Lock Points" → LockPointsListView
  → @Query-driven list of all saved LockPoints
  → Tap for detail (name, QR image, created date, session count)
  → Swipe to delete (guard: cannot delete active lock point)
  → Tap to reshare QR code
```

### Flow 8: Settings (NOT YET IMPLEMENTED)

```
HomeView → Settings (nav bar) → SettingsView
  → Re-select apps (FamilyActivityPicker)
  → Re-request Screen Time permission
  → Reset onboarding
  → About / version
  → Debug tools (#if DEBUG)
```

---

## Code Smells & Cleanup Items

- **33 `print()` statements** with emoji — replace with `Logger` / `os.log`
- **`ContentView.swift`** is unnecessary — just wraps `HomeView()`
- **`DeviceActivity` imported but unused** in current ScreenTimeService
- **`selectedApps` in OnboardingManager** declared but never written to
- **QR device ID appended but never validated** on scan — either validate or remove
- **No error states in QR scanner** for camera denied/unavailable
- **Deployment target mismatch** — README says iOS 15+, project says 26.2, code uses iOS 17+ APIs
- **UserDefaults as primary database** for structured data (addressed by SwiftData migration)

---

## Phased Implementation Plan

### Phase 0: Foundation

| # | Task | Depends On | Effort |
|---|------|------------|--------|
| 0.1 | Refactor to DI via Environment — remove singletons, inject via `@EnvironmentObject` | — | Medium |
| 0.2 | Fix OnboardingManager — remove duplicate `@StateObject`, use `@EnvironmentObject` | 0.1 | Small |
| 0.3 | Delete `ContentView.swift` — reference `HomeView` directly | 0.1 | Trivial |
| 0.4 | Add `NSPhotoLibraryAddUsageDescription` to Info.plist | — | Trivial |

### Phase 1: SwiftData

| # | Task | Depends On | Effort |
|---|------|------------|--------|
| 1.1 | Define SwiftData models — `LockPoint` as `@Model`, new `FocusSession` as `@Model` | 0.1 | Medium |
| 1.2 | Setup `ModelContainer` in app entry point | 1.1 | Small |
| 1.3 | Migrate LockService persistence — replace UserDefaults JSON with `ModelContext` | 1.2 | Medium |
| 1.4 | Add FocusSession tracking — create on lock, close on unlock, compute daily totals | 1.3 | Medium |
| 1.5 | Migrate views to `@Query` — HomeView reads lock points directly | 1.3 | Small |

### Phase 2: DeviceActivityMonitor Extension

| # | Task | Depends On | Effort |
|---|------|------------|--------|
| 2.1 | Create App Group `group.com.christianwarren.locked` | — | Small |
| 2.2 | Create DeviceActivityMonitor extension target (`LockedMonitor`) | 2.1 | Medium |
| 2.3 | Implement named `ManagedSettingsStore` shared between app and extension | 2.2 | Small |
| 2.4 | Implement `LockedMonitor` — `intervalDidStart`, `intervalDidEnd` | 2.3 | Medium |
| 2.5 | Rework `ScreenTimeService` — named store, `startMonitoring()` / `stopMonitoring()` | 2.3 | Medium |
| 2.6 | Wire lock/unlock to ScreenTimeService — `lock()` calls `applyBlock()` + `startMonitoring()` | 0.1, 2.5 | Small |
| 2.7 | Add "no selection" guard — show picker if user tries to lock with empty selection | 2.6 | Small |

### Phase 3: Complete Core Features

| # | Task | Depends On | Effort |
|---|------|------------|--------|
| 3.1 | Build `LockPointsListView` — `@Query`-driven list, detail view, swipe-to-delete | 1.5 | Medium |
| 3.2 | Save LockPoint on generation — `QRGeneratorView` saves to SwiftData immediately | 1.3 | Small |
| 3.3 | Add save-to-photos feedback — completion handler + success/error alert | 0.4 | Small |
| 3.4 | Build `SettingsView` — re-select apps, re-request permissions, reset onboarding | 2.5 | Medium |
| 3.5 | Guard debug UI — wrap "Force Unlock" and "Test QR Scanner" in `#if DEBUG` | — | Trivial |

### Phase 4: Polish

| # | Task | Depends On | Effort |
|---|------|------------|--------|
| 4.1 | Replace `print()` with `Logger` | — | Small |
| 4.2 | Fix deployment target — set iOS 17+, update README | 1.1 | Trivial |
| 4.3 | Remove unused code — `DeviceActivity` import, `selectedApps` in OnboardingManager | 0.1 | Trivial |
| 4.4 | Clean up QR security — validate device ID on scan or stop appending it | — | Small |
| 4.5 | Add error states to QR scanner — camera denied, unavailable, invalid QR feedback | — | Small |
| 4.6 | App icon + accent color | — | Small |
| 4.7 | Haptic feedback on lock/unlock transitions | — | Trivial |

### Phase 5: New Features

| # | Task | Depends On | Effort |
|---|------|------------|--------|
| 5.1 | Usage analytics / focus history — charts querying FocusSession by day/week/month | 1.4 | Large |
| 5.2 | DeviceActivityReport extension — custom SwiftUI usage report (WWDC22 API) | 2.2, 5.1 | Large |
| 5.3 | Widgets / Live Activities for active sessions | 1.4 | Large |
| 5.4 | Unit tests — LockService state machine, QRCodeService, session tracking | All | Medium |

---

## Open Questions

1. **App Group name** — Plan assumes `group.com.christianwarren.locked`. Confirm or change.
2. **"No selection on lock" UX** — Should the app require app selection before locking, or allow locking without blocking (timer/QR commitment only) with a banner suggesting to select apps in Settings?
3. **Migration from existing UserDefaults data** — Since there are no production users, we can skip data migration and just swap the persistence layer. If testing data needs to be preserved, a one-time migration can read JSON from UserDefaults, insert into SwiftData, and delete the old keys.
