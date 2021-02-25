#!/bin/bash
#############################################################
#
#  getDataHeizung.sh
#
#############################################################
#
#  2021-02-16-1.0: created.
#
#############################################################
#
# DESCRIPTION
#   This scripts reads values of parameters from the BSB-LAN-Arduino
#   via wget to ascii file 'heizung.dat' on the remote computer.
#   The script can be called periodically via cron.
#
#   The parameters are specified in file 'parameter.txt' in the
#   following format:
#     <parameter1> # comment
#     <parameter2> # comment
#     .....
#   where parameter is 8510, 8700 etc., # comment is optional.
#
#   Format of data file 'heizung.dat':
#   YYYYMMDD HHMMSS day_of_year parameter "parameter_text" value unit
#   Delimiter is 'tab'
#
# EXAMPLE
#   getDataHeizung.sh [-apHn]
#
# OPTIONS
#   -a <nnn.nnn.nnn.nnn> : specifies IP of arduino [192.168.2.88].
#   -p <path>            : path to parameter and data file [.]
#   -H                   : print history of script.
#   -h                   : print help.
#
# ENVIRONMENT
#   The program does not use any environment variables.
#
# REQUIRE
#   bash, date, sed, wc, wget, grep
#
# BUGS
#   No known bugs.
#
# AUTHOR
#   Written by Karl-Heinz Mantel. 
#   Send bug reports to 'mantel@lmu.de'.
#
#############################################################

#-------------------  global variables  ---------------------
# IP of arduino
ARDUINO="192.168.2.88"
# path to parameter and data file
DIR="."

#-------------------  functions -----------------------------
#-------------------  get command line options --------------
usage()
{
  echo "";
  echo " getDataHeizung.sh [-a]"
  echo " This bash-script reads parameters from BSB-LAN-arduino."
  echo " Available Options:"
  echo " -a <nnn.nnn.nnn.nnn> : ip of arduino [192.168.2.88]"
  echo " -p <path> : path to parameter and data file [.]"
  echo " -h: print help"
  echo " -H: print history of script"
  exit 0;
}

history()
{
  echo "";
  echo " getDataHeizung.sh[History]:";
  echo " 2021-02-16-kh: created."
  exit 0;
}

#-------------------------   main  ---------------------------
# get options from commandline
optstring="hHa:p:"
while getopts "$optstring" arg; do
    case "${arg}" in
	a)  ARDUINO=${OPTARG}
	    ;;
	p)  DIR=${OPTARG}
	    ;;
	h)  usage
            ;;
	H)  history
	    exit 1
            ;;
	?)  usage        # undeclared option found
	exit 1
	;;
    esac
done

# get date & time
# add blank between date and time
DATE0=`date +%Y%m%d_%H%M%S`;
DATE0=$(sed "s/_/ /" <<< $DATE0);

# compute day of year"
DOY=`date +%j`;
HOUR=`date +%H`;
MIN=`date +%M`;
DATE=`bc <<<"scale=4;$DOY+$HOUR/24+$MIN/3600"`;

# get parameters from file "parameter.txt",
# write to format "par1/par2/par3/..."
#  - remove comments
#  - assign to var READPAR0, one parameter per line
READPAR0=`sed 's/\([0-9]*\).*/\1/' $DIR/parameter.txt`;

#  - read multiples lines,
#  - replace CR at each EOL by "/"
#  - assign to var READPAR
#    - determine number of parameter in parameter.txt
#    - construct var ANZN which gives number of lines for sed
NN=`wc -l $DIR/parameter.txt | sed "s/ .*//"`;
i=1; while [ $i -lt $NN ]; do ANZN=$ANZN"N;" && i=$[$i+1]; done
#    - replace ANZN CRs with "/"
READPAR=$(sed "$ANZN; s/\n/\//g" <<< $READPAR0);

# read parameters from heizung
# remove html code
# add time stamp, add separator "tab"
# write to data file
# use of quotes: " inserts content of vars e.g. $DATE
#                ' does not interpret "$"
wget -qO- http://$ARDUINO/$READPAR | grep "$READPAR0" | sed 's/<\/td><td><.*// ; s/<tr><td>\(.*\)/\1/ ; s/\([0-9][0-9][0-9][0-9]\) \(.*\): \(.*\)/'"$DATE0"'\t'"$DATE"' \1\t\"\2\"\t\3/' >>$DIR/heizung.dat

