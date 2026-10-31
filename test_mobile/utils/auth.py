"""
Start tests signed in without going through the login screen.

Signs the test user in through the Supabase API and writes the session where
supabase_flutter restores it on launch: SharedPreferences key
'flutter.sb-<project ref>-auth-token' in shared_prefs/FlutterSharedPreferences.xml.
The /token response already has the shape of gotrue's Session.toJson, so it is
stored as-is. Writing into the app's private storage uses run-as, so this needs
the debug APK.
"""
import base64
import time
from urllib.parse import urlparse
from xml.sax.saxutils import escape

import requests

from config.config import Config

PREFS_PATH = f"@{Config.APP_PACKAGE}/shared_prefs/FlutterSharedPreferences.xml"
# Access tokens last an hour; make a new session well before that
SESSION_MAX_AGE = 45 * 60

_shared = {"value": None, "created": 0.0}


def create_session() -> str:
    """Sign the test user in through the Supabase API; returns the session JSON"""
    if not Config.SUPABASE_URL or not Config.SUPABASE_ANON_KEY:
        raise RuntimeError("SUPABASE_URL and SUPABASE_ANON_KEY must be set "
                           "(test_mobile/.env or the app's .env)")
    res = requests.post(
        f"{Config.SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": Config.SUPABASE_ANON_KEY},
        json={"email": Config.TEST_EMAIL, "password": Config.TEST_PASSWORD},
        timeout=30,
    )
    if not res.ok:
        raise RuntimeError(f"Test user sign-in failed ({res.status_code}): {res.text}")
    return res.text


def shared_session() -> str:
    """One session reused across tests, renewed before its access token expires"""
    if not _shared["value"] or time.time() - _shared["created"] > SESSION_MAX_AGE:
        _shared["value"], _shared["created"] = create_session(), time.time()
    return _shared["value"]


def _prefs_xml(session_json: str) -> str:
    project_ref = urlparse(Config.SUPABASE_URL).hostname.split(".")[0]
    value = escape(session_json, {'"': "&quot;"})
    return ("<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n"
            f'    <string name="flutter.sb-{project_ref}-auth-token">{value}</string>\n'
            "</map>\n")


def store_session(driver, session_json: str):
    """Write the session into the (not yet launched) app's SharedPreferences"""
    data = base64.b64encode(_prefs_xml(session_json).encode()).decode()
    driver.push_file(PREFS_PATH, base64data=data)
