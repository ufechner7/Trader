 #!/usr/bin/env bash
 
source ./init.sh
if test -f "MakieSysDev.so"; then
    julia -t auto -J MakieSysdev.so --project 
else
    julia --optimize=1 --project
fi
