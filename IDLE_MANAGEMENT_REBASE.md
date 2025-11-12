# Idle Management Feature - Rebase Summary

**Branch**: reset
**Date Created**: 2025-11-09
**Feature**: Automatic idle detection with configurable timeouts for screen dimming, DPMS, lock, and suspend

## Overview

Modular idle management service using Quickshell's native `IdleMonitor` (Wayland ext-idle-notify-v1 protocol) with separate AC/Battery configurations, inhibitor apps, and debounce protection.

---

## Files Created (3 new files)

### 1. Services/Power/IdleManagementService.qml (~420 lines)
**Purpose**: Core idle management service
**Key Features**:
- 4 separate IdleMonitor instances (dim, DPMS, lock, suspend)
- AC/Battery power mode detection via UPower
- Inhibitor app checking via shell script
- Debounce logic for suspend
- Compositor-specific DPMS control (Hyprland/Sway/Niri)

### 2. Modules/Panels/Settings/Tabs/IdleManagementTab.qml (~370 lines)
**Purpose**: Settings UI panel
**Key Features**:
- Master enable toggle
- Collapsible AC/Battery mode sections
- Timeout configuration (dim, screen-off, lock, suspend)
- Brightness dim level sliders
- Inhibitor apps list management
- Debug status display

### 3. Bin/idle-management/check-inhibitors.sh (~40 lines)
**Purpose**: Helper script for checking running apps
**Function**: Uses `pgrep -x` to check if inhibitor apps are running

---

## Files Modified (4 existing files)

### 1. Commons/Settings.qml
**Line 17**: Changed `settingsVersion: 21` → `settingsVersion: 22`

**After line 441** (after battery section): Added new settings object:
```qml
// idle management
property JsonObject idleManagement: JsonObject {
  property bool enabled: false
  property int debounceSeconds: 5
  property list<string> inhibitApps: []

  property JsonObject acMode: JsonObject {
    property int dimTimeout: 0
    property int dimBrightness: 30
    property int screenOffTimeout: 0
    property int lockTimeout: 300
    property int suspendTimeout: 0
  }

  property JsonObject batteryMode: JsonObject {
    property int dimTimeout: 120
    property int dimBrightness: 20
    property int screenOffTimeout: 180
    property int lockTimeout: 240
    property int suspendTimeout: 600
  }

  property string lidCloseAction: "none"
  property string lidOpenAction: "none"
}
```

### 2. shell.qml
**Line 82** (after PowerProfileService.init()): Added service initialization:
```qml
IdleManagementService.init()
```

### 3. Modules/Panels/Settings/SettingsPanel.qml

**Line 54** (in Tab enum): Added `IdleManagement` entry:
```qml
enum Tab {
  About,
  Audio,
  Bar,
  ColorScheme,
  LockScreen,
  IdleManagement,  // <-- ADDED
  ControlCenter,
  ...
}
```

**Line 151-154**: Added component definition:
```qml
Component {
  id: idleManagementTab
  IdleManagementTab {}
}
```

**Line 193-197** (in updateTabsModel, after LockScreen entry): Added tab configuration:
```qml
}, {
  "id": SettingsPanel.Tab.IdleManagement,
  "label": "settings.idle-management.title",
  "icon": "hourglass-low",
  "source": idleManagementTab
}, {
```

### 4. Assets/Translations/en.json
**Line 1329** (after "lock-screen" section): Added complete translation structure:
```json
"idle-management": {
  "ac-mode": {
    "description": "Configure idle timeouts when connected to AC power.",
    "label": "AC Power Mode"
  },
  "advanced": {
    "description": "Additional idle management settings.",
    "label": "Advanced Settings"
  },
  "battery-mode": {
    "description": "Configure idle timeouts when running on battery power.",
    "label": "Battery Power Mode"
  },
  "debounce": {
    "description": "Wait this many seconds after waking before allowing suspend. Prevents immediate suspend if you briefly wake your screen then walk away.",
    "label": "Suspend debounce duration"
  },
  "dim-brightness": {
    "label": "Dimmed brightness level"
  },
  "dim-timeout": {
    "description": "Dim screen brightness after this many minutes of inactivity.",
    "label": "Dim screen timeout"
  },
  "enabled": {
    "description": "Enable automatic idle detection and power management.",
    "label": "Enable idle management"
  },
  "inhibitor-apps": {
    "add": "Add app to inhibitor list",
    "description": "Prevent idle actions while these apps are running (enter process names, e.g., 'vlc', 'firefox').",
    "hint": "Tip: Use exact process names as shown in 'ps' or 'htop'. Idle actions will be blocked while any of these apps are running.",
    "label": "Inhibitor apps",
    "placeholder": "e.g., vlc, mpv, steam",
    "remove": "Remove app from inhibitor list"
  },
  "lock-timeout": {
    "description": "Lock the screen after this many minutes of inactivity.",
    "label": "Lock screen timeout"
  },
  "screen-off-timeout": {
    "description": "Turn off displays (DPMS) after this many minutes of inactivity.",
    "label": "Screen off timeout"
  },
  "section": {
    "description": "Configure automatic screen dimming, locking, and suspend based on idle time.",
    "label": "Idle Management"
  },
  "suspend-timeout": {
    "description": "Suspend the system after this many minutes of inactivity.",
    "label": "Suspend timeout"
  },
  "title": "Idle Management",
  "zero-disables": "(0 = disabled)"
}
```

---

## Dependencies

**Quickshell Components**:
- `Quickshell.Wayland.IdleMonitor` - Wayland idle detection (ext-idle-notify-v1 protocol)
- `Quickshell.Services.UPower` - AC/Battery detection

**Existing Services**:
- `BrightnessService` - For dimming brightness
- `CompositorService` - For compositor detection and suspend
- `PanelService` - For lock screen activation
- `Settings` - For configuration persistence

**External Tools** (optional):
- `pgrep` - For inhibitor app detection (standard on most Linux systems)

---

## Translation Keys Added

All keys under `settings.idle-management.*`:
- title, section.label, section.description
- enabled.label, enabled.description
- ac-mode.label, ac-mode.description
- battery-mode.label, battery-mode.description
- dim-timeout.label, dim-timeout.description
- dim-brightness.label
- screen-off-timeout.label, screen-off-timeout.description
- lock-timeout.label, lock-timeout.description
- suspend-timeout.label, suspend-timeout.description
- debounce.label, debounce.description
- advanced.label, advanced.description
- inhibitor-apps.* (label, description, placeholder, hint, add, remove)
- zero-disables

**Total**: 29 translation entries added to en.json

---

## Testing

### Basic Testing
1. **Enable the feature**: Settings → Idle Management → Enable
2. **Test AC mode**: Set low timeouts (1-2 min) and verify each action triggers
3. **Test Battery mode**: Disconnect AC and verify different timeouts apply
4. **Test inhibitor apps**: Add "firefox" to list, open Firefox, verify actions blocked
5. **Test debounce**: Wake screen, wait less than debounce time, verify no immediate suspend
6. **Test DPMS**: Verify displays turn off/on (compositor-specific)

### Verification Commands
```bash
# Check service loaded
qs -p . 2>&1 | grep IdleManagement

# Monitor idle state (enable debug)
env NOCTALIA_DEBUG=1 qs -p . 2>&1 | grep -E "IdleManagement|idle"

# Test inhibitor script
bash Bin/idle-management/check-inhibitors.sh "firefox,chrome"
echo $?  # 0 = app running, 1 = no apps running
```

### Expected Behavior
- **Disabled by default**: No idle actions until user enables
- **AC vs Battery**: Different timeouts based on power source
- **Cascading timeouts**: Dim → Screen Off → Lock → Suspend (if all enabled)
- **Independent timeouts**: Each can be disabled with 0
- **Inhibitors block all**: When inhibitor app runs, all idle actions blocked
- **Debounce works**: Brief wake-ups don't trigger immediate suspend

---

## Potential Merge Conflicts

### High Risk:
1. **Commons/Settings.qml** - Settings version number conflicts (line 17)
   - **Resolution**: Use highest version number, merge settings objects
   - **Command**: Check upstream version, set to max(upstream, 22)

2. **Commons/Settings.qml** - New settings sections (line 443+)
   - **Resolution**: Add idleManagement section after any new sections added upstream
   - **Strategy**: Keep alphabetical order if upstream changes ordering

3. **Assets/Translations/en.json** - Translation additions (line 1329)
   - **Resolution**: Add idle-management block after lock-screen (alphabetical)
   - **Note**: Verify JSON syntax after merge

### Medium Risk:
4. **shell.qml** - Service initialization order (line 82)
   - **Resolution**: Keep IdleManagementService.init() after PowerProfileService.init()
   - **Why**: Needs UPower/power services to be ready

5. **Modules/Panels/Settings/SettingsPanel.qml** - Tab enum (line 54)
   - **Resolution**: Add IdleManagement to enum, renumber if needed
   - **Note**: Enum order doesn't matter, but keep consistent

### Low Risk:
6. **Modules/Panels/Settings/SettingsPanel.qml** - Component/tab registration
   - **Resolution**: Add idleManagementTab component and updateTabsModel entry
   - **Location**: After lockScreenTab component

---

## Cherry-Pick Strategy

**Recommended approach**:

### Step 1: Prepare
```bash
# Fetch latest upstream
git fetch upstream

# Create new branch from upstream/main
git checkout -b idle-management-rebased upstream/main
```

### Step 2: Cherry-pick in order
```bash
# 1. Settings schema (foundation)
git cherry-pick <commit-with-Settings.qml>

# 2. Translations (UI strings)
git cherry-pick <commit-with-en.json>

# 3. New files (no conflicts expected)
git cherry-pick <commit-with-new-files>

# 4. Service initialization
git cherry-pick <commit-with-shell.qml>

# 5. Panel registration
git cherry-pick <commit-with-SettingsPanel.qml>
```

### Step 3: Resolve conflicts
- **Settings version**: Use latest + 1
- **Service init order**: Keep after PowerProfileService
- **Tab enum**: Add IdleManagement, adjust numbering if needed

### Step 4: Test after merge
```bash
# Verify shell loads
timeout 10 qs -p . 2>&1 | grep -E "(ERROR|IdleManagement)"

# Check translations load
timeout 10 qs -p . 2>&1 | grep "I18n.*Loaded translations"

# Validate settings
timeout 10 qs -p . 2>&1 | grep "Settings loaded"
```

---

## Squash Commit Message Template

```
feat: Add Idle Management service with AC/Battery modes

Implements automatic idle detection and power management using Wayland's
ext-idle-notify-v1 protocol via Quickshell's IdleMonitor component.

Features:
- Separate AC and Battery power mode configurations
- 4 independent timeout actions: dim, screen-off, lock, suspend
- Inhibitor apps to block idle actions while specific apps run
- Debounce protection to prevent immediate suspend after wake
- Compositor-agnostic DPMS control (Hyprland/Sway/Niri)

New files:
- Services/Power/IdleManagementService.qml
- Modules/Panels/Settings/Tabs/IdleManagementTab.qml
- Bin/idle-management/check-inhibitors.sh

Modified files:
- Commons/Settings.qml (settings v22, idleManagement section)
- shell.qml (service initialization)
- Modules/Panels/Settings/SettingsPanel.qml (tab registration)
- Assets/Translations/en.json (29 translation keys)

Disabled by default. Users enable via Settings → Idle Management.
```

---

## Notes

- Feature is **disabled by default** (Settings.data.idleManagement.enabled = false)
- No behavior changes unless user explicitly enables
- Uses native Wayland protocols (compositor-agnostic)
- Minimal upstream conflict surface (mostly new files)
- All timeouts can be individually disabled (0 = off)
- Respects existing IdleInhibitorService (via IdleMonitor.respectInhibitors)

---

## Maintenance

**When rebasing**:
1. ✅ Check this document for complete file list
2. ✅ Verify IdleMonitor API hasn't changed in Quickshell
3. ✅ Check UPower integration still works
4. ✅ Verify compositor commands (DPMS) for new compositors
5. ✅ Update translation files for new languages (de, es, fr, pt, tr, uk-UA, zh-CN)
6. ✅ Test on all supported compositors (Niri, Hyprland, Sway)

**Known working with**:
- Quickshell: Latest (as of 2025-11-09)
- Noctalia upstream commit: 7c168b3d (autoformatting)
- Compositors tested: Niri

---

## Migration Path for Users

Users upgrading from Noctalia without idle management:

1. Settings will auto-migrate to v22 on first run
2. Feature disabled by default (no behavior change)
3. User manually enables in Settings → Idle Management
4. Configure AC/Battery timeouts as desired
5. Optionally add inhibitor apps (vlc, mpv, steam, etc.)

**No breaking changes** - fully backward compatible.
