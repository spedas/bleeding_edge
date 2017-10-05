PRO eva_sitl_save, auto=auto, dir=dir, quiet=quiet
  compile_opt idl2
  
  stn = tnames('mms_stlm_fomstr',ct)
  if ct ne 1 then begin
    answer=dialog_message('FOMstr not found',/center,/error)
    return
  endif
  
  get_data,'mms_stlm_fomstr',data=D,lim=eva_lim,dl=eva_dl
  
  if keyword_set(auto) then begin 
    if n_elements(dir) eq 0 then dir = spd_default_local_data_dir() + 'mms/'
    fnameP= 'eva-fom-modified.sav'
    fname = 'eva-fom-modified-most-recent.sav'
    fname1= 'eva-fom-modified.1step-before.sav'
    fname2= 'eva-fom-modified.2steps-before.sav'
    fname3= 'eva-fom-modified.3steps-before.sav'
    fname4= 'eva-fom-modified.4steps-before.sav'
    found=file_test(fname3) & if found then file_copy, fname3, fname4,/overwrite
    found=file_test(fname2) & if found then file_copy, fname2, fname3,/overwrite
    found=file_test(fname1) & if found then file_copy, fname1, fname2,/overwrite
    found=file_test(fname)  & if found then file_copy, fname,  fname1,/overwrite
    found=file_test(fnameP) & if found then file_delete, fnameP
  endif else begin
    fname_default = 'eva-fom-modified-'+time_string(systime(1,/utc),format=2)+'.sav'
    fname = dialog_pickfile(DEFAULT_EXTENSION='sav', /WRITE, $
      FILE=fname_default)
    if strlen(fname) eq 0 then begin
      answer = dialog_message('Cancelled',/center,/info)
      return
    endif
  endelse
  save, eva_lim, eva_dl, filename=fname
  found = file_test(fname)
  if found then begin
    if keyword_set(auto) then msg = 'Successfully saved!' $
      else msg = 'Successfully saved as '+fname 
    if ~keyword_set(quiet) then answer = dialog_message(msg,/center,/info)
  endif else begin
    answer = dialog_message('Not Saved! (eva_sitl_save)',/center,/error)
  endelse
END
