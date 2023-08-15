;+
; mms_colorblind_friendly_colors
;
; This crib sheet shows how to change the default colors (lines, spectra) to use olorblind-friendly color tables
;
; Note from Naritoshi Kitamura:
;    "At least Science and journals of Nature portfolio require the use of colorblind-friendly color schemes for figures."
; 
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

; load some data for the figures
mms_load_fpi, trange=['2015-10-16/13:06','2015-10-16/13:08'], probes=[1, 2, 3, 4], datatype='dis-moms', data_rate='brst', /time_clip

; example of new colorblind-friendly color tables (1075-1080)
options, 'mms1_dis_energyspectr_omni_brst', 'color_table', 1080
tplot, 'mms1_dis_energyspectr_omni_brst'
stop

; change the default line colors to a colorblind-friendly scheme
; color table suggested by https://www.nature.com/articles/nmeth.1618 except for reddish purple
; see also: line_clrs=7 and 8
loadct2, 43, line_clrs=9
tplot, 'mms1_dis_bulkv_dbcs_brst'
stop

; show the ion density for all 4 spacecraft using a colorblind-friendly scheme
store_data, 'multi_sc_density', data='mms1_dis_numberdensity_brst mms2_dis_numberdensity_brst mms3_dis_numberdensity_brst mms4_dis_numberdensity_brst'
options, 'multi_sc_density', 'colors', [0, 1, 3, 5]
options, 'multi_sc_density', 'labflag', -1
options, 'multi_sc_density', 'labels', ['MMS1', 'MMS2', 'MMS3', 'MMS4']
tplot, 'multi_sc_density'
stop

; use the new color tables for non-tplot variables:
loadcsv, 1080 
mms_part_slice2d, time='2015-10-16/13:06', species='i', data_rate='brst'

stop
end