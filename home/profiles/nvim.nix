{ inputs, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    inputs.nixd.packages.${pkgs.system}.default
    tree-sitter
    nodePackages.eslint
    nodePackages.prettier
    jdt-language-server
  ];

  # -----------------------------------------------------
  # @TODO
  #
  # - Get Cody for Sourcegraph working
  #   - https://docs.sourcegraph.com/cody/overview/install-neovim
  #   - https://github.com/sourcegraph/sourcegraph/blob/f93a6e46a33acd0a4000a57078949986104d5756/shell.nix#L49
  # - Get Github copilot working
  #   - https://github.com/github/copilot.vim
  #   - https://www.reddit.com/r/neovim/comments/twe45i/copilotlua_copilotcmp_pure_lua_plugins_for_github/
  # - treesitter textobject aware comments
  #   - https://github.com/numToStr/Comment.nvim
  # - location and syntax aware textobjects
  #   - https://github.com/RRethy/nvim-treesitter-textsubject
  # - Look at Lazy-Nix-Helper
  #   - https://www.reddit.com/r/NixOS/comments/18skfx9/introducing_lazynixhelper_use_your_existing/
  # - codify any state possible in ~/.local/share/nvim
  # - update large file handling logic
  #   - https://www.reddit.com/r/neovim/comments/z85s1l/disable_lsp_for_very_large_files/
  # - CodeGTP plugin
  #   - https://github.com/dpayne/CodeGPT.nvim
  # -----------------------------------------------------

  # -----------------------------------------------------
  # Profiling performance issues
  # -----------------------------------------------------

  # :profile start profile.log
  # :profile func *
  # :profile file *
  # " At this point do slow actions
  # :profile pause
  # :noautocmd qall!

  # -----------------------------------------------------
  # Notes
  # -----------------------------------------------------

  # :help     - Help for VIM
  # ctrl-]    - Go to section in VIM help
  #
  # Motion
  # --------
  # http://vimdoc.sourceforge.net/htmldoc/motion.html
  #
  # ctrl-o    - back
  # ctrl-i    - forward
  # :jumps    - history
  #
  # .         - REPEAT AN OPERATION!
  # :retab    - convert tabs to spaces
  # gf        - Go to file (e.g. C++ header)
  # ^wf       - Go to file in new pane
  # ^wgf      - Go to file in new tab
  # ~         - Swap case
  # g~        - Swap case for <modifier>
  # gi        - Go to last insertion point
  # gu        - Lower case
  # gU        - Upper case
  # %         - Move to matching item for bracket under or after cursor.
  # [(        - go to [count] previous unmatched '('.
  # [{        - go to [count] previous unmatched '{'.
  # ])        - go to [count] next unmatched ')'.
  # ]}        - go to [count] next unmatched '}'.
  # )         - go [count] sentences forward.
  # (         - go [count] sentences backward.
  # }         - go [count] paragraphs forward.
  # {         - go [count] paragraphs backward.
  # ]]        - [count] sections forward or to the next '{' in the first column.
  # ][        - [count] sections forward or to the next '}' in the first column.
  # [[        - [count] sections backward or to the previous '{' in the first column.
  # []        - [count] sections backward or to the previous '}' in the first column.
  # ]m        - Go to [count] next start of a method (for Java or similar structured language)
  # ]M        - Go to [count] next end of a method (for Java or similar structured language)
  # [m        - Go to [count] previous start of a method (for Java or similar structured language)
  # [M        - Go to [count] previous end of a method (for Java or similar structured language)
  # ]s        - Go to next spelling error
  # [s        - Go to previous spelling error
  # z=        - List spelling suggestions
  # 1z=       - Choose first spelling suggestion without seeing them
  # [* or [/  - go to [count] previous start of a C comment "/*".
  # ]* or ]/  - go to [count] next end of a C comment "*/".
  # m{a-zA-Z} - Set mark {a-zA-Z} at cursor position
  # '{a-zA-Z} - Jump to mark
  # m' or m`  - Set the previous context mark.
  # \'\' or \'\'  - Jump to previous context mark.
  # H         - Jump to top of window.
  # M         - Jump to middle of window.
  # L         - Jump to bottom of window.
  # zz        - recenter window.
  # :'<,'>    - visual selection as range.  So type : with a selection then do a s/// search/replace
  # yaf       - yank function (treesitter textobjects)
  # yiw       - yank word
  # yi"       - yank between quotes
  # yiW       - yank to surrounding spaces
  # viw       - select word under cursor
  # viwp      - select word then replace
  # vi"p      - select between quotes and replace
  # viw"0p    - select word then replace with first selection rather than last replaced word
  # o         - switch sides of visual selection
  # :cn       - next in quickfix list
  # :cp       - previous in quickfix list
  # :copen    - open quickfix list
  # :ccl      - close quickfix list
  # :<ctrl-f> - open command history in editor mode
  #
  # Telescope bindings
  # ---------------------------
  # <leader>ff  - files
  # <leader>fg  - string (grep)
  # <leader>fb  - buffers
  # <leader>fh  - help
  # <leader>fm  - man
  # <leader>fp  - previous
  # <leader>fs  - spell
  # <leader>fr  - lsp references
  # <leader>fi  - lsp incoming calls
  # <leader>fo  - lsp outgoing calls
  # <leader>fw  - lsp workspace symbols
  # <leader>fd  - lsp definitions
  #
  # Search and Replace in files
  # ---------------------------
  # Select files first:
  # :args **/*.js
  # :args `find . -type f`
  #
  # then search and replace:
  # :argdo %s/search/replace/g
  # :bufdo
  # :windo
  # :tabdo
  #
  # Using quickfix list, select files:
  # :grep blah -r **/*.txt
  # (or "ms" search in NERDTree)
  #
  # then search and replace, save, then close all buffers:
  # :cfdo %s/from/to/g | update
  # :cfdo :bd

  # @TODO: organize config by files like this:
  # https://www.reddit.com/r/NixOS/comments/xa30jq/homemanager_nvim_lua_config_for_plugins/

  ## Add this if raw lua is desired
  #   home.file."./.config/nvim/lua" = {
  #     source = ./nvim/lua;
  #     recursive = true;
  #   };

  ## THEN add the following beloe:
  #   extraConfig = ":luafile ~/.config/nvim/lua/init.lua";

  ## Hack to get this config loaded first above the plugin config
  xdg.configFile."nvim/init.lua".text = lib.mkBefore ''
    vim.opt.termguicolors = true

    -- if vim.fn.system('echo -n $HOSTNAME'):gsub('\n', "") ~= 'sicmundus' and vim.fn.system('echo -n $HOST'):gsub('\n', "") ~= 'sicmundus' then
    --   -- Messes up colors over mosh, so don't set this for the server
    --   vim.op.termguicolors = true
    -- end

    --------- OPTIONS AND VARS

    -- The following replace vim "set"
    -- vim.o        -- option, like :set, sets both local and global
    -- vim.go       -- global option, like :setglobal
    -- vim.bo       -- buffer local
    -- vim.wo       -- window local
    -- vim.opt      -- like vim.o, with objects, tables, and OO methods
    -- vim.g        -- global var, like :let

    --------- MODES

    -- n            -- normal (esc)
    -- i            -- insert (i)
    -- v            -- visual/select (v/gh)
    -- x            -- visual (v)
    -- s            -- select (gh)
    -- c            -- command (:)
    -- r            -- replace (R)
    -- o            -- operator pending

    --------- MAPPINGS

    -- map          -- will map recursively e.g. with j --> gg, Q --> j becomes Q --> gg
                    -- works in normal, visual, select, and operator pending modes
    -- map!         -- works in insert and command modes
    -- nnoremap     -- n/x (normal/visual mode) no (not) re (recursive) map

    -------------------------------------------------------
    -- General settings
    -------------------------------------------------------

    -- leaders give you 1 second to enter command
    -- default is \
    vim.g.mapleader = " "                               -- global
    vim.g.maplocalleader = " "                          -- per buffer, e.g. can change behavior per filetype
    vim.o.wrap = false                                  -- don't wrap lines
    vim.o.ruler = true                                  -- displays line, column, and cursor position at bottom
    vim.o.mouse = "a"                                   -- enable mouse for "all" modes
    vim.o.signcolumn = "yes"                            -- always show two column sign column on left
    vim.o.foldexpr = "nvim_treesitter#foldexpr()"

    vim.o.undodir = vim.fn.expand('~/.local/share/nvim/undo/')
    vim.o.undofile = true

    vim.o.cursorline = true                             -- Highlight line cursor sits on
    vim.o.number = true
    vim.o.relativenumber = true

    -- - enables filetype detection,
    -- - enables filetype-specific scripts (ftplugins),
    -- - enables filetype-specific indent scripts.
    -- Things like ctrl-w ctrl-] won't find custom ctag files without this
    -- ** Not needed as this is default for nvim
    -- vim.cmd [[filetype plugin indent on]]


    -------------------------------------------------------
    -- Key mappings
    -------------------------------------------------------

    -- Next buffer
    vim.api.nvim_set_keymap("", '<Tab>', ':bn<CR>', { noremap = true })
    -- Previous buffer
    vim.api.nvim_set_keymap("", '<S-Tab>', ':bp<CR>', { noremap = true })
    -- Close buffer
    vim.api.nvim_set_keymap("", '<leader><Tab>', ':bd<CR>', { noremap = true })
    vim.api.nvim_set_keymap("", '<leader><S-Tab>', ':bd!<CR>', { noremap = true })
    -- New tab
    vim.api.nvim_set_keymap("", '<leader>t', ':tabnew split<CR>', { noremap = true })

    -- Vimscript config
    vim.cmd([[

      " -----------------------------------------------------
      " Inline functions and config
      " -----------------------------------------------------

      " Have Vim jump to the last position when reopening a file
      if has("autocmd")
        au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
      endif

      " Automatically resize splits when window is resized
      augroup AutoResize
          autocmd FocusGained,FocusLost,VimResized * wincmd =
      augroup end

      " Highlight tabs
      fun! HighlightTabs()
          if exists('w:extratabs')
              call matchdelete(w:extratabs)
              unlet w:extratabs
          endif
          highlight ExtraTabs ctermbg=red guibg=red
          if &ft == 'help'
              return
          else
              let w:extratabs=matchadd('ExtraTabs', '\t\+')
          endif
      endfun

      augroup TabHighlight
          autocmd BufEnter * call HighlightTabs()
      augroup END

      " Remove trailing whitespace
      fun! TrimTrailingWhitespace()
          if &ft =~ 'javascript\|html\|jade\|json\|css\|less\|php\|python\|sh\|c\|cpp\|markdown\|yaml\|vim\|nix'
              :%s/\s\+$//e
          elseif expand('%:t') =~ '\.gltf$' || expand('%:t') =~ '\.glsl$'
              :%s/\s\+$//e
          endif
      endfun

      augroup WhiteSpaceTrim
          autocmd BufWritePre * call TrimTrailingWhitespace()
      augroup END

      " Show max line width
      fun! ShowMaxLineWidth()
          if &ft =~ 'javascript\|html\|css\|python\|sh\|c\|cpp\|markdown\|yaml\|vim\|nix'
              :set colorcolumn=120
          endif
      endfun

      augroup MaxLineWidth
          autocmd BufEnter * call ShowMaxLineWidth()
      augroup END

      " Indented folding
      " Modified from http://dhruvasagar.com/2013/03/28/vim-better-foldtext
      function! NeatFoldText()
          let indent_level = indent(v:foldstart)
          let indent = repeat(' ',indent_level)
          let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', \'\', 'g') . ' '
          let lines_count = v:foldend - v:foldstart + 1
          let lines_count_text = '-' . printf("%10s", lines_count . ' lines') . ' '
          let foldchar = matchstr(&fillchars, 'fold:\zs.')
          let foldtextstart = strpart('+' . repeat(foldchar, v:foldlevel*2) . line, 0, (winwidth(0)*2)/3)
          let foldtextend = lines_count_text . repeat(foldchar, 8)
          let foldtextlength = strlen(substitute(foldtextstart . foldtextend, '.', 'x', 'g')) + &foldcolumn
          return indent . foldtextstart . repeat(foldchar, winwidth(0)-foldtextlength) . foldtextend
      endfunction
      set foldtext=NeatFoldText()

      " -----------------------------------------------------
      " Backspace settings
      "   indent  allow backspacing over autoindent
      "   eol     allow backspacing over line breaks (join lines)
      "   start   allow backspacing over the start of insert; CTRL-W and CTRL-U
      "   0     same as ":set backspace=" (Vi compatible)
      "   1     same as ":set backspace=indent,eol"
      "   2     same as ":set backspace=indent,eol,start"
      " -----------------------------------------------------

      set bs=2

      " -----------------------------------------------------
      " Indentation  settings
      " -----------------------------------------------------

      set tabstop=4       " number of spaces a tab counts for
      set shiftwidth=4    " control how many columns text is indented with the reindent operations (<< and >>) and automatic C-style indentation.
      set expandtab       " Insert spaces when entering <Tab>
      set softtabstop=4   " Number of spaces that a <Tab> counts for while performing editing operations, like inserting a <Tab> or using <BS>.  It "feels" like a tab though
      set ai              " auto indent

      " -----------------------------------------------------
      " Spell checking
      " -----------------------------------------------------

      setlocal spell spelllang=en_us
      " Show nine spell checking candidates at most
      set spellsuggest=best,9

      augroup SpellCheck
          autocmd BufRead,BufNewFile *.txt setlocal spell
          autocmd BufRead,BufNewFile *.md setlocal spell
      augroup END

      " -----------------------------------------------------
      " Fold settings
      "
      "   fdm:
      "     manual     Folds are created manually.
      "     indent     Lines with equal indent form a fold.
      "     expr       'foldexpr' gives the fold level of a line.
      "     marker     Markers are used to specify folds.
      "     syntax     Syntax highlighting items specify folds.
      "     diff       Fold text that is not changed.
      " -----------------------------------------------------

      set fdm=marker
      "set foldmethod=indent
      "set foldlevelstart=0
      " javascript folding doesn't work very well with several levels of nested anonymous functions
      "let javaScript_fold=1         " JavaScript
      "let php_folding=1             " PHP
      let g:vim_markdown_folding_disabled=1

      " -----------------------------------------------------
      " Huge file handling
      " -----------------------------------------------------

      " disable syntax highlighting in big files
      function DisableSyntaxTreesitter()
          echo("Big file, disabling syntax, treesitter and folding")
          if exists(':TSBufDisable')
              exec 'TSBufDisable autotag'
              exec 'TSBufDisable highlight'
              " etc...
          endif

          set foldmethod=manual
          syntax clear
          syntax off    " hmmm, which one to use?
          filetype off
          set noundofile
          set noswapfile
          set noloadplugins
      endfunction

      augroup BigFileDisable
          autocmd!
          autocmd BufWinEnter * if getfsize(expand("%")) > 512 * 1024 | exec DisableSyntaxTreesitter() | endif
      augroup END

    ]])
  '';

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    plugins = with pkgs.vimPlugins; [

      # =======================
      # Dashboard / Pre-pended config
      # =======================

      {
        plugin = vim-startify;
      }

      # =======================
      # Indentation
      # =======================

      # set shiftwidth and expandtab automatically based on file or other files in the working directory
      {
        plugin = vim-sleuth;
      }

      # =======================
      # Ack
      # =======================

      {
        plugin = ack-vim;
        config = ''
          lua << EOF
          vim.g.ackprg = "ag --nocolor --nogroup --column"
          EOF
        '';
      }

      # =======================
      # Editor Config files
      # =======================

      {
        plugin = editorconfig-vim;
        config = ''
          lua << EOF
          vim.g.EditorConfig_exclude_patterns = { 'fugitive://.*' }
          EOF
        '';
      }

      # =======================
      # Maximize panes
      # =======================

      # @TODO: replace with https://github.com/anuvyklack/windows.nvim
      # nnoremap <silent><C-w>z :MaximizerToggle<CR>
      # vnoremap <silent><C-w>z :MaximizerToggle<CR>gv
      # inoremap <silent><C-w>z <C-o>:MaximizerToggle<CR>:w

      # =======================
      # File tree
      # =======================

      ## Check out:
      ##   https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes
      ##   https://github.com/nvim-tree/nvim-tree.lua/blob/master/doc/nvim-tree-lua.txt
      {
        plugin = nvim-tree-lua;
        config = ''
          lua << EOF

          -- disable netrw at the very start of your init.lua
          vim.g.loaded_netrw = 1
          vim.g.loaded_netrwPlugin = 1

          require("nvim-tree").setup({
            -- sort_by = "case_sensitive",
            disable_netrw = true,
            actions = {
              remove_file = {
                close_window = false,
              },
            },
            view = {
              mappings = {
               list = {
                 { key = "c", action = "copy_file_to", action_cb = copy_file_to },
               }
              },
            },
            -- Keep tree open if already open when opening a tab
            tab = {
              sync = {
                open = true,
                close = true,
              },
            },
            view = {
              width = 30,
            },
            renderer = {
              group_empty = true,
            },
            git = {
              enable = true,
              ignore = false,
              timeout = 500,
            }
            -- filters = {
            --   dotfiles = true,
            -- },
          })

          local function copy_file_to(node)
            local file_src = node['absolute_path']
            -- The args of input are {prompt}, {default}, {completion}
            -- Read in the new file path using the existing file's path as the baseline.
            local file_out = vim.fn.input("COPY TO: ", file_src, "file")
            -- Create any parent dirs as required
            local dir = vim.fn.fnamemodify(file_out, ":h")
            vim.fn.system { 'mkdir', '-p', dir }
            -- Copy the file
            vim.fn.system { 'cp', '-R', file_src, file_out }
          end

          -- SEE: https://github.com/nvim-tree/nvim-tree.lua/wiki/Auto-Close
          vim.api.nvim_create_autocmd("BufEnter", {
            group = vim.api.nvim_create_augroup("NvimTreeClose", {clear = true}),
            pattern = "NvimTree_*",
            callback = function()
              local layout = vim.api.nvim_call_function("winlayout", {})
              if layout[1] == "leaf" and vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(layout[2]), "filetype") == "NvimTree" and layout[3] == nil then vim.cmd("confirm quit") end
            end
          })

          vim.api.nvim_set_keymap('n', ',n', ':NvimTreeFindFile<CR>', {})
          vim.api.nvim_set_keymap('n', ',m', ':NvimTreeToggle<CR>', {})

          EOF
        '';
      }

      # =======================
      # Code commenting
      # =======================

      {
        plugin = comment-nvim;
        config = ''
          lua << EOF
          require('Comment').setup()
          EOF
        '';
      }

      # =======================
      # Argument splitting
      # =======================

      {
        plugin = vim-argwrap;
        config = ''
          lua << EOF
          vim.api.nvim_set_keymap('n', 'gs', ':ArgWrap<CR>', { noremap = true, silent = true })
          vim.g.argwrap_padded_braces = '[{'
          vim.g.argwrap_tail_comma_braces = '[{'
          -- vim.g.argwrap_tail_comma = 1
          -- vim.g.argwrap_tail_indent_braces = '('
          -- vim.g.argwrap_wrap_closing_brace = 0
          -- vim.g.argwrap_comma_first = 1
          -- vim.g.argwrap_comma_first_indent = 1
          EOF
        '';
      }

      # =======================
      # Code delimiters
      # =======================

      {
        plugin = nvim-autopairs;
        config = ''
          lua << EOF
          require("nvim-autopairs").setup {}
          EOF
        '';
      }

      {
        plugin = rainbow-delimiters-nvim;
        config = ''
          lua << EOF
          -- This module contains a number of default definitions
          local rainbow_delimiters = require 'rainbow-delimiters'

          vim.g.rainbow_delimiters = {
              strategy = {
                  ['''] = rainbow_delimiters.strategy['global'],
                  vim = rainbow_delimiters.strategy['local'],
              },
              query = {
                  ['''] = 'rainbow-delimiters',
                  lua = 'rainbow-blocks',
              },
              highlight = {
                  'RainbowDelimiterRed',
                  'RainbowDelimiterYellow',
                  'RainbowDelimiterBlue',
                  'RainbowDelimiterOrange',
                  'RainbowDelimiterGreen',
                  'RainbowDelimiterViolet',
                  'RainbowDelimiterCyan',
              },
          }
          EOF
        '';
      }

      # support surrounding tags (dst)
      # cs"'       - change double quotes to single quotes
      # cs'<q>     - change single quotes to html tags
      # ds"        - delete surrounding quotes
      # ysiw"      - surround word with double quotes
      # ys$"       - surround to end of line with double quotes
      # yss"       - surround entire sentence with quotes
      # S"         - surround visual selection with quotes
      {
        plugin = vim-surround;
        config = ''
        '';
      }

      # =======================
      # Diffing
      # =======================

      {
        plugin = vim-dirdiff;
        config = ''
          lua << EOF
          -- Not a vim-dirdiff setting, but put here with other diff config
          vim.opt.diffopt:append {'internal,algorithm:patience'}

          -- @TODO: Enable this with nvim 0.9
          vim.opt.diffopt:append {'linematch:60'}
          EOF
        '';
      }


      # =======================
      # Zellji
      # =======================

      # Integration with Zellij using hjkl navigation
      {
        plugin = zellij-nvim;
        config = ''
          lua << EOF

          require("zellij").setup({
            vimTmuxNavigatorKeybinds = true,
          })

          EOF
        '';
      }

      # =======================
      # Tmux
      # =======================

      # Integration with Tmux using hjkl navigation
      {
        plugin = vim-tmux-navigator;
        config = ''
          lua << EOF
          if (vim.fn.has("unix")) then
              local uname = vim.fn.system("uname -s"):gsub('\n', "")
              if (uname == "Darwin") then
                -- for some reason nvim doesn't map ctrl-h properly
                vim.api.nvim_set_keymap('n', '<bs>', ':<c-u>TmuxNavigateLeft<CR>', {})
            end
          end

          -- Allow navigating out of NERDTree pane
          -- Not using NERDTree, but keeping around just in case
          -- vim.g.NERDTreeMapJumpNextSibling = '<Nop>'
          -- vim.g.NERDTreeMapJumpPrevSibling = '<Nop>'
          EOF
        '';
      }

      ## Required by neogit
      {
        plugin = diffview-nvim;
        config = ''
          lua << EOF
          require("diffview").setup {}
          vim.keymap.set('n', ',d', function()
            if next(require('diffview.lib').views) == nil then
              vim.cmd('DiffviewOpen origin')
            else
              vim.cmd('DiffviewClose')
            end
          end)
          EOF
          '';
      }
      {
        plugin = vim-tmux-clipboard;
        config = ''
        '';
      }

      # =======================
      # Clipboard
      # =======================

      {
        plugin = vim-oscyank;
        config = ''
          lua << EOF
          -- This is a global option and not relatd to vim-oscyank
          vim.opt.clipboard:append {'unnamedplus'}

          vim.api.nvim_create_autocmd("TextYankPost", {
            command = "if v:event.operator is 'y' && v:event.regname is \'\' | execute 'OSCYankRegister \"' | endif",
          })
          EOF
        '';
      }

      # =======================
      # BufferLine
      # =======================

      {
        plugin = bufferline-nvim;
        config = ''
          lua << EOF
          require('bufferline').setup {
              options = {
                  tabpages = true,
                  sidebar_filetypes = {
                      NvimTree = true,
                  },
                  diagnostics = "nvim_lsp",
                  always_show_bufferline = true,
              },
              highlights = {
                  buffer_selected = {
                      -- fg = '#ffffff',
                      bold = true,
                  },
              },
          }

          vim.api.nvim_set_keymap('n', '<A-h>', ':BufferLineCyclePrev<CR>', { noremap = true, silent = true })
          vim.api.nvim_set_keymap('n', '<A-l>', ':BufferLineCycleNex<CR>', { noremap = true, silent = true })
          vim.api.nvim_set_keymap('n', '<A-c>', ':bdelete!<CR>', { noremap = true, silent = true })
          EOF
        '';
      }

      # =======================
      # Status line
      # =======================

      {
        plugin = lualine-lsp-progress;
        config = ''
          lua << EOF
          require('lualine').setup {
            options = { theme = 'gruvbox' },
            sections = {
              lualine_c = {
                'lsp_progress'
              }
            }
          }
          EOF
        '';
      }
      {
        plugin = lualine-nvim;
        config = ''
          lua << EOF

          local function path_option()
            if vim.o.columns > 78 then
              return 2
            else
              return 0
            end
          end

          require('lualine').setup {
            options = {
              theme = 'gruvbox',
            },
            sections = {
              lualine_c = {'filename'},
            }
          }
          EOF
        '';
      }

      # =======================
      # vim-orgmode
      # =======================

      # @TODO: Look at neorg

      {
        plugin = vim-speeddating;
        config = ''
        '';
      }

      {
        plugin = vim-orgmode;
        config = ''
          lua << EOF
          vim.g.org_heading_highlight_colors = {'Title', 'Constant', 'Identifier', 'Statement', 'PreProc', 'Type', 'Special'}
          vim.g.org_agenda_files = vim.fn.expand('~/Documents/org-mode/agenda.org')
          EOF
        '';
      }

      # =======================
      # Man page viewer
      # =======================

      {
        plugin = vim-manpager;
        config = ''
        '';
      }

      # =======================
      # todo.txt helper
      # =======================

      {
        plugin = todo-txt-vim;
        config = ''
        '';
      }

      # =======================
      # LSP/Code parsing
      # =======================

      {
        # Needs to be loaded before nvim-lspconfig
        plugin = cmp-nvim-lsp;
        config = ''
        '';
      }
      {
        # keybinding configured as <space>ca in nvim-lspconfig
        plugin = nvim-lightbulb;
        config = ''
          lua << EOF
          require('nvim-lightbulb').setup({
            float = {
              -- "true" causes "invalid buffer id" error
              enabled = false,
            },
            autocmd = {
              enabled = true,
            },
          })
          EOF
        '';
      }
      {
        plugin = nvim-lspconfig;
        config = ''
          lua << EOF
          local nvim_lsp = require "lspconfig"

          --Change diagnostic symbols in the sign column (gutter)
          local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
          for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
          end
          vim.diagnostic.config({
            virtual_text = true,          -- whether to show errors inline
            signs = true,                 -- whether to show error signs in gutter
            underline = true,
            update_in_insert = true,
            severity_sort = false,
          })

          local on_attach = function(client, bufnr)
            local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
            local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

            -- Enable completion triggered by <c-x><c-o>
            buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

            -- Mappings.
            local opts = { noremap=true, silent=true }

            -- See `:help vim.lsp.*` for documentation on any of the below functions
            buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
            buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
            buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
            buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
            buf_set_keymap('n', 'gk', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
            buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
            buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
            buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
            buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
            buf_set_keymap('n', '<space>r', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
            buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
            buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
            buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
            buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
            buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
            buf_set_keymap('n', ',k', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
            buf_set_keymap('n', ',j', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
            buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
            buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

            vim.api.nvim_create_autocmd("CursorHold", {
              buffer = bufnr,
              callback = function()
                local opts = {
                  focusable = false,
                  close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                  border = "rounded",
                  source = "always",
                  prefix = " ",
                  scope = "line",
                }
                vim.diagnostic.open_float(nil, opts)
              end,
            })
          end

          -- Use a loop to conveniently call 'setup' on multiple servers and
          -- map buffer local keybindings when the language server attaches

          -- This is a bit hacky as it loads another plugin
          local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

          local base_config = {
            on_attach = on_attach,
            flags = {
              debounce_text_changes = 150,
            },
            settings = {
              packageManager = "yarn"
            },
            capabilities = capabilities,
          }

          local servers = {
            'pyright',
            'nil_ls',
            -- Using nil_ls as main language server for nix
          }
          for _, lsp in ipairs(servers) do
            -- for servers with generic config
            nvim_lsp[lsp].setup(base_config)
          end

          -- -- Disabled nixd, using nil_ls above
          -- local configs = require 'lspconfig.configs'
          -- if not configs.nixd then
          --   configs.nixd = {
          --     default_config = {
          --       cmd = { 'nixd' },
          --       filetypes = { 'nix' },
          --       name = 'nixd',
          --       root_dir = nvim_lsp.util.root_pattern('.nixd.json', 'flake.nix', '.git'),
          --       single_file_support = true,
          --       settings = {}
          --     }
          --   }
          -- end
          -- nvim_lsp.nixd.setup(base_config)

          local tsserver_config = {
            on_attach = on_attach,
            flags = {
              debounce_text_changes = 150,
            },
            capabilities = capabilities,
            cmd = {
              "${pkgs.nodePackages.typescript-language-server}/bin/typescript-language-server",
              "--stdio",
            },
          }
          nvim_lsp.ts_ls.setup(tsserver_config)

          local vscode_servers = {'eslint', 'html' }
          for _, lsp in ipairs(vscode_servers) do
            -- local server_config = {table.unpack(base_config)}
            local server_config = {
              on_attach = on_attach,
              flags = {
                debounce_text_changes = 150,
              },
              settings = {
                packageManager = "yarn"
              },
              capabilities = capabilities,
              cmd = {
                "${pkgs.nodePackages.vscode-langservers-extracted}/bin/vscode-" .. lsp .. "-language-server",
                "--stdio",
              },
            }
            nvim_lsp[lsp].setup(server_config)
          end

          local cssls_config = {
            on_attach = on_attach,
            flags = {
              debounce_text_changes = 150,
            },
            capabilities = capabilities,
            cmd = {
              "${pkgs.nodePackages.vscode-langservers-extracted}/bin/vscode-css-language-server",
              "--stdio",
            },
          }
          nvim_lsp.cssls.setup(cssls_config)

          local jsonls_config = {
            on_attach = on_attach,
            flags = {
              debounce_text_changes = 150,
            },
            capabilities = capabilities,
            cmd = {
              "${pkgs.nodePackages.vscode-langservers-extracted}/bin/vscode-json-language-server",
              "--stdio",
            },
          }
          nvim_lsp.jsonls.setup(jsonls_config)

          EOF
        '';
      }
      {
        plugin = lsp_signature-nvim;
        config = ''
          lua << EOF
          require("lsp_signature").setup()
          EOF
        '';
      }

      # @TODO: Add incremental selection
      {
        # plugin = nvim-treesitter;
        plugin = nvim-treesitter.withAllGrammars;
        config = ''
          lua << EOF

          -- Need to disable treesitter for large JS files
          -- See: https://github.com/nvim-treesitter/nvim-treesitter/issues/2996

          local function treesitter_disable_func(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local js_max_filesize = 20 * 1024 -- 20 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and (stats.size > max_filesize or lang == 'js' and stats.size > js_max_filesize) then
              return true
            end
          end

          local function is_supported_func(lang)
            if vim.fn.strwidth(vim.fn.getline('.')) > 300
              or vim.fn.getfsize(vim.fn.expand('%')) > 100 * 1024 then
              return false
            else
              return true
            end
          end

          -- disable:       takes a list of languages that this module is disabled for. This is usually overridden by the user.
          --                can also take a function with (lang, buf) as params and returns true or false
          -- is_supported:  takes a function that takes a language and determines if this module supports that language.
          require 'nvim-treesitter.configs'.setup {
            indent = {
              enable = false,
              additional_vim_regex_highlighting = false,
              use_languagetree = false,
              disable = treesitter_disable_func,
              -- is_supported = is_supported_func,
            },

            highlight = {
              enable = false,
              additional_vim_regex_highlighting = false,
              use_languagetree = false,
              disable = treesitter_disable_func,
              -- is_supported = is_supported_func,
            },

            refactor = {
              highlight_definitions = {
                enable = false,
                disable = treesitter_disable_func,
                -- is_supported = is_supported_func,
              },
              highlight_current_scope = {
                enable = false,
                disable = treesitter_disable_func,
                -- is_supported = is_supported_func,
              },
              smart_rename = {
                enable = true,
                keymaps = {
                  -- smart_rename = "<space>r"
                }
              }
            },

            select = {
              enable = true,

              -- Automatically jump forward to textobj, similar to targets.vim
              lookahead = true,

              keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                -- You can optionally set descriptions to the mappings (used in the desc parameter of
                -- nvim_buf_set_keymap) which plugins like which-key display
                ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
                -- You can also use captures from other query groups like `locals.scm`
                ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
              },
              -- You can choose the select mode (default is charwise 'v')
              --
              -- Can also be a function which gets passed a table with the keys
              -- * query_string: eg '@function.inner'
              -- * method: eg 'v' or 'o'
              -- and should return the mode ('v', 'V', or '<c-v>') or a table
              -- mapping query_strings to modes.
              selection_modes = {
                ['@parameter.outer'] = 'v', -- charwise
                ['@function.outer'] = 'V', -- linewise
                ['@class.outer'] = '<c-v>', -- blockwise
              },
              -- If you set this to `true` (default is `false`) then any textobject is
              -- extended to include preceding or succeeding whitespace. Succeeding
              -- whitespace has priority in order to act similarly to eg the built-in
              -- `ap`.
              --
              -- Can also be a function which gets passed a table with the keys
              -- * query_string: eg '@function.inner'
              -- * selection_mode: eg 'v'
              -- and should return true of false
              include_surrounding_whitespace = true,
            },
          }
          EOF
        '';
      }
      # { plugin = nvim-treesitter-parsers.awk; }
      # { plugin = nvim-treesitter-parsers.c; }
      # { plugin = nvim-treesitter-parsers.cmake; }
      # { plugin = nvim-treesitter-parsers.comment; }
      # { plugin = nvim-treesitter-parsers.cpp; }
      # { plugin = nvim-treesitter-parsers.css; }
      # { plugin = nvim-treesitter-parsers.diff; }
      # { plugin = nvim-treesitter-parsers.dockerfile; }
      # { plugin = nvim-treesitter-parsers.git_config; }
      # { plugin = nvim-treesitter-parsers.git_rebase; }
      # { plugin = nvim-treesitter-parsers.gitattributes; }
      # { plugin = nvim-treesitter-parsers.gitcommit; }
      # { plugin = nvim-treesitter-parsers.gitignore; }
      # { plugin = nvim-treesitter-parsers.graphql; }
      # { plugin = nvim-treesitter-parsers.html; }
      # { plugin = nvim-treesitter-parsers.java; }
      # { plugin = nvim-treesitter-parsers.javascript; }
      # { plugin = nvim-treesitter-parsers.json; }
      # { plugin = nvim-treesitter-parsers.lua; }
      # { plugin = nvim-treesitter-parsers.luadoc; }
      # { plugin = nvim-treesitter-parsers.make; }
      # { plugin = nvim-treesitter-parsers.markdown; }
      # { plugin = nvim-treesitter-parsers.markdown_inline; }
      # { plugin = nvim-treesitter-parsers.nix; }
      # { plugin = nvim-treesitter-parsers.org; }
      # { plugin = nvim-treesitter-parsers.python; }
      # { plugin = nvim-treesitter-parsers.regex; }
      # { plugin = nvim-treesitter-parsers.tsx; }
      # { plugin = nvim-treesitter-parsers.typescript; }
      # { plugin = nvim-treesitter-parsers.vim; }
      # { plugin = nvim-treesitter-parsers.vimdoc; }
      # { plugin = nvim-treesitter-parsers.yaml; }

      {
        plugin = nvim-treesitter-context;
        config = ''
          lua << EOF
          require'treesitter-context'.setup{
            enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
            max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
            trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
            min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
            patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
              -- For all filetypes
              -- Note that setting an entry here replaces all other patterns for this entry.
              -- By setting the 'default' entry below, you can control which nodes you want to
              -- appear in the context window.
              default = {
                'class',
                'function',
                'method',
                'for',
                'while',
                'if',
                'switch',
                'case',
                'interface',
                'struct',
                'enum',
              },
              -- Patterns for specific filetypes
              -- If a pattern is missing, *open a PR* so everyone can benefit.
              tex = {
                'chapter',
                'section',
                'subsection',
                'subsubsection',
              },
              haskell = {
                'adt'
              },
              rust = {
                'impl_item',
              },
              terraform = {
                'block',
                'object_elem',
                'attribute',
              },
              scala = {
                'object_definition',
              },
              vhdl = {
                'process_statement',
                'architecture_body',
                'entity_declaration',
              },
              markdown = {
                'section',
              },
              elixir = {
                'anonymous_function',
                'arguments',
                'block',
                'do_block',
                'list',
                'map',
                'tuple',
                'quoted_content',
              },
              json = {
                'pair',
              },
              typescript = {
                'export_statement',
              },
              yaml = {
                'block_mapping_pair',
              },
            },
            exact_patterns = {
                -- Example for a specific filetype with Lua patterns
                -- Treat patterns.rust as a Lua pattern (i.e "^impl_item$" will
                -- exactly match "impl_item" only)
                -- rust = true,
            },

            -- [!] The options below are exposed but shouldn't require your attention,
            --     you can safely ignore them.

            zindex = 20, -- The Z-index of the context window
            mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
            -- Separator between context and content. Should be a single character string, like '-'.
            -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
            separator = nil,
          }
          EOF
        '';
      }

      {
        plugin = nvim-treesitter-refactor;
        config = ''
        '';
      }

      {
        plugin = trouble-nvim;
        config = ''
          lua << EOF
          require 'trouble'.setup {
          }
          EOF
        '';
      }

      {
        plugin = vim-nix;
        config = ''
        '';
      }

      {
        plugin = fzf-lsp-nvim;
        config = ''
        '';
      }

      ## Required by neogit
      {
        plugin = fzf-lua;
        config = ''
        '';
      }

      # {
      #   # plugin = pkgs.unstable.vimPlugins.sg-nvim;
      #   plugin = inputs.sg-nvim.packages.${pkgs.system}.sg-nvim;
      #   config = ''
      #     lua << EOF

      #     require("sg").setup {
      #       use_cody = true,
      #       -- token = '***REMOVED***',
      #       -- user = '***REMOVED***',
      #       accept_tos = true,
      #       tos_accepted = true,
      #       endpoint = 'https://sourcegraph.netflix.net',
      #     }
      #     vim.keymap.set('n', '<leader>cs', require('sg.extensions.telescope').fuzzy_search_results, { noremap = true, desc = 'cody search' })
      #     -- vim.api.nvim_set_keymap('n', '<leader>cs', require('sg.extensions.telescope').fuzzy_search_results, { noremap = true, desc = 'cody search'})
      #     -- vim.api.nvim_set_keymap('n', '<leader>cc', [[<cmd>CodyToggle<CR>]], { noremap = true, desc = 'CodyChat'})
      #     -- vim.api.nvim_set_keymap('v', '<leader>cc', [[:CodyAsk ]], { noremap = true, desc = 'CodyAsk'})
      #     vim.api.nvim_set_keymap('n', '<leader>cc', '<cmd>CodyToggle<CR>', { noremap = true, desc = 'CodyChat'})
      #     vim.api.nvim_set_keymap('v', '<leader>cc', ':CodyAsk', { noremap = true, desc = 'CodyAsk'})

      #     EOF
      #   '';
      # }

      # =======================
      # Fuzzy finding
      # (Should be loaded after LSP)
      # =======================

      # plenary is a generic lua lib used by telescope.nvim and neogit
      {
        plugin = plenary-nvim;
        config = ''
        '';
      }
      # Used by telescope.nvim
      {
        plugin = telescope-ui-select-nvim;
        config = ''
        '';
      }

      {
        plugin = telescope-nvim;
        config = ''
          lua << EOF

          -- Must be loaded after telescope
          local actions = require("telescope.actions")
          local trouble = require("trouble.sources.telescope")

          require("telescope").setup({
              defaults = {
                  mappings = {
                      i = {
                          -- One instead of two esc taps to exit telescope
                          ["<esc>"] = actions.close,

                          -- Ctrl-space is used by Tmux, so remap to Ctrl-e
                          ["<c-e>"] = actions.to_fuzzy_refine,

                          ["<c-o>"] = trouble.open,
                      },
                      n = {
                        ["<c-o>"] = trouble.open,
                      },
                  },
              },
              extensions = {
                  ["ui-select"] = {
                      require("telescope.themes").get_dropdown {
                          -- even more opts
                      }
                  }
              }
          })

          require("telescope").load_extension("ui-select")

          -- Lists files in your current working directory, respects .gitignore
          vim.api.nvim_set_keymap('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { noremap = true })
          vim.api.nvim_set_keymap('n', '<c-p>', '<cmd>Telescope find_files<cr>', { noremap = true })
          -- Search for a string in your current working directory and get results live as you type, respects .gitignore. (Requires ripgrep)
          vim.api.nvim_set_keymap('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', { noremap = true })
          vim.api.nvim_set_keymap('n', '<c-s>', '<cmd>Telescope live_grep<cr>', { noremap = true })
          -- Lists open buffers in current neovim instance
          vim.api.nvim_set_keymap('n', '<leader>fb', '<cmd>Telescope buffers<cr>', { noremap = true })
          -- Lists available help tags and opens a new window with the relevant help info on <cr>
          vim.api.nvim_set_keymap('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', { noremap = true })
          -- Lists manpage entries, opens them in a help window on <cr>
          vim.api.nvim_set_keymap('n', '<leader>fm', '<cmd>Telescope man_pages<cr>', { noremap = true })
          -- Lists previously open files
          vim.api.nvim_set_keymap('n', '<leader>fp', '<cmd>Telescope oldfiles<cr>', { noremap = true })
          -- Maps to ctrl-/
          vim.api.nvim_set_keymap('n', '<c-_>', '<cmd>Telescope oldfiles<cr>', { noremap = true })
          -- Lists spelling suggestions for the current word under the cursor, replaces word with selected suggestion on <cr>
          vim.api.nvim_set_keymap('n', '<leader>fs', '<cmd>Telescope spell_suggest<cr>', { noremap = true })
          -- Lists LSP references for iword under the cursor
          vim.api.nvim_set_keymap('n', '<leader>fr', '<cmd>Telescope lsp_references<cr>', { noremap = true })
          -- Lists LSP incoming calls for word under the cursor
          vim.api.nvim_set_keymap('n', '<leader>fi', '<cmd>Telescope lsp_incoming_calls<cr>', { noremap = true })
          -- Lists LSP outgoing calls for word under the cursor
          vim.api.nvim_set_keymap('n', '<leader>fo', '<cmd>Telescope lsp_outgoing_calls<cr>', { noremap = true })
          -- Dynamically Lists LSP for all workspace symbols
          vim.api.nvim_set_keymap('n', '<leader>fw', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', { noremap = true })
          -- Goto the definition of the word under the cursor, if there's only one, otherwise show all options in Telescope
          vim.api.nvim_set_keymap('n', '<leader>fd', '<cmd>Telescope lsp_definitions<cr>', { noremap = true })
          -- Other options:
          -- git_files     search only files in git, respects .gitignore
          -- oldfiles      previously opened files
          -- command_history
          -- search_history
          -- man_pages
          -- resume        lists the results including multi-selections of the previous
          -- picker

          EOF
        '';
      }

      # =======================
      # Completion
      # =======================

      {
        plugin = nvim-cmp;
        config = ''
          lua << EOF

          -- Not specifically nvim-cmp configuration
          vim.opt.completeopt = "menuone,noselect"
          -- vim.opt.completeopt = "menu,menuone,noselect"

          local cmp = require'cmp'

          local select_opts = {behavior = cmp.SelectBehavior.Select}

          local kind_icons = {
            Text = "󰊄",
            Method = "",
            Function = "󰡱",
            Constructor = "",
            Field = "",
            Variable = "󱀍",
            Class = "",
            Interface = "",
            Module = "󰕳",
            Property = "",
            Unit = "",
            Value = "",
            Enum = "",
            Keyword = "",
            Snippet = "",
            Color = "",
            File = "",
            Reference = "",
            Folder = "",
            EnumMember = "",
            Constant = "",
            Struct = "",
            Event = "",
            Operator = "",
            TypeParameter = "",
          }

          cmp.setup({
            snippet = {
              -- REQUIRED - you must specify a snippet engine
              expand = function(args)
                -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
                require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
              end,
            },
            mapping = {
              ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
              ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
              -- Don't override as it conflicts with filtered searching with telescope
              -- ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
              ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
              ['<C-e>'] = cmp.mapping({
                i = cmp.mapping.abort(),
                c = cmp.mapping.close(),
              }),
              -- Cr is too annoying when not wanting to autocomplete at the end of a line
              -- ['<Cr>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
              ['<Tab>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
              ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
              ['<C-n>'] = cmp.mapping.select_next_item(select_opts),
            },
            formatting = {
              fields = { "kind", "abbr", "menu" },
              format = function(entry, vim_item)
              vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
              vim_item.menu = ({
                path = "[Path]",
                nvim_lua = "[NVIM_LUA]",
                nvim_lsp = "[LSP]",
                luasnip = "[Snippet]",
                buffer = "[Buffer]",
              })[entry.source.name]
              return vim_item
              end,
            },
            sources = cmp.config.sources({
              { name = 'path' },
              { name = 'nvim_lua' },
              { name = 'nvim_lsp' },
              { name = 'buffer' },
              -- { name = 'vsnip' }, -- For vsnip users.
              { name = 'luasnip' }, -- For luasnip users.
              -- { name = 'ultisnips' }, -- For ultisnips users.
              -- { name = 'snippy' }, -- For snippy users.
            })
          })

          -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
          cmp.setup.cmdline('/', {
            sources = {
              { name = 'buffer' }
            }
          })

          -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
          cmp.setup.cmdline(':', {
            sources = cmp.config.sources({
              { name = 'path' }
            }, {
              { name = 'cmdline' }
            })
          })
          EOF
        '';
      }

      {
        plugin = cmp-buffer;
        config = ''
        '';
      }

      {
        plugin = cmp-path;
        config = ''
        '';
      }

      {
        plugin = cmp-cmdline;
        config = ''
        '';
      }

      {
        plugin = cmp-copilot;
        config = ''
        '';
      }

      {
        plugin = cmp-git;
        config = ''
        '';
      }

      {
        plugin = cmp-tmux;
        config = ''
        '';
      }

      {
        plugin = cmp-treesitter;
        config = ''
        '';
      }

      {
        plugin = cmp-zsh;
        config = ''
        '';
      }

      # =======================
      # Snippets
      # =======================

      {
        plugin = cmp-vsnip;
        config = ''
        '';
      }

      {
        plugin = vim-vsnip;
        config = ''
        '';
      }

      {
        plugin = luasnip;
        config = ''
        '';
      }

      ## Disabled as it slows editing significantly
      # {
      #   plugin = ultisnips;
      #   config = ''
      #   '';
      # }

      {
        plugin = friendly-snippets;
        config = ''
        '';
      }

      {
        plugin = vim-snippets;
        config = ''
        '';
      }

      # =======================
      # Debugging
      # =======================

      {
        plugin = nvim-dap;
        config = ''
        '';
      }

      {
        plugin = nvim-dap-ui;
        config = ''
        '';
      }

      {
        plugin = nvim-dap-virtual-text;
        config = ''
        '';
      }

      # =======================
      # Terminal
      # =======================

      {
        plugin = nvim-terminal-lua;
        config = ''
        '';
      }

      # =======================
      # VCS Support
      # =======================

      # Git wrapper
      # :G<command> or :Git <command>    - run a git command
      {
        plugin = vim-fugitive;
        config = ''
        '';
      }

      {
        plugin = gitsigns-nvim;
        config = ''
          lua << EOF
          require('gitsigns').setup {
          }
          EOF
        '';
      }

      # Git branch viewer
      # :Flog or :Flogsplit       - open viewer (all commands below only work in viewer)
      #       <C-N> and <C-P>     - jump between commits
      #       u                   - refresh graph
      #       a                   - toggle all branches
      #       gb                  - toggle bisect mode
      #       gm                  - toggle displaying no merges
      #       gr                  - toggle reflog
      #       gq                  - quit
      #       g?                  - help
      {
        plugin = vim-flog;
        config = ''
        '';
      }

      # Visual Git management
      # {
      #   plugin = vim-twiggy;
      #   config = ''
      #     lua << EOF
      #     vim.api.nvim_set_keymap('n', '<c-g>', ':Twiggy<CR>', { noremap = true })
      #     EOF
      #   '';
      # }

      ## Git management
      ## Currently broken
      # {
      #   plugin = pkgs.vimPlugins.neogit;
      #   config = ''
      #     lua << EOF
      #     local neogit = require("neogit")
      #     neogit.setup {}
      #     vim.api.nvim_set_keymap('n', '<c-g>', ':Neogit<CR>', { noremap = true })
      #     vim.api.nvim_set_keymap("", '<leader>gg', ':Neogit<CR>', { noremap = true })
      #     EOF
      #   '';
      # }

      # Show diff marks
      {
        plugin = vim-signify;
        config = ''
          lua << EOF
          vim.g.signify_vcs_cmds = {
              git = "git diff --no-color --no-ext-diff -U0 master -- %f",
          }
          vim.g.signify_priority = 1
          vim.cmd[[highlight SignColumn ctermbg=237]]
          EOF
        '';
      }

      # Magit
      # :Magit            - open
      # <C-n> an <C-p>    - jump between hunks
      # S                 - stage a hunk
      # CC                - commit staged hunks
      # CC or :w          - finalize commit
      {
        plugin = vimagit;
        config = ''
        '';
      }

      # =======================
      # Icons
      # =======================

      {
        plugin = nvim-web-devicons;
        config = ''
          lua << EOF
          require('nvim-web-devicons').setup {
            -- globally enable default icons (default to false)
            -- will get overriden by `get_icons` option
            default = true;
          }
          EOF
        '';
      }

      # =======================
      # Custom unsupported plugins
      # =======================

      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "ghopen";
          src = pkgs.fetchFromGitHub {
            owner = "amjith";
            repo = "ghopen.nvim";
            rev = "97d3a5da2ac27bdbd2aae275625bd9f2b653e0d9";
            sha256 = "sha256-63tCRtwvtC84q67jKGhQreu0GK8jSio32LF7I1D7mkM=";
          };
        };
        config = ''
          lua << EOF
          require('ghopen').setup { }
          vim.api.nvim_set_keymap('n', 'go', ':Ghopen<CR>', { noremap = true })
          EOF
        '';
      }

      # {
      #   plugin = let kui-nvim-plugin = pkgs.vimUtils.buildVimPlugin {
      #     name = "kui-nvim-plugin";
      #     src = pkgs.fetchFromGitHub {
      #       owner = "romgrk";
      #       repo = "kui.nvim";
      #       rev = "ac04753b03b0b5e13c2b4ba858b88611d3f02834";
      #       sha256 = "1830q9p51xzn4i5p4ma1m0r08c9lyiglndxlzszxipl6mfzn08v7";
      #     };
      #     buildInputs = [ pkgs.cairo ];
      #     extraPackages = [
      #       pkgs.cairo
      #     ];
      #   }; in pkgs.buildFHSUserEnv {
      #     # @TODO: There has to be a better way of including runtime dependencies here
      #     # buildFHSUserEnv is too crude
      #     # Some say makeWrapper better for runtime dependencies
      #     name = "kui-nvim";
      #     targetPkgs = pkgs: with pkgs; [
      #       cairo
      #       kui-nvim-plugin
      #     ];
      #   };
      #
      #   config = ''
      #   '';
      # }
      #
      # {
      #   plugin = pkgs.vimUtils.buildVimPlugin {
      #     name = "fzy-lua-native";
      #     src = pkgs.fetchFromGitHub {
      #       owner = "romgrk";
      #       repo = "fzy-lua-native";
      #       rev = "820f745b7c442176bcc243e8f38ef4b985febfaf";
      #       sha256 = "1zhrql0ym0l24jvdjbz6qsf6j896cklazgksssa384gfd8s33bi5";
      #     };
      #
      #     buildPhase = ''
      #       make
      #     '';
      #
      #   };
      #
      #   config = ''
      #   '';
      # }
      #
      # {
      #   plugin = pkgs.vimUtils.buildVimPlugin {
      #     name = "kirby-nvim";
      #     src = pkgs.fetchFromGitHub {
      #       owner = "romgrk";
      #       repo = "kirby.nvim";
      #       rev = "6069b141f7ef6a33fa9f649fea1208b3c33581bf";
      #       sha256 = "0cbkb1dbbi3ir41yva517sk4q4hil0px7b40hp2jqn7fq6l2ygz6";
      #     };
      #   };
      #
      #   config = ''
      #     lua << EOF
      #     local kirby = require('kirby')
      #
      #     kirby.register({
      #       id = 'git-branch',
      #       name = 'Git checkout',
      #       values = function() return vim.fn['fugitive#CompleteObject']("", ' ', "") end,
      #       onAccept = 'Git checkout',
      #     })
      #
      #     kirby.register({
      #       id = 'session',
      #       name = 'Open session',
      #       values = function() return vim.fn['xolox#session#complete_names']("", 'OpenSession ', 0) end,
      #       onAccept = 'OpenSession',
      #     })
      #
      #     kirby.register({
      #       id = 'note',
      #       name = 'Open note',
      #       values = function() return vim.fn['xolox#notes#cmd_complete']("", 'Note ', 0) end,
      #       onAccept = 'Note',
      #     })
      #     EOF
      #   '';
      # }
      #
    ];
    # ripgrep, silver-searcher and fd is needed for fzf
    extraPackages = with pkgs; [
      ripgrep
      silver-searcher
      git
      fd

      nodejs
      nodePackages.eslint
      nodePackages.prettier
      # nodePackages.neovim
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
    ];
  };
}
