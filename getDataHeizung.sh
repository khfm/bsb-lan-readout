#!/bin/bash
#############################################################
#
#  getDataHeizung.sh
#
#############################################################
#
#  2021-02-16-1.0: created.
#  2021-03-06-1.1: changed to JSON format.
#                  output format changed.
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
#   Delimiter is ','
#
# EXAMPLE
#   getDataHeizung.sh [-apHn]
#
# OPTIONS
#   -a <nnn.nnn.nnn.nnn> : specifies IP of arduino [192.168.2.88].
#   -d <path>            : path to data file [heizung.dat]
#   -p <path>            : path to parameter file [parameter.dat]
#   -H                   : print history of script.
#   -h                   : print help.
#
# ENVIRONMENT
#   The program does not use any environment variables.
#
# REQUIRE
#   bash, date, sed, awk, wc, wget, cat, echo
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
# path to parameter, data and temp file
PARAMFILE="parameter.txt"
DATAFILE="heizung.dat";
TMPFILE="data.tmp";
# rewrite flag for data file
REWRITE=false;

#-------------------  functions -----------------------------
#-------------------  get command line options --------------
usage()
{
  echo "";
  echo " getDataHeizung.sh [-adprhH]";
  echo " This bash-script reads parameters from BSB-LAN-arduino.";
  echo " Available Options:";
  echo " -a <nnn.nnn.nnn.nnn> : ip of arduino [192.168.2.88]";
  echo " -d <path> : path to data file [heizung.dat]";
  echo " -p <path> : path to parameter file [parameter.txt]";
  echo " -r: rewrite existing data file [append data to data file]";
  echo " -h: print help";
  echo " -H: print history of script";
  exit 0;
}

phistory()
{
  echo "";
  echo " getDataHeizung.sh[History]:";
  echo " 2021-02-16-kh: created.";
  echo " 2021-03-06-kh: uses now JSON format for data transfer.";
  echo "                output format: all parameters now in one line.";
  echo "                               new delimiter ','.";
  exit 0;
}

options()
# get options from commandline
{
  optstring="hHra:p:d:"
  while getopts "$optstring" arg $OPTS; do
    case "${arg}" in
	a)  ARDUINO=${OPTARG}
	    ;;
	d)  DATAFILE=${OPTARG}
	    ;;
	p)  PARAMFILE=${OPTARG}
	    ;;
	r)  REWRITE=true;
	    ;;
	h)  usage
            ;;
	H)  phistory
	    exit 1
            ;;
	?)  usage        # undeclared option found
	exit 1
	;;
    esac
  done
  # check if path to parameter file and data file are valid
  test -f $PARAMFILE || { echo "ERROR [getDataHeizung.sh]: parameter file '$PARAMFILE' does not exist, aborted."; exit; }
  touch $DATAFILE 2>/dev/null 1>&2
  test -f $DATAFILE  || { echo "ERROR [getDataHeizung.sh]: no valid path to data file '$DATAFILE', aborted."; exit; } 
  return;
}


#-------------------------   main  ---------------------------

# get options from commandline
OPTS=$@;
options;

# get date
DATE0=`date +%Y%m%d`;

# compute day of year"
DOY=`date +%j`;
HOUR=`date +%H`;
MIN=`date +%M`;
SEC=`date +%S`;
DATE=`bc <<<"scale=5;$DOY+$HOUR/24+$MIN/1440+$SEC/86400"`;

# get parameters from file "parameter.txt",
# write to format "par1/par2/par3/..."
#  - remove comments, discard empty lines
#  - assign to var READPAR0, one parameter per line
READPAR0=`sed 's/^\([0-9]*\).*/\1/; /^ *$/d; ' $PARAMFILE`;

#  - read multiples lines, discard empty lines
#  - replace CR at each EOL by ","
#  - assign to var READPAR
#    - determine number of parameter in parameter.txt
#    - construct var ANZN which gives number of lines for sed
#      NN = number of lines in parameter.txt
NN=`cat $PARAMFILE | sed '/^#/d; /^$/d' | wc -l`;
i=1; while [ $i -lt $NN ]; do ANZN=$ANZN"N;" && i=$[$i+1]; done
#    - replace ANZN CRs with ","
READPAR=$(sed "$ANZN; s/\n/,/g" <<< $READPAR0);

# reset temp file
# read parameters from heizung
# distinguish "name" from "dataType_name"
# set field seperator to "+"
# get parameter field, name, value and unit, write to temp file
rm -rf $TMPFILE;
wget -qO- http://$ARDUINO/JQ=$READPAR | sed 's/\"name/\"xname/g; s/\"/+/g' | awk '
BEGIN { ii=1; FS= "+" }
{ if ( $2 ~ /[0-9][0-9][0-9][0-9]/ ) {
      a[ii]=$2;
      ii++; }
  else {
      if ( $2 ~ /.*xname.*/ ) {
          a[ii]=$4;
          ii++; }
      else
          if ( $2 ~ /.*+value.*/ ) {
              a[ii]=$4;
              ii++; }
          else
              if ( $2 ~ /.*+unit.*/ ) {
                  if ( $4 ~ /^$/ ) a[ii]="0"; 
                  else a[ii]=$4;
                  ii++; }
  }
}
END {
    for (i=1; i<ii; i++) {
        printf ("%s\n", a[i]) > TMPFILE
    }
}' TMPFILE=$TMPFILE

# read parameters from temp file
# discard empty lines
# replace CR by ','
# add time stamp
# write to data file
READPAR20=`sed 's/\(.*\)/\1/;' $TMPFILE`;
NN=`cat $TMPFILE | sed "/^$/d" | wc -l`;
i=1; while [ $i -lt $NN ]; do ANZ=$ANZ"N;" && i=$[$i+1]; done
#    - replace ANZ CRs with ","
DATA=$(sed "$ANZ; s/\n/,/g" <<< $READPAR20);
if $REWRITE
then
    rm -rf $DATAFILE;
fi;
echo "$DATE0,$DATE,$DATA" >>$DATAFILE;
rm -rf $TMPFILE;

