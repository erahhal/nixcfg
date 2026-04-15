{ ... }:
{
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
        "presentation@nflx-skills"
        "https://github.netflix.net/corp/nflx-skills/blob/main/.generator/output/platform-engineering/developer-enablement/skills/presentation/SKILL.md"
        # "https://github.netflix.net/corp/prod-sci-dse-templates/blob/main/ajaishankar/skills/create-presentation/SKILL.md"
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
    };
  };
}
