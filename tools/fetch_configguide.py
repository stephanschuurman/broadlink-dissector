#!/usr/bin/env python3
"""
Fetch the Broadlink config guide and optionally download images.

Usage:
  python3 fetch_configguide.py            # only fetch and save JSON
  python3 fetch_configguide.py --images   # also download all images
"""

import argparse
import hashlib
import json
import os
import re
import ssl
import sys
import time
from urllib.parse import urlparse, parse_qs, quote
from urllib.request import urlopen, Request
from urllib.error import URLError

try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
except ImportError:
    pass  # python-dotenv not installed; fall back to environment variables

# Broadlink servers use a self-signed certificate chain
_SSL_CTX = ssl.create_default_context()
_SSL_CTX.check_hostname = False
_SSL_CTX.verify_mode = ssl.CERT_NONE

API_URL = os.environ.get("BROADLINK_API_URL", "https://ai-service-eu-001.ibroadlink.com/vtproxy/common")

HEADERS = {
    "messageId": "0",  # overridden per request with current epoch timestamp
    "Accept": "*/*",
    "userid": os.environ["BROADLINK_USER_ID"],
    "licenseid": os.environ["BROADLINK_LICENSE_ID"],
    "Accept-Language": os.environ.get("BROADLINK_ACCEPT_LANGUAGE", "en"),
    "Accept-Encoding": "identity",
    "Content-Type": "application/json",
    "language": "en",
    "User-Agent": os.environ.get("BROADLINK_USER_AGENT", "BroadLink"),
    "companyid": os.environ["BROADLINK_COMPANY_ID"],
}

# Environment variables (required unless noted):
#   BROADLINK_USER_ID       — 32-char hex string identifying the app user
#   BROADLINK_LICENSE_ID    — 32-char hex string, app licence key
#   BROADLINK_COMPANY_ID    — 32-char hex string, OEM company identifier
#   BROADLINK_USER_AGENT    — (optional) HTTP User-Agent string;
#                              e.g. "BroadLink/1.7.67 (iPad; iOS 26.3; Scale/2.00)"
#   BROADLINK_ACCEPT_LANGUAGE — (optional) BCP 47 language tag(s);
#                              e.g. "nl-NL;q=1, en-NL;q=0.9" (default: "en")
#   BROADLINK_API_URL       — (optional) override the API endpoint URL
# Copy .env.example to .env and fill in the values.

TYPEIDS = [
    "1000168901000000000076accfe44d8e", # Universal Remote
    "1000168901000000000030a5fc8ab9e1", # Gateway
    "1000168901000000000030a5fc8ab9e2", # S3 Smart Kit
    "100016890100000000002dc8a03f3b8c", # Sensor
    "1000168901000000000099c3a0c31920", # Smart Plug
    "10001689010000000000fd364e3dfdfa", # Smart Bulb
    "10001689010000000000a78d070efef4", # General Wifi Device
]

BASE_PAYLOAD = {
    "devpid": "",
    "pid": "00000000000000000000000017890100",
    "ope": "getconfigguide",
}

IMAGE_FIELDS = ["productimage", "gif1", "gif1_night", "gif2"]


def filename_from_url(url: str) -> str:
    """Derive a local filename from a vtstaticfile URL using fileid + original name."""
    qs = parse_qs(urlparse(url).query)
    fileid = qs.get("fileid", ["unknown"])[0]
    name = qs.get("name", ["file"])[0]
    safe_name = re.sub(r"[^\w.\-]", "_", name)
    return f"{fileid}_{safe_name}"


def collect_urls(data: list) -> dict[str, str]:
    """Walk the data array and collect all unique image URLs -> local filenames."""
    urls: dict[str, str] = {}
    for item in data:
        for field in IMAGE_FIELDS:
            url = item.get(field, "")
            if url and url not in urls:
                urls[url] = filename_from_url(url)
        for method in item.get("configmethod", []):
            for field in IMAGE_FIELDS:
                url = method.get(field, "")
                if url and url not in urls:
                    urls[url] = filename_from_url(url)
    return urls


def fetch_api(typedid: str) -> tuple[dict, list]:
    payload = {"typedid": typedid, **BASE_PAYLOAD}
    body = json.dumps(payload).encode()
    headers = {**HEADERS, "messageId": str(int(time.time()))}
    req = Request(API_URL, data=body, headers=headers, method="POST")
    with urlopen(req, timeout=30, context=_SSL_CTX) as resp:
        response_data = json.loads(resp.read().decode())
    if response_data.get("status") != 0:
        raise RuntimeError(f"API error: {response_data.get('msg')}")
    return response_data, response_data["data"]


def download_file(url: str, dest: str) -> bool:
    if os.path.exists(dest):
        print(f"  skip (exists): {os.path.basename(dest)}")
        return False
    safe_url = quote(url, safe=":/?=&%+#")
    req = Request(safe_url, headers={"User-Agent": HEADERS["User-Agent"]})
    try:
        with urlopen(req, timeout=30, context=_SSL_CTX) as resp:
            with open(dest, "wb") as f:
                f.write(resp.read())
        print(f"  downloaded:    {os.path.basename(dest)}")
        return True
    except URLError as e:
        print(f"  FAILED:        {os.path.basename(dest)} ({e})", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="Fetch Broadlink config guide data.")
    parser.add_argument(
        "--images", action="store_true", help="also download all images"
    )
    args = parser.parse_args()

    base_dir = os.path.dirname(os.path.abspath(__file__))

    all_data: list = []
    combined: dict = {}

    for typedid in TYPEIDS:
        print(f"Fetching {typedid}…")
        try:
            response_data, data = fetch_api(typedid)
        except Exception as e:
            print(f"  FAILED: {e}", file=sys.stderr)
            continue
        print(f"  {len(data)} products")
        all_data.extend(data)
        combined[typedid] = response_data

    print(f"\nTotal: {len(all_data)} products across {len(TYPEIDS)} requests.")

    json_path = os.path.join(base_dir, "configguide.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(combined, f, ensure_ascii=False, indent=2)
    print(f"JSON saved to {json_path}")

    if not args.images:
        return

    out_dir = os.path.join(base_dir, "images")
    os.makedirs(out_dir, exist_ok=True)

    urls = collect_urls(all_data)
    print(f"\nFound {len(urls)} unique image URLs.\n")

    downloaded = skipped = failed = 0
    for url, fname in sorted(urls.items(), key=lambda x: x[1]):
        dest = os.path.join(out_dir, fname)
        result = download_file(url, dest)
        if result is True:
            downloaded += 1
        elif result is False and os.path.exists(dest):
            skipped += 1
        else:
            failed += 1

    print(f"\nDone. {downloaded} downloaded, {skipped} skipped, {failed} failed.")


if __name__ == "__main__":
    main()
