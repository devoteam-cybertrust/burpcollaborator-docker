#!/usr/bin/env python3
"""Download and verify the latest stable Burp Suite JAR from PortSwigger."""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
import tempfile
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

DOWNLOADS_URL = "https://portswigger.net/burp/downloads"
DOWNLOAD_URL = (
    "https://portswigger.net/burp/releases/download"
    "?product=desktop&version={version}&type=Jar"
)
USER_AGENT = "burpcollaborator-docker/1.0"


class DownloadProgress:
    """Render live download progress on stderr while stdout remains machine-readable."""

    def __init__(self, total: int | None) -> None:
        self.total = total
        self.downloaded = 0

    def update(self, amount: int) -> None:
        self.downloaded += amount
        downloaded_mb = self.downloaded / (1024 * 1024)
        if self.total:
            percent = min(100, self.downloaded * 100 // self.total)
            width = 30
            complete = min(width, self.downloaded * width // self.total)
            bar = "#" * complete + "-" * (width - complete)
            total_mb = self.total / (1024 * 1024)
            message = (
                f"\rDownloading Burp Suite JAR: [{bar}] {percent:3d}% "
                f"({downloaded_mb:.1f}/{total_mb:.1f} MiB)"
            )
        else:
            message = f"\rDownloading Burp Suite JAR: {downloaded_mb:.1f} MiB"
        print(message, end="", file=sys.stderr, flush=True)

    def finish(self) -> None:
        print(file=sys.stderr, flush=True)


class DownloadMetadataParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.version: str | None = None
        self.jar_build_id: str | None = None
        self.jar_sha256: str | None = None
        self._panel_build_id: str | None = None
        self._panel_depth = 0
        self._capture_sha = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        classes = set((values.get("class") or "").split())
        if tag == "input" and values.get("id") == "CurrentVersion":
            self.version = values.get("value")
        if tag == "button" and "platform-chip" in classes and values.get("data-type") == "Jar":
            self.jar_build_id = values.get("data-build-id")
        if tag == "div" and "checksum-panel" in classes:
            self._panel_build_id = values.get("data-build-id")
            self._panel_depth = 1
        elif self._panel_depth:
            self._panel_depth += 1
        if (
            tag == "code"
            and "sha-256-checksum" in classes
            and self._panel_build_id == self.jar_build_id
        ):
            self._capture_sha = True

    def handle_endtag(self, tag: str) -> None:
        if tag == "code":
            self._capture_sha = False
        if self._panel_depth and tag == "div":
            self._panel_depth -= 1
            if self._panel_depth == 0:
                self._panel_build_id = None

    def handle_data(self, data: str) -> None:
        if self._capture_sha:
            value = data.strip().lower()
            if re.fullmatch(r"[0-9a-f]{64}", value):
                self.jar_sha256 = value


def request_bytes(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def download_latest(
    output: Path,
    metadata_url: str = DOWNLOADS_URL,
    download_url_template: str = DOWNLOAD_URL,
) -> tuple[bool, str, str]:
    parser = DownloadMetadataParser()
    parser.feed(request_bytes(metadata_url).decode("utf-8"))
    if not parser.version or not parser.jar_build_id or not parser.jar_sha256:
        raise RuntimeError("PortSwigger download metadata did not contain JAR version and checksum")

    if output.is_file() and file_sha256(output) == parser.jar_sha256:
        return False, parser.version, parser.jar_sha256

    output.parent.mkdir(parents=True, exist_ok=True)
    download_url = download_url_template.format(
        version=urllib.parse.quote(parser.version, safe="")
    )
    request = urllib.request.Request(download_url, headers={"User-Agent": USER_AGENT})
    temporary_name: str | None = None
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            content_length = getattr(response, "headers", {}).get("Content-Length")
            total = int(content_length) if content_length and content_length.isdigit() else None
            progress = DownloadProgress(total)
            try:
                with tempfile.NamedTemporaryFile(dir=output.parent, delete=False) as temporary:
                    temporary_name = temporary.name
                    digest = hashlib.sha256()
                    first_bytes = b""
                    while block := response.read(1024 * 1024):
                        if not first_bytes:
                            first_bytes = block[:4]
                        temporary.write(block)
                        digest.update(block)
                        progress.update(len(block))
                    temporary.flush()
                    os.fsync(temporary.fileno())
            finally:
                progress.finish()
        if first_bytes != b"PK\x03\x04":
            raise RuntimeError("Downloaded file is not a JAR/ZIP archive")
        actual_sha256 = digest.hexdigest()
        if actual_sha256 != parser.jar_sha256:
            raise RuntimeError(
                f"JAR checksum mismatch: expected {parser.jar_sha256}, got {actual_sha256}"
            )
        os.chmod(temporary_name, 0o644)
        os.replace(temporary_name, output)
        temporary_name = None
        return True, parser.version, parser.jar_sha256
    finally:
        if temporary_name:
            Path(temporary_name).unlink(missing_ok=True)


def main() -> int:
    argument_parser = argparse.ArgumentParser()
    argument_parser.add_argument("--output", required=True, type=Path)
    argument_parser.add_argument("--metadata-url", default=DOWNLOADS_URL)
    argument_parser.add_argument("--download-url-template", default=DOWNLOAD_URL)
    args = argument_parser.parse_args()

    print("Checking PortSwigger for the latest stable JAR...", file=sys.stderr, flush=True)
    changed, version, checksum = download_latest(
        args.output, args.metadata_url, args.download_url_template
    )
    state = "downloaded" if changed else "already-current"
    print(f"Burp Suite JAR {version}: {state} (SHA-256 {checksum})")
    print(f"BURP_JAR_CHANGED={int(changed)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
