;+
; MMS curlometer crib sheet
;
;  This script shows how to calculate div B and curl B
;  using mms_curl
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-04-03 08:35:22 -0700 (Mon, 03 Apr 2017) $
; $LastChangedRevision: 23083 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_curlometer_crib.pro $
;-

tplot_options,'xmargin', [15, 15]

trange = ['2015-10-30/05:15:45', '2015-10-30/05:15:48']

mms_load_fgm, trange=trange, /get_fgm_ephemeris, probes=[1, 2, 3, 4], data_rate='brst'

fields = 'mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2'
positions = 'mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2'

; method #1: mms_curl
mms_curl, trange=trange, fields=fields, positions=positions, suffix='_mms_curl'

tplot, ['divB','curlB','jtotal','jperp','jpar','baryb']+'_mms_curl'
stop

; method #2: mms_lingradest
mms_lingradest, fields=fields, positions=positions, suffix='_lingradest'

window, 1
tplot, window=1, ['Bbc_lingradest', 'jtotal_lingradest']

stop
end