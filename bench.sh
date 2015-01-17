#! /bin/bash

parse_opt() {
  local io ia
  args=() # array
  opt=()
  io=0
  ia=0
  while [[ "$#" > 0 ]]; do #[[ "$1" =~ "$re" ]]; do
    if [[ "$1" =~ $re ]]; then
      opt[$io]=$1
      ((io++))
    else
      args[$ia]="$1"
      ((ia++))
    fi
    shift
  done
}

dot_working() {
  while true; do
    echo -n '.'
    sleep 2
  done
}

re='^--?[a-zA-Z0-9]+'
important() {
  parse_opt $@
  echo ${opt[@]} "[104;30m"${args[@]}"[0m"
}

warning() {
  parse_opt $@
  echo ${opt[@]} "[33m"${args[@]}"[0m"
}

error() {
  parse_opt $@
  echo ${opt[@]} "[101m"${args[@]}"[0m"
}

ok() {
  echo "[32m ✓ [0m"
}

ko() {
  echo "[31m ✗ [0m"
}

warn() {
  echo "[33m ⚠ [0m"
}

good() {
  parse_opt $@
  echo ${opt[@]} "[32m"${args[@]}"[0m"
}

bad() {
  parse_opt $@
  echo ${opt[@]} "[31m"${args[@]}"[0m"
}

working() {
  parse_opt $@
  echo ${opt[@]} "[34m"${args[@]}"[0m"
}

cleanup() {
  local elapsed LOG_END
  kill $DOT 2>/dev/null
  wait $DOT 2>/dev/null
  DOT=
  LOG_END=$(date +%s%N)
  elapsed=$(echo "scale=3; ($LOG_END - $LOG_START) / 1000000000" | bc)
  echo -n "[${elapsed} s]"
}

killed() {
  kill 0
  if [[ "$DOT" ]]; then
    cleanup
  fi
  bad " ☠ "
  exit 1
}

log_cmd() {
  local cmd critical p name p_cmd
  LOG_START=$(date +%s%N)
  dot_working &
  DOT=$!
  critical=
  if [[ "$1" == "-c" ]]; then
    critical=YES
    shift
  fi
  name="$1"
  cmd="$2"
  shift
  shift
  if [[ "$critical" ]]; then
    $cmd $@ > ${LOG_DIR}/${name}.out 2> ${LOG_DIR}/${name}.err &
    p_cmd=$!
    if ! wait $p_cmd; then
      cleanup
      error ' CRITICAL '
      warning "Checking log at ${LOG_DIR}/${name}.err"
      less ${LOG_DIR}/${name}.err
      exit 1
    fi
  else
    $cmd $@ > ${LOG_DIR}/${name}.out 2> ${LOG_DIR}/${name}.err &
    p_cmd=$!
    wait $p_cmd
    p=$?
    cleanup
    return $p
  fi
}

# Exit correctly with <C-C>
trap 'killed' SIGINT SIGTERM

echo "Let's do some benchmarking."
echo "This benchmarking have been prepared for room E300."
warning "Make sure all computers are turned on before going on"

LOG_DIR=$(mktemp -d /tmp/sparkXXXXXXXX)
important "Logs will be available at $LOG_DIR"

#read -p "<Press ENTER to continue>"

stop_cluster() {
  working -n "Stopping started cluster"
  log_cmd spark-stop ./smake --stop && ok || ko
}

WORK_DIR="$HOME/spark-make/spark-1.1.1/work"
cleaning_work() {
  working -n "Cleaning existing work at $WORK_DIR"
  if [[ -d "$WORK_DIR" ]]; then
    log_cmd clean-work rm -r $WORK_DIR/*
    ok
  fi
}

configure_cluster() {
  local from to n
  n=$1
  (( from = 301, to = from + n ))
  working -n "Configuring the cluster"
  log_cmd spark-stop ./smake --master --clear-workers $(./workers.sh $from $to) && ok || ko
}

be_patient() {
  working -n "Waiting a bit before starting again"
  log_cmd spark-wait sleep $1 && ok || ko
}

launch_cluster() {
  working -n "Launching the cluster"
  log_cmd spark-start ./smake --start && ok || warn
}

run_makefile() {
  working -n "Running makefile $1"
  log_cmd spark-run-$w ./smake --run $1 && ok || ko
}

# Makefiles to test against
MAKEFILES="makefiles/blender_2.49/Makefile makefiles/blender_2.49/Makefile-recurse"
WORKERS="4 10 30"
for w in $WORKERS; do
  important "Starting the benchmark with $w computers"
  stop_cluster
  cleaning_work
  configure_cluster $w
  be_patient 3
  launch_cluster
  for m in $MAKEFILES; do
    run_makefile $m;
  done
  read
done
