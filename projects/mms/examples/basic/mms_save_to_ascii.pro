;+
; PROCEDURE:
;         mms_save_to_ascii
;         
; PURPOSE:
;         Crib sheet showing how to load some MMS data into tplot 
;         variables then save the variables to ASCII files
; 
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-07-03 14:33:15 -0700 (Tue, 03 Jul 2018) $
; $LastChangedRevision: 25435 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_save_to_ascii.pro $
;-

; load some FGM data
mms_load_fgm, trange=['2015-10-16/13:00', '2015-10-16/13:10'], probes=[1, 2, 3, 4], data_rate='brst', /time_clip

; save all of the data in the tplot variables to individual files with the 
; filenames being the same as the tplot variable names (in your IDL working directory)
tplot_ascii, ['mms1_fgm_b_gse_brst_l2', 'mms2_fgm_b_gse_brst_l2', 'mms3_fgm_b_gse_brst_l2', 'mms4_fgm_b_gse_brst_l2']

; use trange keyword to limit the output to a specific time range
tplot_ascii, trange=['2015-10-16/13:04', '2015-10-16/13:05'], ['mms1_fgm_b_gse_brst_l2', 'mms2_fgm_b_gse_brst_l2', 'mms3_fgm_b_gse_brst_l2', 'mms4_fgm_b_gse_brst_l2']

; use fname to change the filename of the output file
tplot_ascii, 'mms1_fgm_b_gse_brst_l2', fname='some_fgm_data'
stop
end