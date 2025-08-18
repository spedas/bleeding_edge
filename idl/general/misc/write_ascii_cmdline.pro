pro write_ascii_cmdline, data, filename, header=header, nrecs=nrecs
;
; NAME:
;   WRITE_ASCII_CMDLINE
;
; PURPOSE:
;   Write an IDL data to an ASCII file.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   WRITE_ASCII_CMDLINE, data, filename, field_types=field_types, header=header
;   
;
; INPUTS:
;   data             = A structure containing the fields or columns. Ex:
;                      {field01:[col1], field02:[col2], ...} where colx is a 1-D or
;                      nrow array. All colx's must be of the same size or nrows.  
;                      Data could also be an ncol x nrow array of data where all data
;                      is of the same type.
;   filename         = Name of file to read.
;
; INPUT KEYWORD PARAMETERS:
;
;   header           = An array of strings containing header information for the file
;
; OUTPUT KEYWORD PARAMETERS:
;   nrecs            = The number of data records writen. This count does not include header
;                      data. 
;
; OUTPUTS:
;   none
;
; EXAMPLES:
;   data = dingen(3,10) (ncol,nrow)
;   filename = 'test.txt'
;   write_ascii_cmdline, data, filename
;   
;   data = {t:[], x:[], y:[], z:[]}  where t=array of string times, x,y,z= an array of doubles 
;   header = ['', '', '',...]
;   field_types = ['string', 'double', 'double', 'double']
;   write_ascii_cmdline, data, filename, field_types=field_types, header=header, count=count
;
; NOTES:
;   May possibly want to add a keyword to specify formats. Something similar to the 
;   field_types keyword in read_ascii_cmdline. 
;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; verify filename
if (filename ne '') then begin
   openw,unit,filename,/get_lun 
endif else begin
   print, 'You must enter a filename'
   print, 'Usage: write_ascii_cmdline, data, filename, field_types=field_types, header=header, count=count'
   return
endelse

; check the type of input data and determine the array sizes
if is_struct(data) then begin
   ncols = n_elements(tag_names(data))
   nrows = n_elements(data.(0))
endif else begin
   if n_elements(size(data, /dim)) eq 1 then begin
      ncols=1
      nrows=size(data, /dim)
   endif else begin
      ncols = (size(data, /dim))[0]
      nrows = (size(data, /dim))[1]
   endelse
endelse

; write header information first
if is_string(header) then for i=0,n_elements(header)-1 do printf, unit, header[i]

; now write the data
strings = make_array(ncols, /string)
for i=0,nrows-1 do begin
  if is_struct(data) then begin
    for j=0, ncols-1 do strings[j]=string(data.(j)[i])
       printf, unit, strings
  endif else begin
       printf, unit, data[*,i]
  endelse
endfor

free_lun,unit

nrecs=i
if nrecs ne nrows then print, 'Error - Did not finish writing all rows to the file.'

end

 

 

 
