#!/usr/bin/env python3
"""
Generate a static PNG world map colour-coded by the percentage of your
stargazers that come from each country.  The script maintains a CSV
in ".github/stargazer_countries.csv" cache so that locations are only looked
up once (unless the country entry is blank).
"""

import csv
import math
import os
import sys
import time
from collections import Counter
from pathlib import Path

import plotly.graph_objects as go
import pycountry
import requests
from geopy.geocoders import Nominatim

# ---- Configuration ----------------------------------------------------------

REPO = os.getenv("REPO")  # expected   "owner/repo"
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")  # provided by workflow
CSV_PATH = Path(".github/stargazer_countries.csv")
PNG_PATH = Path(".github/stargazer_map.png")

# ---- Rendering theme --------------------------------------------------------
# Dark, opaque panel: GitHub does not swap the image between README themes, so
# a single background has to work in both.  A dark canvas with a bright
# sequential ramp stays readable on light and dark pages alike.
BG = "#0d1117"  # page / ocean
LAND = "#2b323c"  # countries with zero stargazers (still visible)
BORDER = "#0d1117"  # country outlines, same as background
FG = "#e6edf3"  # primary text
MUTED = "#8b98a5"  # secondary text

# Viridis truncated at 35 %: even a single stargazer gets a colour that is
# clearly distinct from the empty-land grey.
SCALE = ["#2c728e", "#21918c", "#35b779", "#90d743", "#fde725"]

# pycountry names that are too long / too formal for a top-5 list
SHORT_NAMES = {
    "Russian Federation": "Russia",
    "Korea, Republic of": "South Korea",
    "Korea, Democratic People's Republic of": "North Korea",
    "Iran, Islamic Republic of": "Iran",
    "Taiwan, Province of China": "Taiwan",
    "Viet Nam": "Vietnam",
    "Moldova, Republic of": "Moldova",
    "Bolivia, Plurinational State of": "Bolivia",
    "Venezuela, Bolivarian Republic of": "Venezuela",
    "Tanzania, United Republic of": "Tanzania",
    "Syrian Arab Republic": "Syria",
}

HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json",
}
GEOL = Nominatim(user_agent="gh-stargazer-map")

# Non-answers that Nominatim happily resolves to a real place: "Earth" is a
# town in Texas, "Remote" is a settlement in Oregon.  Matched on the whole
# stripped, lowercased string only -- "Earth, TX" is someone's actual address
# and must still geocode.
JUNK_LOCATIONS = {
    "127.0.0.1",
    "/dev/null",
    "anywhere",
    "earth",
    "everywhere",
    "here",
    "home",
    "internet",
    "localhost",
    "mars",
    "moon",
    "n/a",
    "none",
    "nowhere",
    "null",
    "planet earth",
    "remote",
    "space",
    "the internet",
    "unknown",
    "world",
    "worldwide",
}


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
    if loc.strip().strip(".!").lower() in JUNK_LOCATIONS:
        return ""
    try:
        g = GEOL.geocode(loc, language="en", addressdetails=True, timeout=10)
    except Exception:
        return ""
    # Use the ISO code from the structured address: Nominatim's English display
    # names ("Russia", "Turkey", "Ivory Coast") do not all match pycountry's ISO
    # names ("Russian Federation", "Türkiye", "Côte d'Ivoire").
    code = ((g.raw.get("address") or {}).get("country_code") or "") if g else ""
    country = pycountry.countries.get(alpha_2=code.upper()) if code else None
    return country.name if country else ""


def count_by_country(cache):
    """Counter of country name -> stargazers, ignoring blank locations."""
    return Counter(c for c in cache.values() if c)


def _log_ticks(lo, hi):
    """Colourbar ticks at ... 0.1, 0.3, 1, 3, 10, 30 ... spanning [lo, hi]."""
    candidates = [m * 10**k for k in range(-3, 3) for m in (1, 3)]
    ticks = [t for t in candidates if lo / 1.5 <= t <= hi]
    return ticks or [hi]


def _fmt_pct(value):
    """1 -> '1%', 0.3 -> '0.3%' -- no trailing zeros."""
    return f"{value:.2f}".rstrip("0").rstrip(".") + "%"


def build_figure(counts, total_stargazers):
    """Build the choropleth figure from a {country name: stargazers} mapping."""
    by_iso = {}
    for name, n in counts.items():
        try:
            code = pycountry.countries.lookup(name).alpha_3
        except LookupError:
            print("Skip unknown country:", name)
            continue
        # two spellings can resolve to the same ISO code, so accumulate
        by_iso[code] = by_iso.get(code, 0) + n

    iso = list(by_iso)
    vals = [by_iso[k] for k in iso]
    # count only what is actually drawn, so the caption matches the map
    located = sum(vals) or 1
    pcts = [v / located * 100 for v in vals]
    lo, hi = (min(pcts), max(pcts)) if pcts else (1.0, 1.0)

    # The distribution is heavily long-tailed (the top country holds ~200x the
    # share of the tail), so a linear ramp collapses everything but a handful
    # of countries into the first colour step.  Colour on log10 of the share.
    ticks = _log_ticks(lo, hi)
    fig = go.Figure(
        go.Choropleth(
            locations=iso,
            locationmode="ISO-3",
            z=[math.log10(p) for p in pcts],
            zmin=math.log10(lo) - 0.15,  # keep the smallest share off the floor
            zmax=math.log10(hi),
            colorscale=SCALE,
            marker_line_color=BORDER,
            marker_line_width=0.5,
            colorbar=dict(
                title=dict(
                    text="share of located stargazers (log scale)",
                    font=dict(color=MUTED, size=13),
                    side="top",
                ),
                orientation="h",
                x=0.52,
                y=0.02,
                xanchor="center",
                yanchor="bottom",
                thickness=12,
                len=0.34,
                outlinewidth=0,
                tickvals=[math.log10(t) for t in ticks],
                ticktext=[_fmt_pct(t) for t in ticks],
                tickfont=dict(color=MUTED, size=12),
            ),
        )
    )

    fig.update_geos(
        projection_type="natural earth",
        showframe=False,
        showcoastlines=False,
        showland=True,
        landcolor=LAND,
        showocean=True,
        oceancolor=BG,
        showlakes=False,
        bgcolor=BG,
        lataxis_range=[-56, 84],  # crop Antarctica, it is always empty
        lonaxis_range=[-176, 186],
        domain=dict(x=[0.0, 1.0], y=[0.04, 0.92]),
    )

    repo = REPO or "this repository"
    caption = (
        f"{total_stargazers:,} stargazers"
        f"   |   {located:,} mapped to a country"
        f"   |   {len(by_iso)} countries"
    )
    annotations = [
        dict(
            text=f"<b>Stargazers of {repo}</b>",
            x=0.012,
            y=0.985,
            xref="paper",
            yref="paper",
            xanchor="left",
            yanchor="top",
            showarrow=False,
            font=dict(color=FG, size=25),
        ),
        dict(
            text=caption,
            x=0.012,
            y=0.925,
            xref="paper",
            yref="paper",
            xanchor="left",
            yanchor="top",
            showarrow=False,
            font=dict(color=MUTED, size=15),
        ),
        dict(
            text="Countries in grey have no located stargazer.<br>"
            "Location is read from the public GitHub profile,<br>"
            "so the map covers the located subset only.<br>"
            "Country lookup by Nominatim geocoding,<br>"
            "data © OpenStreetMap contributors.",
            x=0.988,
            y=0.05,
            xref="paper",
            yref="paper",
            xanchor="right",
            yanchor="bottom",
            align="right",
            showarrow=False,
            font=dict(color=MUTED, size=12),
        ),
    ]

    # Top 5, laid out as two separate annotations (names, share) so each column
    # stays aligned whatever the country name length -- HTML text in an SVG
    # annotation collapses padding spaces, so a monospace table would not line
    # up.
    top = counts.most_common(5)
    if top:
        base_y = 0.40
        columns = [
            (
                0.022,
                "left",
                "<br>".join(
                    f"{i}. {SHORT_NAMES.get(name, name)}"
                    for i, (name, _) in enumerate(top, 1)
                ),
                FG,
            ),
            (
                0.215,
                "right",
                "<br>".join(f"{n / located * 100:.1f}%" for _, n in top),
                FG,
            ),
        ]
        annotations.append(
            dict(
                text="<b>TOP COUNTRIES</b>",
                x=0.022,
                y=base_y,
                xref="paper",
                yref="paper",
                xanchor="left",
                yanchor="top",
                showarrow=False,
                font=dict(color=MUTED, size=13),
            )
        )
        annotations += [
            dict(
                text=text,
                x=x,
                y=base_y - 0.055,
                xref="paper",
                yref="paper",
                xanchor=anchor,
                yanchor="top",
                align=anchor,
                showarrow=False,
                font=dict(color=color, size=15),
            )
            for x, anchor, text, color in columns
        ]

    fig.update_layout(
        width=1240,
        height=680,
        paper_bgcolor=BG,
        plot_bgcolor=BG,
        margin=dict(l=0, r=0, t=0, b=0),
        annotations=annotations,
    )
    return fig


def build_choropleth(counts, total_stargazers, path=PNG_PATH):
    fig = build_figure(counts, total_stargazers)
    path.parent.mkdir(parents=True, exist_ok=True)
    # 1.5x of 1240x680 -> 1860x1020, sharp on HiDPI at README width without
    # committing a multi-megabyte PNG every week.
    fig.write_image(str(path), scale=1.5)


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

    # The cache is never pruned, so it still holds users who have since
    # unstarred.  Keep them for future geocoding, but render only current stars.
    counts = count_by_country({u: cache[u] for u in users})

    print("Rendering PNG map…")
    build_choropleth(counts, len(users))
    print(
        "Done – files saved:",
        CSV_PATH.relative_to("."),
        PNG_PATH.relative_to("."),
        sep="\n• ",
    )


if __name__ == "__main__":
    main()
