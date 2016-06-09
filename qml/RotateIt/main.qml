import QtQuick 1.1
import com.nokia.symbian 1.1
import imagefetcher 1.0
import imageview 1.0
import engine 1.0

PageStackWindow {
    id: window
    showStatusBar: false
    showToolBar: false

    property string currentImagePath
    onCurrentImagePathChanged: {
        if(pageStack.currentPage !== mainPage) {
            pageStack.push(mainPage)
        }
    }

    StartPage {
        id: startPage
        onOpen: openMenu.open()
        onAbout: {
            var aboutPageObject = object.create("AboutPage.qml")
            pageStack.push(aboutPageObject)
            aboutPageObject.back.connect(pageStack.pop)
        }

        onBack: Qt.quit()
    }

    Page {
        id: mainPage
        orientationLock: PageOrientation.LockLandscape

        property int previewWidth: (width > height) ? width : height
        property int previewHeight: (height > width) ? width : height

        Connections {
            target: imageFetcher
            onFetchedChanged: {
                mainPage.orientationLock = imageFetcher.fetched ?
                            PageOrientation.LockLandscape :
                            PageOrientation.Automatic
            }
        }
        Connections {
            target: window
            onCurrentImagePathChanged: slider.reset()
        }

        ImageView {
            id: imageView
            anchors.fill: parent
            Connections {
                target: engine
                onPreviewImageChanged: {
//                    var startTime = new Date().getTime()
                    imageView.sourceImage = engine.previewImage
                    gc()
//                    var stopTime = new Date().getTime()
//                    console.log(stopTime - startTime)
                }
            }
        }

        Rectangle {
            id: horizontCursor
            color: "white"
            height: 2
            opacity: 0.4
            width: parent.width
            y: parent.height / 2
            function blink() { borderAnimation.start() }

            SequentialAnimation {
                id: borderAnimation
                PropertyAnimation {
                    target: horizontCursor
                    properties: "color"
                    to: "blue"
                }
                PropertyAnimation {
                    target: horizontCursor
                    property: "color"
                    to: "white"
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            drag.target: horizontCursor
            drag.axis: Drag.YAxis
            drag.minimumY: 0
            drag.maximumY: parent.height - horizontCursor.height
            onClicked: mainToolBar.shown = false
            onPressed: horizontCursor.blink()
        }

        CustomSlider {
            id: slider
            anchors.left: parent.left
            anchors.right: parent.right
            y: (parent.height / 3) * 2
            amplitude: 10
            onYChanged: reset()
            onPressed: mainToolBar.shown = false
            onValueChanged: engine.rotation = value
        }

        tools: ToolBarLayout {
            id: mainToolBarLayout
            ToolButton {
                iconSource: "toolbar-back"
                onClicked: Qt.quit()
            }
            ToolButton {
                iconSource: "qrc:///qml/RotateIt/images/open.png"
                onClicked: openMenu.open()
            }
            ToolButton {
                iconSource: "qrc:///qml/RotateIt/images/save.svg"
                onClicked: console.log("clicked 'save'")
            }
            ToolButton {
                iconSource: "toolbar-menu"
                onClicked: mainPageMenu.open()
            }
        }

        TopBar {
            id: mainTopBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            Connections {
                target: engine
                onStateChanged: {
                    if(engine.state === Engine.Processing) {
                        mainTopBar.text = qsTr("Processing")
                        mainTopBar.shown = true
                    }
                    else if(engine.state === Engine.Passive) {
                        mainTopBar.shown = false
                    }
                    else {
                        mainTopBar.shown = false
                    }
                }
            }
        }

        Menu {
            id: mainPageMenu
            MenuLayout {
                MenuItem {
                    text: qsTr("File")
                    platformSubItemIndicator: true
                    onClicked: fileMenu.open()
                }
                MenuItem {
                    text: qsTr("Settings")
                    onClicked: {}
                }
                MenuItem {
                    text: qsTr("About")
                    onClicked: {
                        var aboutPageObject = object.create("AboutPage.qml")
                        pageStack.push(aboutPageObject)
                        aboutPageObject.back.connect(pageStack.pop)
                    }
                }
            }
        }
        ContextMenu {
            id: fileMenu
            MenuLayout {
                MenuItem {
                    text: qsTr("Open")
                    platformSubItemIndicator: true
                    onClicked: openMenu.open()
                }
                MenuItem {
                    text: qsTr("Save")
                    onClicked: {}
                }
            }
        }
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
        Component.onCompleted: push(startPage)
    }

    CustomToolBar {
        id: mainToolBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        z: 1
        tools: pageStack.currentPage.tools
        //background: "qrc:///qml/RotateIt/images/toolbar-background.svg"
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: mainToolBar.height
        onPressed: mainToolBar.shown = true
    }

    ImageFetcher {
        id: imageFetcher
    }

    Engine {
        id: engine
        previewWidth: mainPage.previewWidth * 1.0
        previewHeight: mainPage.previewHeight * 1.0
        imagePath: window.currentImagePath
        onStateChanged: {

        }
    }

    ContextMenu {
        id: openMenu
        MenuLayout {
            MenuItem {
                text: qsTr("From Gallery")
                onClicked: currentImagePath = imageFetcher.fetchImage(ImageFetcher.Gallery)
            }
            MenuItem {
                text: qsTr("File Manager")
                onClicked: currentImagePath = imageFetcher.fetchImage(ImageFetcher.FileManager)
            }
        }
    }

    QtObject {
        id: object
        function create(obj) {
            return Qt.createComponent(obj).createObject(window)
        }
    }
}
