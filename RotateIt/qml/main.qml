import QtQuick 1.1
import com.nokia.symbian 1.1
import imagefetcher 1.0
import imageview 1.0
import engine 1.0
import "DynamicObject.js" as DynamicObject
import "UiConstants.js" as UiConstants

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

    Component.onCompleted: currentImagePath = startImagePath

    StartPage {
        id: startPage
        onOpen: openMenu.open()
        onAbout: {
            var aboutPageObject = DynamicObject.create(window, "AboutPage.qml")
            pageStack.push(aboutPageObject)
            aboutPageObject.back.connect(pageStack.pop)
        }
        onSettings: {
            var settingsPageObject = DynamicObject.create(window, "SettingsPage.qml")
            pageStack.push(settingsPageObject)
            settingsPageObject.back.connect(pageStack.pop)
        }
        onBack: Qt.quit()
    }

    Page {
        id: mainPage

        property int previewWidth: (width > height) ? width : height
        property int previewHeight: (height > width) ? width : height

        property bool imageModified: false

        function handleClickToScreen() {
            if(mainToolBoard.shown) {
                mainToolBoard.hide()
            }
            else {
                mainToolBar.hide()
            }
        }

        Connections {
            target: window
            onCurrentImagePathChanged: {
                slider.offset = 0
                slider.reset()
            }
        }

        ImageView {
            id: imageView
            anchors.fill: parent
            // !! Memory leak !!
            //            sourceImage: engine.previewImage
            Connections {
                target: engine
                onPreviewImageChanged: {
                    //                                        var startTime = new Date().getTime()
                    imageView.sourceImage = engine.previewImage
                    gc()
                    //                                        var stopTime = new Date().getTime()
                    //                                        console.log(stopTime - startTime)
                }
            }
        }

        Rectangle {
            id: horizontCursor
            color: "white"
            height: 2
            opacity: 0.4
            width: parent.width
            y: parent.height / 4
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
            onClicked: parent.handleClickToScreen()
            onPressed: horizontCursor.blink()
        }

        CustomSlider {
            id: slider
            anchors.left: parent.left
            anchors.right: parent.right
            y: (parent.height / 3) * 2 - height / 2
            amplitude: 10
            onYChanged: reset()
            property bool tempToolBarStatus
            onClicked: parent.handleClickToScreen()
            onPressed: {
                tempToolBarStatus = mainToolBar.shown
                mainToolBar.hide()
                if(!settings.spthPreview) {
                    engine.smoothPixmapTransformHint = false
                }
            }
            onReleased: {
                mainToolBar.shown = tempToolBarStatus
                if(!settings.spthPreview) {
                    engine.smoothPixmapTransformHint = true
                    engine.rotate(value)
                    engine.smoothPixmapTransformHint = false
                }
            }

            onValueChanged: {
                //Smooth
                if(settings.spthPreview) {
                    engine.smoothPixmapTransformHint = true
                    engine.rotation = value
                }
                else {
                    engine.smoothPixmapTransformHint = false
                    engine.rotation = value
                } //EndSmooth

                //IsModified?
                mainPage.imageModified = (value.toFixed(1) !== "0.0") ? true : false
                //EndIsModified
            }
        }

        tools: ToolBarLayout {
            id: mainToolBarLayout
            CustomToolButton {
                iconSource: "toolbar-back"
                toolTip: toolTip
                toolTipText: qsTr("Exit")
                onClicked: {
                    if(mainPage.imageModified) {
                        saveDialog.openDialog("quit")
                    }
                    else {
                        Qt.quit()
                    }
                }
            }
            CustomToolButton {
                iconSource: "qrc:/images/images/open.png"
                toolTip: toolTip
                toolTipText: qsTr("Open")
                onClicked: {
                    if(mainPage.imageModified) {
                        saveDialog.openDialog("open")
                    }
                    else {
                        openMenu.open()
                    }
                }
            }
            CustomToolButton {
                id: upToolButton
                iconSource: "qrc:/images/images/up.png"
                toolTip: checked ? null : toolTip
                toolTipText: qsTr("Tools")
                property bool checked: false
                onClicked: checked = !checked
                onCheckedChanged: checked ? mainToolBoard.open() :
                                            mainToolBoard.hide()
                rotation: checked ? 180.0 : 0.0
                Behavior on rotation {
                    PropertyAnimation{}
                }
                Connections {
                    target: mainToolBoard
                    onShownChanged: {
                        upToolButton.checked = mainToolBoard.shown
                    }
                }
            }
            CustomToolButton {
                iconSource: "qrc:/images/images/save.svg"
                toolTip: toolTip
                toolTipText: qsTr("Save")
                onClicked: {
                    engine.smoothPixmapTransformHint = true
                    engine.save(settings.quality)
                    mainPage.imageModified = false
                }
            }
            CustomToolButton {
                iconSource: "toolbar-menu"
                toolTip: toolTip
                toolTipText: qsTr("Menu")
                onClicked: {
                    mainPageMenu.open()
                }
            }
        }

        ToolTip {
            id: toolTip
            visible: false
        }

        CustomToolTip {
            id: customToolTip
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
                    else {
                        mainTopBar.shown = false
                    }
                }
            }
        }

        ToolBoard {
            id: mainToolBoard
            offsetY: mainToolBarLayout.height
            anchors.bottom: parent.bottom
            z: 1
            onShowToolTip: {
                customToolTip.show(text, mainToolBoard)
            }
            onHideToolTip: {
                customToolTip.hide()
            }
            Connections {
                target: mainToolBar
                onShownChanged: {
                    if(mainToolBoard.visible && !mainToolBar.shown) {
                        mainToolBoard.hide()
                    }
                }
            }
            ToolBoardItem {
                text: qsTr("Rotate -90") + "°"
                iconSource: "qrc:/images/images/rotate-left.png"
                onClicked: slider.offset = slider.offset - 90.0
            }
            ToolBoardItem {
                text: qsTr("Refresh")
                iconSource: "qrc:/images/images/refresh.svg"
                onClicked: { slider.offset = 0; slider.reset()}
            }
            ToolBoardItem {
                text: qsTr("Rotate 90") + "°"
                iconSource: "qrc:/images/images/rotate-right.png"
                onClicked: slider.offset = slider.offset + 90.0
            }
            ToolBoardItem {
                text: qsTr("Line")
                iconSource: "qrc:/images/images/horizont-line.svg"
                onClicked: horizontCursor.visible = !horizontCursor.visible
            }
            ToolBoardItem {
                text: qsTr("View gallery")
                iconSource: "qrc:/images/images/gallery.svg"
                onClicked: extAppLauncher.startDetached("glx.exe")
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
                    onClicked: {
                        var settingsPageObject = DynamicObject.create(
                                    window, "SettingsPage.qml")
                        pageStack.push(settingsPageObject)
                        settingsPageObject.back.connect(pageStack.pop)
                    }
                }
                MenuItem {
                    text: qsTr("About")
                    onClicked: {
                        var aboutPageObject = DynamicObject.create(
                                    window, "AboutPage.qml")
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
                    onClicked: {
                        if(mainPage.imageModified) {
                            saveDialog.openDialog("open")
                        }
                        else {
                            openMenu.open()
                        }
                    }
                }
                MenuItem {
                    text: qsTr("Save")
                    onClicked: {
                        engine.smoothPixmapTransformHint = true
                        engine.save(settings.quality)
                        mainPage.imageModified = false
                    }
                }
            }
        }

        QueryDialog {
            id: saveDialog
            titleText: qsTr("Image does not saved")
            message: qsTr("Do you want to save the modified image?")
            acceptButtonText: qsTr("Yes")
            rejectButtonText: qsTr("No")
            property string _cause

            function openDialog(cause) {
                _cause = cause
                open()
            }

            onAccepted: {
                engine.smoothPixmapTransformHint = true
                engine.save(settings.quality)
                mainPage.imageModified = false
                if(_cause === "quit") {
                    engine.savingFinished.connect(Qt.quit)
                }
                else if(_cause === "open") {
                    engine.smoothPixmapTransformHint = true
                    openMenu.open()
                }
            }
            onRejected: {
                if(_cause === "quit") {
                    Qt.quit()
                }
                else if(_cause === "open") {
                    openMenu.open()
                }
            }
            onClickedOutside: close()
        }
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
        Component.onCompleted: push(startPage)
        onCurrentPageChanged: {
            if(currentPage !== mainPage) {
                mainToolBar.shown = true
            }
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: mainToolBar.height
        onPressed: mainToolBar.shown = true
    }

    CustomToolBar {
        id: mainToolBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        tools: pageStack.currentPage.tools
        //background: "qrc:/images/images/toolbar-background.svg"
    }

    ImageFetcher {
        id: imageFetcher
    }

    Engine {
        id: engine
        previewWidth: mainPage.previewWidth * 1.0
        previewHeight: mainPage.previewHeight * 1.0
        imagePath: window.currentImagePath
        exifEnabled: settings.exifEnabled
        onSavingFinished: {
            if(settings.vibraOn) {
                vibra.doubleVibrate(65, 160)
            }
        }
    }

    QueryDialog {
        id: queryDialog
        buttonTexts: [qsTr("Close")]
        onClickedOutside: close()
    }

    ContextMenu {
        id: openMenu

        MenuLayout {
            CustomMenuItem {
                text: qsTr("From Gallery")
                Component.onCompleted: disabled = !settings.galleryAvailable

                onClicked: {
                    if(!disabled) {
                        currentImagePath = imageFetcher.fetchImage(ImageFetcher.Gallery)
                    }
                    else
                    {
                        queryDialog.titleText = qsTr("Not available")
                        queryDialog.message = qsTr("Available only in extended (unsigned) version! \
You can download extended version on AppList, GitHub(see 'About' for \
more details) or on Symbian Zone community(vk.com/symbian_zone).  \
Note that your Symbian phone needs to be hacked and an \
InstallServer patch applied to ROMPatcher. Most Custom Firmwares (CFW) \
already have a modified InstallServer to allow installing unsigned apps.")
                        queryDialog.open()
                    }
                }
            }
            MenuItem {
                text: qsTr("File Manager")
                onClicked: currentImagePath = imageFetcher.fetchImage(ImageFetcher.FileManager)
            }
        }
    }
}
