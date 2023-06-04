{ pkgs, ... }:

let weechat-configured = self: super: {
  weechat = super.weechat.override {
    configure = { availablePlugins, ... }: {
      scripts = with super.weechatScripts; [
        # weechat-otr
        # wee-slack
      ];
    };
  };
};
in
{
  nixpkgs.overlays = [ weechat-configured ];
}
