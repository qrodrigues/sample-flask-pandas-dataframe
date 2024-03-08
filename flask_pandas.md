# Démarrage du projet

Je démarre mon environnement virtuel Python venv. Puis j'exécute ces commandes.
```shell
pip install -r requirements.txt
/bin/sh init_database.sh
flask run --host=0.0.0.0 --port=31201
```

Le fichier init_database.sh est un script shell qui permet de créer et remplir la base de données :
```shell
flask shell << shell
from app import db;
db.create_all();
quit()
shell

flask load-data titanic-min.csv
``` 