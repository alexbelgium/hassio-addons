#!/usr/bin/env python3
"""
Generate a static PNG world map colour-coded by the percentage of your
stargazers that come from each country.  The script maintains a CSV
in ".github/stargazer_countries.csv" cache so that locations are only looked
up once (unless the country entry is blank).
"""

import csv
import os
import sys
import time
from collections import Counter
from pathlib import Path

import plotly.express as px
import pycountry
import requests
from geopy.geocoders import Nominatim

# ---- Configuration ----------------------------------------------------------

REPO = os.getenv("REPO")  # expected   "owner/repo"
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")  # provided by workflow
CSV_PATH = Path(".github/stargazer_countries.csv")
PNG_PATH = Path(".github/stargazer_map.png")

HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json",
}
GEOL = Nominatim(user_agent="gh-stargazer-map")


# -----------------------------------------------------------------------------


def github_paginated(url):
    page = 1
    while True:
        resp = requests.get(f"{url}?per_page=100&page={page}", headers=HEADERS)
        resp.raise_for_status()
        data = resp.json()
        if not data:
            break
        yield from data
        page += 1


def fetch_stargazer_usernames():
    url = f"https://api.github.com/repos/{REPO}/stargazers"
    return [s["login"] for s in github_paginated(url)]


def load_cache():
    if not CSV_PATH.exists():
        return {}
    with CSV_PATH.open(newline="", encoding="utf-8") as f:
        return {row["username"]: row["country"] for row in csv.DictReader(f)}


def save_cache(cache):
    CSV_PATH.parent.mkdir(parents=True, exist_ok=True)
    with CSV_PATH.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["username", "country"])
        for user, country in sorted(cache.items()):
            w.writerow([user, country or ""])


def username_to_country(login):
    """Return readable country name or '' if unknown."""
    resp = requests.get(f"https://api.github.com/users/{login}", headers=HEADERS)
    resp.raise_for_status()
    loc = (resp.json() or {}).get("location") or ""
    if not loc.strip():
        return ""
    try:
        g = GEOL.geocode(loc, language="en", timeout=10)
    except Exception:
        return ""
    if not g or "display_name" not in g.raw:
        return ""
    # take the last comma-separated component that matches a country
    for part in reversed(g.raw["display_name"].split(",")):
        part = part.strip()
        try:
            country = pycountry.countries.lookup(part).name
            return country
        except LookupError:
            pass
    return ""


def build_choropleth(percent_by_iso):
    iso, vals = zip(*percent_by_iso.items())
    fig = px.choropleth(
        locations=list(iso),
        locationmode="ISO-3",
        color=list(vals),
        color_continuous_scale="Greens",
        range_color=(0, max(vals) if vals else 1),
    )
    fig.update_layout(
        coloraxis_colorbar=dict(
            title="% stargazers",
            orientation="h",  # <-- échelle horizontale
            x=0.5,  # <-- centré
            y=0,  # <-- tout en bas
            xanchor="center",
            yanchor="bottom",
            thickness=15,
            len=0.7,  # <-- longueur de l'échelle, ajustable
        ),
        margin=dict(l=0, r=0, t=0, b=0),
    )
    PNG_PATH.parent.mkdir(parents=True, exist_ok=True)
    fig.write_image(str(PNG_PATH), scale=2)


def main():
    if not REPO or not GITHUB_TOKEN:
        sys.exit("REPO and GITHUB_TOKEN env vars are required")

    print("Fetching stargazer list…")
    users = fetch_stargazer_usernames()
    print(f"Total stargazers: {len(users)}")

    cache = load_cache()

    # Determine which usernames need a lookup
    to_lookup = [u for u in users if cache.get(u, "") == ""]
    print(f"Need geocode for {len(to_lookup)} users")

    for i, login in enumerate(to_lookup, 1):
        country = username_to_country(login)
        cache[login] = country
        print(f"{i}/{len(to_lookup)}: {login:<20} -> {country}")
        # Nominatim polite usage
        time.sleep(1)

    # Ensure all stargazers are in cache (even those with blank location)
    for u in users:
        cache.setdefault(u, "")

    save_cache(cache)

    # Build stats
    countries = [c for c in cache.values() if c]
    counts = Counter(countries)
    total = sum(counts.values()) or 1
    pct_by_country = {c: v / total for c, v in counts.items()}

    # convert to ISO-3 for plotly
    pct_by_iso = {}
    for c, pct in pct_by_country.items():
        try:
            iso = pycountry.countries.lookup(c).alpha_3
            pct_by_iso[iso] = pct * 100  # plotly wants numeric
        except LookupError:
            print("Skip unknown country:", c)

    print("Rendering PNG map…")
    build_choropleth(pct_by_iso)
    print(
        "Done – files saved:",
        CSV_PATH.relative_to("."),
        PNG_PATH.relative_to("."),
        sep="\n• ",
    )


if __name__ == "__main__":
    main()
