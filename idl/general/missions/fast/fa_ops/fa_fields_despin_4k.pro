;+
; PROCEDURE: FA_FIELDS_DESPIN_4k, V58, V14, V1458, phase=phase, fudge=fudge,
;     shadow_notch=shadow_notch, mag_notch=mag_notch, store=store, time=time,
;     save_mem=save_mem, spec=spec
;       
;
; PURPOSE: A high level routine which produces despun DC efield
;          data from sdt _4k data in SDT.
;
; INPUT: 
;       V58 -         If blank, program will get V5-V8_4k. 
;       V14 -         If blank, program will get V1-V4_4k
;       V1458 -       If blank, program will get V1+V4-V5-V8_4k
;
; KEYWORDS: 
;       shadow -      Notch out shadow pulses.           DEFAULT = 0
;       mag -         Notch out mag pulses.              DEFAULT = 0
;       store -       Store data as a tplot file.        DEFAULT = 1
;       time -        OPTIONAL. The time range of data.  DEFAULT = /all
;       save_mem -    BLOWS AWAY ARRAYS THAT ARE NO
;                     LONGER NEEDED                      DEFAULT = 0
;                     DEFAULT = 1 if V58, V14, V1458, 
;                     and phase are not given.
;
;       spec -        Will create a FFT spectra.         DEFAULT = 0
;
; CALLING: fa_fields_despin_4k
;       That's easy! Now you can plot E_near_B and E_along_V.
;
; IMPORTANT! SDT SETUP: Need to have: V5-V8_4k, V1-V4_4k, and
;                       V1458_4k, 1032_spinphase, 1032_spinnum, and
;                       1032_magphase.
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
Pro fa_fields_despin_4k, V58, V14, V1458, phase=phase, fudge=fudge, $
                         shadow_notch=shadow_notch, mag_notch=mag_notch, store=store, $
                         time=time, save_mem=save_mem, spec=spec

; Set up constants.
  two_pi = 2.d*!dpi
  if not keyword_set(V58) AND not keyword_set(V14) AND $
     not keyword_set(V1458) AND not keyword_set(phase) then save_mem=1
  if n_elements(time) NE 2 then time=0

;No need for save_mem, jmm, 2025-09-23
  save_mem=0b
  
; First set up V58.
  IF not keyword_set(V58) then BEGIN
     if keyword_set(time) then $
        V58 = get_fa_fields('V5-V8_4k',time(0),time(1),/repair) else $
           V58 = get_fa_fields('V5-V8_4k',/all,/rep)
     IF data_type(V58) ne 8 then BEGIN
        message, /info, "Cannot get V5-V8_4k. Check SDT setup."
;        return
     ENDIF
  ENDIF

; Next set up V14.
  IF not keyword_set(V14) then BEGIN
     if keyword_set(time) then $
        V14 = get_fa_fields('V1-V4_4k',time(0),time(1),/repair) else $
           V14 = get_fa_fields('V1-V4_4k',/all,/repair)
     IF data_type(V14) ne 8 then BEGIN
        message, /info, "Cannot get V1-V4_4k. Check SDT setup."
;        return
     ENDIF
  ENDIF

; Next set up V1458.
  IF not keyword_set(V1458) then BEGIN
     if keyword_set(time) then $
        V1458 = $
        get_fa_fields('V1+V4-V5+V8_4k',time(0),time(1),/repair) else $
           V1458 = get_fa_fields('V1+V4-V5+V8_4k',/all,/repair)
     IF data_type(V1458) ne 8 then BEGIN
        message, /info, "Cannot get V1+V4-V5-V8_4k. Check SDT setup."
;        return
     ENDIF
  ENDIF

; Set up the phase.
  IF not keyword_set(phase) then BEGIN
     phase = get_fa_fields('SMPhase_1055',/all)
     phase = fa_fields_phase(phase, freq=0.01)
     IF data_type(phase) ne 8 then BEGIN
        message, /info, "Cannot get 1055 phase. Check SDT setup."
;        return
     ENDIF
  ENDIF

; SET UP FUDGE FACTOR
  if not keyword_set(fudge) then fudge = 0.4209d

;
; Begin the combine process. Do not add to structure. Save some space.
; 
  If(v14.valid Eq 1 And v58.valid Eq 1) Then Begin
    
     time_offset = 9.1552734e-05 < (v14.time[0] - v58.time[0])

; Combine V14
     fa_fields_combine,V58,V14,result=v14_dat, time_offset=time_offset
     if keyword_set(save_mem) then V14 = 0

; Combine V1458
     fa_fields_combine,V58,V1458,result=v158_dat, time_offset=time_offset 
     if keyword_set(save_mem) then V1458 = 0
     V158_dat = (v14_dat + v158_dat) * fudge
     if keyword_set(save_mem) then V14_dat = 0

; Check to see if phases are needed.
     fa_fields_combine, V58, phase, result=Bphase, /interp, delt=1000.

;  if keyword_set(shadow_notch) then fa_fields_combine, $
;     V58, phase, tag_2='comp2', result=Sphase, /interp, delt=1000.
;needed to save phase
     fa_fields_combine, V58, phase, tag_2='comp2', result=Sphase, /interp, delt=1000.

; Save some space
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
     store_data,'fa_e_near_b_4k', data=data
     dlimit = {spec:0, ystyle:1, yrange:[-1000.,1000.],  $
               ytitle:'E NEAR B!C!C(mV/m)',$
               panel_size:3}
     store_data,'fa_e_near_b_4k', dlimit=dlimit

     data = {x:time+start_time, y:e2}
     store_data,'fa_e_along_v_4k', data=data
     dlimit = {spec:0, ystyle:1, yrange:[-1000.,1000.],  $
               ytitle:'E ALONG V!C!C(mV/m)',$
               panel_size:3}
     store_data,'fa_e_along_v_4k', dlimit=dlimit

     data = {x:time+start_time, y:v158_dat}
     store_data,'fa_e1458_4k', data=data
     dlimit = {spec:0, ystyle:1, $
               ytitle:'E1458(mV/m)'}
     store_data,'fa_e1458_4k', dlimit=dlimit
  
     data = {x:time+start_time, y:v58_dat}
     store_data,'fa_e58_4k', data=data
     dlimit = {spec:0, ystyle:1, $
               ytitle:'E58(mV/m)'}
     store_data,'fa_e58_4k', dlimit=dlimit

;Add other variables, store phases
     data = {x:time+start_time, y:(bphase Mod (2.0*!dpi))}
     store_data,'fa_bphase_4k', data=data
     dlimit = {spec:0, ystyle:1, $
               ytitle:'BPHASE'}
     store_data,'fa_bphase_4k', dlimit=dlimit

     data = {x:time+start_time, y:(sphase Mod (2.0*!dpi))}
     store_data,'fa_sphase_4k', data=data
     dlimit = {spec:0, ystyle:1, $
               ytitle:'SPHASE'}
     store_data,'fa_sphase_4k', dlimit=dlimit
  Endif Else Begin
     message, /info, "Missing v14 or v58 data"
     time = -1 ;No process if time stays -1
;     return
  Endelse

;And voltages, need to change units from mV/m to volts on differences
;get boom lengths
  v12x = get_fa_fields('V1-V2_4k')
  v14x = get_fa_fields('V1-V4_4k')
  v58x = get_fa_fields('V5-V8_4k')
  v56x = get_fa_fields('V5-V6_4k')
  v57x = get_fa_fields('V5-V7_4k')
  v68x = get_fa_fields('V6-V8_4k')
  v78x = get_fa_fields('V7-V8_4k')
  v2x = get_fa_fields('V2_4k')
  v6x = get_fa_fields('V6_4k')
  v7x = get_fa_fields('V7_4k')
  v9x = get_fa_fields('V9_4k')
  v10x = get_fa_fields('V10_4k')
  If(is_struct(v12x) && (v12x.valid Ne 0)) Then t70 = v12x.time[0] $
  Else If(is_struct(v14x) && (v14x.valid Ne 0)) Then t70 = v14x.time[0] $
  Else If(is_struct(v58x) && (v58x.valid Ne 0)) Then t70 = v58x.time[0] $
  Else If(is_struct(v56x) && (v56x.valid Ne 0)) Then t70 = v56x.time[0] $
  Else If(is_struct(v57x) && (v57x.valid Ne 0)) Then t70 = v57x.time[0] $
  Else If(is_struct(v68x) && (v68x.valid Ne 0)) Then t70 = v68x.time[0] $
  Else If(is_struct(v78x) && (v78x.valid Ne 0)) Then t70 = v78x.time[0] $
  Else If(is_struct(v2x) && (v2x.valid Ne 0)) Then t70 = v2x.time[0] $
  Else If(is_struct(v6x) && (v6x.valid Ne 0)) Then t70 = v6x.time[0] $
  Else If(is_struct(v7x) && (v7x.valid Ne 0)) Then t70 = v7x.time[0] $
  Else If(is_struct(v9x) && (v9x.valid Ne 0)) Then t70 = v9x.time[0] $
  Else If(is_struct(v10x) && (v10x.valid Ne 0)) Then t70 = v10x.time[0] $
  Else Begin
     If(n_elements(time) Eq 1 && time[0] Eq -1) Then Begin
        message, /info, "No 4k Data"
        return
     Endif
     t70 = time[0]+start_time
  Endelse
     
;Now boom lengths
  v12l = 0.0 & v14l = 0.0 & v58l = 0.0 & v910l= 0.0
  v24l = 0.0 & v56l = 0.0 & v57l =  0.0 & v68 = 0.0 & v78l = 0.0
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
  Endif Else Begin
     v12l = 0.0 & v14l = 0.0 & v58l = 0.0 & v910l = 0.0
     v24l = 0.0 & v56l = 0.0 & v57l =  0.0 & v68 = 0.0 & v78l = 0.0
  Endelse


  If(is_struct(v12x) && (v12x.valid Ne 0)) Then Begin
     data_v12x = {x:v12x.time, y:v12x.comp1*v12l} ;changed units from mV/m to V
     store_data, 'fa_v1_v2_4k', data = data_v12x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1-V2_4k(V)'}
          store_data,'fa_v1_v2_4k', dlimit=dlimit
  Endif

  If(is_struct(v14x) && (v14x.valid Ne 0)) Then Begin
     data_v14x = {x:v14x.time, y:v14x.comp1*v14l} ;changed units from mV/m to V
     store_data, 'fa_v1_v4_4k', data = data_v14x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V1-V4_4k(V)'}
     store_data,'fa_v1_v4_4k', dlimit=dlimit
  Endif

  If(is_struct(v58x) && (v58x.valid Ne 0)) Then Begin
     data_v58x = {x:v58x.time, y:v58x.comp1*v58l} ;changed units from mV/m to V
     store_data, 'fa_v5_v8_4k', data = data_v58x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V5-V8_4k(V)'}
     store_data,'fa_v5_v8_4k', dlimit=dlimit
  Endif

  If(is_struct(v56x) && (v56x.valid Ne 0)) Then Begin
     data_v56x = {x:v56x.time, y:v56x.comp1*v56l} ;changed units from mV/m to V
     store_data, 'fa_v5_v6_4k', data = data_v56x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V5-V6_4k(V)'}
     store_data,'fa_v5_v6_4k', dlimit=dlimit
  Endif

  If(is_struct(v57x) && (v57x.valid Ne 0)) Then Begin
     data_v57x = {x:v57x.time, y:v57x.comp1*v57l} ;changed units from mV/m to V
     store_data, 'fa_v5_v7_4k', data = data_v57x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V5-V7_4k(V)'}
     store_data,'fa_v5_v7_4k', dlimit=dlimit
  Endif

  If(is_struct(v68x) && (v68x.valid Ne 0)) Then Begin
     data_v68x = {x:v68x.time, y:v68x.comp1*v68l} ;changed units from mV/m to V
     store_data, 'fa_v6_v8_4k', data = data_v68x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V6-V8_4k(V)'}
     store_data,'fa_v6_v8_4k', dlimit=dlimit
  Endif

  If(is_struct(v78x) && (v78x.valid Ne 0)) Then Begin
     data_v78x = {x:v78x.time, y:v78x.comp1*v78l} ;changed units from mV/m to V
     store_data, 'fa_v7_v8_4k', data = data_v78x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V7-V8_4k(V)'}
     store_data,'fa_v7_v8_4k', dlimit=dlimit
  Endif

  If(is_struct(v2x) && (v2x.valid Ne 0)) Then Begin
     data_v2x = {x:v2x.time, y:v2x.comp1}
     store_data, 'fa_v2_4k', data = data_v2x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V2_4k(V)'}
     store_data,'fa_v2_4k', dlimit=dlimit
  Endif

  If(is_struct(v6x) && (v6x.valid Ne 0)) Then Begin
     data_v6x = {x:v6x.time, y:v6x.comp1}
     store_data, 'fa_v6_4k', data = data_v6x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V6_4k(V)'}
     store_data,'fa_v6_4k', dlimit=dlimit
  Endif

  If(is_struct(v7x) && (v7x.valid Ne 0)) Then Begin
     data_v7x = {x:v7x.time, y:v7x.comp1}
     store_data, 'fa_v7_4k', data = data_v7x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V7_4k(V)'}
     store_data,'fa_v7_4k', dlimit=dlimit
  Endif

  If(is_struct(v9x) && (v9x.valid Ne 0)) Then Begin
     data_v9x = {x:v9x.time, y:v9x.comp1}
     store_data, 'fa_v9_4k', data = data_v9x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V9_4k(V)'}
     store_data,'fa_v9_4k', dlimit=dlimit
  Endif

  If(is_struct(v10x) && (v10x.valid Ne 0)) Then Begin
     data_v10x = {x:v10x.time, y:v10x.comp1}
     store_data, 'fa_v10_4k', data = data_v10x
     dlimit = {spec:0, ystyle:1, $
               ytitle:'V10_4k(V)'}
     store_data,'fa_v10_4k', dlimit=dlimit
  Endif

;tplot,['E_NEAR_B_4k','E_ALONG_V_4k']


; 
; OPTIONAL SPECTRA SECTION
;
if not keyword_set(spec) then return

;
; FIRST PARALLEL COMPONENT
;

e4k = {time: time+start_time, units_name: 'mV/m', comp1: e1, valid: 1l,$
        data_name: 'Eparl', project_name: 'FAST', calibrated: 1l}

result = fa_fields_fft(e4k, nave=nave, slide=slide, npts=nfft)

data   = {x:result.time, y:alog10(result.comp1), v:result.yaxis}
store_data,'fa_vlf_epar_4k', data=data

options,'fa_vlf_epar_4k','spec',1
options,'fa_vlf_epar_4k','panel_size',5
options,'fa_vlf_epar_4k','ystyle',1
options,'fa_vlf_epar_4k','ylog',1
options,'fa_vlf_epar_4k','yrange',[0.008, 4.0]
options,'fa_vlf_epar_4k','ytitle','LF EnearB!C!C(kHz)'
options,'fa_vlf_epar_4k','zstyle',1
options,'fa_vlf_epar_4k','zrange',[-12,-2]
options,'fa_vlf_epar_4k','ztitle','Log (V/m)!U2!N/Hz'
options,'fa_vlf_epar_4k','y_no_interp',1
options,'fa_vlf_epar_4k','x_no_interp',1


store_data,'fa_vlf_epar_4k_fch',data=['fa_vlf_epar_4k','FCH']
options,'fa_vlf_epar_4k_fch','panel_size',5

;
; NEXT PERP COMPONENT
;

e4k = {time: time+start_time, units_name: 'mV/m', comp1: e2, valid: 1l,$
        data_name: 'Eperp', project_name: 'FAST', calibrated: 1l}

result = fa_fields_fft(e4k, nave=nave, slide=slide, npts=nfft)

data   = {x:result.time, y:alog10(result.comp1), v:result.yaxis}
store_data,'fa_vlf_eperp_4k', data=data

options,'fa_vlf_eperp_4k','spec',1
options,'fa_vlf_eperp_4k','panel_size',5
options,'fa_vlf_eperp_4k','ystyle',1
options,'fa_vlf_eperp_4k','ylog',1
options,'fa_vlf_eperp_4k','yrange',[0.008, 4.0]
options,'fa_vlf_eperp_4k','ytitle','LF Eperp!C!C(kHz)'
options,'fa_vlf_eperp_4k','zstyle',1
options,'fa_vlf_eperp_4k','zrange',[-12,-2]
options,'fa_vlf_eperp_4k','ztitle','Log (V/m)!U2!N/Hz'
options,'fa_vlf_eperp_4k','y_no_interp',1
options,'fa_vlf_eperp_4k','x_no_interp',1


store_data,'fa_vlf_eperp_4k_fch',data=['fa_vlf_eperp_4k','FCH']
options,'fa_vlf_eperp_4k_fch','panel_size',5


tplot, ['fa_vlf_epar_4k_fch','fa_vlf_eperp_4k_fch']
return
end
