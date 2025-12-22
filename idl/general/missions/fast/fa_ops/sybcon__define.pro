;
; constructor for sybcon class
;

FUNCTION sybcon::INIT, config=config, appname=appname

if keyword_set(config) then self.config = config

if not keyword_set(appname) then appname = 'idl'

if data_type(appname) ne 7 then begin
    message,/info,'appname must be a string'
    return, 0
end

dbproc = 0l     ; a 'null' pointer

retval = call_external('libsybidl.so', 'sybconnect', dbproc, $
                       self.config, appname)

self.dbproc = dbproc

if retval ne 0 then return, 0 else return, 1

end

; 
; diagnostic print routine for sybcon class
;

pro sybcon::print
help, self.dbproc
help, self.config
end

;
; Destructor for sybcon class.  Simply calls obj_destroy.
;
PRO sybclose, con
obj_destroy, con
end


; Class:  sybcon
; Method: cleanup
;
; cleanup proceedure called when sybcon object instance is destroyed.
; closes connection with sybase and frees IDL dynamic memory.

PRO sybcon::cleanup
retval = call_external('libsybidl.so', 'sybclose', self.dbproc)
ptr_free, self.row
ptr_free, self.datatype
ptr_free, self.datasize
ptr_free, self.nullind
;print, "sybcon::cleanup", retval
end


; obsolete datetime structure.  This is Sybase Client-Library's native
; date format.  Fetch currently automatically converts this to an IDL
; time double.
pro CS_DATETIME__DEFINE
   struc = {CS_DATETIME, dtdays:0l, dttime:0l}
END


; Class:  sybcon
; class definition.
;
pro SYBCON__DEFINE
; must initialize DB-library before SYBCON class can be used.
if call_external('libsybidl.so', 'sybinit') eq 1 then begin
    struc = {sybcon, dbproc:0l, config:'', $
             row:ptr_new(), datatype:ptr_new(), datasize:ptr_new(),  $
             nullind:ptr_new(), ncols:0l}
end

END

