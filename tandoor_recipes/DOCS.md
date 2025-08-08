## Configuration

Please check Tandoor Recipes documentation : https://docs.tandoor.dev/install/docker/

```yaml
Required :
    "ALLOWED_HOSTS": "your system url", # You need to input your homeassistant urls (comma separated, without space) to allow ingress to work
    "DB_TYPE": "list(sqlite|postgresql_external)" # Type of database to use.
    "SECRET_KEY": "str", # Your secret key
    "Environment": 0|1 # 1 is debug mode, 0 is normal mode. You should run in normal mode unless actively developing.
Optional :
    "POSTGRES_HOST": "str?", # Needed for postgresql_external
    "POSTGRES_PORT": "str?", # Needed for postgresql_external
    "POSTGRES_USER": "str?", # Needed for postgresql_external
    "POSTGRES_PASSWORD": "str?", # Needed for postgresql_external
    "POSTGRES_DB": "str?" # Needed for postgresql_external
    "AI_MODEL_NAME": "str?", # Used when configuring llm integration
    "AI_API_KEY": "str?", # Used when configuring llm integration
    "AI_RATELIMIT": "int?", # Used when configuring llm integration
    "externalfiles_folder": "str?" # a folder that you want to map in to tandoor. Not needed as /share/ and /media/ are mapped. This folder will be created if it doesn't already exist.
```
This add-on now uses Tandoor's integrated Nginx server and exposes port 80 (mapped to 9928 by default).

### Mariadb
Mariadb is a popular addon in the home assistant community, however it is not supported by the Tandoor Recipes application.

### Debug mode
This is the "Environment" setting.
0 is normal mode
1 is debug mode.

### Authentication
using external authentication. Tandoor Recipes supports this, but it is not implemented yet.


### External Recipe files

The directory `/config/addons_config/tandoor_recipes/externalfiles` can be used for importing external files in to Tandoor. You can map this with /opt/recipes/externalfiles within Docker. As per directions here: https://docs.tandoor.dev/features/external_recipes/
The directories `/config`, `/media/`, and `/share/` are mapped in to the addon. you can create a folder manually in any of these locations and map it in to tandoor:
- create a directory in the location you want, e.g. `/share/tandoor/recipebook/`
- create an externalstorage location in tandoor - `/share/tandoor/`
- watch the specific folder - `/share/tandoor/recipebook/`
- sync now
- import.
