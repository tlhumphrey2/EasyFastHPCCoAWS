#!/bin/bash
x=$(cat /proc/meminfo | grep MemTotal | awk '{ printf "%.0f\n", $2*1000 }')
echo $x
