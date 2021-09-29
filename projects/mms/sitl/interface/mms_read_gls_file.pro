; Function to read MMS gls files
; Input is the filename
; Output is a structure that includes FOM_Start, FOM_stop, FOM and comment. Times are given in UTC time format.
; 


FUNCTION mms_read_gls_file_template
  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {VERSION:1.00000, $
    DATASTART:0L, $
    DELIMITER:44b, $
    MISSINGVALUE:anan[0], $
    COMMENTSYMBOL:'', $
    FIELDCOUNT:6L, $
    FIELDTYPES:[7L, 7L, 3L, 7L, 7L, 3L], $
    FIELDNAMES:['FIELD1','FIELD2','FIELD3','FIELD4','FIELD5','FIELD6'], $
    FIELDLOCATIONS:lonarr(6),$
    FIELDGROUPS:[0L,1L,2L,3L,4L,5L]}
  return, ppp
END


function mms_read_gls_file, filename

if strlen(filename) eq 0 then return, 0

;output = read_csv(filename)
output = read_ascii(filename,template=mms_read_gls_file_template())

start_time = output.field1
stop_time = output.field2
fom = output.field3
comment = output.field4

outstruct = {start: start_time, $
             stop: stop_time, $
             fom: fom, $
             comment: comment}

return, outstruct
end