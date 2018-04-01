#!/bin/bash
# This is a workaround for a suspected (babeld?) memory leak
# https://github.com/sudomesh/bugs/issues/24

set -e

date_last_error=$(sudo journalctl -u babeld -o short-iso | grep "Cannot allocate memory" | tail -n1 | awk '{print $1}')

date_last_started=$(sudo journalctl -u babeld -o short-iso | grep "Started babeld" | tail -n1 | awk '{print $1}')

if [[ "$date_last_error" == "" || "$date_last_started" == "" ]]; then
    echo "found no [Cannot allocate memory] error entry or babeld is not running"
else
  if [[$(date -d $date_last_error) > $(date -d $date_last_restart)]]; then
    echo "found [Cannot allocate memory] error since last babeld restart"
    echo "babeld restarting..."
    service babeld restart
    echo "babeld restarted."
    # add tunnel interfaces to babeld
    echo "add tunnel interfaces to babeld..."
    ip addr | tr ' ' '\n' | grep -E "l2tp[0-9]+$" | sort | uniq | xargs -L 1 babeld -a 
    echo "add tunnel interfaces to babeld done."
  else
    echo "found no [Cannot allocate memory] error since last babeld restart"
  fi
fi


