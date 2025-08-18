;+
;	Batch File: THM_CRIB_EFI
;
;	Purpose:  Demonstrate the loading, calibration, and plotting
;		of THEMIS EFI data.
;
;	Calling Sequence:
;	.run thm_crib_fbk, or using cut-and-paste.
;
;	Arguements:
;   None.
;
;	Notes:
;               ***WARNING: Running THM_CRIB_EFI (or likely just calling THM_LOAD_EFI) after THM_CRIB_CLEANEFW will result in the wrong plot labels.
;                           The problem is probably in the way that some of the LASP code handles, or does not handle, the TPLOT labelling.
;	None.
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2016-11-29 13:22:27 -0800 (Tue, 29 Nov 2016) $
; $LastChangedRevision: 22415 $
; $URL $
;-

;------------------------------------------------------------------------------
; EFI waveform data example.
;------------------------------------------------------------------------------
tplot_title = 'THEMIS EFI Waveform Examples'
tplot_options, 'title', tplot_title
tplot_options, 'xmargin', [ 15, 10]
tplot_options, 'ymargin', [ 5, 5]

; Data parameters, load data, and set color table:
;
dur = 1.0   ;days
;tr_string = '2008-05-15'
tr_string = '2007-07-20'
timespan, tr_string, dur, /day
tr = timerange()
probe = 'c d' ; converting a to d below.
;; state data needed by thm_load_fgm, which is needed for dot0 quantities.
thm_load_state , probe = probe, /get_support
thm_load_efi, level=1, suffix='_raw',  type='raw', /get_support, probe = probe;, /no_download
loadct2, 39

; the following are optional, since they should be set
; by thm_load_efi as the default plotting options (dlimits).
; you can use these as a starting point if you want to modify the labels/colors.
;options, 'th?_v??_raw', 'colors', [ 1, 2, 3, 4, 5, 6]
;options, 'th?_v??_raw', 'labels', [ 'V1', 'V2', 'V3', 'V4', 'V5', 'V6']
;options, 'th?_v??_raw', 'labflag', 1

;options, 'th?_e??_raw', 'colors', [ 2, 4, 6]
;options, 'th?_e??_raw', 'labels', [ 'e12', 'e34', 'e56']
;options, 'th?_e??_raw', 'labflag', 1

tplot, [ 'th[cde]_vaf_raw', 'th[cde]_eff_raw']

print, 'The plot shows raw data for all probe for which the booms have
print, 'been deployed as of 2007-06-30.'
print,'Enter ".c"  to print the contents of DLIMITS.DATA_ATT structure for'
print,'"thd_vaf_raw", and "thd_eff_raw".'
stop

;------------------------------------------------------------------------------
;zoom in on the data
;------------------------------------------------------------------------------
;
;tlimit, [ tr[0] + 10d*3600 + 10d*60 , tr[0] + 13d*3600 + 56d*60 ]    ;10:10:00 to 13:56:00
tlimit, [ tr[0] + 17d*3600 + 36d*60 , tr[0] + 17d*3600 + 45d*60 ]    ;17:36:00 to 17:45:00     Mozer intervals.

;print, 'zoomed into a period where all satellites have some good data  '
print, 'zoomed into a period of interest'
print, 'Enter ".c"  to continue.'
stop

thm_cal_efi, /verbose, in_suffix='_raw', onthefly_edc_offset = onthefly_edc_offset, gap_begin = gap_begin, gap_end = gap_end, $
             out_suffix='_dsl _gei', coord = 'dsl gei'

tplot, [ 'thc_vaf_raw', 'thc_vaf', 'thc_eff_raw', 'thc_eff', 'thc_eff_0', 'thc_eff_dot0_gei' ]

print,'Enter ".c"  to print the contents of DLIMITS.DATA_ATT structure for'
print,'"thc_vaf", and "thc_eff" (note updated and additional fields).'
stop

;------------------------------------------------------------------------------
;view data attributes
;------------------------------------------------------------------------------

get_data,'thd_vaf',dlimits=dl
help,dl.data_att,/st
get_data,'thd_eff',dlimits=dl
help,dl.data_att,/st

print, 'Enter ".c" to view the structure and substructure of the optional ONTHFLY_EDC_OFFSET keyword (GAP_BEGIN and GAP_END are similar).'
stop

;------------------------------------------------------------------------------
;view calibration parameters
;------------------------------------------------------------------------------

help, onthefly_edc_offset, onthefly_edc_offset.d, /st

print,'Enter ".c" to view particle burst data.'
stop

;------------------------------------------------------------------------------
;wave burst data
;------------------------------------------------------------------------------

;tlimit, /full
timespan, tr[0], tr[1] - tr[0], /seconds
tplot, [ 'thd_vap_raw', 'thd_vap', 'thd_efp_raw', 'thd_efp_dsl', 'thd_efp_gei', 'thd_efp_0', 'thd_efp_dot0_dsl', 'thd_efp_dot0_gei' ]
print, 'particle burst'
print, 'use the mouse to zoom in. click anywhere on plot. first click sets start. second click sets end.'
tlimit
print, 'Enter ".c" to view wave burst data.'

stop

;------------------------------------------------------------------------------
;wave burst inside particle burst
;------------------------------------------------------------------------------

;tplot, [ 'thd_vaw_raw', 'thd_vaw', 'thd_efw_raw', 'thd_efw', 'thd_efw_0', 'thd_efw_dot0' ]
tplot, [ 'thd_vaw_raw', 'thd_vaw', 'thd_efw_raw', 'thd_efw_dsl', 'thd_efw_gei', 'thd_efw_0', 'thd_efw_dot0_dsl', 'thd_efw_dot0_gei' ]
print, 'wave burst occurs within particle burst'
print, 'use the mouse to zoom in'
tlimit



end
