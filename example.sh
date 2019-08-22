#!/usr/bin/env bash

# Require 3 Control C's in 10 seconds to exit
TRAP_DOWNCT=3
ALARMPID=

function trappist_trap()
{
    case $1 in
	SIGALRM)
	    TRAP_DOWNCT=3   # After 10 seconds go back to 3
	    echo ^C reset
	;;
	SIGINT)
	    if (( --TRAP_DOWNCT == 0 ))   # Did we get our 3?
	    then
		if [ ! -z "$ALARMPID" ]
		then
		    kill -9 $ALARMPID
		fi
		echo Bye bye!
		exit
	    else
		echo Press ^C some more in the next 10 seconds to really exit
		if (( TRAP_DOWNCT == 2 ))  # note we already did -- so the first run is at 2
		then
		    ALRMPID=$$
		    ( trap "" SIGINT ; sleep 10 ; kill -SIGALRM $ALRMPID ) &   # set alarm process to tell us to reset count later
		    ALARMPID=$!
		fi
	    fi
	;;
    esac
}

source trappist.sh   # load our library

# we only handle SIGINT and SIGALRM, we also ignore SIGQUIT
trappist_init = SIGINT SIGALRM -SIGQUIT
while true
do
    echo Waiting....
    for i in {1..30}  # cheap 30 second wait in 1 second bites
    do
	sleep 1
    done
done
   
