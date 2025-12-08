#!/usr/bin/env bash

# Build tmux status-right segments with icons, colors, and sensible fallbacks.

os_name="$(uname -s 2>/dev/null)"

case "$os_name" in
  Darwin)
    load="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2, $3, $4}')"
    ;;
  *)
    load="$(cut -d ' ' -f 1-3 /proc/loadavg 2>/dev/null)"
    ;;
esac
[ -z "$load" ] && load="-- -- --"

temp_icon=""
temp_value=""
if [ "$os_name" = "Darwin" ]; then
  if command -v osx-cpu-temp >/dev/null 2>&1; then
    temp_value="$(osx-cpu-temp --celcius 2>/dev/null | awk '{print int($1)}')"
  elif command -v istats >/dev/null 2>&1; then
    temp_value="$(istats cpu temp --value-only 2>/dev/null | head -n1 | awk '{print int($1)}')"
  fi
else
  if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
    temp_value="$(awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null)"
  elif command -v acpi >/dev/null 2>&1; then
    temp_value="$(acpi -t 2>/dev/null | awk '{print int($4)}')"
  fi
fi
if [ -n "$temp_value" ] && [ "$temp_value" -gt 0 ] && [ "$temp_value" -lt 150 ]; then
  temp_value="${temp_icon} ${temp_value}°C"
else
  temp_value="${temp_icon} --"
fi

battery_icon=""
battery_state=""
if [ "$os_name" = "Darwin" ]; then
  if command -v pmset >/dev/null 2>&1; then
    info="$(pmset -g batt 2>/dev/null | sed -n '2p')"
    pct="$(printf '%s' "$info" | grep -Eo '[0-9]+%' | head -n1 | tr -d '%')"
    state="$(printf '%s' "$info" | awk -F';' '{gsub(/^[ \t-]+/,"",$2); print tolower($2)}')"
    if [ -n "$pct" ]; then
      if [ "$pct" -ge 80 ]; then battery_icon=""
      elif [ "$pct" -ge 60 ]; then battery_icon=""
      elif [ "$pct" -ge 40 ]; then battery_icon=""
      elif [ "$pct" -ge 20 ]; then battery_icon=""
      else battery_icon=""
      fi
      case "$state" in
        *discharg*) state_icon="" ;;
        *charg*) state_icon="" ;;
        *full*|*charged*) state_icon="" ;;
        *) state_icon="--" ;;
      esac
      battery_state="${battery_icon} ${pct}% ${state_icon}"
    fi
  fi
else
  if command -v acpi >/dev/null 2>&1; then
    info="$(acpi -b 2>/dev/null | head -n1)"
    state="$(printf '%s' "$info" | awk -F'[,: ]+' '{print $3}')"
    pct="$(printf '%s' "$info" | awk -F'[,: ]+' '{gsub("%","",$4); print $4}')"
    if [ -n "$pct" ]; then
      if [ "$pct" -ge 80 ]; then battery_icon=""
      elif [ "$pct" -ge 60 ]; then battery_icon=""
      elif [ "$pct" -ge 40 ]; then battery_icon=""
      elif [ "$pct" -ge 20 ]; then battery_icon=""
      else battery_icon=""
      fi
      case "$state" in
        Charging) state_icon="" ;;
        Discharging) state_icon="" ;;
        Full) state_icon="" ;;
        *) state_icon="--" ;;
      esac
      battery_state="${battery_icon} ${pct}% ${state_icon}"
    fi
  fi
fi
[ -z "$battery_state" ] && battery_state="${battery_icon} --"

net_value=""
if [ "$os_name" = "Darwin" ]; then
  default_if="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
  wifi_if="$(networksetup -listallhardwareports 2>/dev/null | awk '/Hardware Port: Wi-Fi/{getline; if($1=="Device:"){print $2}}')"
  airport_bin="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  if [ -n "$wifi_if" ] && [ "$wifi_if" = "$default_if" ] && [ -x "$airport_bin" ]; then
    ssid="$("$airport_bin" -I 2>/dev/null | awk -F': ' '/ SSID/ {print $2; exit}')"
    [ -n "$ssid" ] && net_value=" ${ssid}"
  fi
  if [ -z "$net_value" ] && [ -n "$default_if" ]; then
    net_value=" ${default_if}"
  fi
  if [ -n "$default_if" ]; then
    ip_addr="$(ipconfig getifaddr "$default_if" 2>/dev/null)"
    [ -n "$ip_addr" ] && net_value="${net_value}  ${ip_addr}"
  fi
else
  default_if="$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}')"
  if [ -n "$default_if" ]; then
    wifi_iface_is_wireless=""
    [ -d "/sys/class/net/${default_if}/wireless" ] && wifi_iface_is_wireless=1
    if [ -n "$wifi_iface_is_wireless" ] || command -v iwgetid >/dev/null 2>&1; then
      if command -v iwgetid >/dev/null 2>&1; then
        ssid="$(iwgetid -r 2>/dev/null)"
      fi
      if [ -z "$ssid" ] && command -v nmcli >/dev/null 2>&1; then
        ssid="$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"
      fi
      if [ -n "$ssid" ]; then
        net_value=" ${ssid}"
      else
        net_value=" ${default_if}"
      fi
    else
      net_value=" ${default_if}"
    fi
    ip_addr="$(ip -4 addr show dev "$default_if" 2>/dev/null | awk '/inet / {print $2; exit}' | cut -d'/' -f1)"
    [ -n "$ip_addr" ] && net_value="${net_value}  ${ip_addr}"
  fi
fi
[ -z "$net_value" ] && net_value=" --"

date_str="$(date '+%d.%m.%Y %H:%M:%S')"

printf '#[fg=colour244] %s #[fg=colour240]| #[fg=colour245]%s #[fg=colour240]| #[fg=colour107]%s #[fg=colour240]| #[fg=colour81]%s #[fg=colour240]| #[fg=colour214]%s' \
  "$load" "$temp_value" "$battery_state" "$net_value" "$date_str"
