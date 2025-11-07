# Noctalia Shell

**A beautiful, minimal desktop shell for Wayland that actually gets out of your way.**

Noctalia is a desktop shell built on Quickshell (Qt/QML framework) with a warm lavender aesthetic. It provides a complete desktop environment experience with panels, dock, notifications, lock screen, and extensive customization options.

## AI Guidance

* After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. Use your thinking to plan and iterate based on this new information, and then take the best next action.
* For maximum efficiency, whenever you need to perform multiple independent operations, invoke all relevant tools simultaneously rather than sequentially.
* Before you finish, please verify your solution
* Do what has been asked; nothing more, nothing less.
* NEVER create files unless they're absolutely necessary for achieving your goal.
* ALWAYS prefer editing an existing file to creating a new one.
* NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## Project Overview

- **Primary Language**: QML (Qt Quick)
- **Framework**: Quickshell (Wayland-native shell framework)
- **Supported Compositors**: Niri, Hyprland, Sway (with support for other Wayland compositors)
- **License**: MIT
- **Design Philosophy**: "quiet by design" - minimal, non-intrusive UI

## Architecture

### Core Entry Point
- [shell.qml](shell.qml) - Main shell root that orchestrates all components
  - Initializes services in a specific order
  - Manages screen-specific instances of bars and panels
  - Uses lazy loading with QML Loaders for memory optimization
  - Implements MainScreen for each screen to manage bar + panels

### Directory Structure

#### `/Modules/` - UI Components
Core visual modules and panels:
- **Bar/** - Top/bottom bar with multiple widgets
  - Bar.qml - Main bar component
  - Widgets/ - Bar widget components
  - Extras/ - Additional bar functionality
- **Panels/** - Overlay panels (13 panel types)
  - Audio/ - Audio device panel
  - Battery/ - Battery status panel
  - Bluetooth/ - Bluetooth device panel
  - Calendar/ - Calendar panel
  - ControlCenter/ - Quick settings panel
  - Launcher/ - Application launcher/search
  - NotificationHistory/ - Notification history panel
  - SessionMenu/ - Power menu (logout, shutdown, etc.)
  - Settings/ - Shell configuration UI
  - SetupWizard/ - First-run setup experience
  - Tray/ - System tray panel
  - Wallpaper/ - Wallpaper management panel
  - WiFi/ - WiFi network panel
- **Background/** - Background/wallpaper rendering
- **Dock/** - Application dock/launcher
- **LockScreen/** - Screen locking functionality
- **MainScreen/** - Main screen window management
- **Notification/** - Notification system
- **OSD/** - On-screen display for volume, brightness, etc.
- **Toast/** - Toast notifications
- **Tooltip/** - Tooltip system

#### `/Services/` - Business Logic
Core services that power the shell (40+ services):

**System Integration:**
- `CompositorService.qml` - Compositor-agnostic API
- `HyprlandService.qml` - Hyprland-specific integration
- `NiriService.qml` - Niri-specific integration
- `SwayService.qml` - Sway-specific integration
- `IPCService.qml` - Inter-process communication

**Hardware & System:**
- `AudioService.qml` - Audio control and monitoring
- `BatteryService.qml` - Battery status and management
- `BluetoothService.qml` - Bluetooth device management
- `BrightnessService.qml` - Screen brightness control
- `NetworkService.qml` - Network connection management
- `PowerProfileService.qml` - Power profile management
- `SystemStatService.qml` - System resource monitoring

**UI & Theming:**
- `AppThemeService.qml` - Application theming engine
- `ColorSchemeService.qml` - Color scheme management
- `DarkModeService.qml` - Dark/light mode switching
- `FontService.qml` - Font management
- `WallpaperService.qml` - Wallpaper handling (with Matugen integration)
- `MatugenTemplates.qml` - Material You color generation templates
- `NightLightService.qml` - Blue light filter

**Features:**
- `NotificationService.qml` - Notification daemon
- `MediaService.qml` - Media player control (MPRIS)
- `CalendarService.qml` - Calendar integration
- `ClipboardService.qml` - Clipboard management
- `LocationService.qml` - Geolocation for weather, etc.
- `ScreenRecorderService.qml` - Screen recording functionality
- `IdleInhibitorService.qml` - Prevent screen idle/sleep
- `KeyboardLayoutService.qml` - Keyboard layout switching
- `LockKeysService.qml` - Caps/Num lock status

**Infrastructure:**
- `BarService.qml` - Bar visibility and state management
- `BarWidgetRegistry.qml` - Registry for bar widgets
- `ControlCenterWidgetRegistry.qml` - Registry for control center widgets
- `PanelService.qml` - Panel state management
- `ToastService.qml` - Toast notification service
- `TooltipService.qml` - Tooltip service
- `HooksService.qml` - Custom hook execution
- `ProgramCheckerService.qml` - Check for installed programs
- `DistroService.qml` - Linux distribution detection
- `GitHubService.qml` - GitHub API integration
- `UpdateService.qml` - Update checking
- `CavaService.qml` - Audio visualization (Cava integration)

#### `/Commons/` - Shared Utilities
Common components used throughout the shell:
- `Settings.qml` - Centralized settings management
- `I18n.qml` - Internationalization/translations
- `Color.qml` - Color utilities and helpers
- `Icons.qml` - Icon management
- `TablerIcons.qml` - Tabler icon set (207KB icon definitions)
- `ThemeIcons.qml` - Theme-specific icons
- `Logger.qml` - Logging utility
- `Style.qml` - Shared styling definitions
- `Time.qml` - Time utilities
- `KeyboardLayout.qml` - Keyboard layout definitions

#### `/Widgets/` - Reusable UI Components
40+ custom QML widgets with the "N" prefix (Noctalia):
- **Layout**: NBox, NPanel, NScrollView, NListView, NDivider
- **Input**: NButton, NIconButton, NIconButtonHot, NTextInput, NSlider, NSpinBox, NToggle, NCheckbox, NRadioButton, NComboBox, NSearchableComboBox
- **Display**: NLabel, NText, NIcon, NHeader, NImageCached, NImageCircled, NImageRounded
- **Dialogs**: NColorPickerDialog, NFilePicker
- **Special**: NContextMenu, NColorPicker, NIconPicker, NCircleStat, NCollapsible, NSectionEditor, NReorderCheckboxes, NDateTimeTokens, NBusyIndicator, NShapedRectangle
- **System**: NFullScreenWindow, BarExclusionZone

#### `/Helpers/` - JavaScript Utilities
Helper JavaScript modules:
- `AdvancedMath.js` - Advanced mathematical functions
- `ColorsConvert.js` - Color conversion utilities
- `FuzzySort.js` - Fuzzy search implementation
- `QtObj2JS.js` - Qt object to JavaScript conversion
- `sha256.js` - SHA-256 hashing
- `Debug.js` - Debug utilities

#### `/Assets/` - Resources
- Screenshots, icons, logos, themes
- Default wallpapers
- Theme resources

#### `/Shaders/` - Graphics Shaders
Custom shader effects for visual polish

#### `/Bin/` - Executable Scripts
Helper scripts and utilities

## Key Features

### 1. Multi-Monitor Support
- Per-monitor bar configuration (TODO)
- Screen-specific panel instances
- Exclusion zones for proper compositor integration

### 2. Theming System
- Material You color generation (Matugen integration)
- Dark/light mode support
- Customizable color schemes
- Font customization
- Per-app theming capabilities

### 3. Compositor Integration
- Native support for Niri, Hyprland, Sway
- Compositor-agnostic service layer
- Workspace management
- Window control

### 4. Panel System
Advanced panel management via MainScreen (13 panel types):
- Audio panel
- Battery panel
- Bluetooth panel
- Calendar panel
- Control Center panel
- Launcher panel
- Notification history panel
- Session menu panel
- Settings panel
- Setup wizard panel
- Tray panel
- Wallpaper panel
- WiFi panel

All panels use z-index layering and component-based loading.

### 5. Customization
- Setup wizard for first-time users
- Extensive settings interface
- Widget registry system for adding custom widgets
- Hook system for custom scripts
- Reorderable UI elements

### 6. Audio Features
- Multiple visualization types (Mirrored, Wave, Linear spectrum)
- MPRIS media player integration
- Audio device switching
- Volume OSD

### 7. Notifications
- Custom notification daemon
- Notification history
- Do Not Disturb mode
- Per-app notification settings

## Development Setup

```bash
# Run the shell (requires Quickshell to be installed)
qs -p .

# Run with verbose output for debugging
env NOCTALIA_DEBUG=1 qs -v -p .

# Code formatting and linting
qmlfmt -e -b 360 -t 2 -i 2 -w /path/to/file.qml    # Format a QML file (requires qmlfmt, do not use qmlformat)
qmllint **/*.qml         # Lint all QML files for syntax errors
```

### Nix/NixOS (Recommended)
```bash
# Enter development shell
nix develop

# Or use the legacy shell
nix-shell
```

The dev shell includes:
- Quickshell with required features
- Development utilities
- Required environment variables

### Package Structure
- Nix flake with NixOS and Home Manager modules
- Quickshell dependency (with X11 disabled, i3 enabled, hyprland enabled)
- App2unit integration for .desktop file management

## Configuration

Settings are managed through `Commons/Settings.qml`:
- Persistent configuration storage
- Settings versioning
- Migration handling
- Type-safe settings access

## Service Initialization Order

From [shell.qml:150-164](shell.qml#L150-L164):
1. WallpaperService
2. AppThemeService
3. ColorSchemeService
4. BarWidgetRegistry
5. LocationService
6. NightLightService
7. DarkModeService
8. FontService
9. HooksService
10. BluetoothService
11. BatteryService
12. IdleInhibitorService
13. PowerProfileService
14. DistroService

This order is critical - services depend on previously initialized services.

## Component Lifecycle

1. **Shell Root Initialization**
   - Wait for I18n to load translations
   - Wait for Settings to load configuration

2. **Service Initialization**
   - Services initialize in dependency order
   - Each service may depend on Settings, I18n, or other services

3. **Screen Components**
   - MainScreen created per screen
   - Bar and panel components loaded lazily
   - Exclusion zones created after window loads

4. **Background Components**
   - Background/wallpaper
   - Overview (workspace overview)
   - Screen corners
   - Dock
   - Notifications
   - Lock screen
   - Toast overlay
   - OSD

## Special Patterns

### Lazy Loading
Components use QML Loaders extensively:
- `active` property controls when components load
- `asynchronous` for non-blocking loads
- Memory optimization for unused screens/panels

### Panel Management
MainScreen pattern:
- Single fullscreen window per screen
- Manages bar + all overlay panels
- Z-index based layering (panels at z-index 50)
- Component-based architecture for panels

### Registry Pattern
BarWidgetRegistry and ControlCenterWidgetRegistry:
- Centralized widget registration
- Dynamic widget loading
- Easy extension point for custom widgets

## Git Hooks
Uses `lefthook` for git hooks (see lefthook.yml)

## Community Resources
- Documentation: https://docs.noctalia.dev
- Discord: https://discord.noctalia.dev
- GitHub: https://github.com/noctalia-dev/noctalia-shell

## Contributing
See [development guidelines](https://docs.noctalia.dev/development/guideline)

## Notes for AI Assistants

### Code Style
- QML component names use PascalCase
- Service names end with "Service.qml"
- Widget names start with "N" prefix (e.g., NButton, NPanel)
- JavaScript helpers in Helpers/ directory

### Common Tasks
1. **Adding a new bar widget**: Register in BarWidgetRegistry
2. **Adding a control center widget**: Register in ControlCenterWidgetRegistry
3. **Creating a service**: Follow the Service pattern, add to init order if needed
4. **Modifying theming**: Check AppThemeService and ColorSchemeService
5. **Panel work**: Edit in Modules/Panels/, ensure proper z-index in shell.qml

### Important Files to Check
- Settings schema: `Commons/Settings.qml`
- Service initialization: `shell.qml` (Component.onCompleted)
- Panel registration: `shell.qml` (panelComponents array)
- Theme system: `Services/AppThemeService.qml`
- Color generation: `Services/MatugenTemplates.qml`

### Testing
- Test on target compositors: Niri, Hyprland, Sway
- Check multi-monitor scenarios
- Verify lazy loading doesn't break functionality
- Test settings persistence across restarts

### Debugging
- Use `Logger.qml` for logging (Logger.i, Logger.d, Logger.w, Logger.e)
- Check console output for service initialization messages
- Verify service initialization order if adding dependencies

---

## Fork Integration History

### v3.0 Upstream Integration (2025-11-07)

Successfully integrated fork-specific changes with upstream noctalia-shell v3.0 release.

**Integration Method**: Interactive rebase of 96 commits onto upstream/main (commit f8cffcd3)

**Major Architectural Changes from Upstream**:
- Deleted `NFullScreenWindow` and `NPanel` base classes
- Introduced `MainScreen` component for unified bar + panel management
- Reorganized panel structure: `Modules/Settings/` → `Modules/Panels/Settings/`
- Enhanced theming system with new template support

**Fork-Specific Features Preserved**:
1. **Fuzzel Theming** - Matugen template integration for Fuzzel launcher
2. **Niri Switcher** - Niri compositor workspace switcher support
3. **Power Management** - Enhanced battery and power profile management
4. **AppMenu Integration** - Application menu features
5. **Spotlight Features** - Search and launcher improvements
6. **Walker Terminal Theming** - Walker terminal theme integration with font config sync
7. **Niriswitcher Theming** - Dynamic theming for niriswitcher with CSS generation
8. **Audio Panel** - New audio device panel with right-click integration
9. **AudioVisualizer** - Bar widget for audio visualization with Cava integration
10. **Dock Enhancements** - Multi-display support and setup wizard integration
11. **Recursive Wallpaper Search** - Option to search wallpapers recursively
12. **Notification Transparency** - Configurable notification background opacity
13. **Brightness Controls** - Minimum brightness enforcement and improved hybrid GPU support

**Conflict Resolution Strategy**:
- Accepted upstream's architectural improvements (MainScreen, panel reorganization)
- Kept fork's feature additions where they didn't conflict with upstream changes
- Used upstream's version when both branches fixed the same issue (e.g., overview wallpaper blur)
- Merged settings files to preserve both upstream and fork configuration options

**Key Decisions**:
- **Dropped commit 59be275a**: Fork's overview wallpaper fix was superseded by upstream's better implementation
- **Dropped commit 6f9eef9c**: Vicinae AppImage detection improvement already in upstream
- **Skipped commit b767441f**: Minimum brightness toggle already existed in upstream
- **Skipped commit 19cd1a8c**: Notification history delete functionality already in upstream

**Files with Significant Merges**:
- `Assets/settings-default.json` - Combined template settings (walker, code, niriswitcher)
- `Services/ColorSchemeService.qml` - Used upstream's generic `hasEnabledTemplates()` over fork's hardcoded list
- `Services/ProgramCheckerService.qml` - Merged program availability checks (vicinae AppImage, walker, code, niriswitcher, xdotool)
- `Bin/colors-apply.sh` - Integrated enhanced Walker and Fuzzel theming scripts
- `Commons/Settings.qml` - Merged new settings while avoiding duplicate sections

**Testing Required**:
1. Verify shell startup with `qs -p .`
2. Test all fork-specific features (Fuzzel theming, Walker integration, Niri switcher, audio panel)
3. Validate multi-display dock behavior
4. Check recursive wallpaper search functionality
5. Test notification transparency slider
6. Verify brightness controls with hybrid GPUs

**Branch Structure**:
- `main` - Original fork state (backup)
- `pre-v3-integration` - Pre-integration backup
- `fork-working-copy` - Successfully rebased branch (current)
- Remote `upstream/main` - Upstream v3.0 base (commit f8cffcd3)
