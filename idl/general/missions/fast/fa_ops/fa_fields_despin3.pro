;	@(#)fa_fields_despin.pro	1.19	03/19/98
;+
; PROCEDURE: FA_FIELDS_DESPIN, V58, V12, T1 = t1, T2 = t2, 
;                 PHASE = phase, USE_V158 = Use_V158, 
;                 SHADOW_NOTCH = shadow_notch, 
;                 MAG_NOTCH = mag_notch, STORE=store, SLOW=slow 
;
; PURPOSE: A high-level routine which produces despun DC electric field
;          data for FAST.
;
; INPUT: 
;    V58 -         If blank, program will get V5-V8_S. If you want
;                  to run this program on burst data, use 
;                  V58=get_fa_fields('V5-V8_4k',/all), for example.
;    V12 -         If blank, program will get V1-V2_S
;                  to run this program on burst data, use 
;                  V12=get_fa_fields('V1-V2_4k',/all), for example.
;
; KEYWORDS: 
;    USE_V158       If set, use V158, otherwise V1-V2. DEFAULT = 0
;                   Note: be sure to set this if you supply V1-58!
;
;    SHADOW_NOTCH - Notch out shadow spikes (also known as "sun
;                   spikes"). These are set to NaN's, unless the
;                   Sinterp keyword is set. The default is
;                   SHADOW_NOTCH = 0, in which case the sun spikes are
;                   left alone.
;
;    MAG_NOTCH - Notch out mag pulses. These will be interpolated
;                across, unless the Bnan keyword is set.The default is
;                MAG_NOTCH = 1, so you must say ...,mag_notch=0,... if
;                you want to see the mag spikes.
;
;    STORE -        Store data for tplot.        DEFAULT = 1
;
;    SLOW -         Uses FA_FIELDS_SPINFIT instead
;                      of FF_QUICKFIT.  DEFAULT = 0
;
;    T1, T2 -       Start and stop time, if other than that
;                   contained in V58 and V12, (or if those 
;                   quantities are not defined). 
;
; CALLING: fa_fields_despin,t1='1997-09-27/01:32',t2='1997-09-27/01:34'
;
;       That's easy! Now you can plot E_near_B and E_equatorward.
;
; IMPORTANT! SDT SETUP: Need to have: V5-V8_S, V1-V2_S (or V1-V4_S, V4_S
;                       and V8_S), 1032_spinPhase
;
; OUTPUT: Dat is IDL fields time series data structure with multiple
;         components. This  
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; Added quality flag variable, 2024-05-21, jmm, jimm@ssl.berkeley.edu
; Updated qflag, to give more information about the notches
;-
Pro fa_fields_despin3, V58, V12, T1 = t1, T2 = t2, PHASE = phase, $
                       USE_V158 = use_v158, $
                       SHADOW_NOTCH = shadow_notch, MAG_NOTCH = mag_notch, $
                       STORE = store, DAT = dat, SLOW = slow,  $
                       Binterp = Binterp, Bnan = Bnan,  $
                       Sinterp = Sinterp, Snan = Snan
; Set up constants.
  two_pi = 2.d*!dpi

  req_dqds = ['V5-V8_S','V1-V2_S','SMPhase_FieldsSurvey0']
;These dqds are required for the e_along_v and e_near_b  
  if keyword_set(use_v158) then  $
     req_dqds = ['V1-V4_S','V4_S','V8_S','V5-V8_S','SMPhase_FieldsSurvey0']

  if not (missing_dqds(req_dqds,/quiet,absent=absent) eq 0) then begin
     message,'The following required quantities are not in ' + $
             'SDT:',/continue
     print,absent
     return    
  endif

; First set up V58.
  IF not defined(V58) then BEGIN
     V58 = get_fa_fields('V5-V8_S',t1,t2)
     IF not v58.valid then BEGIN
        print, "FA_FIELDS_DESPIN: STOPPED!"
        print, "Cannot get V5-V8_S. Check SDT setup."
        return
     ENDIF
  ENDIF

; Next set up V12.

  IF not defined(V12) then BEGIN
     IF not keyword_set(Use_V158) then BEGIN
        V12 = get_fa_fields('V1-V2_S',t1,t2)
     ENDIF ELSE BEGIN
        v12 = get_fa_v158(t1,t2,cutoff=cutoff)
        fa_fields_filter,v58,[0,cutoff]
     ENDELSE

     IF not v12.valid then BEGIN
        print, "FA_FIELDS_DESPIN: STOPPED!"
        print, "Cannot get V1-V2_S. Check SDT setup."
        return
     ENDIF
  ENDIF

; Set up the phase.
  IF not defined(phase) then BEGIN
     phase = fa_fields_phase(freq=0.01)
     IF not phase.valid then BEGIN
        print, "FA_FIELDS_DESPIN: STOPPED!"
        print, "Cannot get phase. Check SDT setup."
        return
     ENDIF
  ENDIF

; Begin the combine process. Do not add to structure. Save some space.
; 
  if not keyword_set(use_v158) then begin
     fa_fields_combine,V58,V12,result=v12_dat, /svy
  endif else begin
     v12_dat = v12.comp1
  endelse

  fa_fields_combine, V58, phase, result=Bphase, /interp, delt=100.
  fa_fields_combine, V58, phase, tag_2='comp2', result=Sphase, /interp, delt=100.

  start_time = v58.start_time
  time = v58.time-start_time
  v58_dat = v58.comp1
  units = v58.units_name
  npts=v58.npts

  v12name = 'V12'
  if keyword_set(use_v158) then v12name = 'V158'


; We now have time, V58_dat, V12_dat, Bphase, and Sphase
; Notch the data
;
; The default is mag_notch = 1, Binterp = 1. Do we need to deactivate
; these? Note that keyword_set() is not used here, because it
; evaluates to zero if a keyword is either undefined or defined to be
; zero. 

  if not defined(mag_notch) then mag_notch = 1
  if mag_notch eq 0 then begin
     Binterp = 0 & Bnan = 0
  endif else begin
     if not defined(Bnan) then bnan = 0
     if not defined(Binterp) then binterp = (bnan eq 0)
     if bnan and binterp then begin
        message,'Cannot both interpolate and NaN mag spikes! Doing ' + $
                'interpolation...',/continue
        binterp = 1 & bnan = 0
     endif
  endelse

  if not defined(shadow_notch) then shadow_notch = 0
  if shadow_notch eq 1 then begin
     if not defined(sinterp) then sinterp = 0
     if not defined(snan) then snan = (sinterp eq 0)
     if snan and sinterp then begin
        message,'Cannot both interpolate and NaN sun spikes! ' + $
                'NaNing...',/continue
        sinterp = 0 & snan = 1
     endif
  endif else begin
     sinterp = 0
     snan = 0
  endelse

;
; deal with the true/false, keyword_set or not ambiguity...keyword_set
; means not zero, odd integers are true, and NOT flips all the bits. I
; want true/false here...use 0 and 1. 
;
  if snan then snan = 1 else snan = 0
  if sinterp then sinterp = 1 else sinterp = 0
  if bnan then bnan = 1 else bnan = 0
  if binterp then binterp = 1 else binterp = 0

  notch58 = ff_notch('V58',V58_dat,Bphase=Bphase,Sphase=Sphase, $
                     Binterp=Binterp,Bnan=Bnan, $
                     Sinterp=Sinterp,Snan=Snan, $
                     bnotch=bnotch58, snotch=snotch58)
  notch12 = ff_notch(v12name,V12_dat,Bphase=Bphase,Sphase=Sphase, $
                     Binterp=Binterp,Bnan=Bnan, $
                     Sinterp=Sinterp,Snan=Snan, $
                     bnotch=bnotch12, snotch=snotch12)

  if not keyword_set(use_v158) then begin
;
; DETERMINE THE ZERO LEVEL AND RATIO AND ADJUST DATA. 
;
     if not keyword_set(slow) then begin
; QUICKFIT 58
        index = where(finite(time) AND finite(V58_dat),n_finite)
        IF (n_finite GT 0) then BEGIN
           phs = time(index)
           dat = v58_dat(index)
           ff_quickfit,dat,phs,es=es58, ec=ec58, $
                       phsf=tf58, zero=zero58, per=5.d
        ENDIF

; QUICKFIT 12
        index = where(finite(time) AND finite(V12_dat),n_finite)
        IF (n_finite GT 0) then BEGIN
           phs = time(index)
           dat = v12_dat(index)
           ff_quickfit,dat,phs,es=es12, ec=ec12,  $
                       phsf=tf12, zero=zero12, per=5.d
        ENDIF
        phs=0
        dat=0
     endif else begin
        message,'Using slow spinfitter, not recommended for ' + $
                'long intervals (a few minutes max)...',/continue
        fa_fields_spin_ave,v58,interval=.01,slide=.01
        fa_fields_spin_ave,v12,interval=.01,slide=.01
        
        if not $
           ((fa_fields_spinfit(v58,coeff=c58, $
                               interval=2.,slide=0.2,times=tf58)) and $
            (fa_fields_spinfit(v12,coeff=c12, $
                               interval=2.,slide=0.2,times=tf12))) then begin
           message,'Unable to spinfit for gain normalization...life is ' + $
                   'tough...',/continue 
           return
        endif
        
        ok = where(finite(reform(c58[0,*])) and finite(reform(c12[0,*])),nok)
        if nok eq 0 then begin
           message,'All spinfit data are NaN!',/continue
           return
        endif
        
        tf12 = tf12[ok] - start_time
        tf58 = tf58[ok] - start_time
        
        zero58 = (reform(c58[4,*]))[ok]
        ec58 = (reform(c58[0,*]))[ok]
        es58 = (reform(c58[1,*]))[ok]
        v58dat = v58.comp1
        zero12 = (reform(c12[4,*]))[ok]
        ec12 = (reform(c12[0,*]))[ok]
        es12 = (reform(c12[1,*]))[ok]
        v12dat = v12.comp1
     endelse 

; FIX THE ZERO LEVEL 58
     index = where(finite(zero58))
     zero = zero58[index]
     zt   = tf58[index]
     ff_dce_fix,V58_dat,time,zero,zt
     
; DETERMINE RATIO
     if n_elements(es12) eq 0 or n_elements(es58) eq 0 then begin
        message,'Missing es12 or es58 data',/continue
        return
     endif
        
     etot12 = (es12*es12 + ec12*ec12)
     etot58 = (es58*es58 + ec58*ec58)
     etot12_aligned = ff_interp(tf58, tf12, etot12, delt = 100.)
     ratio = sqrt( etot58 / etot12_aligned )
     index = where(finite(ratio) AND (ratio GT 0.25) AND (ratio LT 2.0), $
                   n_index)

     rat = fltarr(n_elements(tf58))+1.
     rt = tf58
     if n_index gt 3 then begin
        rat = smooth(ratio[index],(n_index/2 < 20) > 2)
        rt = tf58[index]
     endif else begin
        message,'Not enough es12 or es58 data',/continue
        return
     endelse

; FIX THE ZERO LEVEL AND RATIO OF 12
     index = where(finite(zero12))
     zero = zero12[index]
     zt   = tf12[index]
     ff_dce_fix,V12_dat,time,zero,zt,rat, rt
  endif                         ; not keyword_set(use_v158)

;
; DO THE DESPIN
;
  dphi = 2.d*!dpi*37.98d/360.d
  e1 = v12_dat*cos(Bphase+dphi) - v58_dat*sin(Bphase+dphi)
  e2 = v58_dat*cos(Bphase+dphi) + v12_dat*sin(Bphase+dphi)

;Delete all tplot variables
  del_data, '*'
; STORE THE DATA IN TPLOT FORMAT
  data = {x:time+start_time, y:e1}
  store_data,'fa_e_near_b', data=data
  dlimit = {spec:0, ystyle:1,  $
            ytitle:'E NEAR B!C!C(mV/m)'}
  store_data,'fa_e_near_b', dlimit=dlimit

  data = {x:time+start_time, y:e2}
  store_data,'fa_e_along_v', data=data
  dlimit = {spec:0, ystyle:1, $
            ytitle:'E ALONG V!C!C(mV/m)'}
  store_data,'fa_e_along_v', dlimit=dlimit

  data = {x:time+start_time, y:v12_dat}
  store_data,'fa_e12', data=data
  dlimit = {spec:0, ystyle:1, $
            ytitle:'E12(mV/m)'}
  store_data,'fa_e12', dlimit=dlimit
  
  data = {x:time+start_time, y:v58_dat}
  store_data,'fa_e58', data=data
  dlimit = {spec:0, ystyle:1, $
            ytitle:'E58(mV/m)'}
  store_data,'fa_e58', dlimit=dlimit

  data = {x:time+start_time, y:(bphase Mod (2.0*!dpi))}
  store_data,'fa_bphase', data=data
  dlimit = {spec:0, ystyle:1, $
            ytitle:'BPHASE'}
  store_data,'fa_bphase', dlimit=dlimit

  data = {x:time+start_time, y:(sphase Mod (2.0*!dpi))}
  store_data,'fa_sphase', data=data
  dlimit = {spec:0, ystyle:1, $
            ytitle:'SPHASE'}
  store_data,'fa_sphase', dlimit=dlimit

;Times for boom deployment, to determine length
  boom_times = time_double(['1995-07-26/00:00:00',$
                            '1996-09-03/16:53:40', $
                            '1996-09-10/14:16:40', $
                            '1996-09-11/00:00:00', $
                            '1996-09-15/00:00:00', $
                            '1996-09-29/00:00:00', $
                            '1997-02-03/10:07:20'])
  nbt = n_elements(boom_times)
;probe length, distance from center of probe
  probel = fltarr(n_elements(boom_times), 10)
  probel[0, *] = 0.0            ;Launch configuration
  probel[1, *] = [5.5, 0.5, 0.0, 0.6, 0.0, $
                  0.0, 0.0, 0.0, 0.0, 0.0]
  probel[2, *] = [5.5, 0.5, 0.0, 0.6, 5.5, $
                  0.5, 0.5, 5.5, 0.0, 0.0]
  probel[3, *] = [8.0, 3.0, 0.0, 0.6, 8.0, $
                  3.0, 3.0, 8.0, 0.0, 0.0]
  probel[4, *] = [8.0, 3.0, 0.0, 0.6, 28.0, $
                  23.0, 23.0, 28.0, 0.0, 0.0]
  probel[5, *] = [28.3, 23.3, 0.0, 0.6, 28.0, $
                  23.0, 23.0, 28.0, 0.0, 0.0]
  probel[6, *] = [28.3, 23.3, 0.0, 0.6, 28.0, $
                  23.0, 23.0, 28.0, 4.05, 0.0]
  store_data, 'fa_probe_dist', data = {x:boom_times, y:probel}
;probe phase, add to sphase to get angle between probe vector and DSC
;X-axis
  probep = fltarr(n_elements(boom_times), 10)
  probep[0, *] = 0.0            ;Launch configuration
  probep[1, *] = [-142.0, -142.0, 0.0, 38.0, 0.0, $
                  0.0, 0.0, 0.0, 0.0, 0.0]
  probep[2, *] = [-142.0, -142.0, 0.0, 38.0, -45.0, $
                  -45.0, 121.0, 121.0, 0.0, 0.0]
;All probes that will be out are out after this
  probep[3, *] = probep[2, *]
  probep[4, *] = probep[2, *]
  probep[5, *] = probep[2, *]
  probep[6, *] = probep[2, *]
  store_data, 'fa_probe_phase', data = {x:boom_times, y:probep}
;length for probe differences, in meters
  v12_dist = [0.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0]
  v14_dist = [0.0, 6.1, 6.1, 8.6, 8.6, 28.9, 28.9] 
  v58_dist = [0.0, 0.0, 11.0, 16.0, 56.0, 56.0, 56.0]
  v910_dist = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.05]
  store_data, 'fa_v12_dist', data = {x:boom_times, y:v12_dist}
  store_data, 'fa_v14_dist', data = {x:boom_times, y:v14_dist}
  store_data, 'fa_v58_dist', data = {x:boom_times, y:v58_dist}
  store_data, 'fa_v910_dist', data = {x:boom_times, y:v910_dist}

; Q flag, 0 for ok data, 1 for Mag notch, 2 for S notch, 3 for both
; first bit for 12 mag notch, 2nd bit for 12 shadow notch, 3rd bit for
; 58 mag notch, 4th bit for 58 shadow notch
  qflag = bnotch58 & qflag[*] = 0
  not_okbn12 = where(bnotch12 Eq 0, nnot_okbn12)
  not_oksn12 = where(snotch12 Eq 0, nnot_oksn12)
  not_okbn58 = where(bnotch58 Eq 0, nnot_okbn58)
  not_oksn58 = where(snotch58 Eq 0, nnot_oksn58)

help, not_oksn58
  
  If(nnot_okbn12 Gt 0) Then qflag[not_okbn12] = 1
  If(nnot_oksn12 Gt 0) Then qflag[not_oksn12] = qflag[not_oksn12]+2
  If(nnot_okbn58 Gt 0) Then qflag[not_okbn58] = qflag[not_okbn58]+4
  If(nnot_oksn58 Gt 0) Then qflag[not_oksn58] = qflag[not_oksn58]+8
  
  data = {x:time+start_time, y:qflag}
  store_data, 'fa_data_quality', data=data
  dlimit = {spec:0, ystyle:1, $
            ytitle: 'fa_data_quality'}
  store_data, dlimit=dlimit

;Store E0_GSE, E0_GSM, E0_DSC
  e00 = get_fa_fields('FAST_E_0_S_GSE')
  ok_dot0 = 0b ; this needs to be 1 for dot0 calculation to proceed
  If(is_struct(e00) && (e00.valid Ne 0)) Then Begin
     data_e00 = {x:e00.time, y:transpose([transpose(e00.comp1), $
                                          transpose(e00.comp2), $
                                          transpose(e00.comp3)])}
     store_data, 'fa_e0_s_gse', data = data_e00
     dlimit = {spec:0, ystyle:1, $
               ytitle:'E_0_S_GSE(mV/m)'}
     store_data, 'fa_e0_s_gse', dlimit = dlimit
     ok_dot0 = 1b
  Endif Else dprint, 'No FAST_E_0_GSE data'

  e01 = get_fa_fields('FAST_E_0_S_GSM')
  If(is_struct(e01) && (e01.valid Ne 0)) Then Begin
     data_e01 = {x:e01.time, y:transpose([transpose(e01.comp1), $
                                          transpose(e01.comp2), $
                                          transpose(e01.comp3)])}
     store_data, 'fa_e0_s_gsm', data = data_e01
     dlimit = {spec:0, ystyle:1, $
               ytitle:'E_0_S_GSM(mV/m)'}
     store_data, 'fa_e0_s_gsm', dlimit = dlimit
  Endif Else dprint, 'No FAST_E_0_GSM data'

  e02 = get_fa_fields('FAST_E_0_S_DSC')
  If(is_struct(e02) && (e02.valid Ne 0)) Then Begin
     data_e02 = {x:e02.time, y:transpose([transpose(e02.comp1), $
                                          transpose(e02.comp2), $
                                          transpose(e02.comp3)])}
     store_data, 'fa_e0_s_dsc', data = data_e02
     dlimit = {spec:0, ystyle:1, $
               ytitle:'E_0_S_DSC(mV/m)'}
     store_data, 'fa_e0_s_dsc', dlimit = dlimit
  Endif Else dprint, 'No FAST_E_0_DSC data'

;Store all voltages, V1 and V5 need to be calculated
;Start by saving V12, V14, and V58, directly from SDT
;from cal file
;/disks/django/home/sdt/nws/Linux.2.6/lib/fast_fields_cals/fastboom_hist.cal
;v1-v2 boom length is 5.0m, v1-v4 is 28.9m, v5-v8 is 56.0, v9-v10 is
;4.05, after 1997-02-09
;Conversion values are Meters/1000(V/mV)
  v12x = get_fa_fields('V1-V2_S')
  v12l = 0.0 & v14l = 0.0 & v58l = 0.0 & v910l= 0.0
  If(v12x.time[0] Ge time_double('1997-02-03/10:07:20')) Then Begin
     v12l = 5.0e-3
     v14l = 28.9e-3
     v58l = 56.0e-3
     v910l = 4.05e-3
  Endif Else If(v12x.time[0] Ge time_double('1996-09-29/00:00:00')) Then Begin
     v12l = 5.0e-3
     v14l = 28.9e-3
     v58l = 56.0e-3
     v910l = 0.0
  Endif Else If(v12x.time[0] Ge time_double('1996-09-15/00:00:00')) Then Begin
     v12l = 5.0e-3
     v14l = 8.6e-3
     v58l = 56.0e-3
     v910l = 0.0
  Endif Else If(v12x.time[0] Ge time_double('1996-09-11/00:00:00')) Then Begin
     v12l = 5.0e-3
     v14l = 8.6e-3
     v58l = 16.0e-3
     v910l = 0.0
  Endif Else If(v12x.time[0] Ge time_double('1996-09-10/14:16:40')) Then Begin
     v12l = 5.0e-3
     v14l = 6.1e-3
     v58l = 11.0e-3
     v910l = 0.0
  Endif Else If(v12x.time[0] Ge time_double('1996-09-03/16:53:40')) Then Begin
     v12l = 5.0e-3
     v14l = 6.1e-3
     v58l = 0.0
     v910l = 0.0
  Endif Else Begin
     v12l = 0.0 & v14l = 0.0 & v58l = 0.0 & v910l= 0.0
  Endelse
     
  print, time_String(v12x.time[0])
  print, v12l, v14l, v58l, v910l

  If(is_struct(v12x) && (v12x.valid Ne 0)) Then Begin
     data_v12x = {x:v12x.time, y:v12x.comp1*v12l} ;changed units from mV/m to V
     store_data, 'fa_v1_v2_s', data = data_v12x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1-V2_S(V)'}
          store_data,'fa_v1_v2_s', dlimit=dlimit
  Endif
  v14x = get_fa_fields('V1-V4_S')
  If(is_struct(v14x) && (v14x.valid Ne 0)) Then Begin
     data_v14x = {x:v14x.time, y:v14x.comp1*v14l} ;changed units from mV/m to V
     store_data, 'fa_v1_v4_s', data = data_v14x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1-V4_S(V)'}
     store_data,'fa_v1_v4_s', dlimit=dlimit
  Endif
  v58x = get_fa_fields('V5-V8_S')
  If(is_struct(v58x) && (v58x.valid Ne 0)) Then Begin
     data_v58x = {x:v58x.time, y:v58x.comp1*v58l} ;changed units from mV/m to V
     store_data, 'fa_v5_v8_s', data = data_v58x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V5-V8_S(V)'}
     store_data,'fa_v5_v8_s', dlimit=dlimit
  Endif
  v910x = get_fa_fields('V9-V10_S')
  If(is_struct(v910x) && (v910x.valid Ne 0)) Then Begin
     data_v910x = {x:v910x.time, y:v910x.comp1*v910l} ;changed units from mV/m to V
     store_data, 'fa_v9_v10_s', data = data_v910x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V9-V10_S(V)'}
     store_data,'fa_v9_v10_s', dlimit=dlimit
  Endif
  v2x = get_fa_fields('V2_S')
  If(is_struct(v2x) && (v2x.valid Ne 0)) Then Begin
     data_v2x = {x:v2x.time, y:v2x.comp1}
     store_data, 'fa_v2_s', data = data_v2x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V2_S(V)'}
     store_data,'fa_v2_s', dlimit=dlimit
  Endif
  v3x = get_fa_fields('V3_S')
  If(is_struct(v3x) && (v3x.valid Ne 0)) Then Begin
     data_v3x = {x:v3x.time, y:v3x.comp1}
     store_data, 'fa_v3_s', data = data_v3x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V3_S(V)'}
     store_data,'fa_v3_s', dlimit=dlimit
  Endif
  v4x = get_fa_fields('V4_S')
  If(is_struct(v4x) && (v4x.valid Ne 0)) Then Begin
     data_v4x = {x:v4x.time, y:v4x.comp1}
     store_data, 'fa_v4_s', data = data_v4x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V4_S(V)'}
     store_data,'fa_v4_s', dlimit=dlimit
  Endif
  v6x = get_fa_fields('V6_S')
  If(is_struct(v6x) && (v6x.valid Ne 0)) Then Begin
     data_v6x = {x:v6x.time, y:v6x.comp1}
     store_data, 'fa_v6_s', data = data_v6x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V6_S(V)'}
     store_data,'fa_v6_s', dlimit=dlimit
  Endif
  v7x = get_fa_fields('V7_S')
  If(is_struct(v7x) && (v7x.valid Ne 0)) Then Begin
     data_v7x = {x:v7x.time, y:v7x.comp1}
     store_data, 'fa_v7_s', data = data_v7x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V7_S(V)'}
     store_data,'fa_v7_s', dlimit=dlimit
  Endif
  v8x = get_fa_fields('V8_S')
  If(is_struct(v8x) && (v8x.valid Ne 0)) Then Begin
     data_v8x = {x:v8x.time, y:v8x.comp1}
     store_data, 'fa_v8_s', data = data_v8x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V8_S(V)'}
     store_data,'fa_v8_s', dlimit=dlimit
  Endif
  v9x = get_fa_fields('V9_S')
  If(is_struct(v9x) && (v9x.valid Ne 0)) Then Begin
     data_v9x = {x:v9x.time, y:v9x.comp1}
     store_data, 'fa_v9_s', data = data_v9x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V9_S(V)'}
     store_data,'fa_v9_s', dlimit=dlimit
  Endif
  v10x = get_fa_fields('V10_S')
  If(is_struct(v10x) && (v10x.valid Ne 0)) Then Begin
     help, v10x
     data_v10x = {x:v10x.time, y:v10x.comp1}
     store_data, 'fa_v10_s', data = data_v10x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V10_S(V)'}
     store_data,'fa_v10_s', dlimit=dlimit
  Endif
;Rotation matrices, 9 components in order a11,a12,a13,a21,a22,a23,a31,a32,a33
  a11_dsc_gsm = get_fa_fields('FAST_Rot_Mat_DSC_GSM')
  If(is_struct(a11_dsc_gsm) && (a11_dsc_gsm.valid Ne 0)) Then Begin
     ntx = n_elements(a11_dsc_gsm.time)
     y = fltarr(ntx, 3, 3)
     y[*, 0, 0] = a11_dsc_gsm.comp1
     y[*, 0, 1] = a11_dsc_gsm.comp2
     y[*, 0, 2] = a11_dsc_gsm.comp3
     y[*, 1, 0] = a11_dsc_gsm.comp4
     y[*, 1, 1] = a11_dsc_gsm.comp5
     y[*, 1, 2] = a11_dsc_gsm.comp6
     y[*, 2, 0] = a11_dsc_gsm.comp7
     y[*, 2, 1] = a11_dsc_gsm.comp8
     y[*, 2, 2] = a11_dsc_gsm.comp9
     data_gd = {x:a11_dsc_gsm.time, y:y}
;     data_gd = {x:a11_dsc_gsm.time, y:transpose([transpose(a11_dsc_gsm.comp1), $
;                                                 transpose(a11_dsc_gsm.comp2), $
;                                                 transpose(a11_dsc_gsm.comp3), $
;                                                 transpose(a11_dsc_gsm.comp4), $
;                                                 transpose(a11_dsc_gsm.comp5), $
;                                                 transpose(a11_dsc_gsm.comp6), $
;                                                 transpose(a11_dsc_gsm.comp7), $
;                                                 transpose(a11_dsc_gsm.comp8), $
;                                                 transpose(a11_dsc_gsm.comp9)])}
     store_data, 'fa_dsc_gsm', data = data_gd
     dlimit = {spec:0, ystyle:1, $
               ytitle:'DSC_GSM'}
     store_data, 'fa_dsc_gsm', dlimit = dlimit
  Endif Else Begin
     dprint, 'No FAST_DSC_GSM data'
  Endelse

  a11_dsc_gse = get_fa_fields('FAST_Rot_Mat_DSC_GSE')
  If(is_struct(a11_dsc_gse) && (a11_dsc_gse.valid Ne 0)) Then Begin
     ntx = n_elements(a11_dsc_gse.time)
     y = fltarr(ntx, 3, 3)
     y[*, 0, 0] = a11_dsc_gse.comp1
     y[*, 0, 1] = a11_dsc_gse.comp2
     y[*, 0, 2] = a11_dsc_gse.comp3
     y[*, 1, 0] = a11_dsc_gse.comp4
     y[*, 1, 1] = a11_dsc_gse.comp5
     y[*, 1, 2] = a11_dsc_gse.comp6
     y[*, 2, 0] = a11_dsc_gse.comp7
     y[*, 2, 1] = a11_dsc_gse.comp8
     y[*, 2, 2] = a11_dsc_gse.comp9
     data_dg = {x:a11_dsc_gse.time, y:y}
;     data_dg = {x:a11_dsc_gse.time, y:transpose([transpose(a11_dsc_gse.comp1), $
;                                                 transpose(a11_dsc_gse.comp2), $
;                                                 transpose(a11_dsc_gse.comp3), $
;                                                 transpose(a11_dsc_gse.comp4), $
;                                                 transpose(a11_dsc_gse.comp5), $
;                                                 transpose(a11_dsc_gse.comp6), $
;                                                 transpose(a11_dsc_gse.comp7), $
;                                                 transpose(a11_dsc_gse.comp8), $
;                                                 transpose(a11_dsc_gse.comp9)])}
     store_data, 'fa_dsc_gse', data = data_dg
     dlimit = {spec:0, ystyle:1, $
               ytitle:'DSC_GSE'}
     store_data, 'fa_dsc_gse', dlimit = dlimit
  Endif Else Begin
     dprint, 'No FAST_DSC_GSE data'
  Endelse

;Spin axis direction, in GSE, GSM
  attitude = get_fa_fields('Fast_Attitude_Data')
  If(is_Struct(attitude) && (attitude.valid Ne 0)) Then Begin
     axis_gse = {x:attitude.time, y:transpose([transpose(attitude.comp8), $
                                               transpose(attitude.comp9), $
                                               transpose(attitude.comp10)])}
     store_data, 'fa_spin_axis_gse', data = axis_gse
     dlimit = {spec:0, ystyle:1, $
               ytitle:'SPIN_AXIS_GSE'}
     store_data, 'fa_spin_axis_gse', dlimit = dlimit
     axis_gsm = {x:attitude.time, y:transpose([transpose(attitude.comp11), $
                                               transpose(attitude.comp12), $
                                               transpose(attitude.comp13)])}
     store_data, 'fa_spin_axis_gsm', data = axis_gsm
     dlimit = {spec:0, ystyle:1, $
               ytitle:'SPIN_AXIS_GSM'}
     store_data, 'fa_spin_axis_gsm', dlimit = dlimit
  Endif Else Begin
     dprint, 'No FAST Attitude data'
  Endelse
     
  If(~keyword_set(use_v158)) Then Begin
; DESPIN AND STORE QUICKFIT DATA
     index = where(finite(Bphase) AND finite(V58_dat),n_finite)
     If(n_finite Gt 0) Then Begin
        phs = Bphase[index]+dphi
        dat = v58_dat[index]
        ff_quickfit,dat,phs,es=es58, ec=ec58, phsf=phsf58
     Endif
     If(n_elements(phsf58) Eq 0) Then Begin
        message,'Missing phsf58 data, quickfit failed',/continue
        Return
     Endif
     ind     = where(finite(phsf58))
     phsf58  = phsf58[ind]
     es58    = es58[ind]
     ec58    = ec58[ind]
     tf58    = ff_interp(phsf58, phs, time[index], delt= 100.)
     phs=0
     dat=0
     data = {x:tf58+start_time, y:es58}
     store_data,'fa_efit_near_b', data=data
     dlimit = {spec:0, ystyle:1, yrange:[-1000.,1000.],  $
               ytitle:'EFIT NEAR B!C!C55m (mV/m)',$
               panel_size:3}
     store_data,'fa_efit_near_b', dlimit=dlimit
     data = {x:tf58+start_time, y:ec58}
     store_data,'fa_efit_along_v', data=data
     dlimit = {spec:0, ystyle:1, yrange:[-1000.,1000.],  $
               ytitle:'EFIT ALONG V!C!C55m (mV/m)',$
               panel_size:3}
     store_data,'fa_efit_along_v', dlimit=dlimit
  Endif
  
  Return
End
