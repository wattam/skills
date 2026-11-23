# Skills

A collection of agent skills grouped into categories. Each skill is user-invoked only (`disable-model-invocation: true`). Invoke them as slash commands, e.g. `/spec`, `/init-agents-md`.

Each skill is a folder whose only file is `SKILL.md` — the full instructions the agent follows when you invoke it. To change a skill's behavior, edit its markdown.

## Installation

On macOS or Linux:

```bash
./install-skills.sh
```

On Windows, run from PowerShell:

```powershell
.\install-skills.ps1
```

Both scripts copy skills directly into Pi’s skills directory: `~/.pi/agent/skills` on macOS or Linux, or `%USERPROFILE%\.pi\agent\skills` on Windows. If `PI_CODING_AGENT_DIR` is set, they copy into its `skills` subdirectory. They do not install into shared directories or other agents.

Re-run the relevant script after editing a skill to pick up changes. Both installers remove the retired Dagu launcher from the target skills directory.

## Categories

Each category has its own `README.md` (usage) and `AGENTS.md` (authoring conventions):

- **`development-pipeline/`** — skills that form one feature-development workflow (spec → plan → test → cross-check → implement → review → address-review). See `development-pipeline/README.md`.
- **`dagu/`** — a [Dagu](https://docs.dagu.sh/) workflow that runs the pipeline unattended with Pi. Its `skills/` folder holds unattended copies of the `development-pipeline` skills and `pi-dagu-pipeline`, which starts a run and relays questions to you. The stage copies never ask questions directly; they end `blocked` instead. See `dagu/README.md`.
- **`utility/`** — standalone skills, each doing one self-contained job. See `utility/README.md`.

See `AGENTS.md` for the conventions shared across every skill.

## License

This repository is licensed under the [MIT License](LICENSE).
