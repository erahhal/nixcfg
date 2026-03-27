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
    property string statusText: "Checking..."
    property bool isChecking: false
    property string currentIp: "..."

    // Per-VPN status map: { "tun0": {active, online, pingMs, hasEndpoint}, ... }
    property var vpnStatus: ({})
    // Per-VPN history: { "tun0": [{timestamp, active, online, pingMs, hasEndpoint}, ...], ... }
    property var vpnHistories: ({})
    property int maxHistory: 60
    // Internet history
    property var internetHistory: []
    property real internetPingMs: -1

    // Aggregate VPN state (updated by updateAggregateStatus)
    property bool hasAnyVpn: false
    property bool vpnProblem: false   // any active VPN with endpoint is offline
    property bool allOffline: false   // internet AND all active VPNs with endpoints are offline

    // Settings from pluginData
    readonly property bool enabled: pluginData.enabled ?? true
    readonly property int checkInterval: pluginData.checkInterval ?? 30
    readonly property string checkMethod: pluginData.checkMethod ?? "ping"
    readonly property string normalEndpoint: pluginData.normalEndpoint ?? "https://github.com"
    readonly property var vpnEndpoints: pluginData.vpnEndpoints ?? {}
    readonly property var vpnInterfaces: pluginData.vpnInterfaces ?? ["tailscale0", "wg0", "tun0"]

    // Single comprehensive check process — runs all checks in parallel subshells
    Process {
        id: allChecksProcess
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (!line) return

                var parts = line.split(":")
                if (parts.length < 2) return

                var key = parts[0]

                if (key === "internet") {
                    root.isOnline = (parts[1] === "online")
                    var inetPing = parts.length > 2 ? parseFloat(parts[2]) : -1
                    root.internetPingMs = isNaN(inetPing) ? -1 : inetPing
                    return
                }

                // Per-VPN line: iface:active:online:pingMs  or  iface:active:skip  or  iface:inactive
                var active = (parts[1] === "active")
                var status = parts.length > 2 ? parts[2] : ""
                var online = (status === "online")
                var pingMs = parts.length > 3 ? parseFloat(parts[3]) : -1
                var hasEndpoint = !!(root.vpnEndpoints[key] && root.vpnEndpoints[key].endpoint)

                var updated = Object.assign({}, root.vpnStatus)
                updated[key] = {
                    active: active,
                    online: online,
                    pingMs: isNaN(pingMs) ? -1 : pingMs,
                    hasEndpoint: hasEndpoint
                }
                root.vpnStatus = updated
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.isChecking = false
            root.updateAggregateStatus()
            root.recordAllHistory()
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
                if (ip !== "") root.currentIp = ip
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || root.currentIp === "...") root.currentIp = "N/A"
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

    // Build one comprehensive parallel shell script for all checks
    function buildAllChecksCommand() {
        var parts = []

        // Internet connectivity check
        var normalHost = normalEndpoint.replace(/^https?:\/\//, "").split("/")[0]
        var internetCmd
        if (checkMethod === "ping") {
            internetCmd = "MS=$(ping -c 1 -W 2 '" + normalHost + "' 2>/dev/null | grep -oP 'time=\\K[\\d.]+'); "
                        + "if [ -n \"$MS\" ]; then echo \"internet:online:$MS\"; "
                        + "else echo 'internet:offline:-1'; fi"
        } else {
            internetCmd = "wget -q --timeout=2 --tries=1 --spider '" + normalEndpoint + "' 2>/dev/null && echo 'internet:online:-1' || echo 'internet:offline:-1'"
        }
        parts.push("( " + internetCmd + " )")

        // Per-VPN interface checks
        var ifaces = vpnInterfaces || []
        for (var i = 0; i < ifaces.length; i++) {
            var iface = ifaces[i]
            var vpnConfig = vpnEndpoints[iface] || {}
            var endpoint = vpnConfig.endpoint || ""
            var method = vpnConfig.method || "http"

            // Connectivity test command (used when interface is active)
            var connectCmd
            if (endpoint) {
                if (method === "ping") {
                    var host = endpoint.replace(/^https?:\/\//, "").split("/")[0]
                    connectCmd = "MS=$(ping -c 1 -W 2 '" + host + "' 2>/dev/null | grep -oP 'time=\\K[\\d.]+'); "
                               + "if [ -n \"$MS\" ]; then echo \"" + iface + ":active:online:$MS\"; "
                               + "else echo '" + iface + ":active:offline:-1'; fi"
                } else {
                    connectCmd = "wget -q --timeout=2 --tries=1 --spider '" + endpoint + "' 2>/dev/null"
                               + " && echo '" + iface + ":active:online:-1'"
                               + " || echo '" + iface + ":active:offline:-1'"
                }
            } else {
                connectCmd = "echo '" + iface + ":active:skip'"
            }

            // Interface active detection + connectivity check
            var subshell
            if (iface === "tailscale0") {
                subshell = "if tailscale status >/dev/null 2>&1; then "
                         + "TSIF=$(ls /sys/class/net/ 2>/dev/null | grep -E '^tailscale0' | head -1); "
                         + "if [ -n \"$TSIF\" ]; then " + connectCmd + "; "
                         + "else echo 'tailscale0:inactive'; fi; "
                         + "else echo 'tailscale0:inactive'; fi"
            } else {
                subshell = "NIF=$(ls /sys/class/net/ 2>/dev/null | grep -E '^" + iface + "' | head -1); "
                         + "if [ -n \"$NIF\" ]; then " + connectCmd + "; "
                         + "else echo '" + iface + ":inactive'; fi"
            }
            parts.push("( " + subshell + " )")
        }

        return ["sh", "-c", parts.join(" & ") + "; wait"]
    }

    // Recompute aggregate VPN state after a check cycle
    function updateAggregateStatus() {
        var anyActive = false
        var problem = false
        var ifaces = vpnInterfaces || []
        for (var i = 0; i < ifaces.length; i++) {
            var s = vpnStatus[ifaces[i]]
            if (!s) continue
            if (s.active) anyActive = true
            if (s.active && s.hasEndpoint && !s.online) problem = true
        }
        var allDown = !isOnline
        for (var j = 0; j < ifaces.length; j++) {
            var st = vpnStatus[ifaces[j]]
            if (!st) continue
            if (st.active && st.hasEndpoint && st.online) allDown = false
        }
        hasAnyVpn = anyActive
        vpnProblem = problem
        allOffline = allDown
        statusText = isOnline ? ("Online" + (hasAnyVpn ? " (VPN)" : "")) : "Offline"
    }

    // Append one history entry per VPN interface after each check cycle
    function recordAllHistory() {
        // Internet history
        var inetArr = (internetHistory || []).slice()
        inetArr.push({
            timestamp: Date.now(),
            active: true,
            online: isOnline,
            pingMs: internetPingMs,
            hasEndpoint: true
        })
        if (inetArr.length > maxHistory) inetArr.shift()
        internetHistory = inetArr

        var newHistories = Object.assign({}, vpnHistories)
        var ifaces = vpnInterfaces || []
        for (var i = 0; i < ifaces.length; i++) {
            var iface = ifaces[i]
            var s = vpnStatus[iface] || { active: false, online: false, pingMs: -1, hasEndpoint: false }
            var arr = (newHistories[iface] || []).slice()
            arr.push({
                timestamp: Date.now(),
                active: s.active,
                online: s.online,
                pingMs: s.pingMs,
                hasEndpoint: s.hasEndpoint
            })
            if (arr.length > maxHistory) arr.shift()
            newHistories[iface] = arr
        }
        vpnHistories = newHistories
    }

    // Kick off a full check cycle
    function performCheck() {
        if (isChecking || !enabled) return
        isChecking = true
        allChecksProcess.command = buildAllChecksCommand()
        allChecksProcess.running = true
    }

    // Shared canvas paint logic — draws a bar chart for one VPN's history array
    function paintVpnChart(ctx, w, h, data) {
        ctx.clearRect(0, 0, w, h)
        ctx.fillStyle = Theme.surfaceContainer
        ctx.fillRect(0, 0, w, h)

        if (!data || data.length === 0) {
            ctx.fillStyle = Theme.surfaceVariantText
            ctx.font = "11px sans-serif"
            ctx.textAlign = "center"
            ctx.fillText("No data yet", w / 2, h / 2 + 4)
            return
        }

        // Compute max ping for scaling
        var hasPing = data.some(function(e) { return e.pingMs >= 0 && e.online })
        var maxPing = 500
        if (hasPing) {
            maxPing = 0
            data.forEach(function(e) { if (e.pingMs > maxPing) maxPing = e.pingMs })
            maxPing = Math.max(maxPing, 50)
            maxPing = Math.ceil(maxPing * 1.2)
        }

        var barW = w / maxHistory
        var startX = (maxHistory - data.length) * barW

        for (var i = 0; i < data.length; i++) {
            var e = data[i]
            var x = startX + i * barW
            var barH, barY

            if (!e.active) {
                // Interface was inactive — dim grey tick
                ctx.fillStyle = Theme.outlineVariant || "#555"
                ctx.fillRect(x, h - 3, barW - 1, 3)
            } else if (!e.hasEndpoint) {
                // Active but no endpoint configured — medium grey full bar
                ctx.fillStyle = Theme.outline || "#777"
                ctx.fillRect(x, 0, barW - 1, h)
            } else if (!e.online) {
                // Active + endpoint checked + offline — red
                ctx.fillStyle = Theme.error
                ctx.fillRect(x, 0, barW - 1, h)
            } else if (hasPing && e.pingMs >= 0) {
                // Online with ping latency — green bar height ∝ latency
                var ratio = Math.min(e.pingMs / maxPing, 1.0)
                barH = Math.max(2, Math.round(h * ratio))
                barY = h - barH
                ctx.fillStyle = "#4caf50"
                ctx.fillRect(x, barY, barW - 1, barH)
            } else {
                // Online HTTP — full green bar
                ctx.fillStyle = "#4caf50"
                ctx.fillRect(x, 0, barW - 1, h)
            }
        }

        // Scale overlay — drawn last so it sits above bars
        ctx.font = "10px sans-serif"
        ctx.textAlign = "left"
        if (hasPing) {
            ctx.fillStyle = Theme.surfaceVariantText
            ctx.fillText(maxPing + " ms", 3, 11)
        } else if (data.some(function(e) { return e.active && e.online })) {
            ctx.fillStyle = Theme.surfaceVariantText
            ctx.fillText("HTTP", 3, 11)
        }
    }

    // Horizontal bar pill content
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            Item {
                width: root.iconSize
                height: root.iconSize
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: root.hasAnyVpn ? "security" : (root.isOnline ? "public" : "public_off")
                    size: root.iconSize
                    color: {
                        if (root.allOffline) return Theme.error
                        if (!root.hasAnyVpn) return root.isOnline ? Theme.surfaceText : Theme.error
                        return root.vpnProblem ? "#f0b030" : Theme.surfaceText
                    }
                }

                StyledText {
                    visible: root.hasAnyVpn && root.vpnProblem
                    text: "!"
                    font.pixelSize: Math.max(7, Math.round(root.iconSize * 0.4))
                    font.weight: Font.Bold
                    color: root.allOffline ? Theme.error : "#f0b030"
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
            }
        }
    }

    // Vertical bar pill content
    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            Item {
                width: root.iconSize
                height: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: root.hasAnyVpn ? "security" : (root.isOnline ? "public" : "public_off")
                    size: root.iconSize
                    color: {
                        if (root.allOffline) return Theme.error
                        if (!root.hasAnyVpn) return root.isOnline ? Theme.surfaceText : Theme.error
                        return root.vpnProblem ? "#f0b030" : Theme.surfaceText
                    }
                }

                StyledText {
                    visible: root.hasAnyVpn && root.vpnProblem
                    text: "!"
                    font.pixelSize: Math.max(7, Math.round(root.iconSize * 0.4))
                    font.weight: Font.Bold
                    color: root.allOffline ? Theme.error : "#f0b030"
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
            }
        }
    }

    // Popout content
    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn
            headerText: "Network Monitor"
            detailsText: root.statusText
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // ── Internet status ──────────────────────────────────────
                Row {
                    spacing: Theme.spacingM
                    width: parent.width

                    DankIcon {
                        name: root.isOnline ? "public" : "public_off"
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

                        Row {
                            spacing: Theme.spacingXS

                            StyledText {
                                visible: root.isOnline
                                text: root.checkMethod.toUpperCase() + " · " + root.normalEndpoint
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            StyledText {
                                visible: root.isOnline && root.internetPingMs >= 0
                                text: "· " + root.internetPingMs.toFixed(1) + " ms"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }

                // Internet history chart
                Column {
                    width: parent.width
                    spacing: 4

                    StyledText {
                        text: "History (" + root.internetHistory.length + ")"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    Canvas {
                        width: parent.width
                        height: 56
                        property var histRef: root.internetHistory
                        onHistRefChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            root.paintVpnChart(ctx, width, height, root.internetHistory)
                        }
                    }
                }

                // Divider
                StyledRect {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }

                // ── IP Address ───────────────────────────────────────────
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

                // Divider
                StyledRect {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }

                // ── Per-VPN sections ─────────────────────────────────────
                Repeater {
                    model: root.vpnInterfaces

                    delegate: Column {
                        visible: isActive
                        width: parent.width
                        spacing: Theme.spacingS

                        property string ifaceName: modelData
                        // Bind to whole maps so delegate re-evaluates when either is reassigned
                        property var allStatus: root.vpnStatus
                        property var allHistories: root.vpnHistories

                        property var ifaceStatus: allStatus[ifaceName] || {}
                        property var ifaceHistory: allHistories[ifaceName] || []
                        property var ifaceConfig: root.vpnEndpoints[ifaceName] || {}

                        property bool isActive: ifaceStatus.active || false
                        property bool isOnlineVpn: ifaceStatus.online || false
                        property bool hasEndpoint: !!(ifaceConfig.endpoint)
                        property real pingMs: ifaceStatus.pingMs !== undefined ? ifaceStatus.pingMs : -1

                        // Interface header row
                        Row {
                            spacing: Theme.spacingS
                            width: parent.width

                            DankIcon {
                                name: "vpn_lock"
                                size: 20
                                color: {
                                    if (!isActive) return Theme.surfaceVariantText
                                    if (hasEndpoint && !isOnlineVpn) return Theme.error
                                    return Theme.primary
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: ifaceName
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: isActive ? " · Active" : " · Not Available"
                                font.pixelSize: Theme.fontSizeSmall
                                color: isActive ? Theme.primary : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Active details — only shown when interface is up
                        // Use a Row with a spacer item to indent under the icon
                        Row {
                            visible: isActive
                            width: parent.width
                            spacing: 0

                            Item { width: 28; height: 1 }

                            Column {
                                spacing: 4
                                width: parent.width - 28

                                // Endpoint + method
                                StyledText {
                                    visible: hasEndpoint
                                    text: {
                                        var m = (ifaceConfig.method || "http").toUpperCase()
                                        return m + " · " + ifaceConfig.endpoint
                                    }
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideMiddle
                                    width: parent.width
                                }

                                // Connectivity result
                                Row {
                                    spacing: Theme.spacingXS
                                    visible: hasEndpoint

                                    StyledText {
                                        text: isOnlineVpn ? "Online" : "Offline"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: isOnlineVpn ? "#4caf50" : Theme.error
                                    }

                                    StyledText {
                                        visible: isOnlineVpn && pingMs >= 0
                                        text: "· " + pingMs.toFixed(1) + " ms"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                    }
                                }

                                StyledText {
                                    visible: !hasEndpoint
                                    text: "No test endpoint configured"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }

                        // Per-VPN history chart
                        Column {
                            width: parent.width
                            spacing: 4
                            topPadding: 4

                            StyledText {
                                text: "History (" + ifaceHistory.length + ")"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            Canvas {
                                id: vpnCanvas
                                width: parent.width
                                height: 56
                                property var allHistoriesRef: root.vpnHistories
                                onAllHistoriesRefChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d")
                                    var data = root.vpnHistories[ifaceName] || []
                                    root.paintVpnChart(ctx, width, height, data)
                                }
                            }
                        }

                        // Section divider
                        StyledRect {
                            width: parent.width
                            height: 1
                            color: Theme.outlineVariant
                            opacity: 0.6
                        }
                    }
                }

                // ── Check method info ────────────────────────────────────
                Row {
                    spacing: Theme.spacingS
                    width: parent.width

                    DankIcon {
                        name: "schedule"
                        size: 20
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "every " + root.checkInterval + "s"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Divider
                StyledRect {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }

                // ── Check Now button ─────────────────────────────────────
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
    popoutHeight: 700

    // Right-click action — open plugin settings
    pillRightClickAction: function() {
        PopoutService.openSettingsWithTab("plugins")
    }

    Component.onCompleted: {
        Qt.callLater(performCheck)
    }
}
