#!/usr/bin/env Rscript

#récupère des arguments
args<-commandArgs(TRUE)

if (length(args)!= 0 ){
  #Charge le fichier passé en parémètre
  monfichier <- read.table(args[1])
  names(monfichier)=c("makefiles", "nbcoeurs", "time")


  #get l'ensemble des valeurs possibles pour le nom du makefile
  valeur_makefiles <- unique(as.matrix(monfichier$makefiles), incomparable=FALSE, fromLast = FALSE)
  #get le nombre de nom différent
  taille <- length(valeur_makefiles)
  attach(monfichier)

  #pour chaque makefile, génération du graphique associé
  for (i in 1 :taille){

    valeurs<- monfichier[makefiles == valeur_makefiles[i],]
    nbcoeur= as.matrix(valeurs["nbcoeurs"])
    time = as.matrix(valeurs["time"])
    #génére automatiquement a partir du nom du makefiles, le fichier de sorti
    names<-unlist(strsplit(valeur_makefiles[i], "/"))
    name<- paste0(paste0("test_pour_", names[2]),".png")
    #trace le graphique
    png(filename = name, width = 800, height=500);

    plot(nbcoeur, time);
    dev.off()

  }
}else{

  "Pour executer le script, tapper:  Rscript script.r <nom du fichier>"
}
