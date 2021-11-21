#!/usr/bin/env bash

cd data 
LOGFILE=$(ssh vserver './pack.sh')
echo "Fetched:" $LOGFILE 
rm -f $LOGFILE
scp ufechner@vserver:~/*.xz .
unxz *.xz
cd ..