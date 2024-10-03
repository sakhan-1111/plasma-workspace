/*
    SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.8
import QtQuick.Layouts 1.1

import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.private.notifications 2.0 as NotificationsApplet

import ".."

import "global"

NotificationsApplet.NotificationWindow {
    id: notificationPopup

    property int popupWidth

    // Maximum width the popup can take to not break out of the screen geometry.
    readonly property int availableWidth: globals.screenRect.width - globals.popupEdgeDistance * 2 - leftPadding - rightPadding

    readonly property int minimumContentWidth: popupWidth
    readonly property int maximumContentWidth: Math.min((availableWidth > 0 ? availableWidth : Number.MAX_VALUE), popupWidth * 3)

    property alias modelInterface: notificationItem.modelInterface

    property int timeout
    property int dismissTimeout

    signal expired
    signal hoverEntered
    signal hoverExited

    property int defaultTimeout: 5000
    readonly property int effectiveTimeout: {
        if (timeout === -1) {
            return defaultTimeout;
        }
        if (dismissTimeout) {
            return dismissTimeout;
        }
        return modelInterface.timeout;
    }

    // On wayland we need focus to copy to the clipboard, we change on mouse interaction until the cursor leaves 
    takeFocus: notificationItem.replying || focusListener.wantsFocus

    visible: false

    height: mainItem.implicitHeight + topPadding + bottomPadding
    width: mainItem.implicitWidth + leftPadding + rightPadding

    mainItem: KQuickAddons.MouseEventListener {
        id: focusListener
        property bool wantsFocus: false

        implicitWidth: Math.min(Math.max(notificationPopup.minimumContentWidth, notificationItem.Layout.preferredWidth), Math.max(notificationPopup.minimumContentWidth, notificationPopup.maximumContentWidth))
        implicitHeight: notificationItem.Layout.preferredHeight + notificationItem.y

        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: wantsFocus = true
        onContainsMouseChanged: wantsFocus = wantsFocus && containsMouse

        DropArea {
            anchors.fill: parent
            onEntered: {
                if (notificationPopup.hasDefaultAction && !notificationItem.dragging) {
                    dragActivationTimer.start();
                } else {
                    drag.accepted = false;
                }
            }
        }

        Timer {
            id: dragActivationTimer
            interval: 250 // same as Task Manager
            repeat: false
            onTriggered: notificationPopup.defaultActionInvoked()
        }

        // Visual flourish for critical notifications to make them stand out more
        Rectangle {
            id: criticalNotificationLine

            anchors {
                top: parent.top
                // Subtract bottom margin that header sets which is not a part of
                // its height, and also the PlasmoidHeading's bottom line
                topMargin: notificationItem.headerHeight - notificationItem.spacing - 1
                bottom: parent.bottom
                bottomMargin: -notificationPopup.bottomPadding
                left: parent.left
                leftMargin: -notificationPopup.leftPadding
            }
            implicitWidth: 4

            visible: notificationPopup.modelInterface.urgency === NotificationManager.Notifications.CriticalUrgency

            color: Kirigami.Theme.neutralTextColor
        }

        DraggableDelegate {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            draggable: notificationItem.notificationType != NotificationManager.Notifications.JobType
            onDismissRequested: popupNotificationsModel.close(popupNotificationsModel.index(index, 0))

            cursorShape: hasDefaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
            acceptedButtons: {
                let buttons = Qt.MiddleButton;
                if (hasDefaultAction || draggable) {
                    buttons |= Qt.LeftButton;
                }
                return buttons;
            }

            onClicked: mouse => {
                // NOTE "mouse" can be null when faked by the SelectableLabel
                if (mouse && mouse.button === Qt.MiddleButton) {
                    if (notificationItem.closable) {
                        notificationItem.closeClicked();
                    }
                } else if (hasDefaultAction) {
                    notificationPopup.defaultActionInvoked();
                }
            }
            onEntered: notificationPopup.hoverEntered()
            onExited: notificationPopup.hoverExited()

            LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
            LayoutMirroring.childrenInherit: true

            Timer {
                id: timer
                interval: notificationPopup.effectiveTimeout
                running: {
                    if (!notificationPopup.visible) {
                        return false;
                    }
                    if (area.containsMouse) {
                        return false;
                    }
                    if (interval <= 0) {
                        return false;
                    }
                    if (notificationItem.dragging || notificationItem.menuOpen) {
                        return false;
                    }
                    if (notificationItem.replying
                            && (notificationPopup.active || notificationItem.hasPendingReply)) {
                        return false;
                    }
                    return true;
                }
                onTriggered: {
                    if (notificationPopup.dismissTimeout) {
                        notificationPopup.dismissClicked();
                    } else {
                        notificationPopup.expired();
                    }
                }
            }

            NumberAnimation {
                target: notificationItem.modelInterface
                property: "remainingTime"
                from: timer.interval
                to: 0
                duration: timer.interval
                running: timer.running && Kirigami.Units.longDuration > 1
            }

            NotificationItem {
                id: notificationItem

                anchors.left: parent.left
                anchors.leftMargin: !LayoutMirroring.enabled && criticalNotificationLine.visible ? criticalNotificationLine.implicitWidth : 0
                anchors.right: parent.right

                // let the item bleed into the dialog margins so the close button margins cancel out
                y: modelInterface.closable || modelInterface.dismissable || modelInterface.configurable ? -notificationPopup.topPadding : 0

                modelInterface {
                    headingLeftMargin: -anchors.leftMargin

                    headingLeftPadding: LayoutMirroring.enabled ? -notificationPopup.leftPadding : 0
                    headingRightPadding: LayoutMirroring.enabled ? 0 : -notificationPopup.rightPadding

                    maximumLineCount: 8
                    bodyCursorShape: notificationPopup.hasDefaultAction ? Qt.PointingHandCursor : 0

                    thumbnailLeftPadding: -notificationPopup.leftPadding
                    thumbnailRightPadding: -notificationPopup.rightPadding
                    thumbnailTopPadding: -notificationPopup.topPadding
                    thumbnailBottomPadding: -notificationPopup.bottomPadding

                    // When notification is updated, restart hide timer
                    onTimeChanged: {
                        if (timer.running) {
                            timer.restart();
                        }
                    }
                    timeout: timer.running ? timer.interval : 0

                    closable: true

                    onBodyClicked: {
                        if (area.acceptedButtons & Qt.LeftButton) {
                            area.clicked(null /*mouse*/);
                        }
                    }
                }
            }
        }
    }
}
