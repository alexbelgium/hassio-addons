## Environment Variables

<!-- markdownlint-disable MD007 MD010 MD030 MD033 -->

There are a few optional environment variables available for customizing a Whoogle instance. These can be set manually, or copied into `whoogle.env` and enabled for your preferred deployment method:

- Local runs: Set `WHOOGLE_DOTENV=1` before running
- With `docker-compose`: Uncomment the `env_file` option
- With `docker build/run`: Add `--env-file ./whoogle.env` to your command

| Variable                 | Description                                                                                  |
| ------------------------ | -------------------------------------------------------------------------------------------- |
| WHOOGLE_DOTENV           | Load environment variables in `whoogle.env`                                                  |
| WHOOGLE_USER             | The username for basic auth. WHOOGLE_PASS must also be set if used.                          |
| WHOOGLE_PASS             | The password for basic auth. WHOOGLE_USER must also be set if used.                          |
| WHOOGLE_PROXY_USER       | The username of the proxy server.                                                            |
| WHOOGLE_PROXY_PASS       | The password of the proxy server.                                                            |
| WHOOGLE_PROXY_TYPE       | The type of the proxy server. Can be "socks5", "socks4", or "http".                          |
| WHOOGLE_PROXY_LOC        | The location of the proxy server (host or ip).                                               |
| EXPOSE_PORT              | The port where Whoogle will be exposed.                                                      |
| HTTPS_ONLY               | Enforce HTTPS. (See [here](https://github.com/benbusby/whoogle-search#https-enforcement))    |
| WHOOGLE_ALT_TW           | The twitter.com alternative to use when site alternatives are enabled in the config.         |
| WHOOGLE_ALT_YT           | The youtube.com alternative to use when site alternatives are enabled in the config.         |
| WHOOGLE_ALT_IG           | The instagram.com alternative to use when site alternatives are enabled in the config.       |
| WHOOGLE_ALT_RD           | The reddit.com alternative to use when site alternatives are enabled in the config.          |
| WHOOGLE_ALT_TL           | The Google Translate alternative to use. This is used for all "translate \_\_\_\_" searches. |
| WHOOGLE_ALT_MD           | The medium.com alternative to use when site alternatives are enabled in the config.          |
| WHOOGLE_AUTOCOMPLETE     | Controls visibility of autocomplete/search suggestions. Default on -- use '0' to disable     |
| WHOOGLE_MINIMAL          | Remove everything except basic result cards from all search queries.                         |
| WHOOGLE_CSP              | Sets a default set of 'Content-Security-Policy' headers                                      |
| WHOOGLE_RESULTS_PER_PAGE | Set the number of results per page                                                           |

### Config Environment Variables

These environment variables allow setting default config values, but can be overwritten manually by using the home page config menu. These allow a shortcut for destroying/rebuilding an instance to the same config state every time.

| Variable                       | Description                                                   |
| ------------------------------ | ------------------------------------------------------------- |
| WHOOGLE_CONFIG_DISABLE         | Hide config from UI and disallow changes to config by client  |
| WHOOGLE_CONFIG_COUNTRY         | Filter results by hosting country                             |
| WHOOGLE_CONFIG_LANGUAGE        | Set interface language                                        |
| WHOOGLE_CONFIG_SEARCH_LANGUAGE | Set search result language                                    |
| WHOOGLE_CONFIG_BLOCK           | Block websites from search results (use comma-separated list) |
| WHOOGLE_CONFIG_THEME           | Set theme mode (light, dark, or system)                       |
| WHOOGLE_CONFIG_SAFE            | Enable safe searches                                          |
| WHOOGLE_CONFIG_ALTS            | Use social media site alternatives (nitter, invidious, etc)   |
| WHOOGLE_CONFIG_NEAR            | Restrict results to only those near a particular city         |
| WHOOGLE_CONFIG_TOR             | Use Tor routing (if available)                                |
| WHOOGLE_CONFIG_NEW_TAB         | Always open results in new tab                                |
| WHOOGLE_CONFIG_VIEW_IMAGE      | Enable View Image option                                      |
| WHOOGLE_CONFIG_GET_ONLY        | Search using GET requests only                                |
| WHOOGLE_CONFIG_URL             | The root url of the instance (`https://<your url>/`)          |
| WHOOGLE_CONFIG_STYLE           | The custom CSS to use for styling (should be single line)     |

## Usage

Same as most search engines, with the exception of filtering by time range.

To filter by a range of time, append ":past <time>" to the end of your search, where <time> can be `hour`, `day`, `month`, or `year`. Example: `coronavirus updates :past hour`

## Extra Steps

### Set Whoogle as your primary search engine

_Note: If you're using a reverse proxy to run Whoogle Search, make sure the "Root URL" config option on the home page is set to your URL before going through these steps._

Browser settings:

- Firefox (Desktop)
  - Version 89+
    - Navigate to your app's url, right click the address bar, and select "Add Search Engine".
  - Previous versions
    - Navigate to your app's url, and click the 3 dot menu in the address bar. At the bottom, there should be an option to "Add Search Engine".
  - Once you've added the new search engine, open your Firefox Preferences menu, click "Search" in the left menu, and use the available dropdown to select "Whoogle" from the list.
  - **Note**: If your Whoogle instance uses Firefox Containers, you'll need to [go through the steps here](https://github.com/benbusby/whoogle-search/blob/main/README.md#using-with-firefox-containers) to get it working properly.
- Firefox (iOS)
  - In the mobile app Settings page, tap "Search" within the "General" section. There should be an option titled "Add Search Engine" to select. It should prompt you to enter a title and search query url - use the following elements to fill out the form:
    - Title: "Whoogle"
    - URL: `http[s]://\<your whoogle url\>/search?q=%s`
- Firefox (Android)
  - Version <79.0.0
    - Navigate to your app's url
    - Long-press on the search text field
    - Click the "Add Search Engine" menu item
      - Select a name and click ok
    - Click the 3 dot menu in the top right
    - Navigate to the settings menu and select the "Search" sub-menu
    - Select Whoogle and press "Set as default"
  - Version >=79.0.0
    - Click the 3 dot menu in the top right
    - Navigate to the settings menu and select the "Search" sub-menu
    - Click "Add search engine"
    - Select the 'Other' radio button
      - Name: "Whoogle"
      - Search string to use: `https://\<your whoogle url\>/search?q=%s`
- [Alfred](https://www.alfredapp.com/) (Mac OS X)

  1.  Go to `Alfred Preferences` > `Features` > `Web Search` and click `Add Custom Search`. Then configure these settings

      - Search URL: `https://\<your whoogle url\>/search?q={query}
      - Title: `Whoogle for '{query}'` (or whatever you want)
      - Keyword: `whoogle`

  2.  Go to `Default Results` and click the `Setup fallback results` button. Click `+` and add Whoogle, then drag it to the top.

- Chrome/Chromium-based Browsers
  - Automatic
    - Visit the home page of your Whoogle Search instance -- this may automatically add the search engine to your list of search engines. If not, you can add it manually.
  - Manual
    - Under search engines > manage search engines > add, manually enter your Whoogle instance details with a `<whoogle url>/search?q=%s` formatted search URL.
