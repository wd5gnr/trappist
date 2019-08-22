# Function to help manage traps
# Al Williams - Hackaday, August 2019
#
# Here's what it does:
# 1) Provide a function trappist_trap
# 2) Call trappist_init with or without arguments
#
# If you forget to provide trappist_trap, a stupid one will be provided but you can
# still override it later
# With no arguments to trappist_init, all signals you can catch go through your function with an argument indicating which signal fired
# You can ignore it or reraise it as shown in the default handler (see below)
# Of course, you can't do anything with signals you can't catch (e.g., kill -9)
#
# If you provide a list of signals that start with + or -, you will cause those signals to get the default handler (+) or
# to be ignored totally (-) assuming you are allowed to ignore the signal.
# Example:
# trappist_init +SIGQUIT -SIGHUP -SIGILL
#
# If you use the first argument as = you will ONLY catch the signals you name by themselves or with an = prefix and then
# you can also use the + and - prefix, although since + will be the default, you'll probably only need -
# Example:
# trappist_init = SIGQUIT SIGHUP
# trappist_init = =SIGQUIT =SIGHUP  # same as above
# trappist_init = SIGQUIT -SIGHUP
#
# For regularity, you can use @ as the first argument to get the default behavior
# trappist_init @ +SIGQUIT -SIGHUP -SIGILL   # same as earlier example without @ or = 
#
# Normally, you should define your trappist_trap function and then source this file (. /path/to/trappist.sh)
# However, you can define trappist_trap afterwards


function trappist_init()
{
# define a trappist_trap function if there isn't already one
    if ! type trappist_trap >/dev/null
    then
# set up default handler: restore default and reraise which is, of course, stupid
	eval 'function trappist_trap()
            {
	    echo Default trappist_trap: $1
            trap $1     
            kill -$1 $$  
            }'
    fi

# if no arguments, mode 0, do all
    if [ $# -lt 1 ]
    then
	mode=0
    else   # mode 1 is @ or, at least, no = sign
	mode=1  # assume we will get all or handle exclusions
	if [ "$1" == "@" ]   # @ +sig1 -sig2 means default action for sig1, no action for sig2, trap call for all others (mode 1)
	then
	    shift
	else if [ "$1" == "=" ] # = sig1 sig2 +sig3 -sig4 means sig1/2 call trap, sig3 gets default, sig4 is ignored (mode 2)
	     then
		 mode=2   # mode 2 only sets explicit signals
		 shift
	     fi
	fi
    fi
# set up trap calls for everything in mode 0 or 1
    if [ $mode -eq 0 -o $mode -eq 1 ]
    then
	for t in $(trap -l | tr ')' '\n' | tr '\t' ' '  | cut -d ' ' -f 2 | grep ^[A-Z] )
	do
	    trap "trappist_trap $t" $t
	done
    fi
    # for mode 2, only include signals that don't have + or - prefix
    # = prefix means set this signal (not really required as no prefix has same effect)
    if [ $mode -eq 2 ]
    then
	for t in $@
	do
	    if [[ ${t:0:1} == "=" ]]   # skip = which isn't necessary but allowed
	    then
		t=${t:1}
	    fi
# ignore signals with +/- prefix for now
	    if [[ ${t:0:1} != "+" && ${t:0:1} != "-"  ]]
	    then
		trap "trappist_trap $t" $t
	    fi
	done
    fi
# For mode 1 or 2, we need to work through the +signal -signal items
    if [ $mode -eq 1 -o $mode -eq 2 ]
    then
	for t in $@
	do
	    if [[ ${t:0:1} == "+" ]]   # default handler
	    then
		trap ${t:1}
	    else
		if [[ ${t:0:1} == "-"  ]]   # ignore
		then
		    trap "" ${t:1}
		fi
	    fi
	    
	done
    fi
    

    
}

################
# Everything from here down is just an example



## Really simple trap handler
# function trappist_trap()
# {
#    echo Trap: $1
# }


## test harness
#trappist_init 
#echo Trap me @ $$!
#while true
#do sleep 5  # Note: most signals won't happen until after sleep returns!
#   echo Still going
#done


