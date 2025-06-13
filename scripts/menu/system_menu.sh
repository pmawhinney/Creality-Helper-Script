#!/bin/sh

set -e

function check_fw_version() {
  file="/usr/data/creality/userdata/config/system_version.json"
  if [ -e "$file" ]; then
    cat "$file" | jq -r '.sys_version'
  else
    echo -e "N/A"
  fi
}

function check_connection() {
  eth0_ip=$(ip -4 addr show eth0 2>/dev/null | grep -o -E '(inet\s)([0-9]+\.){3}[0-9]+' | cut -d ' ' -f 2 | head -n 1)
  wlan0_ip=$(ip -4 addr show wlan0 | grep -o -E '(inet\s)([0-9]+\.){3}[0-9]+' | cut -d ' ' -f 2 | head -n 1)
  if [ -n "$eth0_ip" ]; then
    echo -e "$eth0_ip (ETHERNET)"
  elif [ -n "$wlan0_ip" ]; then
    echo -e "$wlan0_ip (WLAN)"
  else
    echo -e "xxx.xxx.xxx.xxx"
  fi
}

function format_uptime() {
  local uptime=$1
  local upDays=$((uptime / 60 / 60 / 24))
  local upHours=$((uptime / 60 / 60 % 24))
  local upMins=$((uptime / 60 % 60))
  local output=""
  if [ $upDays -gt 0 ]; then
    output="$output$upDays day"
    [ $upDays -gt 1 ] && output="${output}s"
    output="$output "
  fi
  if [ $upHours -gt 0 ]; then
    output="$output$upHours hour"
    [ $upHours -gt 1 ] && output="${output}s"
    output="$output "
  fi
  if [ $upMins -gt 0 ] || [ -z "$output" ]; then
    output="$output$upMins minute"
    [ $upMins -gt 1 ] && output="${output}s"
  fi
  echo "$output"
}

function system_menu_ui() {
  memfree=`cat /proc/meminfo | grep MemFree | awk {'print $2'}`
  memtotal=`cat /proc/meminfo | grep MemTotal | awk {'print $2'}`
  pourcent=$((($memfree * 100)/$memtotal))
  diskused=`df -h | grep /dev/mmcblk0p10 | awk {'print $3 " / " $2 " (" $4 " available)" '}`
  process=`ps ax | wc -l | tr -d " "`
  uptime=`cat /proc/uptime | cut -f1 -d.`
  formatted_uptime=$(format_uptime $uptime)
  load=`awk -v cpus=2 '{printf "%.2f%% (1 min) | %.2f%% (5 min) | %.2f%% (15 min)\n", $1*100/cpus, $2*100/cpus, $3*100/cpus}' /proc/loadavg`
  device_sn=$(cat /usr/data/creality/userdata/config/system_config.json | grep -o '"device_sn":"[^"]*' | awk -F '"' '{print $4}')
  mac_address=$(cat /usr/data/creality/userdata/config/system_config.json | grep -o '"device_mac":"[^"]*' | awk -F '"' '{print $4}' | sed 's/../&:/g; s/:$//')
  top_line
  title '[ SYSTEM MENU ]' "${yellow}"
  inner_line
  hr
  system_line "     System" "$(uname -s) (Kernel $(uname -r))" "${green}"
  system_line "   Firmware" "$(check_fw_version)"
  system_line "   Hostname" "$(uname -n)"
  system_line "  Device SN" "$device_sn"
  system_line " IP Address" "$(check_connection)"
  system_line "MAC Address" "$mac_address"
  system_line "  CPU Usage" "$load"
  system_line "  RAM Usage" "$(($memfree/1024)) MB / $(($memtotal/1024)) MB ($pourcent% available)"
  system_line " Disk Usage" "$diskused"
  system_line "     Uptime" "$formatted_uptime"
  hr
  inner_line
  hr
  bottom_menu_option 'b' 'Back to [Main Menu]' "${yellow}"
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

function system_menu() {
  clear
  system_menu_ui
  local system_menu_opt
  while true; do
    read -p " ${white}Type your choice and validate with Enter: ${yellow}" system_menu_opt
    case "${system_menu_opt}" in
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
         error_msg "Please select a correct choice!";;
    esac
  done
  system_menu
}
