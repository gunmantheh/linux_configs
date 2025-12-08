#!/usr/bin/env bash

# Build tmux status-right segments with icons, colors, and sensible fallbacks.

load="$(cut -d ' ' -f 1-3 /proc/loadavg 2>/dev/null)"

temp_icon=""
temp_value="--"
if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
  temp_value="$(awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null)"
elif command -v acpi >/dev/null 2>&1; then
  temp_value="$(acpi -t 2>/dev/null | awk '{print int($4)}')"
fi
[ -n "$temp_value" ] && temp_value="${temp_icon} ${temp_value}°C" || temp_value="${temp_icon} --"

battery_icon=""
battery_state="--"
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

date_str="$(date '+%d-%m-%Y %H:%M:%S')"

printf '#[fg=colour244] %s #[fg=colour240]| #[fg=colour245]%s #[fg=colour240]| #[fg=colour107]%s #[fg=colour240]| #[fg=colour214]%s' \
  "$load" "$temp_value" "$battery_state" "$date_str"
