#!/bin/bash

ENV_FILE="../config/.env"
OUTPUT_FILE="../scripts/known_services.lua"

mkdir -p "$(dirname "$OUTPUT_FILE")"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ $ENV_FILE not found!"
    exit 1
fi

echo "Generating known_services from $ENV_FILE..."

echo "local known_services = {" > "$OUTPUT_FILE"
while IFS='=' read -r key value; do
    if [[ -n "$key" && -n "$value" ]]; then
        printf '    ["%s"] = "%s",\n' "$value" "$value" >> "$OUTPUT_FILE"
    fi
done < "$ENV_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

echo "local services = {" >> "$OUTPUT_FILE"
while IFS='=' read -r key value; do
    if [[ -n "$key" && -n "$value" ]]; then
        printf '    "%s",\n' "$value" >> "$OUTPUT_FILE"
    fi
done < "$ENV_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "return known_services, services" >> "$OUTPUT_FILE"

echo "✔ Generated $OUTPUT_FILE"
.
