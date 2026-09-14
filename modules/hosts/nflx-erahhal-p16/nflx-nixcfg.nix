{ ... }:
{
  # nixpkgs removed the unversioned `cairomm` attribute (2026-08-28; it now
  # throws, pointing at the `cairomm_*` ABI-versioned attrs), but
  # nflx-nixcfg's pulse-official client.nix still takes plain `cairomm` as a
  # callPackage arg. Resurrect it as cairomm_1_0 -- the same 1.14.x/ABI-1.0
  # series the old attribute resolved to, and the ABI the Pulse blob links
  # against. Drop this once nflx-nixcfg asks for cairomm_1_0 itself.
  nixpkgs.overlays = [
    (final: prev: {
      cairomm = final.cairomm_1_0;
    })
  ];

  nflx = {
    username = "erahhal";
    ssh-agent.enable = true;
    system = {
      enable-systemd-resolved = true;
    };
    development = {
      java.enable = true;
      workspaces.disable-workspace-id-warning = true;
    };
    genai = {
      project-id = "erahhaldevtools";
      enable-experimental-claude-optimizations = true;
      stride = {
        enable = true;
        workspace.name = "erahhal-stride";
        timezone = "America/Los_Angeles";
        model = "sonnet";
      };
      skills = [
        "*@dx-ai-context"
        "*@ngp-skills"
        "frontend-design@claude-plugins-official"
        "https://github.netflix.net/corp/prod-sci-dse-templates/blob/main/templates/skills/create-presentation/SKILL.md"
        "https://github.netflix.net/cdhanaraj/discovery-agent/blob/main/.claude/skills/find-tables/SKILL.md"
      ];
      gitSkills = [
        {
          url  = "https://github.netflix.net/cdhanaraj/discovery-agent.git";
          path = ".claude/skills/find-tables";
        }
      ];
    };
    vpn.pulse = {
      disable-url-warning = true;
      disable-nm-applet-warning = true;
      disable-desktop-browser-auth = false;
    };

    vpn.pulse-official.enable = true;
  };
}
