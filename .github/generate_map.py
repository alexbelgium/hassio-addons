import os
import requests
import time
import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt

REPO = os.environ.get("REPO")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
HEADERS = {"Authorization": f"token {GITHUB_TOKEN}"}
COUNTRY_FILE = "stargazers_countries.csv"
PNG_FILE = "stargazer_map.png"

def get_stargazers(repo):
    users = []
    page = 1
    while True:
        url = f"https://api.github.com/repos/{repo}/stargazers?per_page=100&page={page}"
        r = requests.get(url, headers={**HEADERS, "Accept": "application/vnd.github.v3.star+json"})
        if r.status_code != 200:
            raise RuntimeError(f"GitHub API error: {r.status_code}")
        data = r.json()
        if not data:
            break
        users += [user['user']['login'] for user in data]
        page += 1
    return users

def get_user_country(login):
    url = f"https://api.github.com/users/{login}"
    r = requests.get(url, headers=HEADERS)
    profile = r.json()
    location = profile.get('location')
    country = None
    if location:
        try:
            import pycountry
            from geopy.geocoders import Nominatim
            geolocator = Nominatim(user_agent="github-stargazer-map")
            geo = geolocator.geocode(location, language="en", timeout=10)
            if geo and geo.raw.get("display_name"):
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
        time.sleep(1)
    return country

def main():
    # Step 1: Load or create user-country cache
    if os.path.exists(COUNTRY_FILE):
        df = pd.read_csv(COUNTRY_FILE)
    else:
        users = get_stargazers(REPO)
        countries = []
        for i, user in enumerate(users):
            print(f"{i+1}/{len(users)}: {user}")
            country = get_user_country(user)
            print(f"    => {country}")
            countries.append((user, country or "Unknown"))
            # Save progress
            pd.DataFrame(countries, columns=["user", "country"]).to_csv(COUNTRY_FILE, index=False)
        df = pd.DataFrame(countries, columns=["user", "country"])

    # Step 2: Calculate stargazer percentages per country
    country_counts = df['country'].value_counts()
    total = country_counts.sum()
    country_perc = (country_counts / total * 100).to_dict()

    # Step 3: Plot map with colored countries
    world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))
    world['country'] = world['name']
    world['stargazer_perc'] = world['country'].map(country_perc).fillna(0)

    fig, ax = plt.subplots(figsize=(18, 9))
    world.plot(column='stargazer_perc',
               ax=ax,
               cmap='Greens',
               linewidth=0.8,
               edgecolor='0.8',
               legend=True,
               legend_kwds={'label': "Stargazers per country (%)", 'shrink': 0.6})

    ax.set_title(f"GitHub Stargazers by Country: {REPO}", fontsize=18)
    ax.axis('off')
    plt.tight_layout()
    plt.savefig(PNG_FILE, dpi=200)
    print(f"Map saved to {PNG_FILE}")
    print(f"Countries saved to {COUNTRY_FILE}")

if __name__ == "__main__":
    main()
