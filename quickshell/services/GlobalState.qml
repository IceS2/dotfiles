pragma Singleton
import QtQuick

QtObject {
    // Bar configuration (set by bar on creation)
    property string barEdge: "top"
    property int barContentSize: 0

    // Bar runtime visibility per screen (keyed by screen name)
    property var barVisible: ({})

    function setBarVisible(screenName: string, visible: bool): void {
        barVisible = Object.assign({}, barVisible, { [screenName]: visible })
    }
}
