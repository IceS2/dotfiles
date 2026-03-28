import QtQuick
import ".." as Root

Rectangle {
    color: "transparent"

    Behavior on color {
        Root.CAnim {}
    }
}
