# Terminal output helpers shared by the scripts (sourced, bash 3.2 compatible).
# Colors and the live progress bar only on an interactive terminal; NO_COLOR disables colors.

if [[ -t 1 ]]; then UI_TTY=1; else UI_TTY=0; fi
if ((UI_TTY)) && [[ -z ${NO_COLOR:-} ]]; then
  C_RESET=$'\033[0m' C_BOLD=$'\033[1m' C_DIM=$'\033[2m'
  C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_CYAN=$'\033[36m'
else
  C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_CYAN=''
fi

# Byte-safe: the container has no UTF-8 locale, so multibyte strings cannot be sliced.
ui_repeat() {
  local i
  for ((i = 0; i < $2; i++)); do printf '%s' "$1"; done
}

ui_title() {
  printf '\n%s▶ %s%s\n\n' "${C_BOLD}${C_CYAN}" "$1" "${C_RESET}"
}

ui_section() {
  printf '\n%s── %s %s%s\n\n' "${C_DIM}" "$1" "$(ui_repeat ─ $((44 - ${#1})))" "${C_RESET}"
}

ui_field() {
  printf '  %s%-12s%s %s\n' "${C_DIM}" "$1" "${C_RESET}" "$2"
}

ui_item() {
  printf '\n  %s[%s]%s %s%s%s\n' "${C_DIM}" "$1" "${C_RESET}" "${C_BOLD}" "$2" "${C_RESET}"
}

ui_detail() {
  printf '    %s%s%s\n' "${C_DIM}" "$1" "${C_RESET}"
}

ui_ok() {
  printf '    %s✔%s %s\n' "${C_GREEN}" "${C_RESET}" "$1"
}

ui_warn() {
  printf '    %s⚠ %s%s\n' "${C_YELLOW}" "$1" "${C_RESET}"
}

ui_fail() {
  printf '    %s✖ %s%s\n' "${C_RED}" "$1" "${C_RESET}"
}

ui_error() {
  printf '%s✖ Error:%s %s\n' "${C_RED}${C_BOLD}" "${C_RESET}" "$1" >&2
}

# Redrawn in place: a no-op when the output is not a terminal (logs, pipes).
ui_progress() {
  ((UI_TTY)) || return 0
  local width=30 filled=$(($1 * 30 / 100))
  printf '\r    %s%s%s%s%s %3d %%  %s%s%s\033[K' \
    "${C_GREEN}" "$(ui_repeat █ "$filled")" "${C_DIM}" "$(ui_repeat ░ $((width - filled)))" "${C_RESET}" \
    "$1" "${C_DIM}" "$2" "${C_RESET}"
}

ui_progress_clear() {
  ((UI_TTY)) && printf '\r\033[K'
  return 0
}

# Decimal units, as displayed by the macOS Finder.
ui_size() {
  awk -v b="$1" 'BEGIN {
    split("B KB MB GB TB", u); i = 1
    while (b >= 1000 && i < 5) { b /= 1000; i++ }
    printf (i == 1 ? "%d %s" : "%.1f %s"), b, u[i]
  }'
}

ui_duration() {
  local s=$1
  if ((s >= 3600)); then
    printf '%d:%02d:%02d' $((s / 3600)) $((s % 3600 / 60)) $((s % 60))
  else
    printf '%d:%02d' $((s / 60)) $((s % 60))
  fi
}
