#!/bin/bash
#############################################################
#
#  plotdata.sh
#
#############################################################
#
#  2021-02-16-1.0: created.
#  2021.03-08-1.1: adapted to new data format.
#
#############################################################
#
# DESCRIPTION
#  This script plots data from an ascii-file with the following
#  format:
#   YYYYMMDD HHMMSS day_of_year parameter "parameter_text" value unit
#   Delimiter is 'tab'
#
# OPTIONS
#   -d <yyyymmdd>   : specifies starting date [plot all data].
#   -i <path>       : specifies path to input data file [heizung.dat].
#   -s <nn.nn>      : start time in day of year [0.0].
#   -e <nn.nn>      : end time in day of year [366.0].
#   -p <parameter>  : specifies parameter to plot [8700].
#   -q              : quiet, no output.
#   -H              : print history of script.
#   -h              : print help.
#
# EXAMPLE
#   plotdata.sh -p 8510 -d 20210216
#
# ENVIRONMENT
#   The program does not use any environment variables.
#
# REQUIRE
#   bash, echo, grep, awk, sed, head, gnuplot
#
# BUGS
#   No known bugs.
#
# AUTHOR
#   Written by Karl-Heinz Mantel. 
#   Send bug reports to 'mantel@lmu.de'.
#
#############################################################

#-------------------  global variables  --------------
# data file
DATAFILE="heizung.dat";
DATATMP="dat.tmp";
PLOTFILE="plot.gpl";
PLOTTMP="plot0.gpl";
# parameter to plot
PARAM="8700";
PLTPAR="8700";
STARTTIME="0.0";
ENDTIME="366.0";
# date of data to plot (preset use all dates)
DATE="";
QUIET="0";


#-------------------  functions -----------------------------
usage()
# print help
{
  echo "";
  echo " plotdata.sh [-idsepqhH]"; echo"";
  echo " This bash-script plots data from ASCII-files with the following format:";
  echo " date %4d, day of year %f, parameter %4d, description %s, value %f, unit %s";
  echo " The last 4 entries may be repeated. Fieldseparator is \",\".";echo"";
  echo " Example:";
  echo " 20210308,67.41251,8700,Außentemperatur,2.7,&deg;C,8510,Kollektortemperatur 1,45.2,&deg;C";
  echo " 20210308,67.41320,8700,Außentemperatur,2.7,&deg;C,8510,Kollektortemperatur 1,45.0,&deg;C";
  echo " ...";
  echo " ";
  echo " Options:";
  echo " -i <path>          : path of data input file [heizung.dat]";
  echo " -d <yyyymmdd>      : date of data to be selected [use all data]";
  echo " -s <nn.nn>         : start time in day of year [0.0]";
  echo " -e <nn.nn>         : last time in day of year [366.0]";
  echo " -p <nnnn,nnnn,...> : parameters to plotted [8700]";
  echo " -q                 : quiet, no output";
  echo " -h                 : print help";
  echo " -H                 : print history of script";
  echo "";
  exit 0;
}

phistory()
# print program history
{
  echo "";
  echo " plotdata.sh[History]:";
  echo " 2021-02-16-kh: created."
  echo " 2021-03-08-kh: adapted to new data format.";
  echo "                added time interval.";
  exit 0;
}

options()
# get options from commandline
{
  optstring="hHqp:i:d:s:e:"
  while getopts "$optstring" arg $OPTS; do
    case "${arg}" in
      p)  PARAM=${OPTARG}
          ;;
      i)  DATAFILE=${OPTARG}
          ;;
      d)  DATE=${OPTARG}
          ;;
      s)  STARTTIME=${OPTARG}
          ;;
      e)  ENDTIME=${OPTARG}
          ;;
      q)  QUIET=1
          ;;
      h)  usage
          ;;
      H)  phistory
          exit 1
          ;;
      ?)  usage        # this is called for undefined options
  	  exit 1
	  ;;
    esac
  done
  # check if path to data file is valid
  test -f $DATAFILE  || { echo "ERROR [plotdata.sh]: no valid path to data file '$DATAFILE', aborted."; exit; } 
  return;
}

checkInput()
# info output
# get starting date from first line of data input file
{
  # read date from very first line 
  DATE00=`sed 's/^\([0-9]*\),.*/\1/; 1q' $DATAFILE`;
  # compute day of year"
  DOY=`sed 's/^[0-9]*,\([0-9]*\).*/\1/; 1q' $DATAFILE`;
  # first and last time entry in data file
  FIRSTTIME=`sed 's/^[0-9]*,\([0-9]*.[0-9]*\).*/\1/; 1q' $DATAFILE`;
  LASTTIME=`awk 'BEGIN{FS=",";} END {print $2}' $DATAFILE`;
  if [ $QUIET -ne "1" ]; then
    echo "plotdata:";
    echo " input file         : $DATAFILE";
    echo " starting date      : $DATE00 (day of year: $DOY)";
    echo " time range         : $FIRSTTIME - $LASTTIME";
    echo " selected time range: "$STARTTIME" - " $ENDTIME;
  fi 
  VALID=`awk -v stime=$STARTTIME -v ltime=$LASTTIME -v etime=$ENDTIME -v ftime=$FIRSTTIME 'BEGIN {  
    if ( (stime > ltime) || (etime<ftime) )
      print "1";
    else
      print "0";
    } '`;
  if [ $VALID -eq "1" ]; then
    echo "ERROR [plotdata.sh]: time range out of bounds, aborted.";
    exit 1;
  fi
  found=`head -n 1 $DATAFILE | sed 's/[[:alpha:]] (*[[:alpha:]]*[0-9])*//g; s/[[:alpha:]]*&*;* *//g; s/[0-9]*\.[0-9]*//g; s/^[0-9]*,,//; s/,,*/ /g; s/ [0-9] //g';`
  if [ $QUIET -ne "1" ]
  then
    echo " parameters found   : $found";
    echo " ";
  fi;
}

selectData()
# select data by time constraints (options s,e)
{
  rm -rf dat.tmp0
  grep "$DATE" $DATAFILE | sed 's/255/100/g;' >dat.tmp0
  awk '
  BEGIN { FS = ","; }
  {
    if ( ($2 > stime) && ($2 < etime) ) {
       print $0;
    }
  }
  END {
  }' stime=$STARTTIME etime=$ENDTIME dat.tmp0 >>$DATATMP;
  rm -rf dat.tmp0;
  return;
}

plotInit()
# init gnuplot execution file
{
  # setup skript file for gnuplot
  echo "set title 'Heizungsdaten         Start: $DATE0'" >$PLOTTMP;
  echo "set datafile separator \",\"" >>$PLOTTMP;
  echo "set pointsize 1.5" >>$PLOTTMP;
  echo "set autoscale"   >>$PLOTTMP;
  echo "unset log" >>$PLOTTMP;
  echo "unset label" >>$PLOTTMP;
  echo "set xtic auto " >>$PLOTTMP;
  echo "set ytic auto " >>$PLOTTMP;
  echo "set xlabel 'Zeit (day of year)' " >>$PLOTTMP;
  echo "set ylabel 'Temperatur °C' " >>$PLOTTMP;
  #echo "set format x '%3.2t'" >>$PLOTTMP
  return;
}

plotConfig()
# get index for value of parameter $PARAM in data file
# write plot command to gnuplot execution file
{
  awk '
  BEGIN { FS = ","; }
  { 
    j=3;
    while ( (j <= NF) && ($j != par) ) {
      j=j+4;
    }
    n=j+1;
    j=j+2;
  }
  END {
    printf ("\"%s\" using 2:%d title columnheader(%d) with linespoints, ",file,j,n);
  }' par=$PLTPAR file=$DATATMP $DATATMP >>$PLOTTMP;
  return;
}


#-------------------------   main  ---------------------------------------

# get options from commandline
OPTS=$@;
options;

# info output
# check input values
checkInput;

# selected data from input file by time constraints
# write to temp file
# change on-value (255) to 100 for better scaling
selectData;

# get starting date from first line of data to be plotted
DATE0=`sed 's/^\([0-9]*\),.*/\1/; 1q' $DATATMP`;

# initialize gnuplot execution file
plotInit;

# get parameters to be plotted
# setup gnuplot execution file
OIFS=$IFS;
IFS=',';
for x in $PARAM
do
    PLTPAR=$x;
    plotConfig;
done
IFS=$OIFS;
sed 's/^"\(.*\)"/plot "\1"/g; s/\(.*\), $/\1\n/g' $PLOTTMP  >$PLOTFILE;
echo "pause -1" >>$PLOTFILE;

# make plot
gnuplot $PLOTFILE;

# remove temp files
rm -rf $DATATMP $PLOTTMP $PLOTFILE;
exit;

