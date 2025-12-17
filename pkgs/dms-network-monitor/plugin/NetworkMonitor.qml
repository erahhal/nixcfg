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
    property string currentIp: "..."
    property string vpnInterfaceName: ""

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
                var iface = data.trim()
                root.hasVpn = iface !== ""
                root.vpnInterfaceName = iface
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
            // Fetch IP after connectivity check
            ipFetchProcess.running = true
        }
    }

    // IP address fetch process
    Process {
        id: ipFetchProcess
        command: ["sh", "-c", "ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \\K[0-9.]+'"]
        stdout: SplitParser {
            onRead: data => {
                var ip = data.trim()
                if (ip !== "") {
                    root.currentIp = ip
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || root.currentIp === "...") {
                root.currentIp = "N/A"
            }
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
        PopoutComponent {
            id: popoutColumn
            headerText: "Network Monitor"
            detailsText: root.statusText
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // Status row with icon
                Row {
                    spacing: Theme.spacingM
                    width: parent.width

                    DankIcon {
                        name: root.isOnline ? (root.hasVpn ? "security" : "public") : "public_off"
                        size: 32
                        color: root.isOnline ? Theme.surfaceText : Theme.error
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            text: root.isOnline ? "Internet Connected" : "No Internet Connection"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: root.isOnline ? Theme.surfaceText : Theme.error
                        }
                    }
                }

                // Divider
                StyledRect {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }

                // IP Address
                Row {
                    spacing: Theme.spacingS
                    width: parent.width

                    DankIcon {
                        name: "lan"
                        size: 20
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            text: "IP Address"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: root.currentIp
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }
                    }
                }

                // VPN Status
                Row {
                    spacing: Theme.spacingS
                    width: parent.width

                    DankIcon {
                        name: root.hasVpn ? "vpn_lock" : "vpn_lock"
                        size: 20
                        color: root.hasVpn ? Theme.primary : Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            text: "VPN Status"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: root.hasVpn ? ("Connected" + (root.vpnInterfaceName ? " (" + root.vpnInterfaceName + ")" : "")) : "Not Connected"
                            font.pixelSize: Theme.fontSizeMedium
                            color: root.hasVpn ? Theme.primary : Theme.surfaceText
                        }
                    }
                }

                // Endpoint being checked
                Row {
                    spacing: Theme.spacingS
                    width: parent.width

                    DankIcon {
                        name: "link"
                        size: 20
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 32

                        StyledText {
                            text: "Checking Endpoint"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: root.lastCheckEndpoint || "Not set"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            elide: Text.ElideMiddle
                            width: parent.width
                        }
                    }
                }

                // Check method and interval
                Row {
                    spacing: Theme.spacingS
                    width: parent.width

                    DankIcon {
                        name: "schedule"
                        size: 20
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            text: "Check Method"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: ((root.hasVpn && root.vpnEndpoint) ? root.vpnCheckMethod : root.checkMethod).toUpperCase() + " every " + root.checkInterval + "s"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }
                    }
                }

                // Divider
                StyledRect {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }

                // Refresh button
                StyledRect {
                    width: parent.width
                    height: 36
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
    }

    popoutWidth: 320
    popoutHeight: 380

    // Right-click action - open plugin settings
    pillRightClickAction: function() {
        PopoutService.openSettingsWithTab("plugins")
    }

    Component.onCompleted: {
        // Initial check on load
        Qt.callLater(performCheck)
    }
}
