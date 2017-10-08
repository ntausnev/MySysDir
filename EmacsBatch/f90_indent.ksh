#!/usr/bin/ksh
USAGE="$0 name_file.{fF}90"
#
# SCRIPT: NAME_of_SCRIPT
# AUTHOR: Nick Tausnev, ntausnev@giss.nasa.gov
# DATE:   12/20/04           
# REV:    1.1.A (Valid are A, B, D, T and P)
#               (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: (SPECIFY: AIX, HP-UX, Linux, Solaris 
#                      or Not platform dependent)
#
# PURPOSE: the tool that indents Fortran 90 code
#
# REV LIST:
#        DATE: DATE_of_REVISION
#        BY:	  AUTHOR_of_MODIFICATION   
#        MODIFICATION: Describe what was modified, new features, etc-
#
#
# set -n   # Uncomment to check your syntax, without execution.
#          # NOTE: Do not forget to put the comment back in or
#          #       the shell script will not execute!
# set -x   # Uncomment to debug this shell script (Korn shell only)
#          
##########################################################
########### DEFINE FILES AND VARIABLES HERE ##############
##########################################################



##########################################################
############### DEFINE FUNCTIONS HERE ####################
##########################################################



##########################################################
################ BEGINNING OF MAIN #######################
##########################################################


print "##################################################################################"
print "\n            $0                                       "
print "\nScript \"   $0   \" starts: ==========> "                 

if (( $# != 1 )) 
then
    print "\nABORT: You should supply name of source file with F90 code "
    print "USAGE: $USAGE"
    print "\n"
    exit 1
fi

f90_source=$1
if [[ ! -f $f90_source ]] 
then
    echo "\nABORT: File $f90_source does not exist \n"
    exit 1
fi
dir=${f90_source%/*}
name=${f90_source##*/}
#Case when f90_source is absolute name
if [[ $dir != $name ]]
then
   cd $dir
fi
cp -p ${f90_source} ${f90_source}_old

emacs --batch -l ${MySysDir}/EmacsBatch/emacs-batch-f90-indent.el -f f90-batch-indent-region $name 

#Replace tab ==> 8 empty blanks
print "A literal replacement of each tab by 8 spaces "
perl -pi.bak -e 's/\t/        /g' $name
perl -pi.bak -e 's/^\s*!/!/g' $name
perl -pi.bak -e 's/^\s*#/#/g' $name

print "\nScript \"  $0  \" ended : <========== \n"                 
# End of script

