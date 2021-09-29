FUNCTION eva_sitl_fom2bak_from_sav, fname
  compile_opt idl2
  
  ;---------------------
  ; RESTORE (from .sav)
  ;---------------------

  restore, fname; save, eva_lim, eva_dl, filename=fname

  if (~strmatch(fname,'*eva-fom-modified*')) and (~strmatch(fname,'*sitl_selections*')) then begin
    print, 'Attempt to read:',fname
    msg = 'The input file name must contain either "eva-fom_modified*" or "sitl_selections*"'
    result = dialog_message(msg,/center,/error)
    return, -1
  endif

  if strmatch(fname,'*eva-fom-modified*') then begin
    unix_fomstr = eva_lim.UNIX_FOMSTR_MOD
  endif else begin
    if n_tags(FOMstr) then begin
      result = dialog_message('Invalid input file.',/center,/error)
      return, -1
    endif
    mms_convert_fom_tai2unix, FOMstr, unix_fomstr, start_string
  endelse
  
  return, unix_fomstr
END
