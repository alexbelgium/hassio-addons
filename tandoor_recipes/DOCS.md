## Configuration

Please check Tandoor Recipes documentation : https://docs.tandoor.dev/install/docker/

```yaml
Required :
    "ALLOWED_HOSTS": "your system url", # You need to input your homeassistant urls (comma separated, without space) to allow ingress to work
    "DB_TYPE": "list(sqlite|postgresql_external)" # Type of database to use.
    "SECRET_KEY": "str", # Your secret key
    "PORT": 9928 # By default, the webui is available on http://HAurl:9928. If you ever need to change the port, you should never do it within the app, but only through this option
    "Environment": 0|1 # 1 is debug mode, 0 is normal mode. You should run in normal mode unless actively developing.
    "GUNICORN_MEDIA": 0|1 # 1 enables gunicorn media hosting. This is not recommended. You should use an nginx server to host your media - see docs.
Optional :
    "POSTGRES_HOST": "str?", # Needed for postgresql_external
    "POSTGRES_PORT": "str?", # Needed for postgresql_external
    "POSTGRES_USER": "str?", # Needed for postgresql_external
    "POSTGRES_PASSWORD": "str?", # Needed for postgresql_external
    "POSTGRES_DB": "str?" # Needed for postgresql_external
    "externalfiles_folder": "str?" # a folder that you want to map in to tandoor. Not needed as /share/ and /media/ are mapped. This folder will be created if it doesn't already exist.
```

### Mariadb

Mariadb is a popular addon in the home assistant community, however it is not supported by the Tandoor Recipes application.

### Debug mode

This is the "Environment" setting.
0 is normal mode  
1 is debug mode.

### Authentication

using external authentication. Tandoor Recipes supports this, but it is not implemented yet.

### Gunicorn Media

Disabling gunicorn media is a good idea, but needs a webserver running to host the media files. The webserver should map `/media/`.  
See https://docs.tandoor.dev/install/docker/#nginx-vs-gunicorn for more information on this.  
0 is gunicorn DISABLED - media won't work without an nginx webserver.  
1 is gunicorn enabled - mesia will be hosted using gunicorn which is not recommended.

### External Recipe files

The directory `/config/addons_config/tandoor_recipes/externalfiles` can be used for importing external files in to Tandoor. You can map this with /opt/recipes/externalfiles within Docker. As per directions here: https://docs.tandoor.dev/features/external_recipes/
The directories `/config`, `/media/`, and `/share/` are mapped in to the addon. you can create a folder manually in any of these locations and map it in to tandoor:

- create a directory in the location you want, e.g. `/share/tandoor/recipebook/`
- create an externalstorage location in tandoor - `/share/tandoor/`
- watch the specific folder - `/share/tandoor/recipebook/`
- sync now
- import.
