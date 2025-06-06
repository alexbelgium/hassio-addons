import os
import requests
import time
import folium
import pycountry
from geopy.geocoders import Nominatim
from collections import Counter, defaultdict

REPO = os.environ.get("REPO")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
HEADERS = {"Authorization": f"token {GITHUB_TOKEN}"}

MAP_OUTPUT = "map/index.html"
os.makedirs("map", exist_ok=True)

def get_stargazers(repo):
    users = []
    page = 1
    while True:
        url = f"https://api.github.com/repos/{repo}/stargazers?per_page=100&page={page}"
        r = requests.get(url, headers={**HEADERS, "Accept": "application/vnd.github.v3.star+json"})
        data = r.json()
        if not data:
            break
        users += [user['user']['login'] for user in data]
        page += 1
    return users

def get_user_country(login, loc_cache):
    if login in loc_cache:
        return loc_cache[login]
    url = f"https://api.github.com/users/{login}"
    r = requests.get(url, headers=HEADERS)
    profile = r.json()
    location = profile.get('location')
    country = None
    if location:
        geolocator = Nominatim(user_agent="github-stargazer-map")
        try:
            geo = geolocator.geocode(location, language="en", timeout=10)
            if geo and geo.raw.get("display_name"):
                # Try to extract country
                parts = geo.raw["display_name"].split(",")
                for part in reversed(parts):
                    try:
                        country_obj = pycountry.countries.search_fuzzy(part.strip())
                        country = country_obj[0].name
                        break
                    except LookupError:
                        continue
        except Exception:
            pass
        time.sleep(1)  # To avoid being rate-limited by Nominatim
    loc_cache[login] = country
    return country

def main():
    print("Fetching stargazers…")
    users = get_stargazers(REPO)
    print(f"Found {len(users)} stargazers")

    # Caching location lookups
    cache_path = ".github/loc_cache.json"
    if os.path.exists(cache_path):
        import json
        with open(cache_path) as f:
            loc_cache = json.load(f)
    else:
        loc_cache = {}

    country_counts = Counter()
    for i, login in enumerate(users):
        country = get_user_country(login, loc_cache)
        if country:
            country_counts[country] += 1
        print(f"{i+1}/{len(users)}: {login} -> {country}")
        # Save cache after each user (robust)
        with open(cache_path, "w") as f:
            import json; json.dump(loc_cache, f)

    total = sum(country_counts.values())
    percent_by_country = {k: v / total for k, v in country_counts.items()}

    print("Generating map…")
    m = folium.Map(location=[20,0], zoom_start=2, tiles="cartodb positron")
    import branca.colormap as cm

    # Prepare color map: 0 (white) to 1 (green)
    colormap = cm.linear.YlGn_09.scale(0, max(percent_by_country.values()) if percent_by_country else 1)

    import json
    # Get country geometries from folium's world geojson
    world = requests.get("https://raw.githubusercontent.com/python-visualization/folium/master/examples/data/world-countries.json").json()

    def country_fill(feature):
        country = feature['properties']['name']
        pct = percent_by_country.get(country, 0)
        return {
            "fillColor": colormap(pct),
            "color": "black",
            "weight": 0.5,
            "fillOpacity": 0.8 if pct > 0 else 0,
        }

    folium.GeoJson(
        world,
        style_function=country_fill,
        tooltip=folium.GeoJsonTooltip(fields=["name"]),
        highlight_function=lambda f: {"weight": 2, "color": "black"}
    ).add_to(m)

    # Add legend
    colormap.caption = "Percentage of Stargazers"
    m.add_child(colormap)

    # Save map
    m.save(MAP_OUTPUT)
    print(f"Map saved to {MAP_OUTPUT}")

if __name__ == "__main__":
    main()
