#!/bin/bash
# matriz.sh <cuento> <plan> <query>: plays one story with one plan and one query (via juega.py, next to this script); logs go to $MATRIZ_LOGS; prints a one-line verdict: exit, pageerrors, finished, marcas, lost, turnos (the speaking turns, id:kind:ok|fallo:tries) and micdecide (must be 0). The query may carry ?mic=stub:..., ?mic=off, ?abiertas=todas (docs/hablar/01-decisiones.md; the log name then ends in a short hash). Run many: xargs -P 5 -L 1 bash historia/tools/matriz.sh < list.txt > out.txt
S=${MATRIZ_LOGS:-/tmp/claude-0/-home-user-field-notes/3c5d275f-89f8-5f76-b4a5-103358f42923/scratchpad/logs}
mkdir -p "$S"
c=$1; pl=$2; q=$3; tag=$(echo "$c-$pl-$q" | tr '&=' '__')
case "$q" in *[:\|/%]*) tag="$(echo "$c-$pl-$q" | tr '&=:|/%' '______' | cut -c1-120)-$(echo "$q" | md5sum | cut -c1-6)";; esac   # a mic query has characters a file name does not like
timeout 240 python3 "$(dirname "$0")/juega.py" - $pl $c 6 "$q" > $S/M_$tag.log 2>&1; e=$?
err=$(grep -c "PAGEERROR" $S/M_$tag.log); fin=$(grep -c "again button: flex" $S/M_$tag.log)
echo "$c $pl [$q] exit=$e pageerrors=$err finished=$fin marcas=$(grep -o 'marcas=[a-z,]*' $S/M_$tag.log | tail -1) lost=$(grep -o 'lost=[0-9]' $S/M_$tag.log | tail -1) turnos=$(grep '^turnos:' $S/M_$tag.log | tail -1 | sed 's/^turnos: *//;s/ /,/g') $(grep -o '^micdecide=[0-9]*' $S/M_$tag.log | tail -1)"
