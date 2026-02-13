# Changelog

## 2026-02-13

- Integrations: replace stale Signal docs link with canonical OpenClaw channel docs URL (#44, thanks @deftdawg).
- Docs: rename README references from old Molt/Clawd names to OpenClaw/openclaw.ai and update Discord invite branding link (#57, thanks @knocte).
- Installer: preinstall Linux native build toolchain before NodeSource setup to reduce npm native-module failures (`make`, `g++`, `cmake`, `python3`) (#45, thanks @wtfloris).
- Installer: auto-detect missing native build toolchain from npm logs, attempt OS-specific install, and retry package install instead of failing early (#49, thanks @knocte).
- Installer: render gum choose header on two lines (real newline, not literal `\n`) for checkout detection prompt (#55, thanks @echoja).
- Showcase: switch to masonry-style multi-column layout with cross-browser card split protection (#42, thanks @reidsolon).

## 2026-02-10

- Installer: modernize `install.sh` UX with staged progress, quieter command output, optional gum UI controls (`--gum`, `--no-gum`, `OPENCLAW_USE_GUM`, `CLAWDBOT_USE_GUM`), and verified-only temporary gum bootstrap (#50, thanks @sebslight).
- CI: add Linux installer matrix workflow and runner script for dry-run/full validation across distro images (#50, thanks @sebslight).

## 2026-01-27

- Home page: keep testimonial links clickable while skipping keyboard focus (#18, thanks @wilfriedladenhauf).
- Fonts: preconnect to Fontshare API/CDN for faster font loading (#16, thanks @wilfriedladenhauf).
- CLI installer: support git-based installs with safer repo directory handling (#17, thanks @travisp).
- Installer: skip sudo usage when running as root (#12, thanks @Glucksberg).
- Integrations: update Microsoft Teams docs link to the channels page (#9, thanks @HesamKorki).
- Integrations: fix Signal documentation link (#13, thanks @RayBB).

## 2026-01-16

- `install.sh`: warn when the user's original shell `PATH` likely won't find the installed `openclaw` binary (common Node/npm global bin issues); link to docs.
- CI: add lightweight unit tests for `install.sh` path resolution.
