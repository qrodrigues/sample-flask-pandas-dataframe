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

![image](https://github.com/qrodrigues/sample-flask-pandas-dataframe/assets/84842857/987baa4f-a0b7-4c4f-a7c1-c9ce6cf30653)


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

Je choisi en étape de build, l'exécution d'un script shell, le script est le suivant
```shell
jmeter -Jjmeter.save.saveservice.output_format=xml -Jjmeter.save.saveservice.response_data.on_error=true -n -t flask_test_plan.jmx  -l testresult.jlt
```

Je vérifie que j'utilise bien, dans le script shell, le fichier de test créé par JMeter (**flask_test_plan.jmx**).

En action à la suite du build, je configure une **Console output (build log) parsing**, avec une règle de projet qui est **parserules**.

Pour que cela fonctionne, j'ai pris le soin d'ajouter la règle parserules dans mon projet. Et je l'ai bien push sur le repos git.

J'ajoute une seconde action après le build, **Publish Performance test result report**, qui va me publier mon résultat de test, avec le fichier source **testresult.jlt**.

![image](https://github.com/qrodrigues/sample-flask-pandas-dataframe/assets/84842857/96292f54-94db-4380-beb9-5c1c1b74b13e)


Et voilà, le test est fonctionnel.

# Jenkins
## Build automatique du projet
Afin de lancer le build automatique de mon projet, notament après un push, je vais créé un webhook github, relié à Jenkins, pour cela je l'ajoute dans mon repos github avec l'url : http://34.155.157.127:32500/github-webhook/

Ensuite, je créé un nouvel item sur Jenkins, que je nomme **flask-panda-build**. Je le relis à mon repository Git : https://github.com/qrodrigues/sample-flask-pandas-dataframe.

Je coche **GitHub hook trigger for GITScm polling** pour démarrer le build au push github.

Et j'exécute des commandes shell. Aujourd'hui, les builds docker ne fonctionnent pas avec la VM fournie, cependant les commandes à exécuter sont les suivantes :
```shell
# Build image
docker build -t fil-rouge .

docker rm -f flask-fil-rouge
docker run -d -p 31201:5000 --name flask-fil-rouge flask-fil-rouge

# Login to docker hub
docker login -u qrodrigues19

# Push image
docker image tag flask-fil-rouge qrodrigues19/flask-panda
docker push qrodrigues19/flask-panda
```

![image](https://github.com/qrodrigues/sample-flask-pandas-dataframe/assets/84842857/99a55084-4f77-464c-b222-79fb2c2c8db3)

Maintenant que cela est configuré, je peux build mon Docker automatiquement après chaque push sur github.

## Pipeline
Afin de créer mon pipeline Jenkins, je vais créer une nouvelle vue, et je vais lui configurer un job initial, c'est **flask-panda-build**.

Désormais, la première étape du pipeline est le build du Dockerfile. Maintenant, je vais configurer le projet **flask-panda-build** pour que quand il termine, il lancer automatiquement le projet de test jmeter. Ainsi, le pipeline aura une deuxième étape.

Pour cela, je me rend dans le projet, et je configure une action à la suite du build, et je sélectionne la construction du projet **flask-panda-build**.

Mon pipeline est désormais entièrement fonctionnel.

# Conclusion
Nous avons réaliser un pipeline, du Dockerfile jusqu'au test, permettant, au push sur Github, de build et déployer notre image, et d'effectuer des tests pour vérifier si cela fonctionne.

![image](https://github.com/qrodrigues/sample-flask-pandas-dataframe/assets/84842857/c80cc031-3f0c-40f6-aafb-6bb738e30183)
