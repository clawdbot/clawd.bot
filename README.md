# openclaw.ai

Landing page for [OpenClaw](https://github.com/openclaw/openclaw) — your personal AI assistant.

**Live**: [openclaw.ai](https://openclaw.ai)

## Pages

- `/` — Main landing page with Quick Start, features, and testimonials
- `/integrations` — Visual grid of all supported chat providers, AI models, platforms, and tools
- `/shoutouts` — Community testimonials and mentions

## Tech Stack

- [Astro](https://astro.build/) — Static site generator
- GitHub Pages — Hosting
- Custom CSS — No framework, just vibes

## Development

```bash
bun install
bun run dev
```

## Build

```bash
bun run build
bun run preview
```

## Deploy

Automatically deployed to GitHub Pages on push to `main`.

## Install Scripts

The landing page hosts installer scripts:

- **macOS/Linux**: `curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash`
- **macOS/Linux (CLI only, no onboarding)**: `curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash`
- **Windows**: `iwr -useb https://openclaw.ai/install.ps1 | iex`

Installer UI controls (macOS/Linux `install.sh`):
- Pass `--gum` to force gum UI when supported, or `--no-gum` to disable gum output.
- Set `OPENCLAW_USE_GUM=auto|1|0` to control gum behavior in automation.
- Compatibility alias: `CLAWDBOT_USE_GUM` (mapped to `OPENCLAW_USE_GUM`).

These scripts:
1. Install Homebrew (macOS) or detect package managers (Windows)
2. Install Node.js 22+ if needed
3. Install openclaw globally via npm
4. Run `openclaw doctor --non-interactive` for migrations (upgrades only)
5. Prompt to run `openclaw onboard` (new installs)

## Related

- [OpenClaw](https://github.com/openclaw/openclaw) — Main repository
- [Docs](https://docs.openclaw.ai) — Documentation
- [Discord](https://discord.gg/openclaw) — Community
