pragma Singleton
import QtQuick
import "modals.js" as Modals

QtObject {
    property bool popupVisible: false

    function showPopup() {
        Modals.closeOthers("overview")
        popupVisible = true;
    }

    function hidePopup() {
        popupVisible = false;
    }

    function togglePopup() {
        if (popupVisible) hidePopup();
        else showPopup();
    }

    Component.onCompleted: {
        var self = this
        Modals.register("overview", function() { return self.popupVisible }, function() { self.hidePopup() })
    }
}
