.pragma library

/**
 * Shared utility functions for QuickShell services.
 *
 * Usage in a singleton:
 *   import "utils.js" as Utils
 *   function findFocusedScreen() { return Utils.findFocusedScreen(Hyprland, Quickshell, fallback) }
 */

/**
 * Find the QS screen object that matches Hyprland's currently focused monitor.
 * @param {object} Hyprland  - Quickshell.Hyprland module
 * @param {object} Quickshell - Quickshell root module
 * @param {object} fallback  - screen to return when nothing matches
 * @returns {object} matching screen or fallback
 */
function findFocusedScreen(Hyprland, Quickshell, fallback) {
    var focusedMon = Hyprland.focusedMonitor;
    if (!focusedMon) return fallback;

    var screens = Quickshell.screens;
    for (var i = 0; i < screens.length; i++) {
        var mon = Hyprland.monitorFor(screens[i]);
        if (mon && mon.name === focusedMon.name) return screens[i];
    }
    return fallback;
}

function popupAnchorForPoint(Quickshell, globalPoint, fallback) {
    var screens = Quickshell.screens;
    for (var i = 0; i < screens.length; i++) {
        var screen = screens[i];
        if (globalPoint.x >= screen.x && globalPoint.x < screen.x + screen.width
                && globalPoint.y >= screen.y && globalPoint.y < screen.y + screen.height) {
            return { screen: screen, x: globalPoint.x - screen.x };
        }
    }

    return {
        screen: fallback,
        x: fallback ? globalPoint.x - fallback.x : globalPoint.x
    };
}

/**
 * List navigation helpers for services with currentIndex + filteredList pattern.
 * Each returns the new index, or -1 if no change occurred.
 */
function listNext(currentIndex, length) {
    return currentIndex < length - 1 ? currentIndex + 1 : -1;
}

function listPrev(currentIndex) {
    return currentIndex > 0 ? currentIndex - 1 : -1;
}

function listPageDown(currentIndex, length) {
    var target = Math.min(currentIndex + 10, length - 1);
    return target !== currentIndex ? target : -1;
}

function listPageUp(currentIndex) {
    var target = Math.max(currentIndex - 10, 0);
    return target !== currentIndex ? target : -1;
}
