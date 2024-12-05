#!/bin/bash

CONFIG_FILE="${PATH_CONFIG:-/usr/share/nginx/html/src/assets/config.json}"

BASE_ENV_CONFIG="${BASE_ENV:-CTIO}"

update_config_file() {
  for var in $(env | grep -E "^${BASE_ENV_CONFIG}" | sed 's/=.*//'); do
    env_value=$(printenv "$var")

    env_value=$(echo "$env_value" | sed 's/^"\(.*\)"$/\1/')

    if echo "$env_value" | jq -e . >/dev/null 2>&1; then
      parsed_value="$env_value"
    elif [[ "$env_value" == "true" || "$env_value" == "false" ]]; then
      parsed_value="$env_value"
    else
      parsed_value=$(echo "$env_value" | jq -R .)
    fi

    json_key=$(echo "$var" | sed "s/^${BASE_ENV_CONFIG}__//" | sed 's/__/./g')

    jq --arg key "$json_key" --argjson value "$parsed_value" \
      'setpath($key | split(".") | map(if test("^[0-9]+$") then tonumber else . end); $value)' \
      "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  done
}


update_config_file

exec "$@"
