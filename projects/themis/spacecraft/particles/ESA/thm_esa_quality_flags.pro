;+
;Procedure:
;  thm_esa_quality_flags
;  
;Description:
;  makes a bitpacked tplot variable containing quality flags for ESA
;  bit0 = pre-efi boom deployment (using zeroed spacecraft potential)
;  bit1 = counter overflow flag
;  bit2 = solar wind mode flag(disabled)
;  bit3 = flow flag, flow less than threshold is flagged
;  bit4 = earth shadow
;  bit5 = lunar shadow
;  bit6 = manuever flag
;  
;  Set timespan by calling timespan outside of this routine.(e.g. time/duration is not an argument)
;  
;Keywords:
;  probe(required): probe letter ('a','b','c','d','e')
;  datatype(required): type string  ('peef','peib', etc...)
;  noload(optional): set this if calling from thm_l2gen_esa
;  flow_threshold(optional): flow threshold for flow flag(default = 1.0, units undocumented)
;  
;  
; $LastChangedBy: jimm $
; $LastChangedDate: 2018-03-12 14:57:15 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24875 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_quality_flags.pro $
;-

;+
;HELPER FUNCTION (main function below)
; Returns the start and end indices of intervals where a condition
; applies
;-
PRO Temp_st_en, condition, st_ss, en_ss, ok=ok

  n = N_ELEMENTS(condition)
  ok = where(condition, nok)
  IF(nok EQ 0) THEN BEGIN
    st_ss = 0
    en_ss = n-1
  ENDIF ELSE BEGIN
    IF(nok EQ 1) THEN BEGIN
      st_ss = ok[0]
      en_ss = ok[0]
    ENDIF ELSE BEGIN
      qq = [5000, ok[1:*]-ok]
      st_ss = ok[where(qq NE 1)]
      qq = [ok[1:*]-ok, 5000]
      en_ss = ok[where(qq NE 1)]
    ENDELSE
  ENDELSE

  RETURN
END

pro thm_esa_quality_flags,probe=probe,datatype=datatype,noload=noload,flow_threshold=flow_threshold
  
  compile_opt idl2
    
  ;add common blocks to environment(which I knew how to put this in a subroutine)
  Case probe Of
    'a':Begin
      common tha_454, tha_454_ind, tha_454_dat
      common tha_455, tha_455_ind, tha_455_dat
      common tha_456, tha_456_ind, tha_456_dat
      common tha_457, tha_457_ind, tha_457_dat
      common tha_458, tha_458_ind, tha_458_dat
      common tha_459, tha_459_ind, tha_459_dat
    End
    'b':Begin
      common thb_454, thb_454_ind, thb_454_dat
      common thb_455, thb_455_ind, thb_455_dat
      common thb_456, thb_456_ind, thb_456_dat
      common thb_457, thb_457_ind, thb_457_dat
      common thb_458, thb_458_ind, thb_458_dat
      common thb_459, thb_459_ind, thb_459_dat
    End
    'c':Begin
      common thc_454, thc_454_ind, thc_454_dat
      common thc_455, thc_455_ind, thc_455_dat
      common thc_456, thc_456_ind, thc_456_dat
      common thc_457, thc_457_ind, thc_457_dat
      common thc_458, thc_458_ind, thc_458_dat
      common thc_459, thc_459_ind, thc_459_dat
    End
    'd':Begin
      common thd_454, thd_454_ind, thd_454_dat
      common thd_455, thd_455_ind, thd_455_dat
      common thd_456, thd_456_ind, thd_456_dat
      common thd_457, thd_457_ind, thd_457_dat
      common thd_458, thd_458_ind, thd_458_dat
      common thd_459, thd_459_ind, thd_459_dat
    End
    'e':Begin
      common the_454, the_454_ind, the_454_dat
      common the_455, the_455_ind, the_455_dat
      common the_456, the_456_ind, the_456_dat
      common the_457, the_457_ind, the_457_dat
      common the_458, the_458_ind, the_458_dat
      common the_459, the_459_ind, the_459_dat
    End
  endcase
  
  ;load ESA data
  If(~keyword_set(noload)) Then thm_load_esa_pkt, probe = probe, /no_time_clip
    
  date = timerange()
  datatype_lc = strlowcase(datatype)
    
  sc = 'th'+probe   
    
  instr_all = ['peif', 'peir', 'peib', 'peef', 'peer', 'peeb']
  pak_all = ['454', '455', '456', '457', '458', '459']
    
  ;Threshold for reduced data flags
  If(keyword_set(flow_threshold)) Then ftr = flow_threshold Else  ftr = 1.0
    
  idx = where(instr_all eq datatype_lc)
  pak_do = pak_all[idx]
  ok = execute('dat = th'+probe[0]+'_'+pak_do[0]+'_dat')
  
;Noload keyword should assume thm_load_esa_pot has been called,
                                ;jmm, 2018-02-05
  If(~keyword_set(noload)) Then Begin
     If((probe[0] Eq 'b') And (time_double(date[0]) Gt time_double('2010-10-13'))) Then Begin
        thm_load_esa_pot, sc = probe, efi_datatype = 'mom'
     Endif Else If((probe[0] Eq 'a') And (time_double(date[0]) Gt time_double('2015-04-01'))) Then Begin
    ;probe A has problems with bad pxxm_pot offsets post 1-apr-2015, jmm,
    ;2015-05-26, so this uses the default values
        thm_load_esa_pot, sc = probe
     Endif Else thm_load_esa_pot, sc = probe, efi_datatype = 'mom'
  Endif

  scpot_name = sc + '_esa_pot' 
;  tinterpol_mxn,scpot_name,dat.time,/overwrite ;for an unknown
;  reason (Not unknown-the _esa_pot variable is created from EFI or
;  MOM data), elements in the scpot don't match elements in esa
;  raw data, this interpolates to match them. 
;  Do not overwrite! jmm, 2018-03-12
  tinterpol_mxn,scpot_name,dat.time,newname='temp_scpot_var'
  get_data, 'temp_scpot_var', data = temp_scpot
  del_data, 'temp_scpot_var' ;drop the temp tplot variable

;Guard against missing sc_pot variable
  boom_time = thm_efi_boom_deployment_time(probe = probe)
 
  If is_struct(temp_scpot) Then Begin
    pot_flag = intarr(n_elements(temp_scpot.x))
    If(total(abs(temp_scpot.y)) Gt 0) Then begin
      If(time_string(date[0], /date_only) Eq time_string(boom_time[0], /date_only)) Then Begin
        xx = where(temp_scpot.x Lt boom_time[0])
        If(xx[0] Ne -1) Then pot_flag[xx] = 1
      endif
    endif
   
  Endif Else Begin            ;if no source, then replace with 0 value
    tim_arr = time_double(date[0])+dindgen(86400) ;1 second time resolution for zero values
    temp_scpot = {x:tim_arr, y:fltarr(86400)}
    pot_flag = intarr(n_elements(temp_scpot.x))+1
  Endelse

  
;here you test for counter overflows
  if undefined(dat) then begin
    flag255 = pot_flag & flag255[*] = 0
  endif else begin
    flag255 = thm_esa_l2_255s(dat)
  endelse
  ;here you test for the solar wind, and solar wind mode, temporarily
  ;disabled, needs more testing, jmm, 2011-01-07
  swflag = pot_flag & swflag[*] = 0
  ;but only after dates in aug 2007
  ;      If(probe[0] Eq 'a') Then mom_date = time_double('2007-08-02/00:00:00') $
  ;      Else mom_date = time_double('2007-08-10/00:00:00')
  ;      If(time_double(date) Ge mom_date) Then Begin
  ;        ppp0 = thm_mom_swtest(probe[0], vlim3 = 1000., smtime = 600.) ;are you in SWIND?
  ;        get_data, ppp0, data = swind_str
  ;        If(is_struct(swind_str)) Then Begin
  ;          dummy = thm_esa_swmode_test(probe[0], instr_do[j], dat, flag = in_swmode) ;Are you in the mode?
  ;          If(in_swmode[0] Ne -1) Then Begin
  ;            swh = data_cut(temporary(swind_str), temp_scpot.x)
  ;            xx = where(swh Gt 0 And in_swmode Eq 0)
  ;            If(xx[0] Ne -1) Then swflag[xx] = 1 ;solar wind -- not in SW mode
  ;            yy = where(in_swmode Gt 0 And swh Eq 0)
  ;            If(yy[0] Ne -1) Then swflag[yy] = 1 ;in SW mode -- but not in the solar wind
  ;          Endif
  ;        Endif
  ;      Endif
  ;Reduced data will be an issue if there is too much velocity during
  ;slow survey mode
  flow_flag = pot_flag & flow_flag[*] = 0
  If(strmid(datatype_lc, 3, 1) Eq 'r') Then Begin ;reduced mode only
    ;Load HSK data
    thm_load_hsk, probe = probe[0], varformat = sc+'*issr_mode*'
    hsk_name = tnames(sc+'_hsk_issr_mode_raw')
    get_data, hsk_name[0], data = hsk
    If(is_struct(hsk)) Then Begin
      ;;Slow survey mode is where hsk.y is 0
      slow = hsk.y Eq 0
      ss_slow = where(slow Eq 0, nss)
      If(nss Gt 0) Then Begin
        ;Find start and end times of slow survey mode
        temp_st_en, slow, st_slow, en_slow
        ;Get the normalized flow velocity for the full mode
        If(datatype_lc Eq 'peer') Then instr_tmp = 'peef' Else instr_tmp = 'peif'
        fv_name = thm_l2_esa_norm_flow(date[0], probe[0], instr_tmp, noload=noload)
        get_data, fv_name, data = fv
        If(is_struct(fv)) Then Begin
          ;Interpolate fv to temp_scpot.x time grid..
          fv = data_cut(temporary(fv), temp_scpot.x) ;fv is now a 1d array
          For k = 0, n_elements(st_slow)-1 Do Begin
            ssk = where(temp_scpot.x Ge hsk.x[st_slow[k]] And $
              temp_scpot.x Le hsk.x[en_slow[k]] And $
              fv Gt ftr, nssk) ;use ge, le since these are center times?
            If(nssk Gt 0) Then flow_flag[ssk] = 1
          Endfor
        Endif
      Endif
    Endif Else Begin
      message, /info, 'No HSK data for: '
      print, 'Probe: ', probe[0], '  Date: ', time_string(date[0])
    Endelse
  Endif
  
  if ~keyword_set(no_load) then begin
    thm_load_state,probe=probe,/get_support
  endif
  
  ;One more flag, a maneuver flag, set to 64..
  man_flag = pot_flag & man_flag[*] = 0
  get_data, sc+'_state_man', data = dmn
  
  If(is_struct(dmn)) Then Begin
    dmn = data_cut(temporary(dmn), temp_scpot.x) ;dmn is now a 1-d array
    ssmn = where(dmn Gt 0, nssmn)
    If(nssmn Gt 0) Then man_flag[ssmn] = 1
  Endif
  
  tinterpol_mxn,sc+'_state_roi',scpot_name,/overwrite,/nearest_neighbor
  get_data,sc+'_state_roi',data=d

  if is_struct(d) then begin
    earth_shadow_flag = d.y and 1
    lunar_shadow_flag = ishft(d.y,-1) and 1
  endif else begin
    earth_shadow_flag = 0
    lunar_shadow_flag = 0
  endelse
  
  all_flag = temporary(pot_flag)+2*temporary(flag255)+$
    4*temporary(swflag)+8*temporary(flow_flag)+$
    16*temporary(earth_shadow_flag)+32*temporary(lunar_shadow_flag)+$
    64*temporary(man_flag)
    
  store_data, sc+'_'+datatype_lc+'_data_quality', $
    data = {x:temp_scpot.x, y:temporary(all_flag)},dlimits={tplot_routine:'bitplot'}
   
end
