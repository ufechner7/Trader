 #!/usr/bin/env bash
 
source ./init.sh
if test -f "MakieSysDev.so"; then
    julia -t auto -J MakieSysDev.so --project 
else
    julia -t auto --optimize=1 --project
fi
