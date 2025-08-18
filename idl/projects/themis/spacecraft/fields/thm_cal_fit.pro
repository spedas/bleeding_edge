;+
;Procedure: THM_CAL_FIT
;
;Purpose:  Converts raw FIT parameter data into physical quantities.
;keywords:
;   /VERBOSE or VERBOSE=n ; set to enable diagnostic message output.
;   higher values of n produce more and lower-level diagnostic messages.
;   /ALL
;   /no_cal will not apply boom shortening factor or Ex offset defaults
; use_eclipse_corrections:  Only applies when loading and calibrating
;   Level 1 data. Defaults to 0 (no eclipse spin model corrections
;   applied).  use_eclipse_corrections=1 applies partial eclipse
;   corrections (not recommended, used only for internal SOC processing).
;   use_eclipse_corrections=2 applies all available eclipse corrections.
; check_l1b: if set, then look for L1B data files that include
;            estimates for Bz. This is the deafult for THEMIS E 
;            after 2024-06-01 (date subject to change....)
;Example:
;   thm_cal_fit, /all
;
;Modifications:
;  Corrected (reversed) polarity of Zscale in CPAR, WMFeuerstein, 5/13/2008.
;  Call THM_GET_EFI_CAL_PARS.PRO and calibrate 'efs' data with EFI parameters, WMF, 5/13/2008.
;  Mods per McFadden and Vassilis: Do not subtract spin-independent offset for 'efs'
;    data, NO_CAL kw effectively sets boom_shorting_factor to 1 and spin-dependent offsets
;    to 0, WMF, 6/27/2008.
;
;Notes:
; -- FGM range changes are handled during L0->L1 processing, no need to do it in this routine
; -- fixed, nominal calibration pars used, rather than proper time-dependent parameters.
;   -- time-dependent spinn axis offset implemented Hannes 05/25/2007
;   -- fixed trouble reading cal files with extra lines at the end,
;      jmm, 8-nov-2007
; $LastChangedBy: jimm $
; $LastChangedDate: 2025-01-28 10:25:21 -0800 (Tue, 28 Jan 2025) $
; $LastChangedRevision: 33100 $
; $URL $
;-
pro thm_cal_fit, probe = probe, datatype = datatype, files = files, trange = trange, $
  coord = coord, valid_names = valid_names, verbose = verbose, in_suf = in_suf, $
  out_suf = out_suf, no_cal = no_cal, true_dsl = true_dsl,$
  use_eclipse_corrections=use_eclipse_corrections, check_l1b=check_l1b, _extra=_extra
  
  
  thm_init
  if not keyword_set(datatype) then datatype = ['fgs', 'efs', 'fgs_sigma', 'efs_sigma']
  vprobes = ['a', 'b', 'c', 'd', 'e']
  vdatatypes = ['fgs', 'efs', 'fit_efit', 'fit_bfit', 'fgs_sigma', 'efs_sigma', 'fit', 'efs_0', 'efs_dot0', 'efs_potl']
  if keyword_set(valid_names) then begin
    probe = vprobes
    datatype = vdatatypes
    return
  endif
  if n_elements(probe) eq 1 then if probe eq 'f' then vprobes = ['f']
  if not keyword_set(probe) then probes = vprobes $
  else probes = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)
  if not keyword_set(probes) then return
  
  dt_output = ssl_check_valid_name(strlowcase(datatype), vdatatypes, /include_all)
  
  if not keyword_set(in_suf) then in_suf = ''
  if not keyword_set(out_suf) then out_suf = ''
  
  if (n_elements(true_dsl) GT 0) then begin
    dprint,dlevel=2,'true_dsl keyword no longer required.'
  endif
  
  if (n_elements(use_eclipse_corrections) EQ 0) then begin
    use_eclipse_corrections=0
    dprint,dlevel=2,'use_eclipse_corrections defaulting to 0 (no eclipse spin model corrections)'
  endif
  
  ;cal parameters
  lv12 = 49.6                   ;m
  lv34 = 40.4                   ;m
  lv56 = 5.6                    ;m
  cpar = {e12:{cal_par_time:'2002-01-01/00:00:00', Ascale:-15000.0/(lv12*2.^15), Bscale:-15000.0/(lv12*2.^15), $
    Cscale:-15000.0/(lv12*2.^15), theta:0.0, sigscale:15000./(lv12*2.^15), Zscale:-15000./(lv56*2.^15), $
    units:'mV/m'}, $
    e34:{cal_par_time:'2002-01-01/00:00:00', Ascale:-15000.0/(lv34*2.^15), Bscale:-15000.0/(lv34*2.^15), $
    Cscale:-15000.0/(lv34*2.^15), theta:0.0, sigscale:15000./(lv34*2.^15), Zscale:-15000./(lv56*2.^15), $
    units:'mV/m'}, $
    b:{cal_par_time:'2002-01-01/00:00:00', Ascale:1.e0, Bscale:1.e0, Cscale:1.e0, theta:0.0, sigscale:1.e0, $
    Zscale:1.e0, units:'nT'}} ; vassilis 2007-04-03, changed b scales
    
  for s = 0L, n_elements(probes)-1L do begin
    sc = probes[s]
    thx = 'th' + sc
    tplot_var = thm_tplot_var(sc, 'fit')
    ;Start the calibration
    if keyword_set(verbose) then $
      dprint, string(tplot_var, format = '("working on TPLOT variable",X,A)')
    get_data, tplot_var+in_suf, data = d, limit = l, dlim = dl
    get_data, tplot_var+'_code'+in_suf, data = d_code, limit = l_code, dlim = dl_code
    ; check that returned data is a structure (get_data returns 0 if no TPLOT variable exists).
    if (size(d, /type) ne 8) then continue ;next probe
    ; Make sure spin model data is loaded.
    thm_autoload_support, probe_in=sc, trange=minmax(d.x), /spinmodel, /spinaxis  ;check for spin vars, etc.
    
    ; JWL 2010-07-20 Retrieve eclipse delta_phi values
    
    smp=spinmodel_get_ptr(sc,use_eclipse_corrections=use_eclipse_corrections)
    spinmodel_interp_t,model=smp,time=d.x,eclipse_delta_phi=delta_phi
    
    edp_idx=where(delta_phi NE 0.0, edp_count)
    if (edp_count NE 0) then begin
      dprint,"Nonzero eclipse delta_phi corrections found."
    endif
    
    case 1 of     ; vassilis 4/28 establish probe number in cal tables
      sc eq 'a' : scn = 0 ; vassilis 4/28 establish probe number in cal tables
      sc eq 'b' : scn = 1 ; vassilis 4/28 establish probe number in cal tables
      sc eq 'c' : scn = 2 ; vassilis 4/28 establish probe number in cal tables
      sc eq 'd' : scn = 3 ; vassilis 4/28 establish probe number in cal tables
      sc eq 'e' : scn = 4 ; vassilis 4/28 establish probe number in cal tables
      sc Eq 'f' : Goto, cal_efs ;no flatsat FGM cal files
    endcase       ; vassilis 4/28 establish probe number in cal tables
    ;start Hannes 05/25/2007
    ;get the calfile
    cal_relpathname = thx+'/l1/fgm/0000/'+thx+'_fgmcal.txt'
    cal_file = spd_download(remote_file=cal_relpathname, _extra = !themis)
    ;read the FGM calibration file
    DPRINT,  'read FGM calibration file:'
    DPRINT,  cal_file
    ncal = file_lines(cal_file)
    calstr = strarr(ncal)
    openr, 2, cal_file
    readf, 2, calstr
    close, 2
    ok_cal = where(calstr Ne '', ncal) ;jmm, 8-nov-2007, cal files have carriage returns at the end
    calstr = calstr[ok_cal]
    ;define variables
    spinperi = dblarr(ncal)
    offi = dblarr(ncal, 3)
    cali = dblarr(ncal, 9)
    utc = dblarr(ncal)
    utcStr = strarr(ncal)

;THEMIS E has two extra columns as of 2024-04-24
    bz_slope_intercept = dblarr(ncal, 2)
;Swapped the cal read from THM_LOAD_FGM, the original version here
;using reads gives incorrect values when the X offset is greater than
;10, jmm, 2024-05-13
;    offi2 = dblarr(ncal, 3)
;    spinperii = dblarr(1)
;    offii = dblarr(3)
;    calii = dblarr(9)
;    utci = '2006-01-01T00:00:00.000Z'
;    utc = dblarr(ncal)
;    utcStr = strarr(ncal)
;    FOR i = 0, ncal-1 DO BEGIN
;      calstri = calstr[i]
;      utci = strmid(calstr[i], 0, 25)
;      reads, strmid(calstr[i], 26), offii, calii, spinperii ;
;      offi[i, *] = offii
;      cali[i, *] = calii
;      spinperi[i] = spinperii
;      utcStr[i] = utci
;      ;translate time information
;      STRPUT, utci, '/', 10
;      utc[i] = time_double(utci)
;    ENDFOR
    DPRINT,  'done reading FGM calibration file'
 
    for i=0,ncal-1 do begin
       split_result = strsplit(calstr[i], COUNT=lct, /EXTRACT)
       utci=split_result[0]
       offi[i,*]=split_result[1:3]
       cali[i,*]=split_result[4:12]
       spinperi[i]=split_result[13]
       utcStr[i]=utci
;translate time information
       STRPUT, utci, '/', 10
       utc[i]=time_double(utci)
       if sc eq 'e' and lct ge 16 then begin
          bz_slope_intercept[i,*] = split_result[14:15]
       endif
    endfor
;for probe e, use the last value for intercept with zero slope, jmm, 2024-05-25
    if sc eq 'e' then begin
       bz_last_time = utc[ncal-1] ;last time for nonzero slope                          
       bz_ext_intercept = bz_slope_intercept[ncal-1,0]
    endif
    
    DPRINT,  'done reading FGM calibration file'
    ;end Hannes 05/25/2007
    ; check that data has not already been calibrated
    if thm_data_calibrated(tplot_var+in_suf) then begin
      dprint, tplot_var+in_suf, " has already been calibrated."
      continue                  ;try the next SC
    endif
    ;jmm, 2010-04-20, calibrate FGS first
    ;search fgm calibration for selected time interval ...
    ; start Hannes 05/25/2007
    count = n_elements(d.X)
    Bzoffset = dblarr(count)
    DPRINT,  'search fgm calibration for selected time interval ...'
    compTime = utc[0]
    refTime = d.X[0]
    i = 0
    WHILE ((compTime lt reftime) && (i lt ncal-1)) DO BEGIN
      i = i+1
      compTime = utc[i]
      IF (compTime gt reftime) THEN BEGIN
        i = i-1
        BREAK
      ENDIF
    ENDWHILE
    istart = i
    compTime = utc[i]
    refTime = d.X[count-1L]
    WHILE ((compTime lt reftime) && (i lt ncal-1)) DO BEGIN
      i = i+1
      compTime = utc[i]
      IF (compTime gt reftime) THEN BEGIN
        i = i-1
        BREAK
      ENDIF
    ENDWHILE
    istop = i
    DPRINT,  'Select calibrations from:'
    FOR i = istart, istop DO BEGIN
      DPRINT,  utcStr[i]
    ENDFOR
    ;end search fgm calibration for selected time interval ...'
    ;build the calibrations vector (offset only at this point)
    ;we still need to implement: Gz,Gxy,phi1
    flipxz = [[0, 0, -1.], [0, -1., 0], [-1., 0, 0]]
    IF (istart eq istop) THEN BEGIN
       ii = istart
       offi2 = invert(transpose([cali[ii, 0:2], cali[ii, 3:5], cali[ii, 6:8]]) ## flipxz)##offi[ii, *]
       if sc eq 'e' then begin ;needs extra correction, jmm, 2024-05-13
          if d.x[0] gt bz_last_time then begin
             offi2x = offi2[2]-bz_ext_intercept
          endif else begin
             offi2x = offi2[2]-(bz_slope_intercept[ii, 0]+$
                      bz_slope_intercept[ii, 1]*(d.x-utc[ii])/3600.0d0)
          endelse
          Bzoffset[0L:count-1L] = offi2x
       endif else begin
          Bzoffset[0L:count-1L] = offi2[2]
       endelse
    ENDIF ELSE BEGIN
      FOR ii = istart, istop DO BEGIN
        IF (ii eq istart) THEN BEGIN
           indcal = WHERE(d.X lt utc[ii+1])
        ENDIF ELSE IF (ii eq istop) THEN BEGIN
           indcal = WHERE(d.X ge utc[ii])
        ENDIF ELSE BEGIN
           indcal = WHERE((d.X ge utc[ii]) AND (d.X lt utc[ii+1]))
        ENDELSE
        IF (indcal[0] gt -1) THEN BEGIN
           offi2 = invert(transpose([cali[ii, 0:2], cali[ii, 3:5], cali[ii, 6:8]]) ## flipxz)##offi[ii, *]
           if sc eq 'e' then begin
              if d.x[indcal[0]] gt bz_last_time then begin
                 offi2x = offi2[2]-bz_ext_intercept
              endif else begin
                 offi2x = offi2[2]-(bz_slope_intercept[ii, 0]+$
                                    bz_slope_intercept[ii, 1]*(d.x[indcal]-utc[ii])/3600.0d0)
              endelse
              Bzoffset[indcal] = offi2x
           endif else begin
              Bzoffset[indcal] = offi2[2]
           endelse
        ENDIF
      ENDFOR
    ENDELSE
    ;Bzoffset is an array (for vectorized processing)
    ;end Hannes 05/25/2007
    adc2nT = 50000./2.^24       ; vassilis 2007-04-03
    rotBxy_angles = [29.95, 29.95, 29.95, 29.95, 29.95] ; vassilis 6/2/2007: deg to rotate FIT on spin plane to match DSL on 5/4
    rotBxy = rotBxy_angles[scn] ;  vassilis 4/28: probably should be part of CAL table as well...
    cs = cos(rotBxy*!PI/180.)   ;  vassilis
    sn = sin(rotBxy*!PI/180.)   ;  vassilis
    
    ;Bz_offset_table = [4.93,6.14,5.03,8.02,2.99] ; vassilis 4/28
    ; vassilis 4/28: note the above must be read from 3rd (Z) offset in FGM cal files
    ;Bzoffset = Bz_offset_table(scn) ;  vassilis 4/28
    str_element, dl, 'data_att', data_att, success = has_data_att
    if has_data_att then begin
      str_element, data_att, 'data_type', 'calibrated', /add
    endif else data_att = {data_type: 'calibrated' }
    str_element, data_att, 'coord_sys',  'dsl', /add
    
    ; B-field fit (FGM).
    idx = 1L
    dqd = 'bfit'
    units = cpar.b.units
    tplot_var_bfit_orig = string(tplot_var, dqd, format = '(A,"_",A)')
    tplot_var_bfit = tplot_var_bfit_orig + out_suf[0]
    str_element, dl, 'ytitle', tplot_var_bfit_orig, /add
    str_element, dl, 'ysubtitle', '['+units+']', /add
    str_element, dl, 'labels', ['A', 'B', 'C', 'Sig', '<Bz>'], /add
    str_element, dl, 'labflag', 1, /add
    str_element, dl, 'colors', [1, 2, 3, 4, 5], /add
    str_element, data_att, 'cal_par_time', cpar.b.cal_par_time, /add
    str_element, data_att, 'units', units, /add
    str_element, dl, 'data_att', data_att, /add
    ;  Code for FGM range changes removed. This is done in the L0->L1 processing.
    
    d.y[*, 0, idx] = cpar.b.Ascale*d.y[*, 0, idx]*adc2nT ;  vassilis
    d.y[*, 1, idx] = cpar.b.Bscale*d.y[*, 1, idx]*adc2nT ;  vassilis
    d.y[*, 2, idx] = cpar.b.Cscale*d.y[*, 2, idx]*adc2nT ;  vassilis
    d.y[*, 3, idx] = cpar.b.sigscale*d.y[*, 3, idx]*adc2nT ;  vassilis
    d.y[*, 4, idx] = cpar.b.Zscale*d.y[*, 4, idx]*adc2nT ;  vassilis
    if (where(dt_output eq 'fit_bfit') ne -1) then begin
      store_data, tplot_var_bfit, $
        data = {x:d.x, y:reform(d.y[*, *, idx])}, $
        lim = l, dlim = dl
    endif
    dqd = 'fgs'
    tplot_var_fgs_orig = string(strmid(tplot_var, 0, 3), dqd, format = '(A,"_",A)') 
    tplot_var_fgs = tplot_var_fgs_orig +out_suf[0]
    tplot_var_fgs_sigma_orig = tplot_var_fgs_orig +'_sigma' 
    tplot_var_fgs_sigma = tplot_var_fgs_sigma_orig + out_suf[0]
    str_element, dl, 'ytitle', tplot_var_fgs_orig, /add
    str_element, dl, 'ysubtitle', '['+units+']', /add
    str_element, data_att, 'cal_par_time', cpar.b.cal_par_time, /add
    str_element, data_att, 'units', units, /add
    str_element, dl, 'data_att', data_att, /add
    str_element, dl, 'labels', ['Bx', 'By', 'Bz'], /add
    str_element, dl, 'colors', [2, 4, 6], /add
    Bxprime = cs*d.y[*, 1, idx]+sn*d.y[*, 2, idx]
    Byprime = -sn*d.y[*, 1, idx]+cs*d.y[*, 2, idx]
    Bzprime = -d.y[*, 4, idx]-Bzoffset ; vassilis 4/28 (SUBTRACTING offset from spinaxis POSITIVE direction)
    
    ; JWL 2010-07-20
    if (use_eclipse_corrections GT 0) then begin
      dprint,'Applying eclipse delta_phi corrections to FGS.'
      correct_delta_phi_vector,x_in=Bxprime,y_in=Byprime,delta_phi=delta_phi,x_out=Bxpp, y_out=Bypp
      Bxprime = Bxpp
      Byprime = Bypp
    endif else begin
      dprint,'Skipping eclipse delta_phi corrections.'
    endelse
    
    dprime = d
    dprime.y[*, 1, idx] = Bxprime ; vassilis DSL
    dprime.y[*, 2, idx] = Byprime ; vassilis DSL
    dprime.y[*, 4, idx] = Bzprime ; vassilis DSL
    
    fgs = reform(dprime.y[*, [1, 2, 4], idx])
    ;fix NaN for y axis
    fgsx_good=where(finite(fgs[*,0]) ne 0, n_fgs_good)
    fgsx_fixed = d.x[fgsx_good]
    fgsy_fixed = fgs[fgsx_good, *]
    
    if n_fgs_good gt 0 then begin ;if all fgs is NaN then skip calculations

;If check_l1b is set, then replace Bz with estimated value
      If(keyword_set(check_l1b)) Then use_l1b_bz = 1b Else Begin
         If(probe[0] Eq 'e') Then Begin
            If(fgsx_fixed[0] Ge time_double('2024-05-25/00:00:00')) Then use_l1b_bz = 1b Else use_l1b_bz = 0b
         Endif Else use_l1b_bz = 0b
      Endelse
      If(use_l1b_bz) Then Begin
         get_data, thx+'_fgl_l1b_bz', data = temp_bz
         If(is_struct(temp_bz)) Then Begin
;if the data overlaps the input, then keep the variable, set start and
;end times to nearest day boundary
            thbz = minmax(temp_bz.x)
            thbz[0] = time_double(time_string(thbz[0], precision=-3))
            thbz[1] = time_double(time_String(thbz[1]+86400.0d0, precision=-3))
            If(min(fgsx_fixed) Ge thbz[0] And max(fgsx_fixed) Le thbz[1]) Then Begin
               read_alt_bz = 0b
            Endif Else read_alt_bz = 1b
         Endif Else read_alt_bz = 1b
         If(read_alt_bz) Then Begin
            If(is_struct(temp_bz)) Then del_data, thx+'_fgl_l1b_bz'
            l1b_relpath = thx+'/l1b/fgm/'
            l1b_filenames = file_dailynames(thx+'/l1b/fgm/', thx+'_l1b_fgm_', '_v01.cdf', $
                                            /yeardir, trange = minmax(fgsx_fixed))
            l1b_files = spd_download(remote_file = l1b_filenames, _extra = !themis)
            cdf2tplot, files = l1b_files, varformat = '*'
            get_data, 'the_fgl_l1b_bz', data = temp_bz
         Endif
         If(is_struct(temp_bz)) Then Begin
            dprint, 'WARNING: Using L1B level Bz estimated from spin-plane components'
            kr=2.980232238769531E-3 ;raw data to nT, kr=25000.0/2^23 --> see *CALPROC*.doc
            fgsy_fixed[*, 2] = -kr*interpol(temp_bz.y, temp_bz.x, fgsx_fixed)
         Endif
      Endif
       
      if (where(dt_output eq 'fgs') ne -1) then begin
        store_data, tplot_var_fgs, data = {x:fgsx_fixed, y:fgsy_fixed}, lim = l, dlim = dl
        ;store_data, tplot_var_fgs, data = {x:d.x, y:fgs}, lim = l, dlim = dl
        if keyword_set(coord) && strlowcase(coord) ne 'dsl' then begin
           thm_cotrans, tplot_var_fgs, out_coord = coord, use_spinaxis_correction = 1, $
                        use_spinphase_correction = 1
          options, tplot_var_fgs, 'ytitle', /def, $
            string(tplot_var_fgs_orig, units, format = '(A,"!C!C[",A,"]")'), /add
        endif
      endif
      
      if (where(dt_output eq 'fgs_sigma') ne -1) then begin
        str_element, dl_sigma, 'ytitle', tplot_var_fgs_sigma_orig, /add
        str_element, dl_sigma, 'ysubtitle', '['+units+']', /add
        str_element, data_att_sigma, 'units', units, /add
        str_element, dl_sigma, 'data_att', data_att_sigma, /add
        ;store_data, tplot_var_fgs+'_sigma', data = {x:d.x, y:d.y[*, 3, idx]}, dl = dl_sigma
        store_data, tplot_var_fgs_sigma, data = {x:fgsx_fixed, y:d.y[fgsx_good, 3, idx]}, dl = dl_sigma
      endif
    endif else begin
      dprint,'No valid fgs data found.'
      
    endelse
    
    ; E-field fit (EFI).
    cal_efs:               ; can't use continue in case statements
    idx = 0L
    dqd = 'efit'
    ;fit codes are 'e1'x and 'e5'x for times that use e12, 'e3'x and e7'x
    ;for times which use e34,jmm,22-Oct-2010
    If(is_struct(d_code)) Then Begin
      e12_ss = where(d_code.y[*, idx] Eq 'e1'x Or $
        d_code.y[*, idx] Eq 'e5'x, ne12)
      e34_ss = where(d_code.y[*, idx] Eq 'e3'x Or $
        d_code.y[*, idx] Eq 'e7'x, ne34)
      If(ne12 Eq 0 And ne34 Eq 0) Then Begin
        Goto, use_e12           ;should never happen
      Endif
    Endif Else Begin
      use_e12:
      dprint, 'No good fit codes, assuming that E12 is used for EFS'
      ne12 = n_elements(d.x)
      e12_ss = lindgen(n_elements(d.x))
      e34_ss = -1
    Endelse
    units = cpar.e12.units
    tplot_var_efit_orig = string(tplot_var, dqd, format = '(A,"_",A)')
    tplot_var_efit = tplot_var_efit_orig + out_suf[0]
    str_element, dl, 'ytitle', tplot_var_efit_orig, /add
    str_element, dl, 'ysubtitle', '['+units+']', /add
    str_element, dl, 'labels', ['A', 'B', 'C', 'Sig', '<Ez>'], /add
    str_element, dl, 'labflag', 1, /add
    str_element, dl, 'colors', [1, 2, 3, 4, 5], /add
    str_element, data_att, 'cal_par_time', cpar.e12.cal_par_time, /add
    str_element, data_att, 'units', units, /add
    str_element, dl, 'data_att', data_att, /add
    
    ;********************************************
    ;Save 'efs' datatype before "hard wired" calibrations.
    ;An EFI-style calibration is performed below.
    ;********************************************
    efs = reform(d.y[*, [1, 2, 4], idx])
    ; Locate samples with non-NaN data values.  Save the indices in
    ; efsx_good, then at the end of calibration, pull the "good"
    ; indices out of the calibrated efs[] array to make the thx_efs
    ; tplot variable.
    efsx_good=where(finite(efs[*,0]) ne 0,n_efs_good)
    if n_efs_good gt 0 then begin ;if it contains only NaNs then skip
      efsx_fixed = d.x[efsx_good]
      If(ne34 Gt 0) Then Begin ;rotate efs 90 degrees if necessary, if e34 was used in spinfit
        efs[e34_ss, *] = reform(d.y[e34_ss, [2, 1, 4], idx])
        efs[e34_ss, 0] = -efs[e34_ss, 0]
        ;verified this using thm_spinfit,jmm,22-oct-2010
      Endif
      ;save Ez separately, for possibility that it's the SC potential
      efsz = reform(d.y[*, 4, idx])
      ;Use cpar to calibrate
      If(ne12 Gt 0) Then Begin
        d.y[e12_ss, 0, idx] = cpar.e12.Ascale*d.y[e12_ss, 0, idx]
        d.y[e12_ss, 1, idx] = cpar.e12.Bscale*d.y[e12_ss, 1, idx]
        d.y[e12_ss, 2, idx] = cpar.e12.Cscale*d.y[e12_ss, 2, idx]
        d.y[e12_ss, 3, idx] = cpar.e12.sigscale*d.y[e12_ss, 3, idx]
        d.y[e12_ss, 4, idx] = cpar.e12.Zscale*d.y[e12_ss, 4, idx]
      Endif
      If(ne34 Gt 0) Then Begin
        d.y[e34_ss, 0, idx] = cpar.e34.Ascale*d.y[e34_ss, 0, idx]
        d.y[e34_ss, 1, idx] = cpar.e34.Bscale*d.y[e34_ss, 1, idx]
        d.y[e34_ss, 2, idx] = cpar.e34.Cscale*d.y[e34_ss, 2, idx]
        d.y[e34_ss, 3, idx] = cpar.e34.sigscale*d.y[e34_ss, 3, idx]
        d.y[e34_ss, 4, idx] = cpar.e34.Zscale*d.y[e34_ss, 4, idx]
      Endif
      ; store the spin fit parameters.
      if (where(dt_output eq 'fit_efit') ne -1)  then begin
        store_data, tplot_var_efit, $
          data = {x:d.x, y:reform(d.y[*, *, idx])}, $
          lim = l, dlim = dl
      endif
      dqd = 'efs'
      tplot_var_efs_orig = string(strmid(tplot_var, 0, 3), dqd, format = '(A,"_",A)')
      tplot_var_efs = tplot_var_efs_orig +out_suf[0]
      tplot_var_efs_sigma_orig = string(strmid(tplot_var, 0, 3), dqd, format = '(A,"_",A)')+'_sigma'
      tplot_var_efs_sigma = tplot_var_efs_sigma_orig+ out_suf[0]
      tplot_var_efs_potl_orig = string(strmid(tplot_var, 0, 3), dqd, format = '(A,"_",A)')+'_potl'
      tplot_var_efs_potl = tplot_var_efs_potl_orig+ out_suf[0]
      str_element, dl, 'ytitle', tplot_var_efs_orig, /add
      str_element, dl, 'ysubtitle', '['+units+']', /add
      str_element, dl, 'labels', ['Ex', 'Ey', 'Ez'], /add
      str_element, dl, 'colors', [2, 4, 6], /add
      ; store the spin fit E-field vector (only the B, C, and <Ez> parameters).
      ;****************************************************************************
      ;This if... endif block contains the EFI-style calibration on 'efs' datatype:
      ;****************************************************************************
      if (where(dt_output eq 'efs') ne -1) $
        or (where(dt_output eq 'efs_0') ne -1) $
        or (where(dt_output eq 'efs_dot0') ne -1) then begin ;todo: EFS start
        ;==================================================================================
        ;Calibrate efs data by applying E12 calibration factors, not despinning,
        ;then applying despun (spin-dependent) calibration factors from E12 (the
        ;spin-independent offset is subtracted on-board):
        ;==================================================================================
        thm_get_efi_cal_pars, d.x, 'efs', sc, cal_pars = cp
        if keyword_set(no_cal) then exx = cp.boom_length else exx = cp.boom_length*cp.boom_shorting_factor
        ;==================
        ;Calibrate E field:
        ;==================
        ;
        ;Calibrate Ex and Ey spinfits that are derived from E12 only!:
        ; JWB, 18 Nov 2008 -- corrected bug in offset subtraction.
        ;*************************************************************
        for icomp = 0, 1 do begin
          If(ne12 Gt 0) Then Begin
            efs[e12_ss, icomp] = -1000.*cp.gain[0] * efs[e12_ss, icomp]/exx[0]
          Endif
          If(ne34 Gt 0) Then Begin
            efs[e34_ss, icomp] = -1000.*cp.gain[1] * efs[e34_ss, icomp]/exx[1]
          Endif
          ;                  if not keyword_set(no_cal) then efs[*,icomp] -= cp.dsc_offset[0]
          if not keyword_set(no_cal) then begin
            efs[*, icomp] -= cp.dsc_offset[icomp]
          endif
        endfor
        ;
        ;Calibrate Ez spinfit by itself:
        ;*******************************
        efs[*, 2] = -1000.*cp.gain[2] * efs[*, 2]/exx[2]
        if not keyword_set(no_cal) then efs[*, 2] -= cp.dsc_offset[2]
        ;
        ;Here, if the fit_code is 'e5'x (229) then efs[*,2] contains the spacecraft
        ;potential, so set all of those values to Nan, jmm, 19-Apr-2010
        ;Or if the fit_code is 'e7'x (231), this will also be including the SC
        ;potential,jmm,22-oct-2010
        If(is_struct(d_code)) Then Begin
          sc_potl = where(d_code.y[*, idx] Eq 'e5'x Or $
            d_code.y[*, idx] Eq 'e7'x, nsc_potl)
          If(nsc_potl Gt 0) Then efs[sc_potl, 2] = !values.f_nan
        Endif
        ;
        
        ; 2010-07-20 JWL
        if (use_eclipse_corrections GT 0) then begin
          dprint,'Applying eclipse delta_phi corrections to EFS.'
          Ex_corr=efs[*,0]
          Ey_corr=efs[*,1]
          
          correct_delta_phi_vector,x_in=Ex_corr,y_in=Ey_corr,delta_phi=delta_phi,x_out=Ex_corrp, y_out=Ey_corrp
          efs[*,0] = Ex_corrp
          efs[*,1] = Ey_corrp
        endif else begin
          dprint,'Skipping eclipse delta_phi corrections.'
        endelse
        
        if (where(dt_output eq 'efs') ne -1) then begin
          if (n_efs_good GT 0) then begin
            store_data, tplot_var_efs,data = {x:efsx_fixed, y:efs[efsx_good,*]},lim = l, dlim = dl
          endif else begin
            dprint,'No valid EFS data found.'
            ; Make tplot variable anyway, even if it's all NaNs...other
            ; code may assume the tplot variable exists.
            ; store_data, tplot_var_efs,data = {x:d.x, y:efs},lim = l, dlim = dl
          endelse
        endif
        if keyword_set(coord) && strlowcase(coord) ne 'dsl' then begin
          thm_cotrans, tplot_var_efs, out_coord = coord, use_spinaxis_correction = 1, use_spinphase_correction = 1
        endif
      endif                       ; END efs
      if (where(dt_output eq 'efs_sigma') ne -1) then begin
        str_element, dl_sigma, 'ytitle', tplot_var_efs_sigma_orig, /add
        str_element, dl_sigma, 'ysubtitle', '['+units+']', /add
        str_element, data_att_sigma, 'units', units, /add
        str_element, dl_sigma, 'data_att', data_att_sigma, /add
        ;store_data, tplot_var_efs+'_sigma', data = {x:d.x, y:d.y[*, 3, idx]}, dl = dl_sigma
        store_data, tplot_var_efs_sigma, data = {x:efsx_fixed, y:d.y[efsx_good, 3, idx]}, dl = dl_sigma
      endif
      if (where(dt_output eq 'efs_potl') ne -1 && is_struct(d_code)) then begin
        sc_potl = where(d_code.y[*, idx] Eq 'e5'x Or d_code.y[*, idx] Eq 'e7'x, nsc_potl)
        If(nsc_potl Gt 0) Then Begin
          ;need a spin period
          model = spinmodel_get_ptr(sc)
          If(obj_valid(model)) Then Begin
            spinmodel_interp_t, model = model, time = d.x, spinper = spin_period, $
              /use_spinphase_correction
            spin_period = median(spin_period)
          Endif Else spin_period = 3.03
          ;time values are offset by spin_period*169.0/360.0, data values are
          ;scaled by: 0.00410937 to be consistent with the pxxm_pot variable
          units = 'V'
          str_element, dl_potl, 'ytitle', tplot_var_efs_potl_orig, /add
          str_element, dl_potl, 'ysubtitle', '['+units+']', /add
          str_element, data_att_potl, 'units', units, /add
          str_element, dl_potl, 'data_att', data_att_potl, /add
          store_data, tplot_var_efs_potl, data = {x:d_code.x[sc_potl], $
            y:0.00410937*efsz[sc_potl]}, dl = dl_potl
        Endif
      endif
      ; _0 and _dot0 variables, if you have an fgs variable
      thx_efs_0 = efs
      thx_efs_0[*, 2] = 0
      str_element, dl, 'labels', ['Ex', 'Ey', 'Ez'], /add
      str_element, dl, 'colors', [2, 4, 6], /add
      str_element, data_att, 'cal_par_time', cpar.e12.cal_par_time, /add
      str_element, data_att, 'units', 'mV/m', /add
      str_element, dl, 'data_att', data_att, /add
      str_element, dl, 'ytitle', thx+'_efs_0', /add
      str_element, dl, 'ysubtitle', '['+units+']', /add
      if where(dt_output eq 'efs_0') ne -1 then begin
        store_data, thx+'_efs_0'+out_suf, data = {x:efsx_fixed, y:thx_efs_0[efsx_good,*]}, limit = l, dlimit = dl
        if keyword_set(coord) && strlowcase(coord) ne 'dsl' then begin ;cotrans here, jmm, 2010-02-22
          thm_cotrans, thx+'_efs_0'+out_suf, out_coord = coord, use_spinaxis_correction = 1, use_spinphase_correction = 1
        endif
      endif
      If(n_elements(fgs) Eq 0) Then Begin
        dprint, 'No Calibrated FGS data available for efs_dot0 calculation'
        Continue
      Endif
      Ez = (efs[*, 0]*fgs[*, 0] + efs[*, 1]*fgs[*, 1])/(-1*fgs[*, 2])
      angle = acos(fgs[*, 2]/(fgs[*, 0]^2+fgs[*, 1]^2+fgs[*, 2]^2)^.5)*180/!dpi
      angle80 = where(angle gt 80)
      if size(angle80, /dim) ne 0 then Ez[where(angle gt 80)] = 'NaN'
      thx_efs_dot0 = efs
      thx_efs_dot0[*, 2] = Ez
      
      str_element, dl, 'ytitle', thx+'_efs_dot0', /add
      if where(dt_output eq 'efs_dot0') ne -1 then begin
        ;fix NaN
        efsx_dot0_good=where((finite(thx_efs_dot0[*,0]) ne 0), n_dot0)
        if (n_dot0 GT 0) then begin
          efsx_dot0_fixed = d.x[efsx_dot0_good]
          efsy_dot0_fixed = thx_efs_dot0[efsx_dot0_good, *]
          ;store_data, thx+'_efs_dot0'+out_suf, data = {x:d.x, y:thx_efs_dot0}, limit = l, dlimit = dl
          store_data, thx+'_efs_dot0'+out_suf, data = {x:efsx_dot0_fixed, y:efsy_dot0_fixed}, limit = l, dlimit = dl
          ;store_data, thx+'_efs_dot0_time'+out_suf, data = {efsx_dot0_fixed}, limit = l, dlimit = dl
        endif else begin ; all NaN
          dprint,'No valid efs_dot0 data found.'
          ; Make tplot variable anyway, even if it's all NaNs...other
          ; code may assume the tplot variable exists.
          ; store_data, thx+'_efs_dot0'+out_suf, data = {x:d.x, y:thx_efs_dot0}, limit = l, dlimit = dl
        endelse
        
        if keyword_set(coord) && strlowcase(coord) ne 'dsl' then begin ;cotrans here, jmm, 2010-02-22
          thm_cotrans, thx+'_efs_dot0'+out_suf, out_coord = coord, use_spinaxis_correction = 1, use_spinphase_correction = 1
        endif
      endif
    endif else begin
      dprint,'No valid efs data found.'
    endelse    
  endfor                        ; loop over spacecraft.
end
