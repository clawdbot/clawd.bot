#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2030,SC2031,SC2016
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local got="$1"
  local want="$2"
  local msg="${3:-}"
  if [[ "$got" != "$want" ]]; then
    fail "${msg} expected=${want} got=${got}"
  fi
}

assert_nonempty() {
  local got="$1"
  local msg="${2:-}"
  if [[ -z "$got" ]]; then
    fail "${msg} expected non-empty"
  fi
}

make_exe() {
  local path="$1"
  shift || true
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<EOF
#!/usr/bin/env bash
set -euo pipefail
$*
EOF
  chmod +x "$path"
}

stub_ui_and_quiet_runner() {
  ui_info() { :; }
  ui_success() { :; }
  ui_warn() { :; }
  ui_error() { :; }
  run_quiet_step() {
    local _title="$1"
    shift
    "$@"
  }
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export OPENCLAW_INSTALL_SH_NO_RUN=1
export CLAWDBOT_INSTALL_SH_NO_RUN=1
# shellcheck source=../public/install.sh
source "${ROOT_DIR}/public/install.sh"

echo "==> case: resolve_openclaw_bin (direct PATH)"
(
  bin="${TMP_DIR}/case-path/bin"
  make_exe "${bin}/openclaw" 'echo "ok" >/dev/null'
  export PATH="${bin}:/usr/bin:/bin"

  got="$(resolve_openclaw_bin)"
  assert_eq "$got" "${bin}/openclaw" "resolve_openclaw_bin (direct PATH)"
)

echo "==> case: resolve_openclaw_bin (npm prefix -g)"
(
  root="${TMP_DIR}/case-npm-prefix"
  prefix="${root}/prefix"
  tool_bin="${root}/tool-bin"

  make_exe "${tool_bin}/npm" "if [[ \"\$1\" == \"prefix\" && \"\$2\" == \"-g\" ]]; then echo \"${prefix}\"; exit 0; fi; if [[ \"\$1\" == \"config\" && \"\$2\" == \"get\" && \"\$3\" == \"prefix\" ]]; then echo \"${prefix}\"; exit 0; fi; exit 1"
  make_exe "${prefix}/bin/openclaw" 'echo "ok" >/dev/null'

  export PATH="${tool_bin}:/usr/bin:/bin"

  got="$(resolve_openclaw_bin)"
  assert_eq "$got" "${prefix}/bin/openclaw" "resolve_openclaw_bin (npm prefix -g)"
)

echo "==> case: resolve_openclaw_bin (nodenv rehash shim creation)"
(
  root="${TMP_DIR}/case-nodenv"
  shim="${root}/shims"
  tool_bin="${root}/tool-bin"

  mkdir -p "${shim}"
  make_exe "${tool_bin}/npm" "exit 1"
  cat >"${tool_bin}/nodenv" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ "\${1:-}" == "rehash" ]]; then
  cat >"${shim}/openclaw" <<'SHIM'
#!/usr/bin/env bash
set -euo pipefail
echo ok >/dev/null
SHIM
  chmod +x "${shim}/openclaw"
  exit 0
fi
exit 0
EOF
  chmod +x "${tool_bin}/nodenv"

  export PATH="${shim}:${tool_bin}:/usr/bin:/bin"
  command -v openclaw >/dev/null 2>&1 && fail "precondition: openclaw unexpectedly present"

  got="$(resolve_openclaw_bin)"
  assert_eq "$got" "${shim}/openclaw" "resolve_openclaw_bin (nodenv rehash)"
)

echo "==> case: warn_openclaw_not_found (smoke)"
(
  root="${TMP_DIR}/case-warn"
  tool_bin="${root}/tool-bin"
  make_exe "${tool_bin}/npm" 'if [[ "$1" == "prefix" && "$2" == "-g" ]]; then echo "/tmp/prefix"; exit 0; fi; if [[ "$1" == "config" && "$2" == "get" && "$3" == "prefix" ]]; then echo "/tmp/prefix"; exit 0; fi; exit 1'
  export PATH="${tool_bin}:/usr/bin:/bin"

  out="$(warn_openclaw_not_found 2>&1 || true)"
  assert_nonempty "$out" "warn_openclaw_not_found output"
)

echo "==> case: ensure_pnpm (existing pnpm command)"
(
  root="${TMP_DIR}/case-pnpm-existing"
  tool_bin="${root}/tool-bin"
  make_exe "${tool_bin}/pnpm" 'if [[ "${1:-}" == "--version" ]]; then echo "10.29.2"; exit 0; fi; exit 0'

  export PATH="${tool_bin}:/usr/bin:/bin"
  PNPM_CMD=()
  stub_ui_and_quiet_runner

  ensure_pnpm
  assert_eq "${PNPM_CMD[*]}" "pnpm" "ensure_pnpm (existing pnpm)"
)

echo "==> case: ensure_pnpm (corepack fallback when pnpm shim missing)"
(
  root="${TMP_DIR}/case-pnpm-corepack-fallback"
  tool_bin="${root}/tool-bin"
  mkdir -p "${tool_bin}"

  cat >"${tool_bin}/corepack" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "enable" ]]; then
  exit 0
fi
if [[ "${1:-}" == "prepare" ]]; then
  exit 0
fi
if [[ "${1:-}" == "pnpm" && "${2:-}" == "--version" ]]; then
  echo "10.29.2"
  exit 0
fi
if [[ "${1:-}" == "pnpm" ]]; then
  shift
  echo "corepack-pnpm:$*" >/dev/null
  exit 0
fi
exit 1
EOF
  chmod +x "${tool_bin}/corepack"

  export PATH="${tool_bin}:/usr/bin:/bin"
  PNPM_CMD=()
  stub_ui_and_quiet_runner

  ensure_pnpm
  assert_eq "${PNPM_CMD[*]}" "corepack pnpm" "ensure_pnpm (corepack fallback)"
  out="$(run_pnpm --version)"
  assert_nonempty "$out" "run_pnpm --version output"
)

echo "==> case: ensure_pnpm (npm fallback install)"
(
  root="${TMP_DIR}/case-pnpm-npm-fallback"
  tool_bin="${root}/tool-bin"
  mkdir -p "${tool_bin}"

  cat >"${tool_bin}/corepack" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 1
EOF
  chmod +x "${tool_bin}/corepack"

  cat >"${tool_bin}/npm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "install" && "${2:-}" == "-g" && "${3:-}" == "pnpm@10" ]]; then
  cat >"${FAKE_PNPM_BIN_DIR}/pnpm" <<'PNPM'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--version" ]]; then
  echo "10.29.2"
  exit 0
fi
exit 0
PNPM
  chmod +x "${FAKE_PNPM_BIN_DIR}/pnpm"
  exit 0
fi
if [[ "${1:-}" == "prefix" && "${2:-}" == "-g" ]]; then
  echo "${FAKE_PNPM_BIN_DIR%/tool-bin}"
  exit 0
fi
if [[ "${1:-}" == "config" && "${2:-}" == "get" && "${3:-}" == "prefix" ]]; then
  echo "${FAKE_PNPM_BIN_DIR%/tool-bin}"
  exit 0
fi
exit 0
EOF
  chmod +x "${tool_bin}/npm"

  export FAKE_PNPM_BIN_DIR="${tool_bin}"
  export PATH="${tool_bin}:/usr/bin:/bin"
  PNPM_CMD=()
  stub_ui_and_quiet_runner
  fix_npm_permissions() { :; }

  ensure_pnpm
  assert_eq "${PNPM_CMD[*]}" "pnpm" "ensure_pnpm (npm fallback)"
)

echo "OK"
