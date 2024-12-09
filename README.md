# Gold Miner

Gold Miner is a powerful bash script designed to scan a list of URLs, extract sensitive data patterns, and identify potential API links from their contents. It is particularly useful for security researchers and developers to uncover sensitive information inadvertently exposed in public web resources.

## Features
- **URL Filtering:** Processes URLs with a status code of `200` for content scanning.
- **Sensitive Data Detection:** Matches predefined keywords like `api_key`, `password`, `token`, etc., using regex.
- **API Link Identification:** Extracts API paths and validates their status codes (`200` or `405`).
- **Customizable Output:** Saves results in an HTML file and logs them to the console in a structured format.

## Usage

```bash
bash tool.sh -f <input_file> -o <output_file>
```

### Arguments
- `-f`: Input file containing a list of URLs to scan (one URL per line).
- `-o`: Output file where the results will be saved in HTML format.

### Example
Input file (`urls.txt`):
```
https://example.com
https://api.example.com/v1
https://notfound.com
```

Command:
```bash
bash gold_miner.sh -f urls.txt -o output.html
```

Output (`output.html` and console):
```
[+] url : https://example.com : 200
[+] Found possible sensitive data : YOUR_API_KEY
[+] Found api link : https://api.example.com/v1
```

## Installation
1. Ensure you have `curl` and `figlet` installed on your system:
   ```bash
   sudo apt-get install curl figlet
   ```
2. Download the `gold_miner.sh` script.
3. Make it executable:
   ```bash
   chmod +x gold_miner.sh
   ```

## Customization
- **Keywords:** Edit the `keywords` array in the script to add/remove sensitive data patterns.
- **Regex Patterns:**
  - Modify `key_value_regex` for sensitive key-value pair detection.
  - Adjust `api_regex` for API link patterns.

## Output Format
The script outputs results in the following format:
- **URLs:** `[+] url : <URL> : <Status_Code>`
- **Matches:** `[+] <MATCH>`
- **API Links:** `[+] api_link: <API_URL>`

### Example Output
Console and HTML file:
```
[+] url : https://example.com : 200
[+] Found possible sensitive data : example_api_key
[+] Found api link : https://api.example.com/v1/resource
```

## Debugging
Enable the debug flag in the script to log additional information:
```bash
DEBUG=true
```

## Contributions
Contributions are welcome! Feel free to open an issue or submit a pull request with your enhancements.

---

Feel free to adjust the customization section or add other details as needed. Let me know if you'd like to integrate more sections!
