PRO eva_sitl_combine_sav, fname1, fname2, fname_new=fname_new, loud=loud
  compile_opt idl2
  
  fname1 = 'eva-fom-modified-levon.sav'
  fname2 = 'eva-fom-modified-levon_SW.sav'
  if(undefined(fname_new))then begin
    fname_new = 'eva-fom-modified-combined.sav'
  endif
  restore, fname1
  eva_lim1 = eva_lim
  restore, fname2
  eva_lim2 = eva_lim
  
  ;--------------------
  ; METADATAEVAL check
  ;--------------------
  t1 = eva_lim1.UNIX_FOMSTR_MOD.METADATAEVALTIME
  t2 = eva_lim2.UNIX_FOMSTR_MOD.METADATAEVALTIME
  if(t1 ne t2) then begin
    print, msg
    if(keyword_set(loud))then begin
      msg = "The two files are for different SITL windows."
      msg = [msg, "EVA cannot combine the two files."]
      result = dialog_message(msg,/center)
    endif
    return
  endif
  s1 = eva_lim1.UNIX_FOMSTR_MOD
  s2 = eva_lim2.UNIX_FOMSTR_MOD

  str_element,/add,eva_lim,'UNIX_FOMSTR_MOD.DISCUSSION',[s1.DISCUSSION,s2.DISCUSSION]
  str_element,/add,eva_lim,'UNIX_FOMSTR_MOD.FOM', [s1.FOM, s2.FOM]
  str_element,/add,eva_lim,'UNIX_FOMSTR_MOD.SEGLENGTHS', [s1.SEGLENGTHS, s2.SEGLENGTHS]
  str_element,/add,eva_lim,'UNIX_FOMSTR_MOD.SOURCEID',[s1.SOURCEID, s2.SOURCEID]
  str_element,/add,eva_lim,'UNIX_FOMSTR_MOD.START',[s1.START, s2.START]
  str_element,/add,eva_lim,'UNIX_FOMSTR_MOD.STOP',[s1.STOP, s2.STOP]
  str_element,/add,eva_lim,'UNIX_FOMSTR_MOD.NBUFFS',s1.NBUFFS+s2.NBUFFS
  str_element,/add,eva_lim,'UNIX_FOMSTR_MOD.NSEGS',s1.NSEGS+s2.NSEGS
  
  save, eva_lim, filename=fname_new
END