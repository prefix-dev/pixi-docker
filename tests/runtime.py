"""Exercise a copied Pixi environment and verify its base image provenance."""

import grp
import hashlib
import json
import locale
import os
from pathlib import Path
import pwd
import sqlite3
import subprocess
import tempfile
import time
import urllib.error
import urllib.request


assert os.getpid() == 1, "The shell hook must exec the application"
pwd.getpwuid(os.getuid())
grp.getgrgid(os.getgid())
locale.setlocale(locale.LC_ALL, "")
assert locale.getencoding().lower().replace("-", "") == "utf8"
with tempfile.TemporaryFile() as temporary_file:
    temporary_file.write(b"runtime")
with sqlite3.connect(":memory:") as connection:
    assert connection.execute("SELECT 6 * 7").fetchone() == (42,)
with urllib.request.urlopen("https://prefix.dev", timeout=30) as response:
    assert response.status == 200

metadata = Path("/usr/share/pixi-runtime")
checksums = {}
for line in (metadata / "files.sha256").read_text().splitlines():
    checksum, filename = line.split("  ", 1)
    path = Path("/") / filename
    assert hashlib.sha256(path.read_bytes()).hexdigest() == checksum, path
    checksums[str(path)] = checksum

origins = {}
for line in (metadata / "origins.tsv").read_text().splitlines():
    destination, source, package = line.split("\t")
    origins[destination] = source
    sbom = json.loads((metadata / "sbom" / f"{package}.spdx.json").read_text())
    assert any(
        f"{component['name']}-{component.get('versionInfo', '')}" == package
        for component in sbom["packages"]
    ), package
assert origins.keys() == checksums.keys(), "Every extracted file needs provenance"

server = subprocess.Popen(
    ["gunicorn", "-w", "1", "docker_project:app", "--bind", "127.0.0.1:8000"]
)
try:
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        assert server.poll() is None, "Gunicorn exited before serving a request"
        try:
            with urllib.request.urlopen("http://127.0.0.1:8000", timeout=5) as response:
                assert response.read() == b"Hello, Pixi server!"
            break
        except (urllib.error.URLError, TimeoutError):
            time.sleep(0.1)
    else:
        raise RuntimeError("Gunicorn did not become ready")
finally:
    server.terminate()
    server.wait(timeout=10)
assert server.returncode == 0, "Gunicorn must shut down cleanly on SIGTERM"
print("Runtime, HTTPS, HTTP server, and file/SBOM provenance checks passed")
