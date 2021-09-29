PRO sppeva_sitl_save, tpv, filename=filename, auto=auto
  compile_opt idl2
  
  if undefined(tpv) then tpv = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr')
  
  ;--------------
  ; Filename
  ;--------------
  u = '.'+!SPPEVA.COM.USER_NAME+'.csv'
  if keyword_set(auto) then begin
    fname  = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr.most-recent'+u)
    fname1 = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr.1step-before'+u)
    fname2 = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr.2steps-before'+u)
    fname3 = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr.3steps-before'+u)
    fname4 = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr.4steps-before'+u)
    found=file_test(fname3) & if found then file_copy, fname3, fname4,/overwrite
    found=file_test(fname2) & if found then file_copy, fname2, fname3,/overwrite
    found=file_test(fname1) & if found then file_copy, fname1, fname2,/overwrite
    found=file_test(fname ) & if found then file_copy, fname , fname1,/overwrite
  endif else begin
    if undefined(filename) then begin
      fname = dialog_pickfile(DEFAULT_EXTENSION='csv', /WRITE, FILE=tpv+'.csv')
      if strlen(fname) eq 0 then begin
        answer = dialog_message('Cancelled',/center)
        return
      endif
    endif else fname = filename
  endelse
  
  ;--------------
  ; SAVE
  ;--------------
  sppeva_sitl_tplot2csv, tpv, filename=fname, msg=msg, error=error, auto=auto

  ;--------------
  ; MESSAGE
  ;--------------
  if keyword_set(auto) and (error eq 0) then return
  
  if strlen(msg) gt 0 then begin
    answer = dialog_message(msg,/center)
  endif else begin
    found = file_test(fname)
    if found then begin
      msg = 'Successfully saved as '+fname
      answer = dialog_message(msg,/center,/info)
    endif else begin
      answer = dialog_message('Not Saved! (sppeva_sitl)',/center,/error)
    endelse
  endelse
END
