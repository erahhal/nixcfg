{ config, inputs, userParams, ... }:
{
  home-manager.users.${userParams.username}.programs = {
    zathura.extraConfig = builtins.readFile (config.scheme inputs.base16-zathura);

    # neovim = {
    #   plugins = [ (pkgs.vimPlugins.base16-vim.overrideAttrs (old:
    #     let schemeFile = config.scheme inputs.base16-vim;
    #     in { patchPhase = ''cp ${schemeFile} colors/base16-scheme.vim''; }
    #   )) ];
    #   extraConfig = ''
    #     set termguicolors
    #     colorscheme base16-scheme
    #     set background=dark
    #     let base16colorspace=256
    #   '';
    # };

    alacritty.settings.colors = with config.scheme.withHashtag;
    let
    default = {
      black = base00; white = base07;
      inherit red green yellow blue cyan magenta;
    };
    in
    {
      primary = { background = base00; foreground = base07; };
      cursor = { text = base02; cursor = base07; };
      normal = default; bright = default; dim = default;
    };
  };
}
