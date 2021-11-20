#!/usr/bin/env bash

cd data 
ssh vserver './pack.sh'
rm log_1637352719.csv
scp ufechner@vserver:~/*.xz .
unxz *.xz
cd ..