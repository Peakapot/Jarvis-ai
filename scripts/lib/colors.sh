#!/usr/bin/env bash
# =============================================================================
# colors.sh — Terminal color and symbol definitions
# -----------------------------------------------------------------------------
# Provides a consistent, TTY-aware palette for all Jarvis scripts. Colors are
# automatically disabled when stdout is not a terminal or when NO_COLOR is set,
# keeping log files and CI output clean (Observability by default).
#
# This file is a library: source it, do not execute it.
# =============================================================================

# Guard against double-sourcing.
[[ -n "${__JARVIS_COLORS_SH:-}" ]] && return 0
__JARVIS_COLORS_SH=1

# Detect whether color output is appropriate. Honour the NO_COLOR standard
# (https://no-color.org/) and the JARVIS_NO_COLOR override.
if [[ -t 1 && -z "${NO_COLOR:-}" && -z "${JARVIS_NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_MAGENTA=$'\033[35m'
  C_CYAN=$'\033[36m'
  C_GREY=$'\033[90m'
else
  C_RESET="" C_BOLD="" C_DIM="" C_RED="" C_GREEN="" C_YELLOW=""
  C_BLUE="" C_MAGENTA="" C_CYAN="" C_GREY=""
fi

# Status symbols. Unicode where the locale supports it, ASCII otherwise.
if [[ "${LANG:-}" == *UTF-8* || "${LC_ALL:-}" == *UTF-8* ]]; then
  SYM_OK="✔"
  SYM_FAIL="✘"
  SYM_WARN="⚠"
  SYM_INFO="ℹ"
  SYM_ARROW="➜"
else
  SYM_OK="[OK]"
  SYM_FAIL="[FAIL]"
  SYM_WARN="[WARN]"
  SYM_INFO="[INFO]"
  SYM_ARROW="->"
fi

export C_RESET C_BOLD C_DIM C_RED C_GREEN C_YELLOW C_BLUE C_MAGENTA C_CYAN C_GREY
export SYM_OK SYM_FAIL SYM_WARN SYM_INFO SYM_ARROW
