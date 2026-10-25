#!/usr/bin/env python3
"""Copy the Playwright HTML report to a publishable directory without secrets.

The report records typed text in step titles ('Type "<password>" ...'), and traces hold
localStorage and request headers with Supabase access and refresh tokens. This script:

  1. copies the report, dropping trace archives and the bundled trace viewer;
  2. replaces TEST_PASSWORD with *** in every file, including inside the zip that
     index.html embeds as base64;
  3. scans the result (zips included) for the password and for token-shaped strings,
     and exits non-zero if anything is left, so nothing unsafe gets published.

Usage: TEST_PASSWORD=... python3 sanitize-report.py <report-dir> <output-dir>
       python3 sanitize-report.py --check <dir>   (scan only)
"""
import base64
import io
import json
import os
import re
import shutil
import sys
import urllib.parse
import zipfile
from pathlib import Path

REDACTED = b'***'
EMBEDDED_ZIP = re.compile(rb'(data:application/zip;base64,)([A-Za-z0-9+/=]+)')
JWT = re.compile(rb'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.')
TOKEN_KEYS = (b'"refresh_token"', b'"access_token"', b'-auth-token')


def secret_forms(secret: str) -> list[bytes]:
    if not secret:
        return []
    forms = {
        secret,
        json.dumps(secret)[1:-1],  # as it appears inside JSON strings
        urllib.parse.quote(secret, safe=''),
        urllib.parse.quote_plus(secret),
    }
    return sorted((f.encode() for f in forms), key=len, reverse=True)


def redact(data: bytes, forms: list[bytes]) -> bytes:
    for form in forms:
        data = data.replace(form, REDACTED)
    return data


def rewrite_zip(blob: bytes, forms: list[bytes]) -> bytes:
    src = zipfile.ZipFile(io.BytesIO(blob))
    out = io.BytesIO()
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as dst:
        for info in src.infolist():
            dst.writestr(info, redact(src.read(info), forms))
    return out.getvalue()


def sanitize_file(path: Path, forms: list[bytes]) -> None:
    data = path.read_bytes()
    if path.suffix == '.zip':
        data = rewrite_zip(data, forms)
    elif path.suffix == '.html':
        data = EMBEDDED_ZIP.sub(
            lambda m: m.group(1) + base64.b64encode(
                rewrite_zip(base64.b64decode(m.group(2)), forms)),
            data,
        )
    path.write_bytes(redact(data, forms))


def blobs(path: Path):
    """Yield (label, bytes) for a file and everything nested in it."""
    data = path.read_bytes()
    yield str(path), data
    nested = []
    if path.suffix == '.zip':
        nested.append((str(path), data))
    for m in EMBEDDED_ZIP.finditer(data):
        nested.append((f'{path} (embedded zip)', base64.b64decode(m.group(2))))
    for label, blob in nested:
        try:
            z = zipfile.ZipFile(io.BytesIO(blob))
        except zipfile.BadZipFile:
            # Can't be scanned, so can't be published
            yield f'{label}: unreadable zip', None
            continue
        for name in z.namelist():
            yield f'{label}:{name}', z.read(name)


def check(root: Path, forms: list[bytes]) -> list[str]:
    problems = []
    for path in sorted(p for p in root.rglob('*') if p.is_file()):
        for label, data in blobs(path):
            if data is None:
                problems.append(label)
                continue
            if any(form in data for form in forms):
                problems.append(f'{label}: contains TEST_PASSWORD')
            if JWT.search(data):
                problems.append(f'{label}: contains a JWT')
            for key in TOKEN_KEYS:
                if key in data:
                    problems.append(f'{label}: contains {key.decode()}')
    return problems


def main() -> int:
    forms = secret_forms(os.environ.get('TEST_PASSWORD', ''))
    if len(sys.argv) == 3 and sys.argv[1] == '--check':
        out = Path(sys.argv[2])
    elif len(sys.argv) == 3:
        src, out = Path(sys.argv[1]), Path(sys.argv[2])
        shutil.rmtree(out, ignore_errors=True)
        # Trace archives live in data/*.zip; trace/ is the viewer that opens them
        shutil.copytree(src, out, ignore=lambda d, names: [
            n for n in names
            if (Path(d).name == 'data' and n.endswith('.zip'))
            or (Path(d) == src and n == 'trace')
        ])
        for path in out.rglob('*'):
            if path.is_file():
                sanitize_file(path, forms)
    else:
        print(__doc__, file=sys.stderr)
        return 2

    problems = check(out, forms)
    for problem in problems:
        print(f'::error::{problem}')
    if problems:
        print(f'{out} is not safe to publish', file=sys.stderr)
        return 1
    if not forms:
        print('::warning::TEST_PASSWORD is not set; only token checks ran')
    print(f'{out} is safe to publish')
    return 0


if __name__ == '__main__':
    sys.exit(main())
