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

# Création du dockerfile
Afin de créer le dockerfile, j'ai commencé par chercher une image Python fonctionnelle. Je voulais partir sur la **python:3.10.1-slim-buster**, cependant elle me provoquait un bug lors de l'installation de mes requirements (problème de thread). Donc j'ai utilisé celle-ci : **python:3.10.1-slim-buster**.

```dockerfile
FROM python:3.10.1-slim-buster
RUN apt-get update && apt-get install -y netcat #maj des packages
```

J'initialise le projet sur le container
```dockerfile
WORKDIR /app
COPY . /app/
RUN pip install --upgrade pip
```

J'installe les paquets dans le requirements.txt
```dockerfile
RUN pip install -r requirements.txt
```

Je configure la variable d'environnement nécessaire au lancement de l'application
```dockerfile
ENV FLASK_APP=app.py
```

J'autorise l'exécution et je démarre le script shell (présenté ci-dessus) pour initialiser et remplir la base de données
```dockerfile
RUN chmod +x init_database.sh
RUN /bin/sh init_database.sh
```

J'expose le port souhaité pour docker, et je run l'application flask
```dockerfile
EXPOSE 5000
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000", "--debug"]
```

Le dockerfile est donc terminé et se build très bien.

# Build, run et envoie de l'image sur docker hub
Afin de construire mon image docker, j'ai utilisé la commande ci-dessous, en étant placé dans le même répertoire que le Dockerfile.
```shell
docker build -t fil-rouge .
```

Je peux run l'image dans un container Docker comme ceci
```shell
docker run -d -p 31201:5000 --name flask-fil-rouge flask-fil-rouge
```
si nécessaire, je peux supprimer le container si il existe déjà
```shell
docker rm -f flask-fil-rouge
```

Pour envoyer l'image sur Dockerhub, je me connecte au Docker hub, puis je tag l'image, et je la push sur dockerhub.
```shell
docker login -u qrodrigues19
docker image tag flask-fil-rouge qrodrigues19/flask-panda
docker push qrodrigues19/flask-panda
```

# Mise en place d'un plan de test
## Jmeter
Afin de mettre en place un plan de test, j'utilise JMeter. Et je construis mon plan de test.

Dans le Response Assertion, pour vérifier si il y a des données, je regarde si **Rows = 0**, est je coche la case **NOT**. Dans ce cas, le test passera si le nombre de rows dans la base de données n'est pas égale à 0.
Je peux également vérifier si **Rows = 5**, car je sais que dans ma base de données il y a 5 enregistrements, mais c'est moins générique.

Une fois mon plan de test créé et testé, je récupère le fichier de test, je le met dans mon repos git, pour que Jenkins puisse l'utiliser.

## Jenkins
Sur la partie Jenkins, je créé un nouveau projet de test, il s'appelle : **flask-panda-jmeter**. Je le lis à mon repos github : https://github.com/qrodrigues/sample-flask-pandas-dataframe.git.