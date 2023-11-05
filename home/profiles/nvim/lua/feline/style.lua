local color = require("feline.presets.colors")
local c = color[color.status_color]
local cc = color[color.status_color].colors
local vi_mode_utils = require("feline.providers.vi_mode")
local icons = require("feline.defaults").separators
local _if = require("feline.providers.lsp")

local components = {
    left = {active = {}, inactive = {}},
    mid = {active = {}, inactive = {}},
    right = {active = {}, inactive = {}}
}

-- left active
-- =======================================
table.insert(
    components.left.active,
    {
        provider = "get_vim_mode",
        hl = function()
            local val = {}
            val.bg = vi_mode_utils.get_mode_color()
            val.fg = "dark"
            val.style = "bold"
            return val
        end
    }
)
table.insert(
    components.left.active,
    {
        provider = icons.slant_right,
        hl = function()
            local val = {}
            val.fg = vi_mode_utils.get_mode_color()
            val.bg = "bg2"
            return val
        end
    }
)
table.insert(
    components.left.active,
    {
        provider = "file_info",
        hl = {fg = "dark", bg = "bg2", style = "bold"}
    }
)
table.insert(
    components.left.active,
    {
        provider = icons.slant_left,
        hl = {bg = "bg2", fg = "dark"},
        enabled = function()
            return vim.b.gitsigns_status_dict
        end,
        right_sep = ""
    }
)
table.insert(
    components.left.active,
    {
        provider = icons.slant_left,
        hl = {fg = "bg", bg = "bg2"},
        enabled = function()
            return not vim.b.gitsigns_status_dict
        end,
        right_sep = ""
    }
)
table.insert(
    components.left.active,
    {
        provider = "file_readonly",
        enabled = function()
            return vim.bo.readonly
        end,
        hl = {fg = "red", style = "bold"}
    }
)
table.insert(
    components.left.active,
    {
        provider = "git_branch",
        hl = {bg = "dark", fg = "light", style = "bold"},
        enabled = function()
            return vim.b.gitsigns_status_dict
        end
    }
)
table.insert(
    components.left.active,
    {
        provider = "git_diff_added",
        hl = {fg = "green", style = "bold", bg = "dark"},
        enabled = function()
            return vim.b.gitsigns_status_dict
        end
    }
)
table.insert(
    components.left.active,
    {
        provider = "git_diff_changed",
        hl = {fg = "yellow", style = "bold", bg = "dark"},
        enabled = function()
            return vim.b.gitsigns_status_dict
        end
    }
)
table.insert(
    components.left.active,
    {
        provider = "git_diff_removed",
        hl = {fg = "red", style = "bold", bg = "dark"},
        enabled = function()
            return vim.b.gitsigns_status_dict
        end
    }
)
table.insert(
    components.left.active,
    {
        provider = icons.slant_right,
        hl = {fg = "dark"},
        enabled = function()
            return vim.b.gitsigns_status_dict
        end
    }
)

-- right active
-- =======================================
table.insert(
    components.right.active,
    {
        provider = "lsp_connected",
        hl = {fg = "connected"},
        right_sep = " "
    }
)
table.insert(
    components.right.active,
    {
        provider = "diag_errors_num",
        hl = {fg = "bg", bg = "error", style = "bold"},
        left_sep = {str = icons.slant_left, hl = {fg = "error", bg = "bg"}},
        right_sep = {str = icons.slant_left, hl = {fg = "warning", bg = "red"}}
    }
)
table.insert(
    components.right.active,
    {
        provider = "diag_warnings_num",
        hl = {fg = "bg", bg = "warning", style = "bold"},
        right_sep = {str = icons.slant_left, hl = {fg = "info", bg = "warning"}}
    }
)
table.insert(
    components.right.active,
    {
        provider = "diag_info_num",
        hl = {fg = "bg", bg = "info", style = "bold"},
        right_sep = {str = icons.slant_left, hl = {fg = "hint", bg = "info"}}
    }
)
table.insert(
    components.right.active,
    {
        provider = "diag_hints_num",
        hl = {fg = "bg", bg = "hint", style = "bold"},
        right_sep = {str = icons.slant_left, hl = {fg = "dark", bg = "hint"}}
    }
)
table.insert(
    components.right.active,
    {
        provider = "file_encoding",
        upper = false,
        hl = {style = "bold", bg = "dark"},
        right_sep = {str = "|", hl = {bg = "dark"}}
    }
)
table.insert(
    components.right.active,
    {
        provider = "file_type",
        upper = false,
        hl = {style = "bold", bg = "dark", fg = "op"}
    }
)
table.insert(
    components.right.active,
    {
        provider = icons.slant_right,
        hl = function()
            local val = {}
            val.bg = vi_mode_utils.get_mode_color()
            val.fg = "dark"
            return val
        end
    }
)
table.insert(
    components.right.active,
    {
        provider = "position",
        icon = "",
        hl = function()
            local val = {}
            val.bg = vi_mode_utils.get_mode_color()
            val.fg = "dark"
            val.style = "bold"
            return val
        end
    }
)
table.insert(
    components.right.active,
    {
        provider = function()
            local curr_line = vim.fn.line(".")
            local lines = vim.fn.line("$")
            return string.format("| %3d%%%% ", vim.fn.round(curr_line / lines * 100))
        end,
        hl = function()
            local val = {}
            val.bg = vi_mode_utils.get_mode_color()
            val.fg = "dark"
            val.style = "bold"
            return val
        end
    }
)

-- left inactive
-- =======================================
table.insert(
    components.left.inactive,
    {
        provider = "file_type",
        left_sep = {str = " ", hl = {bg = "normal"}},
        hl = {fg = "dark", bg = "normal", style = "bold"},
        right_sep = {str = icons.right_filled, hl = {fg = "normal"}}
    }
)
-- right inactive
-- =======================================
table.insert(
    components.right.inactive,
    {
        provider = "position",
        hl = {bg = "normal", fg = "dark", style = "bold"},
        icon = "",
        left_sep = {str = icons.left_filled, hl = {fg = "normal"}}
    }
)

require("feline").setup(
    {
        default_fg = c.default_fg,
        default_bg = c.default_bg,
        colors = {
            bg1 = cc.bg1,
            bg2 = cc.bg2,
            dark = cc.dark,
            light = cc.light,
            normal = cc.normal,
            visual = cc.visual,
            insert = cc.insert,
            replace = cc.replace,
            command = cc.command,
            op = cc.op
        },
        vi_mode_colors = {
            NORMAL = "normal",
            OP = "op",
            INSERT = "insert",
            VISUAL = "visual",
            BLOCK = "visual",
            REPLACE = "replace",
            ["V-REPLACE"] = "replace",
            ENTER = "op",
            MORE = "dark",
            SELECT = "light",
            COMMAND = "command",
            SHELL = "light",
            TERM = "op",
            NONE = "dark"
        },
        components = components
    }
)
