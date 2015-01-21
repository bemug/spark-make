Spark Make
===

#Dépendances

* spark 1.1.1: Installer avec `./get-spark.sh`
* `pcserveur.ensimag.fr` pour centraliser

#Compilation
`./smake --compile`

#Lancement

Utiliser `smake` pour compiler et lancer.
`bench.sh` est là que pour tester les performances et ne doit pas être utilisé
pour lancer l'application.

#Scripts

* `smake`: L'appeler sans arguments pour voir l'utilisation
Exemple typique: `/smake --stop --compile --master --clear-workers --worker
ensipc77 --worker ensipc78 --start --run Makefile`
* `bench.sh`: Lance `smake` et récupère les temps d'exécution
Nécessite de modifier le code pour changer le nombre de cœurs, le makefile,
et les workers.
* `script.r`: script générant des graphiques pour les benchmarks

#Infos
Le travail terminé se trouve dans le dossier du makefile sur
pcserveur.  L'interface graphique est disponible à l'adresse du master:
`http://localhost:8080`
