pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    readonly property string _configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")

    // --- File-based color loading ---
    property FileView _colorsFile: FileView {
        path: Qt.resolvedUrl("file://" + theme._configHome + "/theme/colors.json")
        watchChanges: true
        onTextChanged: {
            var t = _colorsFile.text();
            if (t && t.length > 0) {
                try {
                    _colors = JSON.parse(t);
                } catch (e) {
                    console.warn("Theme: failed to parse colors.json:", e);
                }
            }
        }
    }

    property var _colors: null
    property var _previewColors: null
    property bool showPreview: false
    property var _savedColors: null

    // Active color source — QML tracks this property dependency, so all
    // color bindings re-evaluate when preview/colors change.
    // (QML doesn't track reads inside JS function calls like _c(), but
    // it does track property-to-property bindings.)
    property var _ac: showPreview && _previewColors ? _previewColors : (_colors || {})

    // Preview API for WallpaperPicker
    function setPreviewColors(obj) {
        _previewColors = obj;
        showPreview = true;
    }
    function clearPreview() {
        _previewColors = null;
        showPreview = false;
    }

    // Save/restore for wallpaper picker revert
    function saveState() {
        _savedColors = _colors ? JSON.parse(JSON.stringify(_colors)) : null;
    }

    // Promote preview colors to permanent (no visual flash)
    function commitPreview() {
        if (_previewColors) {
            _colors = _previewColors;
        }
        clearPreview();
        _savedColors = null;
    }

    // Revert to saved colors
    function cancelPreview() {
        clearPreview();
        if (_savedColors) {
            _colors = _savedColors;
            _savedColors = null;
        }
    }

    // Force re-read colors.json from disk (for IPC/external reload)
    function reloadColors() {
        _reloadProcess.running = true;
    }

    property var _reloadLines: []
    property Process _reloadProcess: Process {
        command: ["cat", theme._configHome + "/theme/colors.json"]
        stdout: SplitParser {
            onRead: data => {
                theme._reloadLines.push(data);
            }
        }
        onRunningChanged: {
            if (running) theme._reloadLines = [];
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && theme._reloadLines.length > 0) {
                try {
                    var json = theme._reloadLines.join("\n");
                    theme._colors = JSON.parse(json);
                } catch (e) {
                    console.warn("Theme: failed to reload colors:", e);
                }
            }
        }
    }

    // ── Material You Color Roles ──────────────────────────────────
    // Primary
    property color primary: _ac.primary || "#cba6f7"
    property color primaryContainer: _ac.primary_container || "#45475a"

    // Secondary
    property color secondary: _ac.secondary || "#b4befe"
    property color secondaryContainer: _ac.secondary_container || "#313244"

    // Tertiary
    property color tertiary: _ac.tertiary || "#f5c2e7"
    property color tertiaryContainer: _ac.tertiary_container || "#313244"

    // Error
    property color error: _ac.error || "#f38ba8"
    property color errorContainer: _ac.error_container || "#eba0ac"

    // Surface
    property color surface: _ac.surface || "#1e1e2e"
    property color surfaceVariant: _ac.surface_variant || "#313244"
    property color surfaceDim: _ac.surface_dim || "#181825"
    property color surfaceBright: _ac.surface_bright || "#585b70"
    property color surfaceContainerLowest: _ac.surface_container_lowest || "#11111b"
    property color surfaceContainerLow: _ac.surface_container_low || "#181825"
    property color surfaceContainer: _ac.surface_container || "#313244"
    property color surfaceContainerHigh: _ac.surface_container_high || "#45475a"
    property color surfaceContainerHighest: _ac.surface_container_highest || "#585b70"

    // Outline
    property color outline: _ac.outline || "#6c7086"
    property color outlineVariant: _ac.outline_variant || "#45475a"

    // Inverse
    property color inverseSurface: _ac.inverse_surface || "#cdd6f4"
    property color inverseOnSurface: _ac.inverse_on_surface || "#1e1e2e"
    property color inversePrimary: _ac.inverse_primary || "#7c5fad"

    // Scrim & Shadow
    property color scrim: "#59000000"
    property color shadow: "#000000"

    // Semantic extensions (not in Material You spec)
    property color success: _ac.success || "#a6e3a1"
    property color warning: _ac.warning || "#f9e2af"
    property color caution: _ac.caution || "#fab387"

    // Palette accents (full Catppuccin Mocha — used for widget icons, hover tint, active borders)
    property color rosewater: _ac.rosewater || "#f5e0dc"
    property color flamingo: _ac.flamingo || "#f2cdcd"
    property color maroon: _ac.maroon || "#eba0ac"
    property color peach: _ac.peach || "#fab387"
    property color yellow: _ac.yellow || "#f9e2af"
    property color teal: _ac.teal || "#94e2d5"
    property color sky: _ac.sky || "#89dceb"
    property color sapphire: _ac.sapphire || "#74c7ec"
    property color blue: _ac.blue || "#89b4fa"
    property color lavender: _ac.lavender || "#b4befe"

    // ── "on*" foreground colors (nested to avoid QML naming conflict) ──
    // QML reserves property names matching "on" + uppercase (onSurface,
    // onPrimary, etc.) for signal handlers, silently ignoring bindings.
    // Nested under Theme.on.* to avoid the conflict:
    //   Root.Theme.on.surface, Root.Theme.on.surfaceVariant, etc.
    property QtObject on: QtObject {
        property color primary: theme._ac.on_primary || "#11111b"
        property color primaryContainer: theme._ac.on_primary_container || "#cdd6f4"
        property color secondary: theme._ac.on_secondary || "#11111b"
        property color secondaryContainer: theme._ac.on_secondary_container || "#cdd6f4"
        property color tertiary: theme._ac.on_tertiary || "#11111b"
        property color tertiaryContainer: theme._ac.on_tertiary_container || "#cdd6f4"
        property color error: theme._ac.on_error || "#11111b"
        property color errorContainer: theme._ac.on_error_container || "#11111b"
        property color surface: theme._ac.on_surface || "#cdd6f4"
        property color surfaceVariant: theme._ac.on_surface_variant || "#a6adc8"
        property color success: theme._ac.on_success || "#11111b"
        property color warning: theme._ac.on_warning || "#11111b"
        property color caution: theme._ac.on_caution || "#11111b"
    }

    // ── Derived Transparent Colors ────────────────────────────────
    property color surfaceGlass: Qt.rgba(surface.r, surface.g, surface.b, 0.3)
    property color surfaceDimGlass: Qt.rgba(surfaceDim.r, surfaceDim.g, surfaceDim.b, 0.55)

    // Typography
    readonly property string fontFamily: "Maple Mono NF"
    readonly property string fontFamilyMono: "Maple Mono NF"
    readonly property int fontWeight: Font.Medium
    readonly property int fontSizeTitle: 24
    readonly property int fontSizeLarge: 18
    readonly property int fontSizeNormal: 16
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeTiny: 9
    readonly property int iconFontSize: 18  // Icon-specific size for visual weight

    // Layout & Spacing
    readonly property int spacingTiny: 2
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 16
    readonly property int spacingXLarge: 24

    readonly property int paddingSmall: 8
    readonly property int paddingMedium: 12
    readonly property int paddingLarge: 24

    // Border & Radius
    readonly property int borderRadiusSmall: 6
    readonly property int borderRadiusMedium: 8
    readonly property int borderRadiusLarge: 12
    readonly property int borderWidthThin: 1
    readonly property int borderWidthNormal: 2
    readonly property int borderWidthThick: 3

    // Component Sizes
    readonly property int iconSizeSmall: 16
    readonly property int iconSizeNormal: 32
    readonly property int iconSizeLarge: 48

    readonly property int itemHeightSmall: 32
    readonly property int itemHeightNormal: 48
    readonly property int itemHeightLarge: 64

    readonly property int workspaceCellSize: 24

    readonly property int inputHeightNormal: 50

    // Window Sizes
    readonly property int barHeight: 32
    readonly property int barWidthVertical: 48
    readonly property int barTriggerSize: 4
    readonly property int launcherWidth: 800
    readonly property int launcherHeight: 600

    // Popup/Panel Widths
    readonly property int popupWidthSmall: 88
    readonly property int popupWidthMedium: 300          // CalendarPopup, BluetoothPopup, PerformancePopup, PopupPanel default
    readonly property int popupWidthWide: 340            // AudioPopup, NetworkPopup
    readonly property int popupWidthMenu: 250            // TrayMenu
    readonly property int notificationCenterWidth: 400   // NotificationCenter

    // Clipboard Modal
    readonly property int clipboardWidth: 900
    readonly property int clipboardHeight: 550
    readonly property int clipboardPreviewWidth: 350

    // Caption Font Size
    readonly property int fontSizeCaption: 10

    readonly property int notificationPopupWidth: 380
    readonly property int mediaPopupWidth: 350
    readonly property int mediaArtSize: 100
    readonly property int mediaTextMaxWidth: 400
    readonly property int trayIconSize: 36
    readonly property int calendarCellSize: 38
    readonly property int calendarHeaderHeight: 28
    readonly property int toastProgressWidth: 280

    // Bar Pills (rounded widget group containers)
    readonly property int pillRadius: 10
    readonly property int pillPaddingH: 10
    readonly property int pillPaddingV: 3
    readonly property int pillHeight: 26
    readonly property int pillGap: 8
    readonly property color pillBackground: Qt.rgba(surfaceContainer.r, surfaceContainer.g, surfaceContainer.b, 0.25)
    readonly property color pillBorder: Qt.rgba(outline.r, outline.g, outline.b, 0.12)

    // Hyprland sync (match values in hypr/configs/)
    readonly property int gapOuter: 16       // gaps_out in general.conf
    readonly property int windowRounding: 8  // rounding in decorations.conf

    // Border Frame (decorative screen border)
    readonly property int borderFrameThickness: 8
    readonly property int borderFrameRounding: 12  // inner corner radius

    // Animation Durations (milliseconds)
    readonly property int durationInstant: 50
    readonly property int durationFast: 100
    readonly property int durationNormal: 150
    readonly property int durationSlow: 300

    // MD3 Animation Durations
    readonly property int durationNormalMD3: 400
    readonly property int durationExpressiveDefaultSpatial: 500
    readonly property int durationExpressiveEffects: 200

    // Hover Effects
    readonly property real hoverScale: 1.03

    // MD3 Animation Curves (bezier control points for Easing.BezierSpline)
    readonly property list<real> curveStandard: [0.2, 0, 0, 1, 1, 1]
    readonly property list<real> curveStandardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property list<real> curveStandardDecel: [0, 0, 0, 1, 1, 1]
    readonly property list<real> curveEmphasized: [0.05, 0, 0.133, 0.06, 0.167, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
    readonly property list<real> curveEmphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property list<real> curveEmphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property list<real> curveExpressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property list<real> curveExpressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]

}
