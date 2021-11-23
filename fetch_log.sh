#!/usr/bin/env bash

cd data 
rsync -v ufechner@vserver:~/repos/trader/data/log*.csv .
cd ..