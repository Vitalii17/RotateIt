import QtQuick 1.1
import com.nokia.symbian 1.1

Page {
    id: root
    orientationLock: PageOrientation.Automatic

    Component.onCompleted: console.log("AboutPage: completed")
    Component.onDestruction: console.log("AboutPage: destruction")

    signal back

    tools: ToolBarLayout {
        id: startPageToolBarLayout
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: {
                back()
                root.destroy()
            }
        }
        ToolButton {
            iconSource: "toolbar-menu"
            onClicked: aboutPageMenu.open()
        }
    }

    Menu {
        id: aboutPageMenu
        MenuLayout {
            MenuItem {
                text: qsTr("Exit")
                onClicked: Qt.quit()
            }
        }
    }
}
