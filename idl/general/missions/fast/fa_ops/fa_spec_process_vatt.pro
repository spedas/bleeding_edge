;+
;NAME:
;fa_spec_process_vatt
;PURPOSE:
;Fills variable attributes for FAST SFa, Dsp variables.
;CALLING SEQUENCE:
;vatt = fa_spec_process_vatt(var)
;INPUT:
;var = a variable name
;OUTPUT:
;vatt = variable attributes, suitable for ISTP compliant CDF files
;      E.G.
;     vatt_str = {CATDESC:'NA', $
;                 DISPLAY_TYPE:'time_series', $
;                 FIELDNAM:'NA', $
;                 FORMAT:'E25.18', $
;                 LABLAXIS:'NA', $;
;                 UNITS:'undefined', $
;                 VAR_TYPE:'data', $
;                 FILLVAL:!values.d_nan, $
;                 VALIDMIN:-10000.0, $
;                 VALIDMAX:10000.0, $
;                 DEPEND_0:'Epoch'}
;HISTORY:
; 2025-10-28, jmm, Hacked from fa_dsepin_process.pro
; jimm@ssl.berkeley.edu
;-
Function fa_spec_process_vatt, var

  vatt = {CATDESC:'NA', $
          DISPLAY_TYPE:'time_series', $
          FIELDNAM:'NA', $
          FORMAT:'E25.18', $
          LABLAXIS:'NA', $      ;        STRING    'E NEAR B!C!C(mV/m)'
          UNITS:'undefined', $
          VAR_TYPE:'data', $
          FILLVAL:!values.d_nan, $
          VALIDMIN:-10.0, $
          VALIDMAX:10.0, $
          DEPEND_0:'Epoch'}

  vatt.fieldnam = var
;DSP
  If(strmid(var,0,11) Eq 'fa_dspadc_m') Then Begin
     vatt.units = 'Log(nT^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,11) Eq 'fa_dspadc_n') Then Begin
     vatt.units = 'Log(#/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,11) Eq 'fa_dspadc_v') Then Begin
     X1 = strpos(var, 'trk')
     If(x1[0] Ne -1) Then vatt.units = '#/Hz' $
     Else vatt.units = 'Log(V^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,11) Eq 'fa_dspadc_e') Then Begin
     vatt.units = 'Log((V/m)^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,12) Eq 'fa_dsphsbm_m') Then Begin
     vatt.units = 'Log(nT^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,12) Eq 'fa_dsphsbm_n') Then Begin
     vatt.units = 'Log(#/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,12) Eq 'fa_dsphsbm_v') Then Begin
     X1 = strpos(var, 'trk')
     If(x1[0] Ne -1) Then vatt.units = '#/Hz' $
     Else vatt.units = 'Log(V^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,12) Eq 'fa_dsphsbm_e') Then Begin
     vatt.units = 'Log((V/m)^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
;SFA
  Endif Else If(strmid(var,0,11) Eq 'fa_sfaave_m') Then Begin
     vatt.units = 'Log(nT^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,11) Eq 'fa_sfaave_e') Then Begin
     vatt.units = 'Log((V/m)^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,13) Eq 'fa_sfaburst_m') Then Begin
     vatt.units = 'Log(nT^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else If(strmid(var,0,13) Eq 'fa_sfaburst_e') Then Begin
     vatt.units = 'Log((V/m)^2/Hz)'
     vatt.lablaxis = var+' '+vatt.units
  Endif Else Begin
     vatt.units = '#/Hz'
     vatt.lablaxis = var+' '+vatt.units
  Endelse
  Case var Of
;DSP variables:
     'fa_dspadc_mag3ac': vatt.catdesc = 'FAST DSP (Digital Signal Processor) AC Magnetic field spectral density'
     'fa_dspadc_ne2': vatt.catdesc = 'FAST DSP (Digital Signal Processor) Ne2 (probe 2 density) spectral density'
     'fa_dspadc_ne3': vatt.catdesc = 'FAST DSP (Digital Signal Processor) Ne3 (probe 3 density) spectral density'
     'fa_dspadc_ne6': vatt.catdesc = 'FAST DSP (Digital Signal Processor) Ne6 (probe 6 density) spectral density'
     'fa_dspadc_ne7': vatt.catdesc = 'FAST DSP (Digital Signal Processor) Ne7 (probe 7 density) spectral density'
     'fa_dspadc_v1': vatt.catdesc = 'FAST DSP (Digital Signal Processor) V1 (probe 1 voltage) spectral density'
     'fa_dspadc_v2': vatt.catdesc = 'FAST DSP (Digital Signal Processor) V2 (probe 2 voltage) spectral density'
     'fa_dspadc_v3': vatt.catdesc = 'FAST DSP (Digital Signal Processor) V3 (probe 3 voltage) spectral density'
     'fa_dspadc_v4': vatt.catdesc = 'FAST DSP (Digital Signal Processor) V4 (probe 4 voltage) spectral density'
     'fa_dspadc_v5': vatt.catdesc = 'FAST DSP (Digital Signal Processor) V5 (probe 5 voltage) spectral density'
     'fa_dspadc_v6': vatt.catdesc = 'FAST DSP (Digital Signal Processor) V6 (probe 6 voltage) spectral density'
     'fa_dspadc_v7': vatt.catdesc = 'FAST DSP (Digital Signal Processor) V7 (probe 7 voltage) spectral density'
     'fa_dspadc_v8': vatt.catdesc = 'FAST DSP (Digital Signal Processor) V8 (probe 8 voltage) spectral density'
     'fa_dspadc_e12': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e12 (boom pair 1,2 electric field) spectral density'
     'fa_dspadc_e12hg': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e12HG (boom pair 1,2 HG electric field) spectral density'
     'fa_dspadc_e14': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e14 (boom pair 1,4 electric field) spectral density'
     'fa_dspadc_e14hg': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e14HG (boom pair 1,4 HG electric field) spectral density'
     'fa_dspadc_v12trk': vatt.catdesc = 'FAST DSP (Digital Signal Processor) v12TRK (boom pair 1,2 TRK) spectral density'
     'fa_dspadc_v14trk': vatt.catdesc = 'FAST DSP (Digital Signal Processor) v14TRK (boom pair 1,4 TRK) spectral density'
     'fa_dspadc_e34': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e34 (boom pair 3,4 electric field) spectral density'
     'fa_dspadc_e34hg': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e34HG (boom pair 3,4 HG electric field) spectral density'
     'fa_dspadc_e56': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e56 (boom pair 5,6 electric field) spectral density'
     'fa_dspadc_e58': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e58 (boom pair 5,8 electric field) spectral density'
     'fa_dspadc_e58hg': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e58HG (boom pair 5,8 HG electric field) spectral density'
     'fa_dspadc_e78': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e78 (boom pair 7,8 electric field) spectral density'
     'fa_dspadc_e910': vatt.catdesc = 'FAST DSP (Digital Signal Processor) e910 (boom pair 9,10 electric field) spectral density'
     'fa_dspadc_e910trk': vatt.catdesc = 'FAST DSP (Digital Signal Processor) v910TRK (boom pair 9,10 TRK) spectral density'
     'fa_dspadc_eomni': vatt.catdesc = 'FAST DSP (Digital Signal Processor) EOMNI (OmniDirectional, e14-e58) spectral density'
     'fa_dspadc_eomnihg': vatt.catdesc = 'FAST DSP (Digital Signal Processor) EOMNIHG (OmniDirectional, e14hg-e58hg) spectral density'
     'fa_dsphsbm_mag3ac': vatt.catdesc = 'FAST DSP (Digital Signal Processor) HSBM (High Speed Burst memory) AC Magnetic field spectral density'
     'fa_dsphsbm_e12': vatt.catdesc = 'FAST DSP (Digital Signal Processor) HSBM (High Speed Burst memory) e12 (boom pair 1,2 HG electric field) spectral density'
     'fa_dsphsbm_e14': vatt.catdesc = 'FAST DSP (Digital Signal Processor) HSBM (High Speed Burst memory) e14 (boom pair 1,4 electric field) spectral density'
     'fa_dsphsbm_e34': vatt.catdesc = 'FAST DSP (Digital Signal Processor) HSBM (High Speed Burst memory) e34 (boom pair 3,4 electric field) spectral density'
     'fa_dsphsbm_e56': vatt.catdesc = 'FAST DSP (Digital Signal Processor) HSBM (High Speed Burst memory) e56 (boom pair 5,6 electric field) spectral density'
     'fa_dsphsbm_e58': vatt.catdesc = 'FAST DSP (Digital Signal Processor) HSBM (High Speed Burst memory) e58 (boom pair 5,8 electric field) spectral density'
     'fa_dsphsbm_e78': vatt.catdesc = 'FAST DSP (Digital Signal Processor) HSBM (High Speed Burst memory) e78 (boom pair 7,8 electric field) spectral density'
     'fa_dsphsbm_e910': vatt.catdesc = 'FAST DSP (Digital Signal Processor) HSBM (High Speed Burst memory) e910 (boom pair 9,10 electric field) spectral density'
;SFA variables
     'fa_sfaave_mag3ac': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) AC Magnetic field spectral density'
     'fa_sfaave_e12': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) e12 (boom pair 1,2 electric field) spectral density'
     'fa_sfaave_e14': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) e14 (boom pair 1,4 electric field) spectral density'
     'fa_sfaave_e34': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) e34 (boom pair 3,4 electric field) spectral density'
     'fa_sfaave_e56': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) e56 (boom pair 5,6 electric field) spectral density'
     'fa_sfaave_e58': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) e58 (boom pair 5,8 electric field) spectral density'
     'fa_sfaave_e78': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) e78 (boom pair 7,8 electric field) spectral density'
     'fa_sfaave_e910': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) e910 (boom pair 9,10 electric field) spectral density'
     'fa_sfaave_eomni': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) OMNI (OmniDirectional, e14-e58) spectral density'
     'fa_sfaburst_mag3ac': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) Burst AC Magnetic field spectral density'
     'fa_sfaburst_e12': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) Burst e12 (boom pair 1,2 electric field) spectral density'
     'fa_sfaburst_e14': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) Burst e14 (boom pair 1,4 electric field) spectral density'
     'fa_sfaburst_e34': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) Burst e34 (boom pair 3,4 electric field) spectral density'
     'fa_sfaburst_e56': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) Burst e56 (boom pair 5,6 electric field) spectral density'
     'fa_sfaburst_e58': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) Burst e58 (boom pair 5,8 electric field) spectral density'
     'fa_sfaburst_e78': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) Burst e78 (boom pair 7,8 electric field) spectral density'
     'fa_sfaburst_e910': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) Burst e910 (boom pair 9,10 electric field) spectral density'
     'fa_sfaburst_eomni': vatt.catdesc = 'FAST SFA (Swept Frequency Analyzer) Burst OMNI (OmniDirectional, e14-e58) spectral density'
     Else : Begin
        message, /info, 'No case match for: '+var
     End

  Endcase

  Return, vatt
End
