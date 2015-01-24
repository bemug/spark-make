#! /bin/bash

source task-logger.sh
reset_timer 2

stop_cluster() {
  working -n "Stopping started cluster"
  log_cmd spark-stop ./smake --stop || ko
}

WORK_DIR="$HOME/spark-make/spark-1.1.1/work"
clean_work() {
  working -n "Cleaning existing work at $WORK_DIR"
  if [[ -d "$WORK_DIR" ]]; then
    log_cmd clean-work rm -r $WORK_DIR/* || ok
  fi
}

configure_cluster() {
  local from to n
  n=$2
  from=$1
  (( to = from + n - 1 ))
  working -n "Configuring the cluster from ensipc${from} to ensipc${to}"
  log_cmd spark-stop ./smake --master --clear-workers $(./workers.sh $from $to) || ko
}

be_patient() {
  working -n "Waiting a bit before starting again"
  log_cmd spark-wait sleep $1 || ko
}

launch_cluster() {
  working -n "Launching the cluster"
  log_cmd spark-start ./smake --start || warn
}

run_makefile() {
  local t n p
  n=$(basename $1)
  working -n "Running makefile $1 with $2 cores"
  reset_timer 1
  log_cmd spark-run-$n ./smake --cores $2 --run $1 || ko
  p=$?
  t=$(get_timer 1)
  if [[ "$t" != "" && "$p" == 0 ]]; then
    echo "$1 $2 $t" >> stats.txt
  fi
}

clean_makedirs() {
  working -n "Removing files created by makefiles"
  log_cmd clean-makefiles rm -rf makefiles/premier/*.txt makefiles/blender_2.49/*.{png,mpg,blend} makefiles/blender_2.59/*.{avi,tga,jpg} || ok
}

info "Let's do some benchmarking."
info "This benchmarking have been prepared for room E300."
warning "Make sure all computers are turned on before going on"

important "Logs will be available at $LOG_DIR"

read -p "<Press ENTER to continue>"

stop_cluster
configure_cluster 300 39
be_patient 3
launch_cluster

# Makefiles list to test against
MAKEFILES="makefiles/blender_2.59/Makefile makefiles/blender_2.49/Makefile makefiles/blender_2.49/Makefile-recurse makefiles/premier/Makefile"
CORES="60 70 80 90 100" # We tests with different amount of cores
REPEAT=3 # We must repeat the task some time in order to get correct results
for c in $CORES; do
  important "Starting benchmarking with $c cores. $REPEAT repetitions"
  r=$REPEAT
  while [[ $r > 0 ]]; do
    info -n "[$(date +%H:%M:%S)] "
    important "Remaining iterations: $r"
    clean_work
    clean_makedirs
    for m in $MAKEFILES; do
      run_makefile $m $c;
    done
    ((r--))
  done
done

info -n "[$(date +%H:%M:%S)] "
echo "Finished in $(get_timer 2)s: [92m$SUCCESS ✓ [93m$WARNINGS ⚠ [91m$ERRORS ✗[0m"
