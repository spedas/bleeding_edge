;+
; NAME:
;   rbsp_efw_get_cal_params (function)
;
; PURPOSE:
;   Return RBSP EFW calibration parameters for converting L1 data to L2 data.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   cp = rbsp_efw_get_cal_params(time)
;
; ARGUMENTS:
;   time: (Input, required) A floating time scalar for determining
;         time-dependent calibration parameters.
;
; KEYWORDS:
;   None.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-08-07: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2014-02-25 11:57:04 -0800 (Tue, 25 Feb 2014) $
; $LastChangedRevision: 14428 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_get_cal_params.pro $
;
;-

function rbsp_efw_get_cal_params, time

compile_opt idl2

; Locate the calibration_files folder
traceinfo = scope_traceback(/structure)
nlevels = n_elements(traceinfo)
thisfile = traceinfo[nlevels-1].filename
;-- calfolder: The calibration files folder.
calfolder = file_dirname(thisfile) + path_sep() + $
          'calibration_files' + path_sep()

adc_factor = 2.5d / 32767.5d

; The ADC_gain's and ADC_offset's are set so that
; phys_units = ADC_gain * (ADC_counts - ADC_offset)
;
; Setup template.
;-- RBSP-A
a = {ADC_gain_EAC: [10d, 10d, 10d] * adc_factor $ ; boom 12, 34, 56
   , ADC_gain_EDC: [50d, 50d, 50d] * adc_factor $ ; boom 12, 34, 56
   , ADC_gain_VDC: [100d,100d,100d,100d,100d,100d] * adc_factor $ ; sensors 1-6
   , ADC_gain_VAC: [5d, 5d, 5d, 5d, 5d, 5d] * adc_factor $
   , ADC_gain_MAG: dblarr(4,3) $
   , ADC_gain_MSC: [2d, 2d, 2d] * adc_factor $ ;* [2.35d, 2.22d, 2.22d] $
   , ADC_offset_EAC: [0d, 0d, 0d] $                ; All ADC offsets are
   , ADC_offset_EDC: [0d, 0d, 0d] $                ; in units of ADC counts
   , ADC_offset_VDC: [0d, 0d, 0d, 0d, 0d, 0d] $
   , ADC_offset_VAC: [0d, 0d, 0d, 0d, 0d, 0d] $
   , ADC_offset_MAG: dblarr(4,3) $
   , ADC_offset_MSC: [0d, 0d, 0d] $
   , boom_length:     [100d, 100d, 12d] $ ; boom 12, 34, 56 [m]
   , boom_shorting_factor: [1d, 1d, 1d] $ ; boom 12, 34, 56
   , R_sh:         10d6 $ ; Sheath resistance of EFW sensors [Ohm]
   , E_sunward: 1d      $ ; Sunward offset [mV/m]
     }

;-- RBSP-B
b = {ADC_gain_EAC: [10d, 10d, 10d] * adc_factor $ ; boom 12, 34, 56
   , ADC_gain_EDC: [50d, 50d, 50d] * adc_factor $ ; boom 12, 34, 56
   , ADC_gain_VDC: [100d,100d,100d,100d,100d,100d] * adc_factor $ ; sensors 1-6
   , ADC_gain_VAC: [5d, 5d, 5d, 5d, 5d, 5d] * adc_factor $
   , ADC_gain_MAG: dblarr(4,3) $
   , ADC_gain_MSC: [2d, 2d, 2d] * adc_factor $ ;* [2.33d, 2.10d, 2.22d] $
   , ADC_offset_EAC: [0d, 0d, 0d] $                ; All ADC offsets are
   , ADC_offset_EDC: [0d, 0d, 0d] $                ; in units of ADC counts
   , ADC_offset_VDC: [0d, 0d, 0d, 0d, 0d, 0d] $
   , ADC_offset_VAC: [0d, 0d, 0d, 0d, 0d, 0d] $
   , ADC_offset_MAG: dblarr(4,3) $
   , ADC_offset_MSC: [0d, 0d, 0d] $
   , boom_length:     [100d, 100d, 12d] $ ; boom 12, 34, 56
   , boom_shorting_factor: [1d, 1d, 1d] $ ; boom 12, 34, 56
   , R_sh:         10d6 $ ; Sheath resistance of EFW sensors [Ohm]
   , E_sunward: 1d      $ ; Sunward offset [mV/m]
     }

; Adjust sheath resistance based on time.

; ADC->nT for MAG.
a.ADC_gain_MAG[*,*] = !values.d_nan ; Not defined.
a.ADC_gain_MAG[3,*] = [-1.98306142d, -1.91391225d, -1.92520583d] ; Range 3
a.ADC_gain_MAG[1,*] = [-0.12053275d, -0.11961984d, -0.12030539d] ; Range 1
a.ADC_gain_MAG[0,*] = [-0.00751655d, -0.00745895d, -0.00749288d] ; Range 0

a.ADC_offset_MAG[*,*] = !values.d_nan ; Not defined.
a.ADC_offset_MAG[3,*] = [38.45927264d, 2.50025259d, 4.74938768d] ; Range 3
a.ADC_offset_MAG[1,*] = [173.49869468d, -18.45764055d, 17.55056668d] ; Range 1
a.ADC_offset_MAG[0,*] = [2688.000d, -393.70724250d, 244.00742394d] ; Range 0

b.ADC_gain_MAG[*,*] = !values.d_nan ; Not defined.
b.ADC_gain_MAG[3,*] = [-1.93103806d, -1.90603227d, -1.89987673d] ; Range 3
b.ADC_gain_MAG[1,*] = [-0.11812884d, -0.11913837d, -0.11874722d] ; Range 1
b.ADC_gain_MAG[0,*] = [-0.00735309d, -0.00742355d, -0.00739919d] ; Range 0

b.ADC_offset_MAG[*,*] = !values.d_nan ; Not defined.
b.ADC_offset_MAG[3,*] = [18.12368611d, 0.49911855d, -4.50062627d] ; Range 3
b.ADC_offset_MAG[1,*] = [344.00d, -28.19919978d, -25.49945870d] ; Range 1
b.ADC_offset_MAG[0,*] = [5500.56815691d, -559.00d, -418.00d] ; Range 0

; Get EFW boom length.
a.boom_length = rbsp_efw_boom_length('a', time)
b.boom_length = rbsp_efw_boom_length('b', time)


cp = {a:a, b:b}

return, cp

end

