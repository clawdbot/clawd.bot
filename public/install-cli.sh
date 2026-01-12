#!/usr/bin/env bash
set -euo pipefail

# Clawdbot CLI installer (non-interactive, no onboarding)
# Usage: curl -fsSL https://clawd.bot/install-cli.sh | bash -s -- [--json] [--prefix <path>] [--version <ver>] [--node-version <ver>] [--onboard]

PREFIX="${CLAWDBOT_PREFIX:-${HOME}/.clawdbot}"
CLAWDBOT_VERSION="${CLAWDBOT_VERSION:-latest}"
NODE_VERSION="${CLAWDBOT_NODE_VERSION:-22.12.0}"
SHARP_IGNORE_GLOBAL_LIBVIPS="${SHARP_IGNORE_GLOBAL_LIBVIPS:-1}"
JSON=0
RUN_ONBOARD=0
SET_NPM_PREFIX=0

print_usage() {
  cat <<EOF
Usage: install-cli.sh [options]
  --json                Emit NDJSON events (no human output)
  --prefix <path>        Install prefix (default: ~/.clawdbot)
  --version <ver>        Clawdbot version (default: latest)
  --node-version <ver>   Node version (default: 22.12.0)
  --onboard              Run "clawdbot onboard" after install
  --no-onboard           Skip onboarding (default)
  --set-npm-prefix       Force npm prefix to ~/.npm-global if current prefix is not writable (Linux)

Environment variables:
  SHARP_IGNORE_GLOBAL_LIBVIPS=0|1    Default: 1 (avoid sharp building against global libvips)
EOF
}

log() {
  if [[ "$JSON" -eq 0 ]]; then
    echo "$@"
  fi
}

emit_json() {
  if [[ "$JSON" -eq 1 ]]; then
    printf '%s\n' "$1"
  fi
}

fail() {
  local msg="$1"
  emit_json "{\"event\":\"error\",\"message\":\"${msg//\"/\\\"}\"}"
  log "ERROR: $msg"
  exit 1
}

require_bin() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    fail "Missing required binary: $name"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        JSON=1
        shift
        ;;
      --prefix)
        PREFIX="$2"
        shift 2
        ;;
      --version)
        CLAWDBOT_VERSION="$2"
        shift 2
        ;;
      --node-version)
        NODE_VERSION="$2"
        shift 2
        ;;
      --onboard)
        RUN_ONBOARD=1
        shift
        ;;
      --no-onboard)
        RUN_ONBOARD=0
        shift
        ;;
      --help|-h)
        print_usage
        exit 0
        ;;
      --set-npm-prefix)
        SET_NPM_PREFIX=1
        shift
        ;;
      *)
        fail "Unknown option: $1"
        ;;
    esac
  done
}

os_detect() {
  local os
  os="$(uname -s)"
  case "$os" in
    Darwin) echo "darwin" ;;
    Linux) echo "linux" ;;
    *) fail "Unsupported OS: $os" ;;
  esac
}

arch_detect() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64) echo "x64" ;;
    *) fail "Unsupported architecture: $arch" ;;
  esac
}

node_dir() {
  echo "${PREFIX}/tools/node-v${NODE_VERSION}"
}

node_bin() {
  echo "$(node_dir)/bin/node"
}

npm_bin() {
  echo "$(node_dir)/bin/npm"
}

install_node() {
  local os
  local arch
  local url
  local tmp
  local dir
  local current_major

  os="$(os_detect)"
  arch="$(arch_detect)"
  dir="$(node_dir)"

  if [[ -x "$(node_bin)" ]]; then
    current_major="$("$(node_bin)" -v 2>/dev/null | tr -d 'v' | cut -d'.' -f1 || echo "")"
    if [[ -n "$current_major" && "$current_major" -ge 22 ]]; then
      emit_json "{\"event\":\"step\",\"name\":\"node\",\"status\":\"skip\",\"path\":\"${dir//\"/\\\\\\\"}\"}"
      return
    fi
  fi

  emit_json "{\"event\":\"step\",\"name\":\"node\",\"status\":\"start\",\"version\":\"${NODE_VERSION}\"}"
  log "Installing Node ${NODE_VERSION} (user-space)..."

  mkdir -p "${PREFIX}/tools"
  tmp="$(mktemp -d)"
  url="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${os}-${arch}.tar.gz"

  require_bin curl
  require_bin tar

  curl -fsSL "$url" -o "$tmp/node.tgz"
  rm -rf "$dir"
  mkdir -p "$dir"
  tar -xzf "$tmp/node.tgz" -C "$dir" --strip-components=1
  rm -rf "$tmp"

  ln -sfn "$dir" "${PREFIX}/tools/node"
  emit_json "{\"event\":\"step\",\"name\":\"node\",\"status\":\"ok\",\"version\":\"${NODE_VERSION}\"}"
}

fix_npm_prefix_if_needed() {
  # only meaningful on Linux, non-root installs
  if [[ "$(os_detect)" != "linux" ]]; then
    return
  fi

  local prefix
  prefix="$("$(npm_bin)" config get prefix 2>/dev/null || true)"
  if [[ -z "$prefix" ]]; then
    return
  fi

  if [[ -w "$prefix" || -w "${prefix}/lib" ]]; then
    return
  fi

  local target="${HOME}/.npm-global"
  mkdir -p "$target"
  "$(npm_bin)" config set prefix "$target"

  local path_line="export PATH=\\\"${target}/bin:\\$PATH\\\""
  for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    if [[ -f "$rc" ]] && ! grep -q ".npm-global" "$rc"; then
      echo "$path_line" >> "$rc"
    fi
  done

  export PATH="${target}/bin:${PATH}"
  emit_json "{\"event\":\"step\",\"name\":\"npm-prefix\",\"status\":\"ok\",\"prefix\":\"${target//\"/\\\"}\"}"
  log "Configured npm prefix to ${target}"
}

install_clawdbot() {
  emit_json "{\"event\":\"step\",\"name\":\"clawdbot\",\"status\":\"start\",\"version\":\"${CLAWDBOT_VERSION}\"}"
  log "Installing Clawdbot (${CLAWDBOT_VERSION})..."
  if [[ "$SET_NPM_PREFIX" -eq 1 ]]; then
    fix_npm_prefix_if_needed
  fi
  SHARP_IGNORE_GLOBAL_LIBVIPS="$SHARP_IGNORE_GLOBAL_LIBVIPS" "$(npm_bin)" install -g --prefix "$PREFIX" "clawdbot@${CLAWDBOT_VERSION}"
  rm -f "${PREFIX}/bin/clawdbot"
  cat > "${PREFIX}/bin/clawdbot" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "${PREFIX}/tools/node/bin/node" "${PREFIX}/lib/node_modules/clawdbot/dist/entry.js" "\$@"
EOF
  chmod +x "${PREFIX}/bin/clawdbot"
  emit_json "{\"event\":\"step\",\"name\":\"clawdbot\",\"status\":\"ok\"}"
}

resolve_clawdbot_version() {
  local version=""
  if [[ -x "${PREFIX}/bin/clawdbot" ]]; then
    version="$("${PREFIX}/bin/clawdbot" --version 2>/dev/null | head -n 1 | tr -d '\r')"
  fi
  echo "$version"
}

main() {
  parse_args "$@"

  if [[ "${CLAWDBOT_NO_ONBOARD:-0}" == "1" ]]; then
    RUN_ONBOARD=0
  fi

  PATH="$(node_dir)/bin:${PREFIX}/bin:${PATH}"
  export PATH

  install_node
  if [[ "$SET_NPM_PREFIX" -eq 1 ]]; then
    fix_npm_prefix_if_needed
  fi
  install_clawdbot

  local installed_version
  installed_version="$(resolve_clawdbot_version)"
  if [[ -n "$installed_version" ]]; then
    emit_json "{\"event\":\"done\",\"ok\":true,\"version\":\"${installed_version//\"/\\\"}\"}"
    log "Clawdbot installed (${installed_version})."
  else
    emit_json "{\"event\":\"done\",\"ok\":true}"
    log "Clawdbot installed."
  fi

  if [[ "$RUN_ONBOARD" -eq 1 ]]; then
    "${PREFIX}/bin/clawdbot" onboard
  fi
}

main "$@"
