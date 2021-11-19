 #!/usr/bin/env bash
 
source ./init.sh
if test -f "MakieSys.so"; then
    julia -J MakieSys.so --project 
else
    julia --optimize=1 --project
fi

