#!/usr/bin/env bash

keybinds=$(hyprctl -j binds | jq -r '
  .[]
  | select(.enabled != false)
  | (.display_key // .key // "unknown") as $key
  | if ((.description // "") | length) > 0 then
      "\($key) = \(.description)"
    else
      "\($key) = \(.handler // "action")\(if ((.arg // "") | length) > 0 then " " + .arg else "" end)"
    end
')
rofi -dmenu -theme-str 'window {width: 50%;} listview {columns: 1;}' <<< "$keybinds"
