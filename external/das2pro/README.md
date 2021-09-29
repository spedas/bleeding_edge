# das2pro
Das2 servers typically provide data relavent to space plasma and magnetospheric
physics research.  To retrieve data, an HTTP GET request is posted to a das2 
server by a client program and a self-describing stream of data values covering
the requested time range, at the requested time resolution, is provided in the
response body.  This software provides a client library for das2 servers
written in pure [IDL](https://www.harrisgeospatial.com/docs/using_idl_home.html).
To find out more about das2 visit https://das2.org.

**das2pro** is an IDL package and may be installed using the 
[IPM](https://www.harrisgeospatial.com/docs/ipm.html)  command.  The IPM
command only installs github.com releases (does not use clone).  If you are
using IDL 8.7.1 or higher, das2pro can be downloaded and installed by issuing
the single IDL command:

`IDL> ipm, /install, 'https://github.com/das-developers/das2pro'`

After installation it's best to test the package by generating one or more
of the example plots.  This can be done running the included example 
procedures as follows:
```
IDL> ex01_cassini_rpws_wfrm
IDL> ex03_rbsp_ephem_loc
IDL> ex05_juno_waves_survey
```
Each example generates a PNG image in the current directory. Use your favorite
image viewer to inspect the results.  Other examples may be found in within
your local IDL package directory:

`$HOME/.idl/idl/packages/das2pro/examples`

To update das2pro to the latest version run the IPM command:

`IDL> ipm, /update, 'das2pro'`

and to remove das2pro from your packages directory issue:

`IDL> IPM, /remove, 'das2pro'`

If you are not running IDL 8.7.1 or higher, but are using at least IDL 8.6, 
das2pro will still work.  You can download this package and run the included
examples directly from your git working copy area.  To do so issue:
```
$ git clone https://github.com/das-developers/das2pro.git
$ cd das2pro
$ env IDL_PATH="<IDL_DEFAULT>:$(pwd)/src:$(pwd)/examples" idl87
IDL> das2pro_ut              ;running unit tests
IDL> ex02_mex_marsis_ais     ;for example
```
Here '$' indicates a shell command, and 'IDL>' indicates an IDL command.
