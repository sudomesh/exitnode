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


date_last_error=$(journalctl -u babeld -o short-iso | grep -E "((Cannot allocate memory)|(Unit entered failed state))" | tail -n1 | awk '{print $1}')

date_last_restarted=$(journalctl -u babeld-monitor -o short-iso | grep "babeld restarted" | tail -n1 | awk '{print $1}')

if [[ "$date_last_error" == "" ]]; then
    echo "found no error entry"
else
  if [[ "$date_last_restarted" == "" || "$date_last_error" > "$date_last_restarted" ]]; then
    echo "found error since last babeld restart"
    echo "babeld restarting..."
    service babeld restart
    
    wait_for_babeld
    
    # add tunnel interfaces to babeld
    echo "add tunnel interfaces to babeld..."
    ip addr | tr ' ' '\n' | grep -E "l2tp[0-9\-]+$" | sort | uniq | xargs -L 1 babeld -a 
    babeld -i | head -n1
    echo "add tunnel interfaces to babeld done."

    echo "babeld restarted."
  else
    echo "found no error since last babeld restart"
  fi
fi


