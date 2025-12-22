;+
;NAME:
;fa_despin_process_vatt
;PURPOSE:
;Fills variable attributes for FAST despun Electric Field variables.
;Note that this includes Survey (esv), e4k and e16k variables
;CALLING SEQUENCE:
;vatt = fa_despin_process_vatt(var)
;INPUT:
;var = a variable name
;OUTPUT:
;vatt = variable attributes, suitable for ISTPc compliant CDF files
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
; 2025-09-16, jmm, Hacked from fa_dsepin_process.pro
; jimm@ssl.berkeley.edu
;-
Function fa_despin_process_vatt, var

  vatt = {CATDESC:'NA', $
          DISPLAY_TYPE:'time_series', $
          FIELDNAM:'NA', $
          FORMAT:'E25.18', $
          LABLAXIS:'NA', $      ;        STRING    'E NEAR B!C!C(mV/m)'
          UNITS:'undefined', $
          VAR_TYPE:'data', $
          FILLVAL:!values.d_nan, $
          VALIDMIN:-10000.0, $
          VALIDMAX:10000.0, $
          DEPEND_0:'Epoch'}


  vatt.fieldnam = var
  If(strmid(var,0,4) Eq 'fa_e') Then Begin
     vatt.units = 'mV/m'
     vatt.lablaxis = var+' (mV/m)'           
  Endif Else If(strmid(var,0,1) Eq 'e') Then Begin
     vatt.units = 'mV/m'
     vatt.lablaxis = var+' (mV/m)'
  Endif Else If(strmid(var,0,4) Eq 'fa_v') Then Begin
     vatt.units = 'V'
     vatt.lablaxis = var+' (V)'
  Endif Else If(strmid(var,0,5) Eq 'fa_sc') Then Begin
     vatt.units = 'V'
     vatt.lablaxis = var+' (V)'
  Endif Else If(var Eq 'fa_data_quality') Then Begin
     vatt.units = 'NA'
     vatt.lablaxis = var
  Endif Else If(var Eq 'fa_bphase' Or var Eq 'fa_sphase') Then Begin
     vatt.units = 'radians'
     vatt.lablaxis = var
     vatt.validmin = -10.0
     vatt.validmax = 10.0
  Endif Else If(var Eq 'fa_dsc_gse' Or var Eq 'fa_dsc_gsm') Then Begin
     vatt.units = 'NA'
     vatt.lablaxis = var
  Endif Else If(strpos(var, 'dist') Ne -1) Then Begin
     vatt.units = 'm'
     vatt.lablaxis = var
     vatt.var_type = 'support_data'
     vatt.validmin = 0.0
     vatt.validmax = 100.0
  Endif Else If(var Eq 'fa_probe_phase') Then Begin
     vatt.units = 'radians'
     vatt.lablaxis = var
     vatt.var_type = 'support_data'
     vatt.validmin = -10.0
     vatt.validmax = 10.0
  Endif
           
  Case var Of
;ESV variables     
     'fa_e_near_b': vatt.catdesc = 'FAST Survey mode electric field, in the direction corresponding to zero degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_e_along_v': vatt.catdesc = 'FAST Survey mode electric field, in the direction corresponding to ninety degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_sc_pot': vatt.catdesc = 'FAST Spacecraft Potential'
     'fa_sc_pot_fit': vatt.catdesc = 'FAST Spacecraft Potential, fit over spin'
     'fa_efit_near_b': vatt.catdesc = 'Survey mode Spin-fit electric field, in the direction corresponding to zero degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_efit_along_v': vatt.catdesc = 'Survey mode Spin-fit electric field, in the direction corresponding to ninety degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_data_quality': vatt.catdesc = 'FAST EFI Quality flag, 0 = ok data, Bits set, 0=mag shadow 12, 1=sun shadow 12, 2=mag shadow 58, 3=sun shadow 58'  
     'fa_e12': vatt.catdesc = 'FAST E12, probe 1-2 field, calibrated, not despun'
     'fa_e58': vatt.catdesc = 'FAST E58, probe 5-8 field, calibrated, not despun'
     'fa_e0_s_gse': vatt.catdesc = 'FAST Survey mode electric field, spin plane, in GSE coordinates'
     'fa_e0_s_gsm': vatt.catdesc = 'FAST Survey mode electric field, spin plane, in GSM coordinates'
     'fa_e0_s_dsc': vatt.catdesc = 'FAST Survey mode electric field, spin plane, in DSC (Despun spacecraft) coordinates'
     'fa_bphase': vatt.catdesc = 'FAST B field phase, used for despin'
     'fa_sphase': vatt.catdesc = 'FAST Sun phase, the projection of the sun on the spin plane, SPHASE = 0 corresponds to the X-axis of DSC coordinates'
     'fa_v1_v2_s': vatt.catdesc = 'FAST probe 1-2 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v1_v4_s': vatt.catdesc = 'FAST probe 1-4 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v5_v8_s': vatt.catdesc = 'FAST probe 5-8 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v9_v10_s': vatt.catdesc = 'FAST probe 9-10 (Axial) Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v2_s': vatt.catdesc = 'FAST probe 2 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v4_s': vatt.catdesc = 'FAST probe 4 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v6_s': vatt.catdesc = 'FAST probe 6 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v7_s': vatt.catdesc = 'FAST probe 7 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v8_s': vatt.catdesc = 'FAST probe 8 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v9_s': vatt.catdesc = 'FAST probe 9 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v10_s': vatt.catdesc = 'FAST probe 10 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_dsc_gse': vatt.catdesc = 'FAST DSC_GSE coordinate transformation matrix. 3X3'
     'fa_dsc_gsm': vatt.catdesc = 'FAST DSC_GSM coordinate transformation matrix, 3X3'
     'fa_spin_axis_gse': vatt.catdesc = 'FAST spin axis direction in GSE coordinates'
     'fa_spin_axis_gsm': vatt.catdesc = 'FAST spin axis direction in GSM coordinates'
;4K variables
     'fa_e_near_b_4k': vatt.catdesc = 'FAST 4k Burst mode electric field, in the direction corresponding to zero degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_e_along_v_4k': vatt.catdesc = 'FAST 4k Burst mode electric field, in the direction corresponding to ninety degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_e1458_4k': vatt.catdesc = 'FAST E12, probe 14-58 field, calibrated, not despun'
     'fa_e58_4k': vatt.catdesc = 'FAST E58, probe 5-8 field, calibrated, not despun'
     'fa_bphase_4k': vatt.catdesc = 'FAST B field phase, used for despin'
     'fa_sphase_4k': vatt.catdesc = 'FAST Sun phase, the projection of the sun on the spin plane, SPHASE = 0 corresponds to the X-axis of DSC coordinates'
     'fa_v1_v2_4k': vatt.catdesc = 'FAST probe 1-2 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v1_v4_4k': vatt.catdesc = 'FAST probe 1-4 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v2_v4_4k': vatt.catdesc = 'FAST probe 2-4 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v5_v8_4k': vatt.catdesc = 'FAST probe 5-8 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v5_v6_4k': vatt.catdesc = 'FAST probe 5-6 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v5_v7_4k': vatt.catdesc = 'FAST probe 5-7 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v6_v8_4k': vatt.catdesc = 'FAST probe 6-8 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v7_v8_4k': vatt.catdesc = 'FAST probe 7-8 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v2_4k': vatt.catdesc = 'FAST probe 2 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v6_4k': vatt.catdesc = 'FAST probe 6 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v7_4k': vatt.catdesc = 'FAST probe 7 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v9_4k': vatt.catdesc = 'FAST probe 9 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v10_4k': vatt.catdesc = 'FAST probe 10 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
;16K variables
     'fa_e_near_b_16k': vatt.catdesc = 'FAST 16k Burst mode electric field, in the direction corresponding to zero degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_e_along_v_16k': vatt.catdesc = 'FAST 16k Burst mode electric field, in the direction corresponding to ninety degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_e1458_16k': vatt.catdesc = 'FAST E12, probe 14-58 field, calibrated, not despun'
     'fa_e58_16k': vatt.catdesc = 'FAST E58, probe 5-8 field, calibrated, not despun'
     'fa_bphase_16k': vatt.catdesc = 'FAST B field phase, used for despin'
     'fa_sphase_16k': vatt.catdesc = 'FAST Sun phase, the projection of the sun on the spin plane, SPHASE = 0 corresponds to the X-axis of DSC coordinates'
     'fa_v1_v2_16k': vatt.catdesc = 'FAST probe 1-2 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v1_v3_16k': vatt.catdesc = 'FAST probe 1-3 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v1_v4_16k': vatt.catdesc = 'FAST probe 1-4 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v2_v4_16k': vatt.catdesc = 'FAST probe 2-4 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v3_v4_16k': vatt.catdesc = 'FAST probe 3-4 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v5_v8_16k': vatt.catdesc = 'FAST probe 5-8 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v5_v6_16k': vatt.catdesc = 'FAST probe 5-6 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v5_v7_16k': vatt.catdesc = 'FAST probe 5-7 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v6_v8_16k': vatt.catdesc = 'FAST probe 6-8 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v7_v8_16k': vatt.catdesc = 'FAST probe 7-8 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v9_v10_16k': vatt.catdesc = 'FAST probe 9-10 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v1_v2hg_16k': vatt.catdesc = 'FAST probe 1-2 HG Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v1_v4hg_16k': vatt.catdesc = 'FAST probe 1-4 HG Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v3_v4hg_16k': vatt.catdesc = 'FAST probe 3-4 HG Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v5_v8hg_16k': vatt.catdesc = 'FAST probe 5-8 HG Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v1_16k': vatt.catdesc = 'FAST probe 1 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v2_16k': vatt.catdesc = 'FAST probe 2 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v3_16k': vatt.catdesc = 'FAST probe 3 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v4_16k': vatt.catdesc = 'FAST probe 4 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v5_16k': vatt.catdesc = 'FAST probe 5 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v6_16k': vatt.catdesc = 'FAST probe 6 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v7_16k': vatt.catdesc = 'FAST probe 7 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v8_16k': vatt.catdesc = 'FAST probe 8 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     'fa_v9_16k': vatt.catdesc = 'FAST probe 9 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
     Else: Begin
        print, 'MISSING: '+var
        vatt = -1
     Endcase
  Endcase
  Return, vatt
End
