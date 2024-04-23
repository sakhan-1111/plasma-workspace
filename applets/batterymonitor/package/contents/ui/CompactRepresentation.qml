/*
    SPDX-FileCopyrightText: 2011 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2011 Viranch Mehta <viranch.mehta@gmail.com>
    SPDX-FileCopyrightText: 2013 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2023 Natalie Clarius <natalie.clarius@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.workspace.components as WorkspaceComponents
import org.kde.kirigami as Kirigami

import org.kde.plasma.private.battery

MouseArea {
    id: root

    readonly property bool isConstrained: Plasmoid.formFactor === PlasmaCore.Types.Vertical || Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    property int batteryPercent : 0
    property bool batteryPluggedIn : false
    property bool hasBatteries: false
    property bool hasInternalBatteries : false
    property bool hasCumulative: false

    property alias model: view.model

    required property bool isSetToPerformanceMode
    required property bool isSetToPowerSaveMode
    required property bool isManuallyInhibited
    required property bool isSomehowFullyCharged
    required property bool isDischarging

    activeFocusOnTab: true
    hoverEnabled: true

    Accessible.name: Plasmoid.title
    Accessible.description: `${toolTipMainText}; ${toolTipSubText}`
    Accessible.role: Accessible.Button

    property string powerModeIcon: root.isManuallyInhibited
            ? "system-suspend-inhibited-symbolic" 
            : root.isSetToPerformanceMode
            ? "battery-profile-performance-symbolic" 
            : root.isSetToPowerSaveMode
            ? "battery-profile-powersave-symbolic" 
            : Plasmoid.icon

    //Show only overall battery
    // "No Batteries" case
    Kirigami.Icon {
        anchors.fill: parent
        visible: root.isConstrained && !root.hasBatteries || (root.isConstrained && !root.hasInternalBatteries)
        source: root.powerModeIcon
        active: root.containsMouse
    }

    // Manual inhibition or power profile active while not discharging:
    // Show the active mode so the user can notice this at a glance
    Kirigami.Icon {
        id: powerMode

        anchors.fill: parent

        visible: root.isConstrained && !root.isDischarging && (root.isManuallyInhibited || root.isSetToPerformanceMode || root.isSetToPowerSaveMode)
        source: root.powerModeIcon
        active: root.containsMouse
    }

    Item {
        id: overallBatteryInfo

        anchors.fill: parent

        visible: root.isConstrained && !powerMode.visible && root.hasInternalBatteries

        // Show normal battery icon
        WorkspaceComponents.BatteryIcon {
            id: overalbatteryIcon

            anchors.fill: parent

            active: root.containsMouse
            hasBattery: root.hasCumulative
            percent: root.batteryPercent
            pluggedIn: root.batteryPluggedIn
        }

        WorkspaceComponents.BadgeOverlay {
            anchors.bottom: parent.bottom
            anchors.right: parent.right

            visible: Plasmoid.configuration.showPercentage && !root.isSomehowFullyCharged

            text: i18nc("battery percentage below battery icon", "%1%", root.batteryPercent)
            icon: overalbatteryIcon
        }
    }

    //Show all batteries
    GridView {
        id: view

        visible: !root.isConstrained

        height: root.height
        width: root.width
        contentHeight: height
        contentWidth: width

        cellWidth: Math.min(view.height, view.width)
        cellHeight: cellWidth

        // We have any batteries; show their status
        delegate: Item {
            id: batteryContainer

            width: view.cellWidth
            height: view.cellHeight

            // Show normal battery icon
            WorkspaceComponents.BatteryIcon {
                id: batteryIcon

                anchors.fill: parent

                active: root.containsMouse
                hasBattery: PluggedIn
                percent: Percent
                pluggedIn: ChargeState === BatteryControlModel.Charging
            }

            WorkspaceComponents.BadgeOverlay {
                anchors.bottom: parent.bottom
                anchors.right: parent.right

                visible: Plasmoid.configuration.showPercentage && !root.isSomehowFullyCharged

                text: i18nc("battery percentage below battery icon", "%1%", Percent)
                icon: batteryIcon
            }
        }
    }
}
