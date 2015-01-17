#! /bin/bash

FROM="$1"
TO="$2"

re='^[0-9]+$'
if ! [[ "$FROM" =~ $re ]] ; then
  FROM=301
fi
if ! [[ "$TO" =~ $re ]] ; then
  TO=338
fi

for i in $(seq $FROM $TO); do
  echo -n "--worker ensipc$i "
done

