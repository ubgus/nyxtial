pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
  id: root

  implicitWidth: card.implicitWidth + Tokens.padding.extraLarge * 2
  implicitHeight: card.implicitHeight + Tokens.padding.extraLarge * 2

  StyledRect {
    id: card

    anchors.centerIn: parent
    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    // Same card geometry as the Performance tab for visual continuity.
    implicitWidth: Tokens.sizes.dashboard.perfNetworkCardWidth
    implicitHeight: Tokens.sizes.dashboard.perfNetworkCardHeight

    ColumnLayout {
      id: rows

      anchors.fill: parent
      anchors.margins: Tokens.padding.large
      spacing: Tokens.spacing.medium

      RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
          text: "lan"
          color: Colours.palette.m3primary
          fontStyle: Tokens.font.icon.medium
        }

        StyledText {
          text: Tr.tr("Homelab")
          font: Tokens.font.title.medium
        }
      }

      Repeater {
        model: Homelab.targets

        delegate: RowLayout {
          id: entry

          required property int index
          required property var modelData

          readonly property var entryStatus: Homelab.status[index]

          spacing: Tokens.spacing.small

          Rectangle {
            implicitWidth: 10
            implicitHeight: 10
            radius: 5
            color: {
              const s = entry.entryStatus;
              if (!s.checked)
                return Colours.palette.m3outline;
              return s.up ? Colours.palette.m3primary : Colours.palette.m3error;
            }
          }

          StyledText {
            text: entry.modelData.name
            font: Tokens.font.body.large
          }

          Item {
            Layout.fillWidth: true
          }

          StyledText {
            text: {
              const s = entry.entryStatus;
              return s.checked ? s.ms + " ms" : "...";
            }
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
          }
        }
      }

      Item {
        Layout.fillHeight: true
      }
    }
  }
}
