;+
; PROCEDURE: FA_FIELDS_DESPIN_16k, V58, V14, V1458, phase=phase, fudge=fudge,
;     shadow_notch=shadow_notch, mag_notch=mag_notch, store=store,
;     save_mem=save_mem, t1=t1, t2=t2, nave=nave, slide=slide, nfft=nfft,
;     spec=spec
;       
;
; PURPOSE: A high level routine which produces despun DC efield
;          data from sdt _16k data in SDT.
;
; INPUT: 
;       V58 -         If not set, program will get V5-V8_16k. 
;       V14 -         If not set, program will get V1-V4_16k
;       V1458 -       If not set, program will get V1+V4-V5-V8_16k
;
; KEYWORDS: 
;       t1 -          Optional start time.
;       t2 -          Optional end time.
;       shadow -      Notch out shadow pulses.           DEFAULT = 0
;       mag -         Notch out mag pulses.              DEFAULT = 0
;       store -       Store data as a tplot file.        DEFAULT = 1
;       time -        OPTIONAL. The time range of data.  DEFAULT = /all
;       save_mem -    BLOWS AWAY ARRAYS THAT ARE NO
;                     LONGER NEEDED                      DEFAULT = 0
;                     DEFAULT = 1 if V58, V14, V1458, 
;                       and phase are not given.
;       spec -        Will create a FFT spectra.         DEFAULT = 0
;       nave -        FFT spectra.        		 DEFAULT = 4
;       slide -       FFT spectra.        		 DEFAULT = 0.5
;       nfft -        FFT spectra.        		 DEFAULT = 1024
;
; CALLING: fa_fields_despin_16k
;       That's easy! Now you can plot E_near_B and E_along_V.
;
; IMPORTANT! SDT SETUP: Need to have: V5-V8_16k, V1-V4_16k, and
;                       V1458_16k, 1048_spinphase, 1048_spinnum, and
;                       1048_magphase.
;
; OUTPUT: Dat is IDL fields time series data structure with multiple
;         components. This  
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
Pro fa_fields_despin_16k, V58, V14, V1458, phase=phase, fudge=fudge, $
                          shadow_notch=shadow_notch, mag_notch=mag_notch, store=store, $
                          t1=t1, t2=t2, save_mem=save_mem, nave=nave, slide=slide, nfft=nfft, $
                          spec=spec

; Set up constants.
  two_pi = 2.d*!dpi
  if not keyword_set(V58) AND not keyword_set(V14) AND $
     not keyword_set(V1458) AND not keyword_set(phase) then save_mem=1
  if n_elements(time) NE 2 then time=0
 
;No need for save_mem, jmm, 2025-09-23
  save_mem=0b

; First set up V58.
  IF not keyword_set(V58) then BEGIN
     V58 = get_fa_fields('V5-V8_16k',t1,t2,/repair)
     IF V58.valid ne 1 then BEGIN
        message, /info, "Cannot get V5-V8_16k. Check SDT setup."
;        return
     ENDIF
  ENDIF

; Next set up V14.
  IF not keyword_set(V14) then BEGIN
     V14 = get_fa_fields('V1-V4_16k',t1,t2,/repair)
     IF V14.valid ne 1 then BEGIN
        message, /info, "Cannot get V1-V4_16k. Check SDT setup."
;        return
     ENDIF
  ENDIF

; Next set up V1458.
  IF not keyword_set(V1458) then BEGIN
     V1458 = get_fa_fields('V1+V4-V5+V8_16k',t1,t2,/repair)
     IF V1458.valid ne 1 then BEGIN
        message, /info, "Cannot get V1+V4-V5-V8_16k. Check SDT setup."
;        return
     ENDIF
  ENDIF

; Set up the phase.
  IF not keyword_set(phase) then BEGIN
     phase = get_fa_fields('SMPhase_1048',/all)
     phase = fa_fields_phase(phase, freq=0.01)
     IF phase.valid ne 1 then BEGIN
        message, /info, "Cannot get 1048 phase. Check SDT setup."
;        return
     ENDIF
  ENDIF

; SET UP FUDGE FACTOR
  if not keyword_set(fudge) then fudge = 0.4209d

;
; Begin the combine process. Do not add to structure. Save some space.
; 
  time_offset = 0.0d
  If(v14.valid Eq 1 And v58.valid Eq 1) Then Begin
; Combine V14
     fa_fields_combine,V58,V14,result=v14_dat, time_offset=time_offset
     if keyword_set(save_mem) then V14 = 0
  Endif

; Combine V1458
  If(v58.valid Eq 1 And v1458.valid Eq 1) Then Begin
     fa_fields_combine,V58,V1458,result=v158_dat, time_offset=time_offset 
     if keyword_set(save_mem) then V1458 = 0
     V158_dat = (v14_dat + v158_dat) * fudge
     if keyword_set(save_mem) then V14_dat = 0
  Endif

; Check to see if phases are needed.
  If(v58.valid Eq 1 And phase.valid Eq 1) Then Begin  
     fa_fields_combine, V58, phase, result=Bphase, /interp, delt=1000.
     fa_fields_combine, V58, phase, tag_2='comp2', result=Sphase, /interp, delt=1000.
  Endif

; Save some space
  If(v14.valid Eq 1 And v58.valid Eq 1 And v1458.valid Eq 1) Then Begin
     start_time = v58.start_time
     time = v58.time-start_time
     v58_dat = v58.comp1
     npts=v58.npts
     if keyword_set(save_mem) then v58 = 0

; We now have time, V58_dat, V158_dat, Bphase, and Sphase
; Notch the data
     if keyword_set(mag_notch) then $
        notch58 = ff_notch('V58',V58_dat,Bphase=Bphase,/Binterp)
     if keyword_set(mag_notch) then $
        notch158 = ff_notch('V158',V158_dat,Bphase=Bphase,/Binterp)
     if keyword_set(shadow_notch) then $
        notch58 = ff_notch('V58',V58_dat,Sphase=Sphase,/Snan)
     if keyword_set(shadow_notch) then $
        notch158 = ff_notch('V158',V158_dat,Sphase=Sphase,/Snan)
     notch58 = 0
     notch158 = 0

;
; DO THE DESPIN
;

     dphi = 2.d*!dpi*52.d/360.d
     e1 = -v58_dat*cos(Bphase-dphi) - v158_dat*sin(Bphase-dphi)
     e2 = -v58_dat*sin(Bphase-dphi) + v158_dat*cos(Bphase-dphi)

; STORE THE DATA IN TPLOT FORMAT
     data = {x:time+start_time, y:e1}
     store_data,'fa_e_near_b_16k', data=data
     dlimit = {spec:0, ystyle:1, yrange:[-2000.,2000.],  $
               ytitle:'E NEAR B!C!C(mV/m)',$
               panel_size:3}
     store_data,'fa_e_near_b_16k', dlimit=dlimit
     options,'fa_e_near_b_16k','yticks',4
     options,'fa_e_near_b_16k','ytickname',['-2000','-1000','0','1000','2000']
     options,'fa_e_near_b_16k','ytickv',[-2000, -1000, 0, 1000, 2000]

     data = {x:time+start_time, y:v158_dat}
     store_data,'fa_e1458_16k', data=data
     dlimit = {spec:0, ystyle:1, $
               ytitle:'E1458(mV/m)'}
     store_data,'fa_e1458_16k', dlimit=dlimit
  
     data = {x:time+start_time, y:v58_dat}
     store_data,'fa_e58_16k', data=data
     dlimit = {spec:0, ystyle:1, $
               ytitle:'E58(mV/m)'}
     store_data,'fa_e58_16k', dlimit=dlimit

     data = {x:time+start_time, y:e2}
     store_data,'fa_e_along_v_16k', data=data
     dlimit = {spec:0, ystyle:1, yrange:[-2000.,2000.],  $
               ytitle:'E PERP-SP!C!C(mV/m)',$
               panel_size:3}
     store_data,'fa_e_along_v_16k', dlimit=dlimit
     options,'fa_e_along_v_16k','yticks',4
     options,'fa_e_along_v_16k','ytickname',['-2000','-1000','0','1000','2000']
     options,'fa_e_along_v_16k','ytickv',[-2000, -1000, 0, 1000, 2000]

;Add other variables, store phases
     data = {x:time+start_time, y:(bphase Mod (2.0*!dpi))}
     store_data,'fa_bphase_16k', data=data
     dlimit = {spec:0, ystyle:1, $
               ytitle:'BPHASE'}
     store_data,'fa_bphase_16k', dlimit=dlimit

     data = {x:time+start_time, y:(sphase Mod (2.0*!dpi))}
     store_data,'fa_sphase_16k', data=data
     dlimit = {spec:0, ystyle:1, $
               ytitle:'SPHASE'}
     store_data,'fa_sphase_16k', dlimit=dlimit
  Endif Else Begin
     message, /info, "No Despun fields"
     time = -1
  Endelse

;grab the rest of the possible variables
  v12x = get_fa_fields('V1-V2_16k')  
  v13x = get_fa_fields('V1-V3_16k')
  v14x = get_fa_fields('V1-V4_16k')
  v24x = get_fa_fields('V2-V4_16k')
  v34x = get_fa_fields('V3-V4_16k')
  v58x = get_fa_fields('V5-V8_16k')
  v56x = get_fa_fields('V5-V6_16k')
  v57x = get_fa_fields('V5-V7_16k')
  v68x = get_fa_fields('V6-V8_16k')
  v78x = get_fa_fields('V7-V8_16k')
  v910x = get_fa_fields('V9-V10_16k')
  v12hgx = get_fa_fields('V1-V2HG_16k')
  v14hgx = get_fa_fields('V1-V4HG_16k')
  v34hgx = get_fa_fields('V3-V4HG_16k')
  v58hgx = get_fa_fields('V5-V8HG_16k')
  v1x = get_fa_fields('V1_16k')
  v2x = get_fa_fields('V2_16k')
  v3x = get_fa_fields('V3_16k')
  v4x = get_fa_fields('V4_16k')
  v5x = get_fa_fields('V5_16k')
  v6x = get_fa_fields('V6_16k')
  v7x = get_fa_fields('V7_16k')
  v9x = get_fa_fields('V9_16k')
  If(is_struct(v12x) && (v12x.valid Ne 0)) Then t70 = v12x.time[0] $
  Else If(is_struct(v13x) && (v13x.valid Ne 0)) Then t70 = v13x.time[0] $
  Else If(is_struct(v14x) && (v14x.valid Ne 0)) Then t70 = v14x.time[0] $
  Else If(is_struct(v24x) && (v24x.valid Ne 0)) Then t70 = v24x.time[0] $
  Else If(is_struct(v34x) && (v34x.valid Ne 0)) Then t70 = v34x.time[0] $
  Else If(is_struct(v58x) && (v58x.valid Ne 0)) Then t70 = v58x.time[0] $
  Else If(is_struct(v56x) && (v56x.valid Ne 0)) Then t70 = v56x.time[0] $
  Else If(is_struct(v57x) && (v57x.valid Ne 0)) Then t70 = v57x.time[0] $
  Else If(is_struct(v68x) && (v68x.valid Ne 0)) Then t70 = v68x.time[0] $
  Else If(is_struct(v78x) && (v78x.valid Ne 0)) Then t70 = v78x.time[0] $
  Else If(is_struct(v910x) && (v910x.valid Ne 0)) Then t70 = v910x.time[0] $
  Else If(is_struct(v12hgx) && (v12hgx.valid Ne 0)) Then t70 = v12hgx.time[0] $
  Else If(is_struct(v14hgx) && (v14hgx.valid Ne 0)) Then t70 = v14hgx.time[0] $
  Else If(is_struct(v34hgx) && (v34hgx.valid Ne 0)) Then t70 = v34hgx.time[0] $
  Else If(is_struct(v58hgx) && (v58hgx.valid Ne 0)) Then t70 = v58hgx.time[0] $
  Else If(is_struct(v1x) && (v1x.valid Ne 0)) Then t70 = v1x.time[0] $
  Else If(is_struct(v2x) && (v2x.valid Ne 0)) Then t70 = v2x.time[0] $
  Else If(is_struct(v3x) && (v3x.valid Ne 0)) Then t70 = v3x.time[0] $
  Else If(is_struct(v4x) && (v4x.valid Ne 0)) Then t70 = v4x.time[0] $
  Else If(is_struct(v5x) && (v5x.valid Ne 0)) Then t70 = v5x.time[0] $
  Else If(is_struct(v6x) && (v6x.valid Ne 0)) Then t70 = v6x.time[0] $
  Else If(is_struct(v7x) && (v7x.valid Ne 0)) Then t70 = v7x.time[0] $
  Else If(is_struct(v9x) && (v9x.valid Ne 0)) Then t70 = v9x.time[0] $
  Else Begin
     If(n_elements(time) Eq 1 && time[0] Eq -1) Then Begin
        message, /info, "No 16k Data"
        return
     Endif
     t70 = time[0]+start_time
  Endelse
  
;Now bomm lengths
  v12l = 0.0 & v14l = 0.0 & v58l = 0.0 & v910l= 0.0
  v24l = 0.0 & v56l = 0.0 & v57l =  0.0 & v68l = 0.0 & v78l = 0.0
  v13l = 0.0 & v34l = 0.0
  If(t70 Ge time_double('1997-02-03/10:07:20')) Then Begin
     v12l = 5.0e-3
     v14l = 28.9e-3
     v58l = 56.0e-3
     v910l = 4.05e-3
     v24l = 23.9e-3
     v56l = 5.0e-3
     v57l = 51.0e-3
     v68l = 51.0e-3
     v78l = 5.0e-3
     v13l = 28.3e-3
     v34l = 0.6e-3
  Endif Else If(t70 Ge time_double('1996-09-29/00:00:00')) Then Begin
     v12l = 5.0e-3
     v14l = 28.9e-3
     v58l = 56.0e-3
     v910l = 0.0
     v24l = 23.9e-3
     v56l = 5.0e-3
     v57l = 51.0e-3
     v68l = 51.0e-3
     v78l = 5.0e-3
     v13l = 28.3e-3
     v34l = 0.6e-3
  Endif Else If(t70 Ge time_double('1996-09-15/00:00:00')) Then Begin
     v12l = 5.0e-3
     v14l = 8.6e-3
     v58l = 56.0e-3
     v910l = 0.0
     v24l = 3.6e-3
     v56l = 5.0e-3
     v57l = 51.0e-3
     v68l = 51.0e-3
     v78l = 5.0e-3
     v13l = 8.0e-3
     v34l = 0.6e-3
  Endif Else If(t70 Ge time_double('1996-09-11/00:00:00')) Then Begin
     v12l = 5.0e-3
     v14l = 8.6e-3
     v58l = 16.0e-3
     v910l = 0.0
     v24l = 3.6e-3
     v56l = 5.0e-3
     v57l = 11.0e-3
     v68l = 11.0e-3
     v78l = 5.0e-3
     v13l = 8.0e-3
     v34l = 0.6e-3
  Endif Else If(t70 Ge time_double('1996-09-10/14:16:40')) Then Begin
     v12l = 5.0e-3
     v14l = 6.1e-3
     v58l = 11.0e-3
     v910l = 0.0
     v24l = 1.1e-3
     v56l = 5.0e-3
     v57l = 6.0e-3
     v68l = 6.0e-3
     v78l = 5.0e-3
     v13l = 5.5e-3
     v34l = 0.6e-3
  Endif Else If(t70 Ge time_double('1996-09-03/16:53:40')) Then Begin
     v12l = 5.0e-3
     v14l = 6.1e-3
     v58l = 0.0
     v910l = 0.0
     v24l = 1.1e-3
     v56l = 0.0
     v57l = 0.0
     v68l = 0.0
     v78l = 0.0
     v13l = 5.5e-3
     v34l = 0.6e-3
  Endif Else Begin
     v12l = 0.0 & v14l = 0.0 & v58l = 0.0 & v910l = 0.0
     v24l = 0.0 & v56l = 0.0 & v57l =  0.0 & v68l = 0.0 & v78l = 0.0
     v13l = 0.0 & v34l = 0.0
  Endelse


  If(is_struct(v12x) && (v12x.valid Ne 0)) Then Begin
     data_v12x = {x:v12x.time, y:v12x.comp1*v12l} ;changed units from mV/m to V
     store_data, 'fa_v1_v2_16k', data = data_v12x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1-V2_16k(V)'}
          store_data,'fa_v1_v2_16k', dlimit=dlimit
  Endif

  If(is_struct(v13x) && (v13x.valid Ne 0)) Then Begin
     data_v13x = {x:v13x.time, y:v13x.comp1*v13l} ;changed units from mV/m to V
     store_data, 'fa_v1_v3_16k', data = data_v13x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1-V3_16k(V)'}
     store_data,'fa_v1_v3_16k', dlimit=dlimit
  Endif

  If(is_struct(v14x) && (v14x.valid Ne 0)) Then Begin
     data_v14x = {x:v14x.time, y:v14x.comp1*v14l} ;changed units from mV/m to V
     store_data, 'fa_v1_v4_16k', data = data_v14x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1-V4_16k(V)'}
     store_data,'fa_v1_v4_16k', dlimit=dlimit
  Endif

  If(is_struct(v24x) && (v24x.valid Ne 0)) Then Begin
     data_v24x = {x:v24x.time, y:v24x.comp1*v24l} ;changed units from mV/m to V
     store_data, 'fa_v2_v4_16k', data = data_v24x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V2-V4_16k(V)'}
     store_data,'fa_v2_v4_16k', dlimit=dlimit
  Endif

  If(is_struct(v34x) && (v34x.valid Ne 0)) Then Begin
     data_v34x = {x:v34x.time, y:v34x.comp1*v34l} ;changed units from mV/m to V
     store_data, 'fa_v3_v4_16k', data = data_v34x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V3-V4_16k(V)'}
     store_data,'fa_v3_v4_16k', dlimit=dlimit
  Endif

  If(is_struct(v58x) && (v58x.valid Ne 0)) Then Begin
     data_v58x = {x:v58x.time, y:v58x.comp1*v58l} ;changed units from mV/m to V
     store_data, 'fa_v5_v8_16k', data = data_v58x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V5-V8_16k(V)'}
     store_data,'fa_v5_v8_16k', dlimit=dlimit
  Endif

  If(is_struct(v56x) && (v56x.valid Ne 0)) Then Begin
     data_v56x = {x:v56x.time, y:v56x.comp1*v56l} ;changed units from mV/m to V
     store_data, 'fa_v5_v6_16k', data = data_v56x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V5-V6_16k(V)'}
     store_data,'fa_v5_v6_16k', dlimit=dlimit
  Endif

  If(is_struct(v57x) && (v57x.valid Ne 0)) Then Begin
     data_v57x = {x:v57x.time, y:v57x.comp1*v57l} ;changed units from mV/m to V
     store_data, 'fa_v5_v7_16k', data = data_v57x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V5-V7_16k(V)'}
     store_data,'fa_v5_v7_16k', dlimit=dlimit
  Endif

  If(is_struct(v68x) && (v68x.valid Ne 0)) Then Begin
     data_v68x = {x:v68x.time, y:v68x.comp1*v68l} ;changed units from mV/m to V
     store_data, 'fa_v6_v8_16k', data = data_v68x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V6-V8_16k(V)'}
     store_data,'fa_v6_v8_16k', dlimit=dlimit
  Endif

  If(is_struct(v78x) && (v78x.valid Ne 0)) Then Begin
     data_v78x = {x:v78x.time, y:v78x.comp1*v78l} ;changed units from mV/m to V
     store_data, 'fa_v7_v8_16k', data = data_v78x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V7-V8_16k(V)'}
     store_data,'fa_v7_v8_16k', dlimit=dlimit
  Endif

  If(is_struct(v910x) && (v910x.valid Ne 0)) Then Begin
     data_v910x = {x:v910x.time, y:v910x.comp1*v910l} ;changed units from mV/m to V
     store_data, 'fa_v9_v10_16k', data = data_v910x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V9-V10_16k(V)'}
     store_data,'fa_v9_v10_16k', dlimit=dlimit
  Endif
;What does HG stand for?

  If(is_struct(v12hgx) && (v12hgx.valid Ne 0)) Then Begin
     data_v12hgx = {x:v12hgx.time, y:v12hgx.comp1*v12l} ;changed units from mV/m to V
     store_data, 'fa_v1_v2hg_16k', data = data_v12hgx
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1-V2HG_16k(V)'}
     store_data,'fa_v1_v2hg_16k', dlimit=dlimit
  Endif

  If(is_struct(v14hgx) && (v14hgx.valid Ne 0)) Then Begin
     data_v14hgx = {x:v14hgx.time, y:v14hgx.comp1*v14l} ;changed units from mV/m to V
     store_data, 'fa_v1_v4hg_16k', data = data_v14hgx
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1-V4HG_16k(V)'}
     store_data,'fa_v1_v4hg_16k', dlimit=dlimit
  Endif

  If(is_struct(v34hgx) && (v34hgx.valid Ne 0)) Then Begin
     data_v34hgx = {x:v34hgx.time, y:v34hgx.comp1*v34l} ;changed units from mV/m to V
     store_data, 'fa_v3_v4hg_16k', data = data_v34hgx
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V3-V4HG_16k(V)'}
     store_data,'fa_v3_v4hg_16k', dlimit=dlimit
  Endif

  If(is_struct(v58hgx) && (v58hgx.valid Ne 0)) Then Begin
     data_v58hgx = {x:v58hgx.time, y:v58hgx.comp1*v58l} ;changed units from mV/m to V
     store_data, 'fa_v5_v8hg_16k', data = data_v58hgx
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V5-V8HG_16k(V)'}
     store_data,'fa_v5_v8hg_16k', dlimit=dlimit
  Endif
  
;voltages

  If(is_struct(v1x) && (v1x.valid Ne 0)) Then Begin
     data_v1x = {x:v1x.time, y:v1x.comp1}
     store_data, 'fa_v1_16k', data = data_v1x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1_16k(V)'}
     store_data,'fa_v1_16k', dlimit=dlimit
  Endif

  If(is_struct(v2x) && (v2x.valid Ne 0)) Then Begin
     data_v2x = {x:v2x.time, y:v2x.comp1}
     store_data, 'fa_v2_16k', data = data_v2x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V2_16k(V)'}
     store_data,'fa_v2_16k', dlimit=dlimit
  Endif

  If(is_struct(v3x) && (v3x.valid Ne 0)) Then Begin
     data_v3x = {x:v3x.time, y:v3x.comp1}
     store_data, 'fa_v3_16k', data = data_v3x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V3_16k(V)'}
     store_data,'fa_v3_16k', dlimit=dlimit
  Endif

  If(is_struct(v4x) && (v4x.valid Ne 0)) Then Begin
     data_v4x = {x:v4x.time, y:v4x.comp1}
     store_data, 'fa_v4_16k', data = data_v4x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V4_16k(V)'}
     store_data,'fa_v4_16k', dlimit=dlimit
  Endif

  If(is_struct(v5x) && (v5x.valid Ne 0)) Then Begin
     data_v5x = {x:v5x.time, y:v5x.comp1}
     store_data, 'fa_v5_16k', data = data_v5x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V5_16k(V)'}
     store_data,'fa_v5_16k', dlimit=dlimit
  Endif

  If(is_struct(v6x) && (v6x.valid Ne 0)) Then Begin
     data_v6x = {x:v6x.time, y:v6x.comp1}
     store_data, 'fa_v6_16k', data = data_v6x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V6_16k(V)'}
     store_data,'fa_v6_16k', dlimit=dlimit
  Endif

  If(is_struct(v7x) && (v7x.valid Ne 0)) Then Begin
     data_v7x = {x:v7x.time, y:v7x.comp1}
     store_data, 'fa_v7_16k', data = data_v7x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V7_16k(V)'}
     store_data,'fa_v7_16k', dlimit=dlimit
  Endif

  If(is_struct(v9x) && (v9x.valid Ne 0)) Then Begin
     data_v9x = {x:v9x.time, y:v9x.comp1}
     store_data, 'fa_v9_16k', data = data_v9x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V9_16k(V)'}
     store_data,'fa_v9_16k', dlimit=dlimit
  Endif

;tplot,['fa_e_near_b_16k','fa_e_along_v_16k']

; 
; OPTIONAL SPECTRA SECTION
;
if not keyword_set(spec) then return

;
; SPEC - FIRST PARALLEL COMPONENT
;

e16k = {time: time+start_time, units_name: 'mV/m', comp1: e1, valid: 1l,$
        data_name: 'Eparl', project_name: 'FAST', calibrated: 1l}

result = fa_fields_fft(e16k, nave=nave, slide=slide, npts=nfft)

data   = {x:result.time, y:alog10(result.comp1), v:result.yaxis}
store_data,'VLF_EPAR', data=data

options,'VLF_EPAR','spec',1
options,'VLF_EPAR','panel_size',5
options,'VLF_EPAR','ystyle',1
options,'VLF_EPAR','ylog',1
options,'VLF_EPAR','yrange',[0.032, 16.0]
options,'VLF_EPAR','ytitle','VLF Epar!C!C(kHz)'
options,'VLF_EPAR','zstyle',1
options,'VLF_EPAR','zrange',[-14,-4]
options,'VLF_EPAR','ztitle','Log (V/m)!U2!N/Hz'
options,'VLF_EPAR','y_no_interp',1
options,'VLF_EPAR','x_no_interp',1
options,'VLF_EPAR','yticks',2
options,'VLF_EPAR','ytickname',['0.1','1.0','10.0']
options,'VLF_EPAR','ytickv',[0.1,1.0,10.0]


store_data,'VLF_EPAR_FCH',data=['VLF_EPAR','FCH']
options,'VLF_EPAR_FCH','panel_size',6

;
; NEXT PERP COMPONENT
;

e16k = {time: time+start_time, units_name: 'mV/m', comp1: e2, valid: 1l,$
        data_name: 'Eperp', project_name: 'FAST', calibrated: 1l}

result = fa_fields_fft(e16k, nave=nave, slide=slide, npts=nfft)

data   = {x:result.time, y:alog10(result.comp1), v:result.yaxis}
store_data,'VLF_EPERP', data=data

options,'VLF_EPERP','spec',1
options,'VLF_EPERP','panel_size',5
options,'VLF_EPERP','ystyle',1
options,'VLF_EPERP','ylog',1
options,'VLF_EPERP','yrange',[0.032, 16.0]
options,'VLF_EPERP','ytitle','VLF Eperp!C!C(kHz)'
options,'VLF_EPERP','zstyle',1
options,'VLF_EPERP','zrange',[-14,-4]
options,'VLF_EPERP','ztitle','Log (V/m)!U2!N/Hz'
options,'VLF_EPERP','y_no_interp',1
options,'VLF_EPERP','x_no_interp',1
options,'VLF_EPERP','yticks',2
options,'VLF_EPERP','ytickname',['0.1','1.0','10.0']
options,'VLF_EPERP','ytickv',[0.1,1.0,10.0]


store_data,'VLF_EPERP_FCH',data=['VLF_EPERP','FCH']
options,'VLF_EPERP_FCH','panel_size',6


tplot, ['VLF_EPAR_FCH','VLF_EPERP_FCH']

return
end
