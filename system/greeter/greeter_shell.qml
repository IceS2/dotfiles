import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd
import "./shim"

ShellRoot {
    id: shellRoot

    // ── Configuration (populated from greeter.conf) ──
    property string activeTheme: ""
    property string defaultUser: ""
    property string sessionDirs: ""
    property string themePath: "/etc/greetd/themes/themes/" + activeTheme

    // ── SDDM globals (exposed as root properties for themes) ──
    readonly property var sddm: greetdShim.sddm
    readonly property var config: greetdShim.config
    readonly property var userModel: greetdShim.userModel
    readonly property var sessionModel: greetdShim.sessionModel

    // ── Shim instance ──
    GreetdShim {
        id: greetdShim
        themePath: shellRoot.themePath
        defaultUser: shellRoot.defaultUser
        sessionDirs: shellRoot.sessionDirs
    }

    // ── Greetd lifecycle ──
    Connections {
        target: Greetd

        function onReadyToLaunch() {
            var idx = greetdShim.selectedSessionIndex;
            var session = greetdShim.sessionModel.get(idx);
            var cmd = session ? session.exec : "start-hyprland";
            Greetd.launch(cmd.split(" "));
        }

        function onLaunched() {
            Qt.quit();
        }

        function onError(error) {
            console.error("Greetd error:", error);
        }
    }

    // ── Theme component (loaded into primary monitor) ──
    Component {
        id: themeComponent
        Loader {
            anchors.fill: parent
            source: shellRoot.activeTheme !== ""
                ? "file://" + shellRoot.themePath + "/Main.qml"
                : ""
            onLoaded: {
                item.forceActiveFocus();
            }
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error("Failed to load theme:", source);
                }
            }
        }
    }

    // ── Multi-monitor: theme on primary (DP-2), black on secondary ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            property bool isPrimary: modelData.name === "DP-2"

            screen: modelData
            visible: true
            color: "black"

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: isPrimary
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            Loader {
                anchors.fill: parent
                active: isPrimary
                sourceComponent: themeComponent
            }
        }
    }

    // ── Config loader (FileView reads greeter.conf) ──
    property FileView _configFile: FileView {
        path: Qt.resolvedUrl("file:///etc/greetd/greeter.conf")
        onTextChanged: {
            var t = _configFile.text();
            if (!t || t.length === 0) return;
            var lines = t.split("\n");
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.startsWith("[") || line === "" || line.startsWith("#")) continue;
                var eqIdx = line.indexOf("=");
                if (eqIdx <= 0) continue;
                var key = line.substring(0, eqIdx).trim();
                var val = line.substring(eqIdx + 1).trim();
                if (key === "theme") shellRoot.activeTheme = val;
                else if (key === "default_user") shellRoot.defaultUser = val;
                else if (key === "session_dirs") shellRoot.sessionDirs = val;
            }
            // Fallbacks
            if (shellRoot.activeTheme === "") shellRoot.activeTheme = "pixel-rainyroom";
            if (shellRoot.defaultUser === "") shellRoot.defaultUser = "user";
            if (shellRoot.sessionDirs === "") shellRoot.sessionDirs = "/usr/share/wayland-sessions:/usr/share/xsessions";
            console.log("Configuration Loaded");
        }
    }
}
