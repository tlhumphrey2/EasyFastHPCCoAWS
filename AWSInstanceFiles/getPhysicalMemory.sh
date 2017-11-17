#!/bin/bash
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
x=$(cat /proc/meminfo | grep MemTotal | awk '{ printf "%.0f\n", $2*1000 }')
echo $x
