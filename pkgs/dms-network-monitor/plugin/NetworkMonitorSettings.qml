import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root

    pluginId: "networkMonitor"

    Column {
        width: parent.width
        spacing: Theme.spacingM

        // Header
        StyledText {
            text: "Network Monitor"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            text: "Monitor network connectivity with VPN-aware endpoint switching"
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
            width: parent.width
        }

        StyledRect {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        // Enable toggle
        ToggleSetting {
            settingKey: "enabled"
            label: "Enable Network Monitoring"
            description: "Periodically check network connectivity and display status"
            defaultValue: true
        }

        StyledRect {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        // Check interval
        SliderSetting {
            settingKey: "checkInterval"
            label: "Check Interval"
            description: "How often to check connectivity (in seconds)"
            minimum: 5
            maximum: 300
            defaultValue: 30
            unit: "s"
        }

        StyledRect {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        // Check method selection
        SelectionSetting {
            settingKey: "checkMethod"
            label: "Check Method"
            description: "Method used to verify connectivity"
            options: [
                { value: "http", label: "HTTP Request (wget)" },
                { value: "ping", label: "Ping (ICMP)" }
            ]
            defaultValue: "http"
        }

        StyledRect {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        // Endpoints section
        StyledText {
            text: "Endpoints"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        StringSetting {
            settingKey: "normalEndpoint"
            label: "Default Endpoint"
            description: "URL or host to check when not on VPN"
            placeholder: "https://github.com"
            defaultValue: "https://github.com"
        }

        StringSetting {
            settingKey: "vpnEndpoint"
            label: "VPN Endpoint (optional)"
            description: "URL or host to check when VPN is detected. Leave empty to use default endpoint."
            placeholder: "https://internal.example.com"
            defaultValue: ""
        }

        StyledRect {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        // VPN interfaces section
        StyledText {
            text: "VPN Detection"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        StringSetting {
            id: vpnInterfacesSetting
            settingKey: "vpnInterfacesString"
            label: "VPN Interfaces"
            description: "Comma-separated list of network interface names that indicate VPN is connected"
            placeholder: "tailscale0, wg0, tun0"
            defaultValue: "tailscale0,wg0,tun0"

            // Convert string to array when saving
            onValueChanged: {
                if (value) {
                    var interfaces = value.split(",").map(function(s) { return s.trim() }).filter(function(s) { return s !== "" })
                    root.saveValue("vpnInterfaces", interfaces)
                }
            }
        }

        StyledRect {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        // Info section
        Column {
            width: parent.width
            spacing: Theme.spacingS

            StyledText {
                text: "Common VPN Interfaces:"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Column {
                spacing: Theme.spacingXS
                leftPadding: Theme.spacingM

                StyledText {
                    text: "tailscale0 - Tailscale VPN"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    font.family: "monospace"
                }

                StyledText {
                    text: "wg0 - WireGuard"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    font.family: "monospace"
                }

                StyledText {
                    text: "tun0 - OpenConnect/OpenVPN"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    font.family: "monospace"
                }
            }
        }

        StyledRect {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        // Usage info
        Column {
            width: parent.width
            spacing: Theme.spacingS

            StyledText {
                text: "How It Works:"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Column {
                spacing: Theme.spacingXS
                leftPadding: Theme.spacingM

                StyledText {
                    text: "1. Checks for VPN interface presence in /sys/class/net"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.parent.width - Theme.spacingM
                }

                StyledText {
                    text: "2. Uses VPN endpoint if VPN detected and configured"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.parent.width - Theme.spacingM
                }

                StyledText {
                    text: "3. Tests connectivity via HTTP request or ping"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.parent.width - Theme.spacingM
                }

                StyledText {
                    text: "4. Updates icon: online/offline with VPN indicator"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.parent.width - Theme.spacingM
                }
            }
        }

        // Bottom padding
        Item {
            width: 1
            height: Theme.spacingL
        }
    }
}
