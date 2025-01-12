#!/usr/bin/env bash


#------------------------ General Functions
define_bash_color(){
    #
        emojis='
        ╔ ═ ╗ ║╚ ╝ ╦ ╩ ╠ ╣ ╬
        ✅ ❌ ⤫ ⚠️ 💡 💻 ❗️❓ Ⓜ️ 🏁 ❉ ❈ ❊ ❄ ❁
        ⦀
        💬 💭 🗯 🔔 🔕 ➜ 
        ➡️ ⬅️ ⬆️ ⬇️ ↘️ ↖️
        🔴 🟠 🟡 🟢 🔵 🟣 ⚫️ ⚪️ 🟤
        🕐 🕑 🕒 🕓 🕔 🕕 🕖 🕗 🕘 🕙 🕚 🕛 🕜 🕝 🕞 🕟 🕠 🕡 🕢 🕣 🕤 🕥 🕦 🕧
        📌👍🚜💾❗ab🔥🐳🔗🔎🌟👍🚜🔥🌐
        '
    # Normal
        CLEAR='\033[0m'       # Text Reset
      # Regular Colors
        Black='\033[0;30m'        # Black
        Red='\033[0;31m'          # Red
        Green='\033[0;32m'        # Green
        Yellow='\033[0;33m'       # Yellow
        Blue='\033[0;34m'         # Blue
        Purple='\033[0;35m'       # Purple
        Cyan='\033[0;36m'         # Cyan
        White='\033[0;37m'        # White
      # Bold
        BBlack='\033[1;30m'       # Black
        BRed='\033[1;31m'         # Red
        BGreen='\033[1;32m'       # Green
        BYellow='\033[1;33m'      # Yellow
        BBlue='\033[1;34m'        # Blue
        BPurple='\033[1;35m'      # Purple
        BCyan='\033[1;36m'        # Cyan
        BWhite='\033[1;37m'       # White
    # Underline
        # \e[4m       make underline
        # \e[0m     remove underline
        TUN="$(tput smul)"
        TUND="$(tput rmul)"

    # Blinks
        Blink="\e[5m"
        BlinkDis="\e[25m"

    # Using tput
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
    BG_BLACK="$(tput    setab 0)"
    BG_RED="$(tput      setab 1)"
    BG_GREEN="$(tput    setab 2)"
    BG_YELLOW="$(tput   setab 3)"
    BG_BLUE="$(tput     setab 4)"
    BG_MAGENTA="$(tput  setab 5)"
    BG_CYAN="$(tput     setab 6)"
    BG_WHITE="$(tput    setab 7)"

    FG_BLACK="$(tput    setaf 0)"
    FG_RED="$(tput      setaf 1)"
    FG_GREEN="$(tput    setaf 2)"
    FG_YELLOW="$(tput   setaf 3)"
    FG_BLUE="$(tput     setaf 4)"
    FG_MAGENTA="$(tput  setaf 5)"
    FG_CYAN="$(tput     setaf 6)"
    FG_WHITE="$(tput    setaf 7)"

  }
define_bash_color
#
timeprint(){
     echo -n " --- `jdate +%Y/%m/%d-%H:%M:%S 2> /dev/null || date +%Y/%m/%d-%H:%M:%S` --- "
  }
info(){
    echo -e "`timeprint` : ${BGreen}$@${CLEAR}"
  }
err(){
    echo -e "`timeprint` : ${BRed}$@${CLEAR}"
  }
log(){
    echo -e "`timeprint` : $@"
  }
