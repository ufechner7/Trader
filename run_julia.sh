 #!/usr/bin/env bash
 
source ./init.sh
if test -f "MakieSysdev.so"; then
    julia -t auto -J MakieSysdev.so --project 
else
    julia -t auto --optimize=1 --project
fi
