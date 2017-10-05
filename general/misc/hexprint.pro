;+
;hexprint
; :Description:
;    Routine that will display hex values of an array of bytes, ints or longs.
;
; :Params:
;    buffer - Either an array of (bytes, ints or longs) or a filename to open
;
; :Keywords:
;    unit
;    filename: Set this keyword to filename to dump the results
;    decimal:  display in decimal instead of hex.
;    start
;    nbytes: Set to number of bytes to display. Default is one kilobyte.
;    dlevel
;    ncolumns
;
; :Author: davin  Jan 19, 2015
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;
;-
pro hexprint,buffer,unit=unit,filename=filename,decimal=decimal,start=start,nbytes=nbytes,dlevel=dlevel,ncolumns=ncolumns

if size(/type,buffer) eq 7 && file_test(buffer,/regular) then begin   ; display file
   fi = file_info(buffer)
   file_open,'r',buffer,unit=ifp,dlevel=3,verbose=2
   if not keyword_set(nbytes) then nbytes=1024
   buffer2 = bytarr(nbytes < fi.size)
   readu,ifp,buffer2
   free_lun,ifp
   hexprint,buffer2,unit=unit,filename=filename,decimal=decimal,ncolumns=ncolumns
   return
endif


if keyword_set(filename) then openw,unit,filename,/get_lun
if not keyword_set(unit) then u=-1 else u=unit

nbts = [0,1,2,4,0,0,0,0,0,0,0,0,2,4,8,8,0,0,0,0]
type=size(/type,buffer)
nb = nbts[type]
case nb of
  1: format = '(128(z02," "))'
  2: format = '(128(z04," "))'
  4: format = '(128(z08," "))'
  8: format = '(128(z016," "))'
  else: format =''
endcase
if keyword_set(decimal) then begin
  case type of
     1: format = '(128(i3," "))'
     2: format = '(128(i6," "))'
     12: format = '(128(i5," "))'
     else: format = ''
  endcase
endif
if not keyword_set(format) then print,'No data to display'


cols = ([0,32,16,0,8,0,0,0,8])[nb]

if keyword_set(ncolumns) then cols = ncolumns

remap = bindgen(255)
remap[0:31] =  32b
remap[128:*] = 32b

n = n_elements(buffer)
if keyword_set(nbytes) then n = n < nbytes
blank = '   '
i=0l
while i lt n do begin
  s = string(i,format='(z06,"x: ")' )
  row = buffer[i:(i+cols-1) < (n-1)]
  s += string(row,format=format)
  if n_elements(row) ne cols then s+= strjoin(replicate(blank,cols-n_elements(row)))
  if type eq 1 then begin
    s +=  '  '+ string(remap[row])
  endif
  i+=cols
  printf,u,s
endwhile

if keyword_set(filename) then free_lun,unit

end
