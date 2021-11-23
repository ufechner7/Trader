#!/usr/bin/env bash

cd data 
rsync -vz ufechner@vserver:~/repos/trader/data/log*.csv .
cd ..