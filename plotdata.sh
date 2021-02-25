#!/bin/bash
#############################################################
#
#  plotdata.sh
#
#############################################################
#
#  2021-02-16-1.0: created.
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
#   -d <date>       : specifies starting date [plot all data].
#   -p <parameter>  : specifies parameter to plot [8980].
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
#   bash, grep, sort, awk, gnuplot
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
# file prefix
DIR=".";
# parameter to plot
PARAM="8980";
# date of data to plot (preset use all dates)
DATE="";


#-------------------  functions -----------------------------
#-------------------  get command line options --------------
usage()
{
  echo "";
  echo " plotdata.sh [-pdhH]"
  echo " This bash-script plots data from ascii-files."
  echo " Available Options:"
  echo " -d yyyymmdd : date of data to be selected [use all data]"
  echo " -p nnnn : parameter [8980]"
  echo " -h: print help"
  echo " -H: print history of script"
  exit 0;
}

history()
{
  echo "";
  echo " plotdata.sh[History]:";
  echo " 2021-02-16-kh: created."
  exit 0;
}



#-------------------------   main  ---------------------------------------
# get options from commandline
optstring="hHp:d:"
while getopts "$optstring" arg; do
    case "${arg}" in
	p)  PARAM=${OPTARG}
	    ;;
	d)  DATE=${OPTARG}
	    ;;
	h)  usage
            ;;
	H)  history
	    exit 1
            ;;
	?)  usage        # this is called for undefined options
	exit 1
	;;
    esac
done

# get data from file
# select vi $DATE and $PARAM
grep "$DATE" $DIR/heizung.dat >datd.tmp
grep "$PARAM" datd.tmp >datp.tmp
sort -k 1,2 datp.tmp > dat.tmp
rm datd.tmp datp.tmp
# get starting date from very first line
start=`awk -F " " 'NR==1 {print $1}' dat.tmp`;

# setup skript file for gnuplot
echo "set title 'Heizungsdaten'" >plot.gpl;
echo "set pointsize 1.5" >>plot.gpl;
echo "set autoscale"   >>plot.gpl;
echo "unset log" >>plot.gpl;
echo "unset label" >>plot.gpl;
echo "set xtic auto " >>plot.gpl;
echo "set ytic auto " >>plot.gpl;
echo "set xlabel 'Zeit (day of year)' " >>plot.gpl;
echo "set ylabel 'Temperatur °C' " >>plot.gpl;
echo "plot 'dat.tmp' using 3:6 title columnheader(4) with linespoints" >>plot.gpl; 
echo "pause -1" >>plot.gpl; 

# call gnuplot
gnuplot plot.gpl;
