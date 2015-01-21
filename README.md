Spark Make
===

#Dependances

* spark 1.1.1: Installer avec `./get-spark.sh`
* pcserveur.ensimag.fr pour centraliser

#Compilation
./smake --compile

#Scripts

* `smake`: L'appeler sans arguments pour voir l'utilisation
Exemple typique: ./smake --stop --compile --master --clear-workers --worker ensipc77
--worker ensipc78 --start --run Makefile
* `bench.sh`: Lance `smake` et recupere les temps d'execution
Necessite de modifier le code pour changer le nombre de core, le makefile, et
les workers
* `rgraphs`: script générant des graphs pour les benchmarks

#Infos
Le travail terminé se trouve dans le dossier du makefile sur pcserveur.
L'interface graphique est disponible à l'adresse du master:
http://localhost:8080
