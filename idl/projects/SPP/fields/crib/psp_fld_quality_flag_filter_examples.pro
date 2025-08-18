;+
;NAME: PSP_FLD_QUALITY_FLAG_FILTER_EXAMPLES
;
;DESCRIPTION:
;   Crib sheet to demonstrate how to filter and plot select PSP FIELDS data
;   products based on the set quality flag filters.
;
;CALLING SEQUENCE:
;   .run psp_fld_quality_flag_filter_examples 
;     OR 
;   cut-and-paste relevant portions to the command prompt
;
;NOTES:
;   FIELDS quality flag filtering currently supports the following tplot
;   variables:
;     *psp_fld_l2_mag_RTN
;     *psp_fld_l2_mag_SC
;     *psp_fld_l2_mag_RTN_1min
;     *psp_fld_l2_mag_SC_1min
;     *psp_fld_l2_mag_RTN_4_Sa_per_Cyc
;     *psp_fld_l2_mag_SC_4_Sa_per_Cyc
;   
;   
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-11-18 13:19:37 -0800 (Wed, 18 Nov 2020) $
; $LastChangedRevision: 29360 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/crib/psp_fld_quality_flag_filter_examples.pro $
;-

;----------- Setup Timerange and Load Data -------------------
trange = ['2019-04-10/00:00:00','2019-04-11/00:00:00']
trange = ['2018-11-10/00:00:00','2018-11-12/00:00:00']
timespan, trange
spd_graphics_config

psp_fld_load, type = 'mag_RTN_4_Sa_per_Cyc'
psp_fld_load, type = 'mag_RTN_1min'
stop

;----------- Read Help Doc on QF Filtering -------------------
; This includes the various quality flag definitions
psp_fld_qf_filter, /help
stop

;----------- Filter and Plot ---------------------------------
;
;To filter out flagged data call:
; psp_fld_qf_filter, <tplot variable name or number>, <flag number>
; 
; Both arguments can be scalar or array
; 


; Use flag 0 to keep only values with no data quality flags set
;   for the 1 minute data.  
; A new tplot variable is created with the _000 suffix
psp_fld_qf_filter,'psp_fld_l2_mag_RTN_1min',0
tplot,['psp_fld_l2_mag_RTN_1min','psp_fld_l2_mag_RTN_1min_000']
stop

; Use flag -1 to keep only values with no data quality flags set
;   except for "PSP spacecraft is off umbra pointing" (flag 128)
; A new tplot variable is created with the _0-1 suffix
psp_fld_qf_filter,'psp_fld_l2_mag_RTN_1min',-1
tplot,['psp_fld_l2_mag_RTN_1min','psp_fld_l2_mag_RTN_1min_0-1']
stop 

; Filter out data points corresponding to spacecraft mag rolls or 
;   mag internal calibration times or both (quality flags 8 and 16)
; A new tplot variable is created with suffix _008016
psp_fld_qf_filter,'psp_fld_l2_mag_RTN_1min',[8, 16]
tplot,['psp_fld_l2_mag_RTN_1min','psp_fld_l2_mag_RTN_1min_008016']
stop


; From both the 1min and 4_Sa_per_Cyc variables, filter out the
;   data points corresponding to SCM Calibration or SWEAP in 
;   electron mode or both (quality flags 4 and 32)
tn = ['psp_fld_l2_mag_RTN_1min', $
      'psp_fld_l2_mag_RTN_4_Sa_per_Cyc']
qflgs = [4, 32]
psp_fld_qf_filter, tn, qflgs
tplot, [tn[0], tn[0]+'_004032', tn[1], tn[1]+'_004032']
stop


;------------ With Vector Components ----------------------------
; Filter the vector variable before splitting into componenents
psp_fld_load, type = 'mag_RTN_1min'
psp_fld_qf_filter, 'psp_fld_l2_mag_RTN_1min'  ;Defaults to 0 flag

suffix=['_r','_t','_n']
split_vec, 'psp_fld_l2_mag_RTN_1min', suffix=suffix, names_out=nms 
split_vec, 'psp_fld_l2_mag_RTN_1min_000', suffix=suffix, names_out=nms_filtered

; Plot the base and filtered data for Br
tplot, [nms[0], nms_filtered[0]]
stop
end