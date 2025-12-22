;+
;CLASS: sybcon
;
;FUNCTION: sybcon()
;
;PURPOSE:
;  Create an instance of the sybcon class to manage 
;  a connection to a sybase server.
;
;METHODS:
;  sybcon::INIT
;  sybcon::send
;  sybcon::fetch
;  sybcon::results
;  sybcon::cleanup
;
;DESTRUCTOR:
;  sybclose, con
;  obj_destroy, con
;     both have the same functionality.  If con is not destroyed, this
;     will cause a 'connection leak' which will eventually
;     fill up all available connections on the server.
;
;INPUT:  no inputs
;
;OUTPUT:
;  a pointer to a sybcon class instance.
;
;KEYWORDS:
;  config - name of database config file.
;           $FASTCONFIG/fast_archive.conf used by default.
;  appname - appname to use for connection.  Default: 'idl'
;
;
;CALLING SEQUENCE:
;  con = sybcon()
;  print,  con->send('select start, finish from orbits where orbit = 500')
;  print, con->fetch(orbittime)
;  print, time_string(orbittime.start)
;  print, time_string(orbittime.finish)
;  sybclose, con
;
;
;CREATED BY:	Ken Bromund  Dec 1997
;-
; 

function sybcon, config=config, appname=appname

return, obj_new('sybcon', config=config, appname=appname)

end

