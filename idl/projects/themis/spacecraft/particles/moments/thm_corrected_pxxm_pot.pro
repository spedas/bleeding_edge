;
;Helper function to load MOM calibration files, hacked from old
;thm_load_mom
Function tmp_load_mom_calfile, probe, version
 
  caldata = -1
  calsource = !themis
  calsource.ignore_filesize = 1
  If(version Eq 2) Then Begin
    thx = 'th'+probe[0]
    cal_relpathname = thx+'/l1/mom/0000/'+thx+'_l1_mom_cal_v02.sav'
  Endif Else Begin
    cal_relpathname = 'tha/l1/mom/0000/tha_l1_mom_cal_v01.sav'
  Endelse
  cal_file = spd_download(remote_file=cal_relpathname, _extra = calsource)
  If(file_test(cal_file)) Then Begin
    restore, file = cal_file, verbose = 0
  Endif Else Begin
    dprint, 'Version 2 cal files not found for probe: '+pj+'. No corrections are possible.'
    caldata = -1
  Endelse
  Return, caldata
End
;+
;NAME:
; thm_corrected_pxxm_pot
;PURPOSE:
; Returns an offset corrected time-shifted value of the PXXM pot variable from
; MOM (on-board moment) files
;CALLING SEQUENCE:
; thm_corrected_pxxm_pot,suffix=suffix
;INPUT:
; No Input, the program detects the presence of variables
; 'thx_pxxm_pot' and corrects each one.
;OUTPUT:
; None explicit, tplot variables are created which are time-shifted
; and offset corrected pxxm_pot variables.
;KEYWORDS:
; suffix = is set, this will be appended to the variable names, the
;          default value is '_corrected'
; no_time_shift = if set, no time shifting is performed.
;HISTORY:
; 8-feb-2010, jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-27 11:26:29 -0700 (Mon, 27 Apr 2015) $
;$LastChangedRevision: 17433 $ 
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_corrected_pxxm_pot.pro $
;-
Pro thm_corrected_pxxm_pot, suffix = suffix, no_time_shift = no_time_shift, _extra = _extra

  If(keyword_set(suffix)) Then sfx = suffix Else sfx = '_corrected'
;first check for 'pxxm_pot' variables
  xvarx = tnames('*pxxm_pot*')  ;allows for suffixes
  If(is_string(xvarx) Eq 0) Then Begin
    dprint, 'No PXXM_POT variables loaded'
    Return
  Endif
;For each variable, check for an attribute in the dlimits.data_att
;corrected=1, if found, that ones doesn't need correcting
  nx = n_elements(xvarx)
  correct_this = bytarr(nx)+1b
  For j = 0, nx-1 Do Begin
    get_data, xvarx[j], dlimits = dl
    If(is_struct(dl) && $
       tag_exist(dl, 'data_att') && $ 
       tag_exist(dl.data_att, 'corrected') && $
       (dl.data_att.corrected Eq 1)) Then correct_this[j] = 0b
  Endfor
  keep = where(correct_this)
  If(keep[0] Ne -1) Then xvarx = xvarx[keep] Else Begin
    dprint, 'No uncorrected PXXM_POT variables available'
    Return
  Endelse
;Now correct each variable
  nx = n_elements(xvarx)
  For j = 0, nx-1 Do Begin
    get_data, xvarx[j], data = d, dlimits = dl
    If(is_struct(d)) Then Begin
      pj = strmid(xvarx[j], 2, 1)
      caldata1 = tmp_load_mom_calfile(pj, 1)
      caldata2 = tmp_load_mom_calfile(pj, 2)
      If(is_struct(caldata1) Eq 0 Or is_struct(caldata2) Eq 0) Then Begin
        dprint, 'No calibration data for probe: '+pj
        Continue
      Endif
;This could be raw data. Currently the only way to pick out raw MOM
;data is to find the suffix 'raw' on the variable name
      rawtest = strpos(xvarx[j], 'raw')
      If(rawtest[0] Ne -1) Then raw_data = 1b Else raw_data = 0b
;Now ypou have the calibration data, uncalibrate non-raw data
      If(raw_data Eq 0) Then Begin 
        scpotraw = d.y/caldata1.scpot_scale
      Endif Else scpotraw = d.y
;Apply time-dependent scpot scaling
      scpot_ss = value_locate(caldata2.scpot_time, d.x)
      scpot = (scpotraw - caldata2.scpot_offset[scpot_ss])*caldata2.scpot_scale[scpot_ss]
;Not quite done, now apply the time shift:
      If(Not keyword_set(no_time_shift)) Then Begin
        mom_tim_adjust = time_double(['07-11-29/20:51:26', '07-12-03/18:43:24', $
                                      '07-12-03/18:23:03', '07-11-27/18:34:23', $
                                      '07-11-29/17:49:10'])
        tshft_mom = [1.6028, 0.625]
;From thm_load_esa_pot
; the moment packet potential must be time shifted, the onboard timing
; changed at mom_tim_adjust 1.6028 = 1 + 217/360 times spin_period is
; the spin offset time between s/c pot in moments packet and actual
; time s/c potential calculated before mom_tim_adjust[], 0.625 times
; spin_period is the spin offset time between s/c pot in moments
; packet and actual time s/c potential calculated after
; mom_tim_adjust[],
; changes to timing for s/c potential in moments packets occurred at
; 	THEMIS A: 07-333-20:51:26
; 	THEMIS B: 07-337-18:43:24
; 	THEMIS C: 07-337-18:23:03
; 	THEMIS D: 07-331-18:34:23
; 	THEMIS E: 07-333-17:49:10
;
        pjno = where(['a', 'b', 'c', 'd', 'e'] Eq pj[0])
;Need the spin period
        spv = 'th'+pj[0]+'_state_spinper'
        get_data, spv, data = spinper
        If(is_struct(spinper) Eq 0) Then Begin ;load the state data if we don't have it
          thm_load_state, /get_support_data, probe = pj[0]
          get_data, spv, data = spinper
          If(is_struct(spinper) Eq 0) Then Begin
            dprint, 'No state data available for probe: '+pj[0]
            dprint, 'Using default 3 sec spin period'
            spin_period = replicate(3., n_elements(d.x))
          Endif Else spin_period = interp(spinper.y, spinper.x, d.x)
        Endif Else spin_period = interp(spinper.y, spinper.x, d.x)
        npts = n_elements(d.x)
        If(d.x[0] Ge mom_tim_adjust[pjno]) Then Begin
          d.x = d.x-tshft_mom[1]*spin_period
        Endif Else If(d.x[npts-1] Lt mom_tim_adjust[pjno]) Then Begin
          d.x = d.x-tshft_mom[0]*spin_period
        Endif Else Begin
          aft = where(d.x Ge mom_tim_adjust[pjno])
          If(aft[0] Ne -1) Then d.x[aft] = d.x[aft]-tshft_mom[1]*spin_period[aft]
          bef = where(d.x Lt mom_tim_adjust[pjno])
          If(bef[0] Ne -1) Then d.x[bef] = d.x[bef]-tshft_mom[1]*spin_period[bef]
        Endelse
      Endif                     ;done with time shifting
      newpot = xvarx[j]+sfx
;If dlimits doesn't exist, create it, and data_att
      If(is_struct(dl) Eq 0) Then Begin
        dl = {data_att:{corrected:1}} 
      Endif Else Begin
;If dlimits.data_att doesn't exist, then create that
;If it does exist, then add a corrected=1 flag
        If(tag_exist(dl, 'data_att')) Then Begin
          data_att = dl.data_att
          str_element, data_att, 'corrected', 1, /add_replace
        Endif Else Begin
          data_att = {corrected:1}
        Endelse
        str_element, dl, 'data_att', data_att, /add_replace
      Endelse
      store_data, newpot, data = {x:d.x, y:scpot}, dlimits = dl
    Endif
  Endfor

  Return
End



     
     
     
