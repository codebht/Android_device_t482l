#!/bin/bash

# ============================================================
#   Acer One 8 | T482L — Vendor Setup Script
#   Made with 💖 by codebht
# ============================================================

# ── Colour Palette ──────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'

# Foreground
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

# Bright Foreground
BRED='\033[91m'
BGREEN='\033[92m'
BYELLOW='\033[93m'
BBLUE='\033[94m'
BMAGENTA='\033[95m'
BCYAN='\033[96m'
BWHITE='\033[97m'

# Background
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_BLUE='\033[44m'
BG_MAGENTA='\033[45m'
BG_CYAN='\033[46m'

FAILED=0
CLONED_COUNT=0
SKIPPED_COUNT=0
TOTAL=1

# ── Helper: print centred text (approx 70 cols) ─────────────
centre() {
    local text="$1"
    local colour="$2"
    local pad=$(( (70 - ${#text}) / 2 ))
    printf "%${pad}s"
    echo -e "${colour}${text}${RESET}"
}

# ── Helper: horizontal rule ──────────────────────────────────
hr() { echo -e "${DIM}${1:-$CYAN}$(printf '─%.0s' {1..70})${RESET}"; }

# ── Spinner ──────────────────────────────────────────────────
spin() {
    local pid=$1
    local msg="$2"
    local frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${BMAGENTA}${frames[$i]}${RESET}  ${CYAN}${msg}${RESET}   "
        i=$(( (i+1) % 8 ))
        sleep 0.08
    done
    printf "\r"
}

# ── Boot sequence animation ──────────────────────────────────
boot_flash() {
    local colours=("$BBLUE" "$BCYAN" "$BMAGENTA" "$BYELLOW" "$BGREEN")
    for c in "${colours[@]}"; do
        clear
        echo ""
        echo -e "${c}${BOLD}"
        cat << 'BANNER'
  ████████╗██╗  ██╗ █████╗ ██████╗ ██╗     
  ╚══██╔══╝██║  ██║██╔══██╗╚════██╗██║     
     ██║   ███████║╚█████╔╝ █████╔╝██║     
     ██║   ╚════██║██╔══██╗██╔═══╝ ██║     
     ██║        ██║╚█████╔╝███████╗███████╗
     ╚═╝        ╚═╝ ╚════╝ ╚══════╝╚══════╝
BANNER
        echo -e "${RESET}"
        sleep 0.07
    done
}

# ── Main Banner ──────────────────────────────────────────────
show_banner() {
    clear
    echo ""
    echo -e "${BBLUE}${BOLD}"
    cat << 'BANNER'
  ████████╗██╗  ██╗ █████╗ ██████╗ ██╗     
  ╚══██╔══╝██║  ██║██╔══██╗╚════██╗██║     
     ██║   ███████║╚█████╔╝ █████╔╝██║     
     ██║   ╚════██║██╔══██╗██╔═══╝ ██║     
     ██║        ██║╚█████╔╝███████╗███████╗
     ╚═╝        ╚═╝ ╚════╝ ╚══════╝╚══════╝
BANNER
    echo -e "${RESET}"

    echo -e "  ${BMAGENTA}${BOLD}▌${RESET}${BOLD}${BWHITE}  A C E R   O N E   8   ·   C o d e n a m e :  ${BCYAN}T 4 8 2 L${RESET}${BMAGENTA}${BOLD}  ▐${RESET}"
    echo ""
    hr "$BBLUE"
    echo -e "  ${DIM}${CYAN}2GB RAM Variant  ·  Android Device Tree Setup  ·  Using Prebuilt Kernel${RESET}"
    hr "$BBLUE"
    echo ""
    echo -e "  ${BMAGENTA}✦  ${ITALIC}${BWHITE}Made with ${BRED}❤${BWHITE}  by ${BYELLOW}codebht${BWHITE}  ✦${RESET}"
    echo ""
}

# ── Tree legend ──────────────────────────────────────────────
show_tree_legend() {
    echo ""
    hr "$BMAGENTA"
    echo -e "  ${BMAGENTA}${BOLD}⬡  SOURCE TREE — Required Repositories & Prebuilts${RESET}"
    hr "$BMAGENTA"
    echo ""
    echo -e "  ${BYELLOW}${BOLD}ROM Source Root  (/)${RESET}"
    echo -e "  ${CYAN}│${RESET}"
    echo -e "  ${CYAN}├──${RESET} ${BGREEN}vendor/${RESET}"
    echo -e "  ${CYAN}│   └──${RESET} ${BWHITE}acer/T482L${RESET}            ${DIM}← Vendor blobs (proprietary)${RESET}"
    echo -e "  ${CYAN}│${RESET}"
    echo -e "  ${CYAN}└──${RESET} ${BBLUE}device/${RESET}"
    echo -e "  ${CYAN}    └──${RESET} ${BWHITE}acer/t482l/prebuilts${RESET}  ${DIM}← Using prebuilt kernel & dtb${RESET}"
    echo ""
    hr "$BMAGENTA"
    echo ""
}

# ── Progress bar ─────────────────────────────────────────────
draw_progress() {
    local done=$1
    local total=$2
    local width=40
    local filled=$(( done * width / total ))
    local empty=$(( width - filled ))
    local pct=$(( done * 100 / total ))

    local bar="${BGREEN}"
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${DIM}${CYAN}"
    for ((i=0; i<empty; i++)); do bar+="░"; done
    bar+="${RESET}"

    echo -e "  ${DIM}Progress:${RESET}  [${bar}]  ${BYELLOW}${BOLD}${pct}%%${RESET}  ${DIM}(${done}/${total})${RESET}"
}

# ── Clone a single repo with full UI ─────────────────────────
check_and_clone() {
    local NAME="$1"
    local DIR="$2"
    local REPO="$3"
    local ICON="$4"
    local COLOUR="$5"

    echo -e "  ${COLOUR}${ICON}  ${BOLD}${NAME}${RESET}"
    echo -e "  ${DIM}   Path  :${RESET} ${BWHITE}${DIR}${RESET}"
    echo -e "  ${DIM}   Remote:${RESET} ${DIM}${REPO}${RESET}"
    echo ""

    if [ -d "$DIR" ]; then
        echo -e "  ${BGREEN}  ✔  Already present — skipping clone${RESET}"
        SKIPPED_COUNT=$(( SKIPPED_COUNT + 1 ))
    else
        echo -e "  ${BYELLOW}  ⬇  Not found locally — initiating clone…${RESET}"
        echo ""
        (git clone --progress "$REPO" "$DIR" 2>&1 | \
            while IFS= read -r line; do
                echo -e "     ${DIM}${CYAN}${line}${RESET}"
            done) &
        local GIT_PID=$!
        spin "$GIT_PID" "Fetching objects for ${NAME}…"
        wait "$GIT_PID"
        local EXIT_CODE=$?

        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "  ${BGREEN}  ✔  ${NAME} — cloned successfully ✨${RESET}"
            CLONED_COUNT=$(( CLONED_COUNT + 1 ))
        else
            echo -e "  ${BRED}  ✘  ${NAME} — clone FAILED${RESET}"
            echo -e "  ${DIM}${RED}     Source: ${REPO}${RESET}"
            FAILED=1
        fi
    fi

    echo ""
    draw_progress $(( CLONED_COUNT + SKIPPED_COUNT + (FAILED > 0 ? 1 : 0) )) "$TOTAL"
    echo ""
    hr "$DIM"
    echo ""
}

# ── Summary footer ───────────────────────────────────────────
show_summary() {
    echo ""
    hr "$BCYAN"
    echo -e "  ${BCYAN}${BOLD}⬡  SETUP SUMMARY${RESET}"
    hr "$BCYAN"
    echo ""
    echo -e "  ${BGREEN}  ✔  Cloned   :  ${BOLD}${CLONED_COUNT}${RESET}"
    echo -e "  ${BYELLOW}  ⊙  Skipped  :  ${BOLD}${SKIPPED_COUNT}${RESET}"
    if [ "$FAILED" -ne 0 ]; then
        echo -e "  ${BRED}  ✘  Failed   :  ${BOLD}$(( TOTAL - CLONED_COUNT - SKIPPED_COUNT ))${RESET}"
    fi
    echo ""
    hr "$BCYAN"
    echo ""

    if [ "$FAILED" -eq 0 ]; then
        echo -e "  ${BGREEN}${BOLD}"
        cat << 'OK'
   ██████╗ ██╗  ██╗
  ██╔═══██╗██║ ██╔╝
  ██║   ██║█████╔╝
  ██║   ██║██╔═██╗
  ╚██████╔╝██║  ██╗
   ╚═════╝ ╚═╝  ╚═╝
OK
        echo -e "${RESET}"
        echo -e "  ${BGREEN}${BOLD}  Vendor tree & prebuilts are ready. You're ready to build! 🚀${RESET}"
        echo ""
        echo -e "  ${DIM}  Next steps (Run from ROM root):${RESET}"
        echo -e "  ${CYAN}  $ ${BWHITE}source build/envsetup.sh${RESET}                ${DIM}← initialize build environment${RESET}"
        echo -e "  ${CYAN}  $ ${BWHITE}lunch lineage_AcerOne8T482L-userdebug${RESET}   ${DIM}← select T482L target${RESET}"
        echo -e "  ${CYAN}  $ ${BWHITE}m bacon${RESET}                                 ${DIM}← build flashable ROM zip${RESET}"
        echo -e "  ${CYAN}  $ ${BWHITE}m bootimage${RESET}                             ${DIM}← build boot.img only${RESET}"
        echo -e "  ${CYAN}  $ ${BWHITE}m recoveryimage${RESET}                         ${DIM}← build recovery.img only${RESET}"
    else
        echo -e "  ${BRED}${BOLD}  Repository failed to clone.${RESET}"
        echo -e "  ${YELLOW}  Check your internet connection and the remote URL above.${RESET}"
    fi

    echo ""
    hr "$BMAGENTA"
    echo -e "  ${BMAGENTA}✦  ${ITALIC}${DIM}Acer One 8 · T482L · Built using prebuilts${RESET}${BMAGENTA}  ✦${RESET}"
    echo -e "  ${DIM}   Made with ${BRED}❤${RESET}${DIM}  by ${BYELLOW}codebht${RESET}"
    hr "$BMAGENTA"
    echo ""
}

# ════════════════════════════════════════════════════════════
#   E N T R Y P O I N T
# ════════════════════════════════════════════════════════════

boot_flash
show_banner
show_tree_legend

sleep 0.4

echo -e "  ${BWHITE}${BOLD}⬡  Starting dependency resolution…${RESET}"
echo ""
sleep 0.3

# ── Repo definition ──────────────────────────────────────────
#     NAME                  DIR                   REPO                                               ICON  COLOUR
check_and_clone \
    "Vendor Blobs" \
    "vendor/acer/T482L" \
    "https://github.com/codebht/android_vendor_T482L" \
    "📦" "$BGREEN"

show_summary

if [ "$FAILED" -ne 0 ]; then
    return 1 2>/dev/null || exit 1
fi