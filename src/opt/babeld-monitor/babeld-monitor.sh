#!/bin/bash
# This is a workaround for a suspected (babeld?) memory leak
# https://github.com/sudomesh/bugs/issues/24


wait_for_babeld() {
  local try_count=0
  local try_max=20
  local try_sleep=5

  while [ "$try_count" -lt "$try_max" ]; do
    babeld -i
    local exit_status=$?
    if [[ exit_status -eq 0 ]]; then
      echo "babeld initialized."
      break;
    else
      try_count=`expr $try_count + 1`
      echo "waiting [$try_sleep]s for babeld to initialize... try [$try_count]"
      sleep $try_sleep
    fi
  done
}


date_last_error=$(journalctl -u babeld -o short-iso | grep "Cannot allocate memory" | tail -n1 | awk '{print $1}')

date_last_started=$(journalctl -u babeld -o short-iso | grep "Started babeld" | tail -n1 | awk '{print $1}')

if [[ "$date_last_error" == "" || "$date_last_started" == "" ]]; then
    echo "found no [Cannot allocate memory] error entry or babeld is not running"
else
  if [[ "$date_last_error" > "$date_last_started" ]]; then
    echo "found [Cannot allocate memory] error since last babeld restart"
    echo "babeld restarting..."
    service babeld restart
    echo "babeld restarted."
    
    wait_for_babeld
    
    # add tunnel interfaces to babeld
    echo "add tunnel interfaces to babeld..."
    ip addr | tr ' ' '\n' | grep -E "l2tp[0-9]+$" | sort | uniq | xargs -L 1 babeld -a 
    babeld -i | head -n1
    echo "add tunnel interfaces to babeld done."
  else
    echo "found no [Cannot allocate memory] error since last babeld restart"
  fi
fi


