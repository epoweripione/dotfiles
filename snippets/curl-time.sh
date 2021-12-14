#!/usr/bin/env bash

# https://www.cnblogs.com/JulianHuang/p/15682055.html
curl -w @- -o /dev/null -s "$@" <<'EOF'
    time_namelookup:  %{time_namelookup}\n
       time_connect:  %{time_connect}\n
    time_appconnect:  %{time_appconnect}\n
   time_pretransfer:  %{time_pretransfer}\n
      time_redirect:  %{time_redirect}\n
 time_starttransfer:  %{time_starttransfer}\n
                    ----------\n
         time_total:  %{time_total}\n
EOF

# alias curltime="curl -w \"@\$HOME/.curl-format.txt\" -o /dev/null -s "
