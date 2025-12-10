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
  temp_value=""
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

net_value=""
if [ "$os_name" = "Darwin" ]; then
  default_if="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
  wifi_if="$(networksetup -listallhardwareports 2>/dev/null | awk '/Hardware Port: Wi-Fi/{getline; if($1=="Device:"){print $2}}')"
  airport_bin="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  if [ -n "$wifi_if" ] && [ "$wifi_if" = "$default_if" ] && [ -x "$airport_bin" ]; then
    ssid="$("$airport_bin" -I 2>/dev/null | awk -F': ' '/ SSID/ {print $2; exit}')"
    channel_info="$("$airport_bin" -I 2>/dev/null | awk -F': ' '/ channel/ {print $2; exit}')"
    rssi="$("$airport_bin" -I 2>/dev/null | awk '/agrCtlRSSI/ {print $2; exit}')"
    if [ -n "$ssid" ]; then
      net_value=" ${ssid}"
    else
      net_value=" ${wifi_if}"
    fi
    band=""
    if [ -n "$channel_info" ]; then
      channel_num="${channel_info%%,*}"
      case "$channel_num" in
        '' ) ;;
        *)
          if [ "$channel_num" -le 14 ]; then
            band="2.4GHz"
          elif [ "$channel_num" -le 165 ]; then
            band="5GHz"
          else
            band="6GHz"
          fi
          ;;
      esac
    fi
    wifi_details=""
    [ -n "$band" ] && wifi_details="${wifi_details} ${band}"
    [ -n "$rssi" ] && wifi_details="${wifi_details} (${rssi}dBm)"
    if [ -n "$net_value" ] && [ -n "$wifi_details" ]; then
      net_value="${net_value}${wifi_details}"
    fi
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
    wifi_connected=""
    ssid=""
    wifi_band=""
    wifi_signal=""
    freq=""
    signal_dbm=""
    [ -d "/sys/class/net/${default_if}/wireless" ] && wifi_connected=1
    if command -v iwgetid >/dev/null 2>&1; then
      ssid="$(iwgetid -r "$default_if" 2>/dev/null)"
      [ -n "$ssid" ] && wifi_connected=1
    fi
    if [ -z "$wifi_connected" ] && command -v nmcli >/dev/null 2>&1; then
      wifi_type="$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$1=="'"${default_if}"'"{print $2; exit}')"
      [ "$wifi_type" = "wifi" ] && wifi_connected=1
    fi
    if [ -z "$ssid" ] && [ -n "$wifi_connected" ] && command -v nmcli >/dev/null 2>&1; then
      ssid="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | awk -F: '$1=="'"${default_if}"'" && $2=="wifi"{print $4; exit}')"
    fi
    if [ -n "$wifi_connected" ]; then
      if command -v iw >/dev/null 2>&1; then
        freq="$(iw dev "$default_if" link 2>/dev/null | awk '/freq:/ {print $2; exit}')"
        signal_dbm="$(iw dev "$default_if" link 2>/dev/null | awk '/signal:/ {print $2; exit}')"
      elif command -v iwconfig >/dev/null 2>&1; then
        freq="$(iwconfig "$default_if" 2>/dev/null | awk -F'[ =]+' '/Frequency/ {gsub("GHz","",$5); printf "%.0f", $5*1000; exit}')"
        signal_dbm="$(iwconfig "$default_if" 2>/dev/null | awk -F'=' '/Signal level/ {gsub(/ dBm/,"",$3); split($3,a," "); print a[1]; exit}')"
      fi
      if [ -n "$freq" ]; then
        if [ "$freq" -ge 5925 ]; then
          wifi_band="6GHz"
        elif [ "$freq" -ge 5000 ]; then
          wifi_band="5GHz"
        else
          wifi_band="2.4GHz"
        fi
      fi
      [ -n "$signal_dbm" ] && wifi_signal="${signal_dbm}dBm"
      if [ -n "$ssid" ]; then
        net_value=" ${ssid}"
      else
        net_value=" ${default_if}"
      fi
      wifi_details=""
      [ -n "$wifi_band" ] && wifi_details="${wifi_details} ${wifi_band}"
      [ -n "$wifi_signal" ] && wifi_details="${wifi_details} (${wifi_signal})"
      [ -n "$wifi_details" ] && net_value="${net_value}${wifi_details}"
    else
      net_value=" ${default_if}"
    fi
    ip_addr="$(ip -4 addr show dev "$default_if" 2>/dev/null | awk '/inet / {print $2; exit}' | cut -d'/' -f1)"
    [ -n "$ip_addr" ] && net_value="${net_value}  ${ip_addr}"
  fi
fi
[ -z "$net_value" ] && net_value=" --"

date_str="$(date '+%d.%m.%Y %H:%M:%S')"

status_segments=()
status_segments+=("#[fg=colour244] ${load}")
[ -n "$temp_value" ] && status_segments+=("#[fg=colour245]${temp_value}")
[ -n "$battery_state" ] && status_segments+=("#[fg=colour107]${battery_state}")
status_segments+=("#[fg=colour81]${net_value}")
status_segments+=("#[fg=colour214]${date_str}")

status_line="${status_segments[0]}"
for segment in "${status_segments[@]:1}"; do
  status_line="${status_line} #[fg=colour240]| ${segment}"
done

printf '%s' "$status_line"
