#!/bin/bash
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -e $1 ]
then
echo "done"
else
echo "not done"
fi
