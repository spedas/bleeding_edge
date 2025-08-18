PRO sppeva_load_spp_wrap, str, ylog=ylog
  compile_opt idl2
  if undefined(ylog) then ylog=0
  tpv=tnames(str,cmax)
  if cmax gt 0 then begin
    for c=0,cmax-1 do begin
      tpv_split = STRSPLIT(tpv[c],'_', /EXTRACT)
      kmax = n_elements(tpv_split)
      tpv_temp = ''
      for k=1,kmax-1 do begin
        pattern = (k mod 2) ? '!C': '_'
        tpv_temp += (pattern + tpv_split[k])
      endfor
      options, tpv[c], ylog=ylog, ytitle=tpv_temp
    endfor
  endif
END

FUNCTION sppeva_load_spp, param, perror
  compile_opt idl2

  ;-------------
  ; CATCH ERROR
  ;-------------
  catch, error_status; !ERROR_STATE is set
  if error_status ne 0 then begin
    ;catch, /cancel; Disable the catch system
    eva_error_message, error_status
    msg = [!Error_State.MSG,' ','...EVA will igonore this error.']
    if ~keyword_set(no_gui) then begin
      ok = dialog_message(msg,/center,/error)
    endif
    message, /reset; Clear !ERROR_STATE
    return, pcode
  endif
  
  
  ;------------
  ; FOMstr
  ;------------
  pcode=0
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_fomstr') and (cp eq 0))then begin
    fomstr = {Nsegs:0L}
    tr = time_double(!SPPEVA.COM.STRTR)
    store_data, param, data = {x:tr, y:[0.,0.]}, dl={fomstr:fomstr}
    ylim,param,0,25,0
    options,param,ystyle=1,constant=[5,10,15,20]; Don't just add yrange; Look at the 'fom_vax_value' parameter of eva_sitl_FOMedit
    sppeva_load_spp_wrap, '*_fomstr', ylog=0
  endif

  ;------------
  ; FIELDS
  ;------------
  pcode=1
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_f1_100bps_*') and (cp eq 0))then begin
    sppeva_get_fld,'f1_100bps'
  endif
  if(strmatch(param,'*_dcb_events_*') and (cp eq 0))then begin
    sppeva_get_fld,'dcb_events'
  endif
  
  ;----------------------
  ; FIELDS RFS Level 1
  ;----------------------
  pcode=1
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'spp_fld_rfs_hfr_auto_*') and (cp eq 0))then begin
    sppeva_get_fld,'rfs_hfr_auto'
  endif  
  if(strmatch(param,'spp_fld_rfs_lfr_auto_*') and (cp eq 0))then begin
    sppeva_get_fld,'rfs_lfr_auto'
  endif

  ;----------------------
  ; FIELDS RFS Level 2
  ;----------------------
  pcode=1
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'psp_fld_l2_rfs_hfr_*') and (cp eq 0))then begin
    spp_fld_load,type='rfs_hfr'
  endif
  if(strmatch(param,'psp_fld_l2_rfs_lfr_*') and (cp eq 0))then begin
    spp_fld_load,type='rfs_lfr'
  endif

  ;----------------------
  ; FIELDS MAG Level 2
  ;----------------------
  pcode=1
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'psp_fld_l2_mag_RTN_4_Sa_per_Cyc') and (cp eq 0))then begin
    spp_fld_load,type='mag_RTN_4_Sa_per_Cyc'
  endif
  if(strmatch(param,'psp_fld_l2_mag_SC_4_Sa_per_Cyc') and (cp eq 0))then begin
    spp_fld_load,type='mag_SC_4_Sa_per_Cyc'
  endif

  ;----------------------
  ; FIELDS DFB Spectra
  ;----------------------
  pcode=1
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'psp_fld_l2_dfb_ac_spec_*') and (cp eq 0))then begin
    spp_fld_load,type='dfb_ac_spec'
  endif
  if(strmatch(param,'psp_fld_l2_dfb_dc_spec_*') and (cp eq 0))then begin
    spp_fld_load,type='dfb_dc_spec'
  endif


  ;----------------------
  ; SWEAP POINTER ADDRESS
  ;----------------------
  if(strmatch(param,'*_swp_*'))then begin
    tr = time_double(!SPPEVA.COM.STRTR)
    tp = 'psp_swp_swem_dig_hkp_SW_SSRWRADDR'
    if ~spd_data_exists(tp, tr[0], tr[1]) then begin
      spp_swp_swem_load, trange=tr
    endif
  endif
  
  ;---------------------
  ; SWEAP SPC Level 2
  ;---------------------
  pcode=2
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_spc_l2i_*') and (cp eq 0))then begin
    spp_swp_spc_load, type='l2i'
    sppeva_load_spp_wrap, '*_spc_l2i_*'
  endif
  
  ;---------------------
  ; SWEAP SPC Level 3
  ;---------------------
  pcode=2
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_spc_l3i_*') and (cp eq 0))then begin
    spp_swp_spc_load, type='l3i'
    sppeva_load_spp_wrap, '*_spc_l3i_*'
    options,'psp_swp_spc_l3i_np_*',ylog=1
    options,'psp_swp_spc_l3i_vp_*',colors=[2,4,6];,labflag=-1,labels=['V!Bx','V!By','V!Bz']
  endif
  
  ;---------------------
  ; SWEAP SPAN electrons
  ;---------------------
  pcode=3
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'psp_swp_sp?_sf*') and (cp eq 0))then begin
    spp_swp_spe_load
    sppeva_load_spp_wrap, '*_psp_swp_sp?_sf*'
  endif
  
  return, -1
END