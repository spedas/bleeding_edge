;+
; mms_burst_status_crib  
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;     
; 
; Note: status and FoM bars currently require an MMS team password for the SDC
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_burst_status_crib.pro $
;-


; set time range 
timespan, '2015-10-16', 1, /day

; get data availability for burst and survey data (note that the labels flag
; is set so that the display bars will be labeled)
spd_mms_load_bss, datatype=['fast', 'burst'], /include_labels

; now plot bars with some data 
mms_load_fgm, probe=3, data_rate=['srvy', 'brst'], level='l2'

; degap the mag data to avoid tplot connecting the lines between
; burst segments
tdegap, 'mms3_fgm_b_gse_brst_l2_bvec', /overwrite

tplot,['mms_bss_fast','mms_bss_burst', 'mms3_fgm_b_gse_srvy_l2_bvec', 'mms3_fgm_b_gse_brst_l2_bvec']
stop

; Get all BSS data types (Fast, Burst, Status, and FOM)
; Note: the following will request your MMS team username/password due
; to the FoM and status bars
; spd_mms_load_bss, /include_labels, datatype=['fast', 'burst', 'fom', 'status']

; plot bss bars and fom at top of plot
; tplot,['mms_bss_fast','mms_bss_burst','mms_bss_status', 'mms_bss_fom', $
;       'mms3_fgm_b_gse_srvy_l2_bvec', 'mms3_fgm_b_gse_brst_l2_bvec']
; stop

end
