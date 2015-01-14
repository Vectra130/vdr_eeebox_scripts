#!/bin/bash

#. /etc/vectra130/scripts/test2.sh
echo "--------- "$?
testtime(){
date +%s
echo --- $1
test2="---"$1"---"
}

testtime hallo
echo $test2
