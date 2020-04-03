#!/bin/bash

echo add number to set sleeptime... e.g: ttt 100 10 ,this command while sleep 10 seconds for each poll duration and delete file 1000 line from head.
echo default poll duration is 10 seconds
echo default number of remove is 100

while true ; do
    pa=`du -s /home/out | awk '{print$1}'`
    pp=$1
    echo ===$pp
    if [ ${pa} -gt 10240 ] ; then
        echo 'fie too large, prepare remove head line...'
	echo ---${pp}
	sed -i '1,'${pp:-100}'d' /home/out
     fi
    pe=$2
    sleep ${pe:-10}
done


exit $?
