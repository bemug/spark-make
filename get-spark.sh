#!/bin/bash

echo "Spark installer"
echo "This script will download Spark and install it on the current directory"
echo ""
echo "WARNING: 2.5G needed to install (no joke), check your quota using 'quota'"
echo ""
echo "After instalation, go to 'bin' directory and launch 'spark-shell.sh'"
echo ""
echo "Press enter to continue"
read

URL=http://d3kbcqa49mib13.cloudfront.net/spark-1.1.1.tgz
FILE=${URL##*/}
NAME="${FILE%.*}"

if [ -f $FILE ];
then
	echo "$FILE archive found, getting stray to instalation"
else
	echo "Downloading Spark"
	wget $URL
fi

if [ -d $NAME ];
then
	echo "Removing old instalation"
	rm -rf $NAME
fi

echo "Untaring $FILE"
tar -xf $FILE

echo "Installing $NAME"
cd ./$NAME
./sbt/sbt assembly

if (($? > 0)); then
	exit 1
else
	echo "Instalation complete!"
fi
