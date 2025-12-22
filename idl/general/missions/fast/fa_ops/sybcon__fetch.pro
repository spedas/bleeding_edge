
;+
;FUNCTION: sybcon::fetch(row)
; Class:  sybcon
; Method: fetch
; 
; Fetches a row of result set after sybcon::send or sybcon::results
; returns > 0.  Must be called until returns 0 before calling
; sybcon::results to process next result set in batch.
; 
; result:
;       1 - row successfully fetched
;       0 - no more rows. 
;       < 0 - error.
;
; parameters:
;       row - named variable in which to store the structure
;             containing the row result.
;
;-

FUNCTION sybcon::fetch, row

retval = call_external('libsybidl.so', 'sybfetch', self.dbproc, $
                           *self.row, *self.datatype, *self.datasize, $
                           *self.nullind, self.ncols)
row = *(self.row)

return, retval
end

