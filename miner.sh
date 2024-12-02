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
keywords=("api_key" "API_KEY" "APIKEY" "ApiKey" "admin" "secret" "Secret" "SECRET" "firebase" "FireBase" "FIREBASE" "base" "datadog" 'DataDog" "DATADOG" "UUID" "uuid" "username" "email" "ADMIN" "DB" "db" "DataBase" "database" "Mysql" "mysql" "MySql" "MYSQL" "SQL" "sql" "Sql" "apikey" "secret" "password" "token" "auth" "access" "key" "client_secret")

# Regex for API links (e.g., /api/, /v1/, /cdn-cgi/, etc.)
api_regex="(/[a-zA-Z0-9_\-]+)*(/api(/[a-zA-Z0-9_\-]*)*|/v[0-9]+(/[a-zA-Z0-9_\-]*)*|/cdn-cgi(/[a-zA-Z0-9_\-]*)*|/graphql(/[a-zA-Z0-9_\-]*)*|/rest(/[a-zA-Z0-9_\-]*)*|/services(/[a-zA-Z0-9_\-]*)*|/webservices(/[a-zA-Z0-9_\-]*)*|/soap(/[a-zA-Z0-9_\-]*)*)"

# Read the file line by line
while IFS= read -r url; do
    # Fetch HTTP headers to get the status code
    status_code=$(curl -o /dev/null -s -w "%{http_code}" "$url")
    
    # Process only if the status code is 200, or 405
    if [[ "$status_code" == "200" || "$status_code" == "405" ]]; then
        # Fetch the JavaScript content
        content=$(curl -s "$url")

        # Check for sensitive data using keywords
        matches=$(echo "$content" | grep -oiE "(${keywords[*]})[=:][\"']?[a-zA-Z0-9_\-]+[\"']?")

        # Check for API links
        api_links=$(echo "$content" | grep -oiE "$api_regex")

        if [ ! -z "$matches" ] || [ ! -z "$api_links" ]; then
            echo "[ + ] URL: $url : Status $status_code - found matches" | tee -a "$output_file"
            echo "<br>" >> "$output_file"

            # Save sensitive data matches
            if [ ! -z "$matches" ]; then
                while IFS= read -r match; do
                    echo "      $match" | tee -a "$output_file"
                    echo "<br>" >> "$output_file"
                done <<< "$matches"
            fi

            # Save API links with the full URL
            if [ ! -z "$api_links" ]; then
                echo "      API Links Found:" | tee -a "$output_file"
                while IFS= read -r link; do
                    # Form the full URL if the detected path is relative
                    if [[ "$link" =~ ^/ ]]; then
                        full_link="${url%/}${link}"
                    else
                        full_link="$link"
                    fi
                    
                    # Fetch the status code of the resolved API link
                    api_status_code=$(curl -o /dev/null -s -w "%{http_code}" "$full_link")

                    # Only include the API link if its status code is 200, or 405
                    if [[ "$api_status_code" == "200" || "$api_status_code" == "405" ]]; then
                        echo "          $full_link : Status $api_status_code" | tee -a "$output_file"
                        echo "<br>" >> "$output_file"
                    fi
                done <<< "$api_links"
            fi
        fi
    fi
done < "$input_file"

# Close the HTML file
echo "</body></html>" >> "$output_file"

echo "Results saved in $output_file"
