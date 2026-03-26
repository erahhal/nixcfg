import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

FocusScope {
    id: root

    property var pluginService: null

    implicitHeight: settingsColumn.implicitHeight
    height: implicitHeight

    // Live copy of vpnEndpoints map, kept in sync with saves
    property var vpnEndpointsData: ({})

    function saveSettings(key, value) {
        if (pluginService) {
            pluginService.savePluginData("networkMonitor", key, value)
        }
    }

    function loadSettings(key, defaultValue) {
        if (pluginService) {
            return pluginService.loadPluginData("networkMonitor", key, defaultValue)
        }
        return defaultValue
    }

    function loadVpnEndpoints() {
        vpnEndpointsData = loadSettings("vpnEndpoints", {})
    }

    function saveVpnEndpoint(iface, endpoint, method) {
        var updated = Object.assign({}, vpnEndpointsData)
        updated[iface] = { endpoint: endpoint, method: method }
        vpnEndpointsData = updated
        saveSettings("vpnEndpoints", updated)
    }

    onPluginServiceChanged: if (pluginService) loadVpnEndpoints()
    Component.onCompleted: loadVpnEndpoints()

    Column {
        id: settingsColumn
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        StyledText {
            text: "Network Monitor Settings"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            text: "Monitor network connectivity with VPN-aware endpoint switching"
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
            width: parent.width - 32
        }

        StyledRect {
            width: parent.width - 32
            height: 1
            color: Theme.outlineVariant
        }

        // Enable toggle
        Row {
            spacing: 12
            width: parent.width - 32

            CheckBox {
                id: enabledToggle
                text: "Enable Network Monitoring"
                checked: loadSettings("enabled", true)

                contentItem: StyledText {
                    text: enabledToggle.text
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    leftPadding: enabledToggle.indicator.width + 8
                    verticalAlignment: Text.AlignVCenter
                }

                indicator: StyledRect {
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: Theme.cornerRadiusSmall
                    border.color: enabledToggle.checked ? Theme.primary : Theme.outline
                    border.width: 2
                    color: enabledToggle.checked ? Theme.primary : "transparent"

                    StyledRect {
                        width: 12
                        height: 12
                        anchors.centerIn: parent
                        radius: 2
                        color: Theme.onPrimary
                        visible: enabledToggle.checked
                    }
                }

                onCheckedChanged: {
                    saveSettings("enabled", checked)
                }
            }
        }

        StyledRect {
            width: parent.width - 32
            height: 1
            color: Theme.outlineVariant
        }

        // Check interval
        Column {
            spacing: 8
            width: parent.width - 32

            StyledText {
                text: "Check Interval: " + intervalSlider.value + "s"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: "How often to check connectivity"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            Slider {
                id: intervalSlider
                width: parent.width
                from: 5
                to: 300
                stepSize: 5
                value: loadSettings("checkInterval", 30)

                onValueChanged: {
                    saveSettings("checkInterval", value)
                }
            }
        }

        StyledRect {
            width: parent.width - 32
            height: 1
            color: Theme.outlineVariant
        }

        // Default Endpoint Section
        Column {
            spacing: 12
            width: parent.width - 32

            StyledText {
                text: "Default Endpoint"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Column {
                spacing: 4
                width: parent.width

                StyledText {
                    text: "URL/Host"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                }

                DankTextField {
                    id: normalEndpointField
                    width: parent.width
                    height: 40
                    text: loadSettings("normalEndpoint", "https://github.com")
                    placeholderText: "https://github.com"
                    backgroundColor: Theme.surfaceContainer
                    textColor: Theme.surfaceText

                    onTextEdited: {
                        saveSettings("normalEndpoint", text)
                    }
                }
            }

            Column {
                spacing: 4
                width: parent.width

                StyledText {
                    text: "Check Method"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                }

                Row {
                    spacing: 16

                    RadioButton {
                        id: httpRadio
                        text: "HTTP Request"
                        checked: loadSettings("checkMethod", "ping") === "http"
                        onCheckedChanged: {
                            if (checked) saveSettings("checkMethod", "http")
                        }

                        contentItem: StyledText {
                            text: httpRadio.text
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            leftPadding: httpRadio.indicator.width + 8
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    RadioButton {
                        id: pingRadio
                        text: "Ping"
                        checked: loadSettings("checkMethod", "ping") === "ping"
                        onCheckedChanged: {
                            if (checked) saveSettings("checkMethod", "ping")
                        }

                        contentItem: StyledText {
                            text: pingRadio.text
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            leftPadding: pingRadio.indicator.width + 8
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        StyledRect {
            width: parent.width - 32
            height: 1
            color: Theme.outlineVariant
        }

        // Per-VPN Endpoint Section
        Column {
            spacing: 4
            width: parent.width - 32

            StyledText {
                text: "VPN Endpoints"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: "Configure a test endpoint for each VPN interface. Leave empty to use the default endpoint."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        Repeater {
            model: {
                var interfaces = loadSettings("vpnInterfaces", ["tailscale0", "wg0", "tun0"])
                return Array.isArray(interfaces) ? interfaces : interfaces.split(",").map(function(s) { return s.trim() })
            }

            delegate: Column {
                spacing: 8
                width: parent.width

                property string ifaceName: modelData
                property var ifaceConfig: root.vpnEndpointsData[ifaceName] || {}

                StyledText {
                    text: ifaceName
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                Column {
                    spacing: 4
                    width: parent.width

                    StyledText {
                        text: "URL/Host (optional)"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    DankTextField {
                        id: ifaceEndpointField
                        width: parent.width
                        height: 40
                        text: ifaceConfig.endpoint || ""
                        placeholderText: "Leave empty to use default endpoint"
                        backgroundColor: Theme.surfaceContainer
                        textColor: Theme.surfaceText

                        onTextEdited: {
                            var method = ifaceMethodPing.checked ? "ping" : "http"
                            root.saveVpnEndpoint(ifaceName, text, method)
                        }
                    }
                }

                Row {
                    spacing: 16

                    RadioButton {
                        id: ifaceMethodHttp
                        text: "HTTP"
                        checked: (ifaceConfig.method || "http") === "http"
                        onCheckedChanged: {
                            if (checked) root.saveVpnEndpoint(ifaceName, ifaceEndpointField.text, "http")
                        }

                        contentItem: StyledText {
                            text: ifaceMethodHttp.text
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            leftPadding: ifaceMethodHttp.indicator.width + 8
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    RadioButton {
                        id: ifaceMethodPing
                        text: "Ping"
                        checked: (ifaceConfig.method || "http") === "ping"
                        onCheckedChanged: {
                            if (checked) root.saveVpnEndpoint(ifaceName, ifaceEndpointField.text, "ping")
                        }

                        contentItem: StyledText {
                            text: ifaceMethodPing.text
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            leftPadding: ifaceMethodPing.indicator.width + 8
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.5
                }
            }
        }

        StyledRect {
            width: parent.width - 32
            height: 1
            color: Theme.outlineVariant
        }

        // VPN Interfaces
        Column {
            spacing: 8
            width: parent.width - 32

            StyledText {
                text: "VPN Interfaces"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: "Comma-separated list (e.g., tailscale0, wg0, tun0)"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            DankTextField {
                id: vpnInterfacesField
                width: parent.width
                height: 40
                text: {
                    var interfaces = loadSettings("vpnInterfaces", ["tailscale0", "wg0", "tun0"])
                    return Array.isArray(interfaces) ? interfaces.join(", ") : interfaces
                }
                placeholderText: "tailscale0, wg0, tun0"
                backgroundColor: Theme.surfaceContainer
                textColor: Theme.surfaceText

                onTextEdited: {
                    var interfaces = text.split(",").map(function(s) { return s.trim() }).filter(function(s) { return s !== "" })
                    saveSettings("vpnInterfaces", interfaces)
                }
            }
        }

        StyledRect {
            width: parent.width - 32
            height: 1
            color: Theme.outlineVariant
        }

        // Info
        Column {
            spacing: 4
            width: parent.width - 32

            StyledText {
                text: "Common VPN interfaces:"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                text: "tailscale0 (Tailscale), wg0 (WireGuard), tun0 (OpenConnect/OpenVPN)"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        // Bottom padding
        Item {
            width: 1
            height: 16
        }
    }
}
