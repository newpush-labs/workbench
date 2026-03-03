#!/usr/bin/env python3
import os
import re
import subprocess
import sys

CADDYFILE_PATH = "/etc/workbench/Caddyfile"

def main():
    if not os.path.exists(CADDYFILE_PATH):
        print(f"Caddyfile not found at {CADDYFILE_PATH}", file=sys.stderr)
        return

    with open(CADDYFILE_PATH, "r") as f:
        content = f.read()

    skip_auth = os.environ.get("AUTH_SKIP", "").lower() in ["true", "1", "yes"]
    username = os.environ.get("AUTH_USERNAME", "").strip()
    password = os.environ.get("AUTH_PASSWORD", "")

    if skip_auth:
        print("AUTH_SKIP is set. Disabling basic authentication in Caddyfile.")
        # Remove the basic_auth block completely
        # Matches: basic_auth /* { ... } and preceding whitespace
        content = re.sub(r'\n\s*#.*?\n\s*basic_auth\s*/\*\s*\{.*?\n\s*\}', '', content, flags=re.DOTALL)
        content = re.sub(r'\s*basic_auth\s*/\*\s*\{.*?\n\s*\}', '', content, flags=re.DOTALL)
    elif username and password:
        print(f"Custom AUTH_USERNAME ('{username}') and AUTH_PASSWORD provided. Updating Caddyfile.")
        try:
            result = subprocess.run(
                ["caddy", "hash-password", "--plaintext", password],
                capture_output=True, text=True, check=True
            )
            hash_val = result.stdout.strip()
            
            # Replace the block with the new credentials
            replacement = f"basic_auth /* {{\n        {username} {hash_val}\n    }}"
            content = re.sub(r'basic_auth\s*/\*\s*\{.*?\n\s*\}', replacement, content, flags=re.DOTALL)
        except subprocess.CalledProcessError as e:
            print(f"Failed to hash password: {e}", file=sys.stderr)
            sys.exit(1)
    
    with open(CADDYFILE_PATH, "w") as f:
        f.write(content)

if __name__ == "__main__":
    main()
