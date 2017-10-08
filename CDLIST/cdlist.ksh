#!/bin/ksh

################################################################################
#  
# Copyright (c) 1998 Ivan Van Laningham.
#  All Rights Reserved.
#
#  Permission to use, copy, modify, and distribute this
#  software and its documentation for any purpose and without fee
#  or royalty is hereby granted, provided that the above
#  copyright notice appear in all copies and that both the
#  copyright notice and this permission notice appear in
#  supporting documentation or portions thereof, including
#  modifications, that you make.
#
#  THE AUTHOR IVAN VAN LANINGHAM DISCLAIMS ALL WARRANTIES WITH
#  REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL THE AUTHOR BE
#  LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR
#  ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
#  PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
#  TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE
#  OR PERFORMANCE OF THIS SOFTWARE!
#   Report all bugs to ivanlan@callware.com
#
################################################################################
#
# To use this directory management script, just
#   put it wherever you like and source it as the last
#   line of your .profile, or your ENV file if you use one.
#   The last line of my ENV file is:
#   . newcdlist.f
#


alias integer='typeset -i'
integer _oi=0
integer _i=0

if [ -z "$NULLDEV" ]
then
    export NULLDEV=/dev/null
fi

if [ ! -z "$OS" ]
then
    case "$OS" in 
      Windows*)
	_igncase="1"
        ;;
      *)
	:
	;;
    esac
fi

_ll=""	    # The ``global'' array variable in which directories are stored.
	    # We _always_ hose it on startup.

if [ -z "$insideumask" ]
then
    export insideumask=22	    # Umask for directories that have your username in their paths.
fi
if [ -z "$outsideumask" ]
then
    export outsideumask=2	    # Umask for directories that don't have your username.
fi

if [ -z "$foobar" ]
then
    # These are default variable settings for U/WIN on windoze95/98/NT
    # If you hate them, just set them in your .profile or in your
    # environment file.
    export foobar='[5m[0m'                # Orig
    export foobar='x'                           # TNL

#   export blank='\0262'                        # Orig
    export blank='='                            # TNL

    hil='[7m'
    lowl='[0m'
    mel='[1m'
    bol='[4m'
#   export arrow="[4m\0262\0304\0304[m"   # Orig
    export arrow="->"                         # TNL
fi

export _ll	    # The array of directories
export _i	    # Index of current directory
export _oi	    # Index of old current directory

#
#  Syntax:  convertolist <sepchar> <string>
#  breaks up string on sepchar, returns single string result in _cv
#
converttolist()
{
    OLDIFS="$IFS" 
    IFS="$1" 
    shift 
    olist="$*" 
    set -- $* ""
    IFS="$OLDIFS" 
    _cv="$*" 
    set -- $* ""
    [ ! "$*" ] && _cv="$olist"
    unset OLDIFS olist 
    return 0
}

#
#  Syntax:  isinlist <word> <string>
#    if word is found in string, returns 0 (success),
#    else returns 1 (fail).
#
isinlist()
{
    _rt=0 
    __rt=1 

    i=""
    if [ ! -z "$_igncase" ]
    then
	typeset -u lword="$1"
	typeset -u i
    else
	lword="$1" 
    fi
    shift 
    llist="$*"
    for i in $llist
    do
	if [ "$i" = "$lword" ]
	then
	    _rt=$1 __rt=0
	    break
	fi
    done
    unset lword llist i
    return $__rt
}

#
#  Syntax:  numask <string>
#   sets umask based on <string>; if your username is in the string anywhere,
#   sets umask to $insideumask (e.g., 2), else to $outsideumask (e.g., 22).
#
numask()
{
    converttolist / "$1"
    if isinlist "$USERNAME" "$_cv"
    then
	umask $insideumask ; return 0
    else
	umask $outsideumask ; return 1
    fi
    unset _cv
}

#
#  Syntax:  arraytostring
#   Copies _ll into a string _ss, using '|' as separators.
#
arraytostring()
{
    OLDIFS=$IFS
    IFS='|'
    _ss="${_ll[*]}"
    IFS=$OLDIFS
    unset OLDIFS
}

#
#  Syntax:  stringtoarray <string> <string> ...
#   inserts <string>s into sequential positions in _ll
#
stringtoarray()
{
    integer y=0
    for i in $*
    do
	_ll[$y]="$i"
	let y=y+1
    done
    unset y i
}

#
#  Syntax: _up
#   adds 1 to index of current directory in _ll and chdirs to
#   it if possible.   Good for aliasing.
#
_up()
{
    integer e="${#_ll[@]}"
    integer n="$_i" # Where we are
    let n=n+1       # Where we want to go
    if [ n -ge e ]
    then
	let n=0
    fi
    cdi $n
    unset e n
}

#
#  Syntax:  down
#   subtracts 1 from index of current directory in _ll and chdirs to
#   it if possible.   Good for aliasing.
#
down()
{
    integer e="${#_ll[@]}"
    integer n="$_i" # Where we are
    let n=n-1       # Where we want to go
    if [ n -lt 0 ]
    then
	let n=e-1
    fi
    cdi $n
    unset e n
}

#
#  Syntax:  bk
#   makes $_oi the current directory and $_i the old dir.
#
bk()
{
    cdi "${_oi:=0}"
}

#
#  Syntax:  listtoarray <string>
#   Breaks up <string> on | symbols and assigns resulting
#   pieces to sequential positions in _ll
#
listtoarray()
{
    OLDIFS=$IFS
    IFS='|'

    set -- $1
    set -A _ll $@ 
    IFS=$OLDIFS
    unset OLDIFS
}

#
#  Syntax:  same as listtoarray, except that it stuffs the array
#   members into _tmpll instead of _ll.
#
listtotmparray()
{
    OLDIFS=$IFS
    IFS='|'

    set -- $1
    set -A _tmpll $@ 
    IFS=$OLDIFS
    unset OLDIFS
}

#
#  Syntax:  preloadfile <filename>
#   If there are no $dn environment variables, sucks up the file specified
#   and converts it using listtoarray; syntax of the file is one string with
#   directories separated by | symbols, i.e., "/c/home/ivanlan|/c/home/db"
#   $dn environment variables override the file.  That's so your _ll is not
#   reset to nothing everytime a new shell is started from an old one, as
#   when using su and you want to preserve _ll.
#
preloadfile()
{
    if [ ! -z "$d0" ]
    then
	importvars
    elif [ ! -z "$1" ]
    then
	if [ -f "$1" ]
	then
	    _l=`cat "$1"`
	    listtoarray "$_l"
	fi
	unset _l
    fi
}

#
#  Syntax:  saveloadfile <filename>
#   If $1 is set, saves the directory list to that file,
#   else saves it to $HOME/.preloaddirs
#
saveloadfile()
{
    arraytostring
    if [ ! -z "$1" ]
    then
	echo "$_ss" > "$1"
    else
	echo "$_ss" > "$HOME/.preloaddirs"
    fi
}

#
#  Syntax:  overloadfile <filename>
#   If $1 is set, overloads the directory list from that file,
#   else overloads it from $HOME/.preloaddirs
#
overloadfile()
{
    if [ ! -z "$1" ]
    then
	_xtf="$1"
    else
	_xtf="$HOME/.preloaddirs"
    fi
    if [ -f "$_xtf" ]
    then
	_l=`cat "$_xtf"`
	listtoarray "$_l"
    fi
    unset _xtf
    unset _l
}

#
#  Syntax:  preload
#   If $_l exists, converts that to _ll;
#   else if $dn variables exist, converts those to _ll;
#   else falls back to inserting just one, ~, into _ll.
#
preload()
{
    if [ -z "_l" ]
    then
	stringtoarray "$_l"
    elif [ ! -z "$d0" ]
    then
	importvars
    else
	_l="$HOME"
	listtoarray "$_l"
    fi
}

#
#  Syntax: _cdl_lookup <string>
#   Searches _ll for <string>;
#   if found, returns 0 (success) and sets _rv to index found;
#   else returns 1 (failure) and sets _rv to 0.  $_igncase should
#   be set on Windoze, otherwise /e/TarFiles is considered to be
#   different from /e/tarfiles. ...
#
_cdl_lookup()
{
    _rv=0 
    __rv=1 
    if [ ! -z "$_igncase" ]
    then
	typeset -u lword="$1"
	typeset -u u
    else
	lword="$1"
	u=""
    fi
    integer e=${#_ll[*]}
    integer n=0
    while [ n -lt e ] # Bogus syntax for MKS
    do
	u="${_ll[$n]}"
	if [ "$lword" = "$u" ]
	then
	    _rv=$n
	    __rv=0
	    break
	fi
	let n=n+1
    done
    unset lword e n u
    return $__rv
}

#
#  Syntax:  _ladd <string>
#   Adds <string> to end of _ll array and puts the index into _rv.
#
_ladd()
{
    integer x="${#_ll[@]}"
    _ll[x]="$1"
    _rv=$x
    unset x
}

#
#  Syntax:  cdl
#   Lists all directories in the _ll array.
#   $foobar is expected to visually occupy one character,
#   $arrow four characters, and $blank just one.
#
cdl()
{
    integer e=${#_ll[@]}
    integer n=0

    while [ n -lt e ]
    do
	if [ "$_oi" = "$_i" -a "$_i" = "$n" ]
	then
	    echo "$arrow$foobar[$n]${_ll[$n]}"
	elif [ "$_oi" = "$n" ]
	then
	    echo "   $foobar[$n]${_ll[$n]}"
	elif [ "$_i" = "$n" ]
	then
	    echo "  $arrow[$n]${_ll[$n]}"
	elif [ "${_ll[$n]}" != "." ]
	then
	    echo "    [$n]${_ll[$n]}"
	fi
	let n=n+1
    done
    unset e n
}

#
#  Syntax:  cdi <number>
#   Does a chdir into the directory found by indexing _ll
#   at number.  Wide open for aliasing; I've got mine
#   aliased to @, so that I can type @ 4 and just go there.
#
cdi()
{
    integer n="$1"
    integer e="${#_ll[@]}"
    if [ n -ge 0 -a n -lt e ]
    then
	z="${_ll[$n]}"
	chdir "$z"
     ls
	unset z
    fi
    unset n e
}

#
#  Syntax:  cli <number>
#   Deletes the directory entry from _ll at index number.
#   Redoes all the $dn variables.
#
cli()
{
    deletevars

    integer n="$1"
    integer e="${#_ll[@]}"
    integer i=0
    while [ i -lt e ]
    do
	unset eval "d$i"
	let i=i+1
    done
    if [ n -ge 0 -a n -lt e ]
    then
	unset eval "d$n"
	unset _ll[$n]
    fi
    OLDIFS=$IFS
    IFS='|'
    arraytostring 
    listtoarray "$_ss"
    IFS=$OLDIFS
    unset OLDIFS _ss n e i
    exportvars
}

#
#  Syntax:  chdir <string>
#   Should be aliased to cd.  Cd into <string> if possible, and enter the
#   resultant directory into _ll.  If there are any bogus entries in _ll ("."),
#   replace those before adding onto the end of the array.  If the directory
#   is already in _ll, use that entry without making duplicates.
#
chdir()
{
    argIn="$1"
    arg=${argIn%@} # Remove the rightmost @ character in a string
#   print "Inpur argument $1 "
#   print "rg=${arg}"
    if [ -z "$arg" ]
    then
	\cd && : || return 1; newdir="`pwd`"
    else
	\cd "$arg" && : || return 1; newdir="`pwd`"
    fi
    if _cdl_lookup "$newdir"
    then
	_oi="${_i:=0}" ; _i="$_rv"
    else
	if _cdl_lookup "."
	then
	    _oi="${_i:=0}" ; _i="$_rv"
	    _ll[$_i]="$newdir"
	else
	    _ladd "$newdir"
	    _oi="${_i:=0}" ; _i="$_rv"
	fi
    fi
    exportvars
    numask "$newdir"
    unset newdir
}

#
#  Syntax:  exportvars
#   runs through all directories in _ll and exports
#   variables to the environment; they'll be name d0, d1, d2, etc.
#   Any directory in _ll can be referenced from your commandline
#   as $d0, $d1, and so on.  If the directories have spaces in the
#   names, don't forget to quote them:  cp foo "$d8"/.
#
exportvars()
{
    integer n=0
    integer e="${#_ll[*]}"
    while [ n -lt e ]
    do
	unset eval "d$n"
	export eval "d$n"="${_ll[$n]}"
	let n=n+1
    done
    unset n e
}

#
#  Syntax:  deletevars
#   eliminates all d0,d1,...dn vars from environment
#   based on the entries in _ll
#
deletevars()
{
    integer n=0
    while true
    do
	v=d$n
	vn=`eval echo '$'$v`
	if [ "$vn" = "" ]
	then
	    break
	else
	    unset eval "d$n"
	fi
	let n=n+1
    done
    unset n v vn
}

#
#  Syntax:  importvars
#   Looks for d0,d1,...dn vars in the environment; if they're found
#   there, converts all the ones available into entries in _ll.  This
#   allows a superuser shell started from a non-su shell to import
#   a ready-made list of directories.
#
importvars()
{
    integer n=0
    while true
    do
	v=d$n
	vn=`eval echo '$'$v`
	if [ "$vn" = "" ]
	then
	    break
	else
	    _ll[$n]="$vn"
	    unset eval "d$n"
	fi
	let n=n+1
    done
    unset n v vn
}

#
#  If you've got the file, it will suck up the preloaded
#   directories, unless you're starting a subshell.
#
if [ -f "$HOME/.preloaddirs" ]
then
    preloadfile "$HOME/.preloaddirs"
else
    preload
fi

alias cd='chdir'

#
#  All other aliases are up to you.
#

_initialize()
{
    chdir .		# Wherever you go, there you are.  =<:-)
    cdl > "$NULLDEV"
}

_initialize

