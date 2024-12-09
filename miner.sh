#!/bin/bash

# Function to display usage instructions
usage() {
    figlet "Gold Miner"
    echo "Usage: bash $0 -f <input_file> -o <output_file>"
    exit 1
}

# Initialize variables
input_file=""
output_file=""

# Parse command-line arguments
while getopts ":f:o:" opt; do
    case $opt in
        f) input_file="$OPTARG";;
        o) output_file="$OPTARG";;
        *) usage;;
    esac
done

# Validate required arguments
if [ -z "$input_file" ] || [ -z "$output_file" ]; then
    usage
fi

# Validate input file existence
if [ ! -f "$input_file" ]; then
    echo "File not found: $input_file"
    exit 1
fi

# Create or overwrite the output HTML file
echo "<html><body>" > "$output_file"

# Keywords to search for sensitive data
keywords=("api_key" "API_KEY" "APIKEY" "admin" "secret" "firebase" "datadog" "UUID" "username" "email" "DB" "DataBase" "Mysql" "SQL" "token" "auth" "access" "key" "client_secret" "password")

# Regex for key-value pairs and API paths
keyword_pattern=$(IFS='|'; echo "${keywords[*]}")
key_value_regex="\\b(${keyword_pattern})\\b[[:space:]]*[=:][[:space:]]*['\"]?[[:alnum:]_.-]+['\"]?"
api_regex="(/[a-zA-Z0-9_\-]+)*(/api(/[a-zA-Z0-9_\-]*)*|/v[0-9]+(/[a-zA-Z0-9_\-]*)*|/cdn-cgi(/[a-zA-Z0-9_\-]*)*|/graphql(/[a-zA-Z0-9_\-]*)*|/rest(/[a-zA-Z0-9_\-]*)*|/services(/[a-zA-Z0-9_\-]*)*|/webservices(/[a-zA-Z0-9_\-]*)*|/soap(/[a-zA-Z0-9_\-]*)*)"

# Read the file line by line
while IFS= read -r url; do
    # Fetch HTTP headers to get the status code
    status_code=$(curl -o /dev/null -s -w "%{http_code}" "$url")

    # Process only if the status code is 200
    if [[ "$status_code" == "200" ]]; then
        echo "[+] url : $url : $status_code" | tee -a "$output_file"

        # Fetch the JavaScript content
        content=$(curl -s "$url")

        # Check for sensitive data using full key-value regex
        matches=$(echo "$content" | grep -oiE "$key_value_regex")
        if [ ! -z "$matches" ]; then
            while IFS= read -r match; do
                echo "[+] Found possible sensitive data : $match" | tee -a "$output_file"
            done <<< "$matches"
        fi

        # Check for API links
        api_links=$(echo "$content" | grep -oiE "$api_regex")
        if [ ! -z "$api_links" ]; then
            while IFS= read -r link; do
                # Form the full URL if the detected path is relative
                if [[ "$link" =~ ^/ ]]; then
                    full_link="${url%/}${link}"
                else
                    full_link="$link"
                fi

                # Fetch the status code of the resolved API link
                api_status_code=$(curl -o /dev/null -s -w "%{http_code}" "$full_link")

                # Only include the API link if its status code is 200 or 405
                if [[ "$api_status_code" == "200" || "$api_status_code" == "405" ]]; then
                    echo "[+] Found api link: $full_link" | tee -a "$output_file"
                fi
            done <<< "$api_links"
        fi
    fi
done < "$input_file"

# Close the HTML file
echo "</body></html>" >> "$output_file"

echo "Results saved in $output_file"
