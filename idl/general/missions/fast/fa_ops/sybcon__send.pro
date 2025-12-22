;+
;FUNCTION: sybcon::send(comm, name)
; Class:  sybcon
; Method: send
; 
; sends sql batch to server, creates a structure internal to the class to
; recieve the result columns.  Structure tags will correspond to 
; result column names.  Unnamed columns will be tagged "col#" where
; '#' is the number of the column.  Supply the name argument 
; if you want to fetch data into a named structure.
; 
; result:
;       > 0 - number of columns in result set.  
;       0   - no results to fetch.
;       < 0 - error.
;
; parameters:
;       comm - string containing sql command to send
;       name - name for named structure in which fetch rows will be returned.
;              Optional.
;-

FUNCTION sybcon::send, comm, name

if data_type(comm) ne 7 then begin
    message,/info,'Sql command must be a string'
    return, -1
end

self.ncols = call_external('libsybidl.so', 'sybsend', self.dbproc, comm)
if self.ncols gt 0 then begin
                                ; there are results to bind
    ptr_free, self.datatype
    ptr_free, self.datasize
    ptr_free, self.nullind
    ptr_free, self.row

    self.datatype = ptr_new(lonarr(self.ncols))
    self.datasize = ptr_new(lonarr(self.ncols))
    self.nullind = ptr_new(lonarr(self.ncols))
    structdef = ""
    retval = call_external('libsybidl.so', 'sybdesc_row', $
                           self.dbproc, structdef,  $
                           *self.datatype, *self.datasize, self.ncols)
    ; define the structure which defines the columns for the row.
    if n_params() eq 1 then begin 
        ; anonymous structure
        ret = execute( 'self.row = ptr_new({' + structdef +'})')
    end else begin
        ; named structure
        ret = execute( 'self.row = ptr_new({' + name + ', ' + structdef +'})')
    end        
    retval = call_external('libsybidl.so', 'sybbind_row', self.dbproc, $
                           *self.row, *self.datatype, *self.datasize, $
                           *self.nullind, self.ncols)
    
endif
return, self.ncols
end

