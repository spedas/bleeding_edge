;Load CDF data into IDL heap variables.
;Input:
;  IDL> cdf_load_ptr,FILENAME,CDF_VAR,PTR_ARRAY
;Keywords:
;  FILENAME is the filename of the CDF file.
;  CDF_VAR is a string array containing the desired CDF variable names.
;  PTR_ARRAY is an array of pointers to cdf data returned by cdf_load_ptr.
;Optional Keywords:
;  VALID is an array returned by cdf_load_ptr that flags invalid data with a 0.
;  DATA frees PTR_ARRAY and holds CDF data for one and only one CDF variable.
;  ALL loads data from all CDF variables.
;Bugs: None Known.


pro cdf_load_ptr,filename,cdf_var,ptr_array,valid=valid,data=data,all=all

if NOT arg_present(ptr_array) AND NOT arg_present(data) then begin
   print,'Error: Data cannot be returned to caller!'
   print,'Quitting... No data was returned.'
   return
endif

if file_test(filename) EQ 0 then begin
   print,'Error: File does not exist!'
   return
endif

if keyword_set(all) then begin
   cdfi=cdf_load_vars(filename,varformat='*')
   cdf_var=cdfi.vars.name
endif else begin
   if where(cdf_var EQ '*') NE -1 then begin
      print,'Error: * is not a proper CDF variable'
      valid=intarr(n_elements(cdf_var))
      return
   endif
   cdfi=cdf_load_vars(filename,varformat=cdf_var)
endelse

nvars=n_elements(cdf_var)
if nvars EQ 1 then begin
   valid=0
   ptr_array=ptr_new()
endif else begin
   valid=intarr(nvars)
   ptr_array=ptrarr(nvars)
endelse

for i=0,nvars-1 do begin
    ptr_loc=where(cdfi.vars.name EQ cdf_var[i])
    if ptr_loc EQ -1 then continue else valid=1
    ptr_array[i]=(cdfi.vars.dataptr)[ptr_loc]
endfor

if arg_present(data) then begin
   if nvars NE 1 then begin
      print,'Warning: Keyword DATA used with multiple CDF variables!'
      if (ptr_array)[0] EQ ptr_new() then begin
         print,'Quitting... No DATA was returned.'
         return
      endif
      print,'Returning DATA for CDF variable '+cdf_var[0]+' only.'
      data=*(ptr_array[0])
      heap_free,ptr_array,/ptr
      ptr_array=ptrarr(nvars)
      return
   endif
   if ptr_array EQ ptr_new() then return
   data=*ptr_array
   heap_free,ptr_array,/ptr
   ptr_array=ptr_new()
endif

return

end