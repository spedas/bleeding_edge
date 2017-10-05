;+
;Procedure:
;  thm_crib_cotrans_lmn
;
;Purpose:
;  Crib sheet showing the use of thm_cotrans_lmn.
;
;Notes:
;  Written by: Vladimir Kondratovich
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
;$LastChangedRevision: 17598 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_cotrans_lmn.pro $
;-


; thm_cotrans_lmn method 1
;-------------------------
probe = 'a'
timespan, '7 7 17', 1, /day

thm_load_state, probe=probe, /get_supp
thm_load_fit, level=1, datatype='fgs', probe = probe, coord='gse', suff='_gse'

thm_cotrans_lmn, 'tha_fgs_gse', 'tha_fgs_lmn', resol=1800, /wind
tplot, 'tha_fgs_lmn', trange = ['7 7 17 12 40', '7 7 17 17']

print,''
print,'Type ".continue" to move on to Example 2.'
stop


; thm_cotrans_lmn method 2
;-------------------------
probe = 'a'
timespan, '7 7 17', 1, /day

thm_load_state, probe=probe, /get_supp
thm_load_fit, level=1, datatype='fgs', probe = probe, coord='gsm', suff='_gsm'
get_data, 'tha_fgs_gsm', time, bgsm

thm_cotrans_lmn, bgsm, blmn, time, probe=probe, /GSM, resol=1800, /hro

store_data, 'tha_fgs_lmn', data = {x:time, y:blmn}
tplot, 'tha_fgs_lmn', trange = ['7 7 17 12 40', '7 7 17 17']

END
