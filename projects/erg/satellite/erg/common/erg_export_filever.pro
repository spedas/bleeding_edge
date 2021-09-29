;+
; PRO erg_export_filever
;
; The program for storing data information readed by load procedures 
;
; :Examples:
;   IDL> erg_export_filever, datfiles
;   (datfiles is a strarr including local paths of all loaded files)  
;-

pro erg_export_filever, datfiles

; check the obsolete datalist in tplot
get_data, 'erg_load_datalist', data=datalist
if (undefined(datalist) or (ISA(datalist, 'hash') NE 1)) then begin
   datalist = hash()
   filelist = hash()
endif

; extract erg_load_datalist [version number] 
foreach file, datfiles do begin

   p1 = strpos(file, '/', /REVERSE_SEARCH)
   p2 = strpos(file, '_v', /REVERSE_SEARCH)
   fn = strmid(file, p1+1, (p2-9-p1-1))

   if datalist.HasKey(fn) then filelist = datalist[fn] else filelist = hash()

   cdfinx = strpos(file, '.cdf')
   ymd = strmid(file, cdfinx - 15, 8)
   Majver = strmid(file, cdfinx - 5, 2)
   Minver = strmid(file, cdfinx - 2, 2)

   filelist[ymd] = hash('major',Majver, 'minor',Minver, 'fullpath', file )
   datalist[fn] = filelist

endforeach

; write the data in new datalist
store_data, 'erg_load_datalist', data=datalist

END
