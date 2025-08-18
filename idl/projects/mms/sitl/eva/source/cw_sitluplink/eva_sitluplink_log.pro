FUNCTION eva_sitluplink_log, tai_FOMstr_mod, check=check, title=title
  compile_opt idl2

  fname = 'eva_uplink_log.sav'
  found = file_test(fname)
  if found then begin
    restore, fname
  endif else begin
    eva_uplink_log = ''
  endelse
  
  this_str = tai_FOMstr_mod.METADATAEVALTIME
  
  tn = tag_names(tai_FOMstr_mod)
  idx = where(strlowcase(tn) eq 'uplinkflag', ct)
  
  if(ct eq 0)then begin
    return,'uplink-log: no flag'  ; If no UPLINK flag, then it is okay to submit
  endif else begin
    if (tai_FOMstr_mod.UPLINKFLAG eq 0) then return, 'uplink-log: flag=0'; If UPLINK flag=0, then it is okay to submit
  endelse

  ; If UPLINK=1, then
  
  idx = where(eva_uplink_log eq this_str, ct)
  if ct gt 0 then begin
    if undefined(title) then title = 'FOM Submission'
    msg=['This FOM structure has already been sent to SDC for uplink. ']
    msg=[msg, '(Clicking the UPLINK button multiple times is prohibited.)']
    msg=[msg,'This submission process is aborted.']
    rst = dialog_message(msg,/information,/center,title=title)
    return, 'uplink-log: abort'
  endif

  if keyword_set(check) then begin
    return, 'uplink-log: checked'
  endif else begin
    eva_uplink_log = [eva_uplink_log, this_str]
    save, eva_uplink_log, file=fname
    return, 'uplink-log: new metadataeval time saved'
  endelse
  
END