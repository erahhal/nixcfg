import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Status properties
    property bool isOnline: false
    property bool hasVpn: false
    property string statusText: "Checking..."
    property string lastCheckEndpoint: ""
    property bool isChecking: false

    // Settings from pluginData
    readonly property bool enabled: pluginData.enabled ?? true
    readonly property int checkInterval: pluginData.checkInterval ?? 30
    readonly property string checkMethod: pluginData.checkMethod ?? "http"
    readonly property string vpnCheckMethod: pluginData.vpnCheckMethod ?? "http"
    readonly property string normalEndpoint: pluginData.normalEndpoint ?? "https://github.com"
    readonly property string vpnEndpoint: pluginData.vpnEndpoint ?? ""
    readonly property var vpnInterfaces: pluginData.vpnInterfaces ?? ["tailscale0", "wg0", "tun0"]

    // VPN interface detection process
    Process {
        id: vpnCheckProcess
        command: ["sh", "-c", root.buildVpnCheckCommand()]
        stdout: SplitParser {
            onRead: data => {
                root.hasVpn = data.trim() !== ""
            }
        }
        onExited: (exitCode, exitStatus) => {
            // VPN check complete, now check connectivity
            root.hasVpn = exitCode === 0
            connectivityCheck.command = root.buildConnectivityCommand()
            connectivityCheck.running = true
        }
    }

    // Connectivity check process
    Process {
        id: connectivityCheck
        onExited: (exitCode, exitStatus) => {
            root.isOnline = (exitCode === 0)
            root.isChecking = false
            root.updateStatusText()
        }
    }

    // Periodic check timer
    Timer {
        id: checkTimer
        interval: root.checkInterval * 1000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.performCheck()
    }

    // Build command to check for VPN interfaces
    function buildVpnCheckCommand() {
        if (!vpnInterfaces || vpnInterfaces.length === 0) {
            return "false"
        }
        var interfaces = vpnInterfaces.join("|")
        return "ls /sys/class/net 2>/dev/null | grep -E '^(" + interfaces + ")$'"
    }

    // Build connectivity check command based on settings
    function buildConnectivityCommand() {
        var endpoint = (hasVpn && vpnEndpoint) ? vpnEndpoint : normalEndpoint
        var method = (hasVpn && vpnEndpoint) ? vpnCheckMethod : checkMethod
        lastCheckEndpoint = endpoint

        if (method === "ping") {
            // Extract hostname from URL for ping
            var host = endpoint.replace(/^https?:\/\//, "").split("/")[0]
            return ["ping", "-c", "1", "-W", "2", host]
        } else {
            // HTTP check using wget
            return ["wget", "-q", "--timeout=2", "--tries=1", "--spider", endpoint]
        }
    }

    // Perform connectivity check
    function performCheck() {
        if (isChecking || !enabled) return
        isChecking = true
        vpnCheckProcess.running = true
    }

    // Update status text based on current state
    function updateStatusText() {
        if (isOnline) {
            statusText = "Online" + (hasVpn ? " (VPN)" : "")
        } else {
            statusText = "Offline"
        }
    }

    // Horizontal bar pill content
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            // Network status icon - single icon showing connectivity and VPN status
            DankIcon {
                name: root.isOnline ? (root.hasVpn ? "security" : "public") : "public_off"
                size: root.iconSize
                color: root.isOnline ? Theme.surfaceText : Theme.error
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Vertical bar pill content
    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            // Network status icon - single icon showing connectivity and VPN status
            DankIcon {
                name: root.isOnline ? (root.hasVpn ? "security" : "public") : "public_off"
                size: root.iconSize
                color: root.isOnline ? Theme.surfaceText : Theme.error
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Popout content with more details
    popoutContent: Component {
        Column {
            spacing: Theme.spacingM
            padding: Theme.spacingM

            Row {
                spacing: Theme.spacingM

                DankIcon {
                    name: root.isOnline ? (root.hasVpn ? "security" : "public") : "public_off"
                    size: 48
                    color: root.isOnline ? Theme.surfaceText : Theme.error
                }

                Column {
                    spacing: Theme.spacingXS

                    StyledText {
                        text: root.statusText
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Endpoint: " + root.lastCheckEndpoint
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        text: "Method: " + (root.checkMethod === "ping" ? "Ping" : "HTTP")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        text: "Interval: " + root.checkInterval + "s"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }
            }

            // VPN status section
            Row {
                spacing: Theme.spacingS
                visible: root.hasVpn

                DankIcon {
                    name: "vpn_lock"
                    size: 24
                    color: Theme.primary
                }

                StyledText {
                    text: "VPN Connected"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Refresh button
            StyledRect {
                width: parent.width - Theme.spacingM * 2
                height: 40
                radius: Theme.cornerRadius
                color: refreshMouseArea.containsMouse ? Theme.primaryHover : Theme.primary

                StyledText {
                    anchors.centerIn: parent
                    text: root.isChecking ? "Checking..." : "Check Now"
                    color: Theme.onPrimary
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: refreshMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.isChecking
                    onClicked: root.performCheck()
                }
            }
        }
    }

    popoutWidth: 300
    popoutHeight: 200

    // Click action - trigger immediate check
    pillClickAction: function() {
        performCheck()
    }

    Component.onCompleted: {
        // Initial check on load
        Qt.callLater(performCheck)
    }
}
