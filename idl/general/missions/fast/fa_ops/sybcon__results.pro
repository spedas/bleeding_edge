;+
;FUNCTION: sybcon::results(name)
; Class:  sybcon
; Method: results
; 
; For second and subsequent result sets produced by SQL batch sent with the
; sybcon::send method, sybcon::results creates a structure internal
; to the class to recieve the result columns.  
; Structure tags will correspond to 
; result column names.  Unnamed columns will be tagged "col#" where
; '#' is the number of the column.  Supply the name argument 
; if you want to fetch data into a named structure.
; 
; result:
;       > 0 - number of columns in result set.  
;       0   - no results to fetch.
;       < 0 - error, or no more results.
;
; parameters:
;       name - name for named structure in which fetch rows will be returned.
;              Optional.
;-


FUNCTION sybcon::results, name
self.ncols = call_external('libsybidl.so', 'sybresults', self.dbproc)
if self.ncols gt 0 then begin
                                ; there are results to bind
    struct = ""
    ptr_free, self.datatype
    ptr_free, self.datasize
    ptr_free, self.nullind
    
    self.datatype = ptr_new(lonarr(self.ncols))
    self.datasize = ptr_new(lonarr(self.ncols))
    self.nullind = ptr_new(intarr(self.ncols))
    structdef = ""
    retval = call_external('libsybidl.so', 'sybdesc_row', $
                           self.dbproc, $
                           structdef, *self.datatype, *self.datasize, self.ncols)
    ptr_free, self.row
    if n_params() eq 0 then begin 
        ret = execute( 'self.row = ptr_new({' + structdef +'})')
    end else begin
        ret = execute( 'self.row = ptr_new({' + name + ', ' + structdef +'})')
    end        
    retval = call_external('libsybidl.so', 'sybbind_row', self.dbproc, $
                           *self.row, *self.datatype, *self.datasize, $
                           *self.nullind, self.ncols)
    
endif
return, self.ncols
end


