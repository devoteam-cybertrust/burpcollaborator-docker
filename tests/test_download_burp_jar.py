import hashlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).parents[1] / "certbot" / "download_burp_jar.py"
SPEC = importlib.util.spec_from_file_location("download_burp_jar", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


class Response(io.BytesIO):
    def __init__(self, content=b"", content_length=None):
        super().__init__(content)
        self.headers = {}
        if content_length is not None:
            self.headers["Content-Length"] = str(content_length)

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        self.close()


class BrokenResponse(Response):
    def read(self, _size=-1):
        raise OSError("connection interrupted")


def metadata(checksum):
    return f"""
    <input id="CurrentVersion" value="2026.6">
    <button class="platform-chip" data-build-id="42" data-type="Jar">JAR</button>
    <div class="checksum-panel" data-build-id="42">
      <code class="sha-256-checksum">{checksum}</code>
    </div>
    """.encode()


class DownloadTests(unittest.TestCase):
    def test_progress_bar_reports_download_percentage(self):
        progress = io.StringIO()
        with patch.object(MODULE.sys, "stderr", progress):
            reporter = MODULE.DownloadProgress(10)
            reporter.update(5)
            reporter.update(5)
            reporter.finish()
        rendered = progress.getvalue()
        self.assertIn("50%", rendered)
        self.assertIn("100%", rendered)
        self.assertTrue(rendered.endswith("\n"))

    def test_downloads_verified_jar_atomically(self):
        jar = b"PK\x03\x04new jar"
        checksum = hashlib.sha256(jar).hexdigest()
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "burp.jar"
            with patch.object(MODULE, "request_bytes", return_value=metadata(checksum)):
                with patch.object(MODULE.urllib.request, "urlopen", return_value=Response(jar)):
                    changed, version, actual = MODULE.download_latest(output)
            self.assertTrue(changed)
            self.assertEqual(version, "2026.6")
            self.assertEqual(actual, checksum)
            self.assertEqual(output.read_bytes(), jar)

    def test_current_jar_is_not_downloaded_or_replaced(self):
        jar = b"PK\x03\x04current jar"
        checksum = hashlib.sha256(jar).hexdigest()
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "burp.jar"
            output.write_bytes(jar)
            with patch.object(MODULE, "request_bytes", return_value=metadata(checksum)):
                with patch.object(MODULE.urllib.request, "urlopen") as urlopen:
                    changed, _, _ = MODULE.download_latest(output)
            self.assertFalse(changed)
            urlopen.assert_not_called()
            self.assertEqual(output.read_bytes(), jar)

    def test_checksum_failure_preserves_existing_jar(self):
        old_jar = b"PK\x03\x04old jar"
        downloaded = b"PK\x03\x04tampered jar"
        expected = hashlib.sha256(b"PK\x03\x04expected jar").hexdigest()
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "burp.jar"
            output.write_bytes(old_jar)
            with patch.object(MODULE, "request_bytes", return_value=metadata(expected)):
                with patch.object(
                    MODULE.urllib.request, "urlopen", return_value=Response(downloaded)
                ):
                    with self.assertRaisesRegex(RuntimeError, "checksum mismatch"):
                        MODULE.download_latest(output)
            self.assertEqual(output.read_bytes(), old_jar)

    def test_invalid_metadata_preserves_existing_jar(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "burp.jar"
            output.write_bytes(b"existing")
            with patch.object(MODULE, "request_bytes", return_value=b"<html></html>"):
                with self.assertRaisesRegex(RuntimeError, "metadata"):
                    MODULE.download_latest(output)
            self.assertEqual(output.read_bytes(), b"existing")

    def test_interrupted_download_preserves_existing_jar(self):
        expected = hashlib.sha256(b"PK\x03\x04expected").hexdigest()
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "burp.jar"
            output.write_bytes(b"existing")
            with patch.object(MODULE, "request_bytes", return_value=metadata(expected)):
                with patch.object(
                    MODULE.urllib.request, "urlopen", return_value=BrokenResponse()
                ):
                    with self.assertRaisesRegex(OSError, "interrupted"):
                        MODULE.download_latest(output)
            self.assertEqual(output.read_bytes(), b"existing")

    def test_non_jar_download_preserves_existing_jar(self):
        downloaded = b"an error page"
        expected = hashlib.sha256(downloaded).hexdigest()
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "burp.jar"
            output.write_bytes(b"existing")
            with patch.object(MODULE, "request_bytes", return_value=metadata(expected)):
                with patch.object(
                    MODULE.urllib.request, "urlopen", return_value=Response(downloaded)
                ):
                    with self.assertRaisesRegex(RuntimeError, "not a JAR"):
                        MODULE.download_latest(output)
            self.assertEqual(output.read_bytes(), b"existing")


if __name__ == "__main__":
    unittest.main()
