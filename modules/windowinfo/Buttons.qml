pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var client
    property bool moveToWsExpanded

    anchors.fill: parent
    spacing: Tokens.spacing.small

    RowLayout {
        Layout.topMargin: Tokens.padding.large
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large

        spacing: Tokens.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Move to workspace")
            elide: Text.ElideRight
        }

        StyledRect {
            color: Colours.palette.m3primary
            radius: Tokens.rounding.medium

            implicitWidth: moveToWsIcon.implicitWidth + Tokens.padding.small
            implicitHeight: moveToWsIcon.implicitHeight + Tokens.padding.extraSmall

            StateLayer {
                color: Colours.palette.m3onPrimary
                onClicked: root.moveToWsExpanded = !root.moveToWsExpanded
            }

            MaterialIcon {
                id: moveToWsIcon

                anchors.centerIn: parent

                animate: true
                text: root.moveToWsExpanded ? "expand_more" : "keyboard_arrow_right"
                color: Colours.palette.m3onPrimary
                fontStyle: Tokens.font.icon.large
            }
        }
    }

    GridLayout {
        id: wsGrid

        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.bottomMargin: root.moveToWsExpanded ? Tokens.spacing.medium : 0
        Layout.preferredHeight: root.moveToWsExpanded ? implicitHeight : 0
        opacity: root.moveToWsExpanded ? 1 : 0
        clip: true

        rowSpacing: Tokens.spacing.small
        columnSpacing: Tokens.spacing.small
        columns: 5

        Behavior on Layout.bottomMargin {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on Layout.preferredHeight {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Repeater {
            model: 10

            WButton {
                required property int index
                readonly property int wsId: Math.floor((Hypr.activeWsId - 1) / 10) * 10 + index + 1
                readonly property bool isCurrent: root.client?.workspace.id === wsId

                onClicked: {
                    Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.move({ window = "address:0x${root.client?.address}", workspace = "${wsId}", follow = true })` : `movetoworkspace ${wsId},address:0x${root.client?.address}`);
                }

                color: isCurrent ? Colours.tPalette.m3surfaceContainerHighest : Colours.palette.m3tertiaryContainer
                textColor: isCurrent ? Colours.palette.m3onSurface : Colours.palette.m3onTertiaryContainer
                text: wsId
                disabled: isCurrent
            }
        }
    }

    RowLayout {
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.bottomMargin: Tokens.padding.large

        spacing: Tokens.spacing.small

        // macOS order: red (kill), yellow (pin, floating only), green (float/tile)
        TrafficLight {
            color: "#FF5F57"
            text: Tr.tr("Kill")
            onClicked: Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.kill({ window = "address:0x${root.client?.address}" })` : `killwindow address:0x${root.client?.address}`)
        }

        Loader {
            asynchronous: true
            active: root.client?.lastIpcObject.floating ?? false
            Layout.leftMargin: active ? 0 : -parent.spacing

            sourceComponent: TrafficLight {
                color: "#FEBC2E"
                text: root.client?.lastIpcObject.pinned ? Tr.tr("Unpin") : Tr.tr("Pin")
                onClicked: Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.pin({ window = "address:0x${root.client?.address}" })` : `pin address:0x${root.client?.address}`)
            }
        }

        TrafficLight {
            color: "#28C840"
            text: root.client?.lastIpcObject.floating ? Tr.tr("Tile") : Tr.tr("Float")
            onClicked: Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.float({ window = "address:0x${root.client?.address}" })` : `togglefloating address:0x${root.client?.address}`)
        }
    }

    component TrafficLight: StyledRect {
        property string text

        signal clicked

        implicitWidth: 12
        implicitHeight: 12
        radius: Tokens.rounding.full

        // Labels moved from button text to tooltip/accessible name
        ToolTip.visible: tlLayer.containsMouse
        ToolTip.text: text
        Accessible.role: Accessible.Button
        Accessible.name: text

        StateLayer {
            id: tlLayer

            color: "white" // brighten on hover instead of the default darken
            onClicked: parent.clicked()
        }
    }

    component WButton: StyledRect {
        property color textColor: Colours.palette.m3onSurface
        property alias disabled: stateLayer.disabled
        property alias text: label.text

        signal clicked

        radius: Tokens.rounding.medium

        Layout.fillWidth: true
        implicitHeight: label.implicitHeight + Tokens.padding.small

        StateLayer {
            id: stateLayer

            color: parent.textColor
            onClicked: parent.clicked()
        }

        StyledText {
            id: label

            anchors.centerIn: parent

            animate: true
            color: parent.textColor
            font: Tokens.font.body.medium
        }
    }
}
