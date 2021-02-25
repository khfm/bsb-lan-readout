# bsb-lan-readout
shell scripts for reading data from the bsb-lan adapter on arduino 
and to plot data.

'getDataHeizung.sh' bash script to read data from bsb-lan-adpater
  on arduino board. Data will be read to ASCII-file 'heizung.dat'.

'parameter.txt' ASCII-file with list of parameters to be read by
  bash script 'getDataHeizung.sh'

'plotdata.sh' bash script to plot data from ASCII-file 'heizung.dat'.

'plot.gpl' plot script generated by 'plotdata.sh' in order to plot
  data from ASCII-file 'heizung.dat' via gnuplot.

'dat.tmp' data file of plot generated by 'plotdata.sh' from ASCII-
  file 'heizung.dat'.

For help see:

   getDataHeizung.sh -h
   plotdata.sh -h

20210216-1.0, K.H.Mantel, mantel@lmu.de
