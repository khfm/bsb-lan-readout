# bsb-lan-readout
Mit dem Bash-Skript 'getDataHeizung.sh' können Parameter vom BSB-LAN-Arduino
gelesen werden. Mit dem Bash-Skript 'plotdata.sh' können sie geplottet
werden.

'parameter.txt' ASCII-File zur Definition der zu lesenden Parameter.

'getDataHeizung.sh' Bash-Skript liest parameter von Arduino in Datei
   'heizung.dat'.

'plotdata' Bash-Skript plottet Daten von ascii-file 'heizung.dat'.

'heizung.dat'  ASCII-Datei Beispieldaten.

'plot.gpl' plot script für gnuplot wird von 'plotdata' erstellt.

'dat.tmp' Datenfile des Plots, wird von 'plotdata' aus 'heizung.dat' erstellt.

Help-Funktion:
  getDataHeizung.sh -h
  plotdata.hs -h


20210216-1.0, K.H.Mantel, mantel@lmu.de
