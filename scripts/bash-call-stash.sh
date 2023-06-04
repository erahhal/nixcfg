#!/usr/bin/env bash

pid=${1:-${BASHPID:-$$}}
while (( pid )); do
   mutated=0
   cmdline=( )
   while IFS= read -r -d '' piece || { [[ $piece ]] && mutated=1; }; do
       cmdline+=( "$piece" )
   done <"/proc/$pid/cmdline"
   printf '%s\t' "$pid"
   if (( mutated )); then
     printf '%s ' "${cmdline[@]}"
   else
     printf '%q ' "${cmdline[@]}"
   fi
   printf '\n'
   stat_data=$(<"/proc/$pid/stat") || break
   read _ ppid _ <<<"${stat_data##*')'}" || break
   [[ $ppid = "$pid" ]] && break
   pid=$ppid
done
