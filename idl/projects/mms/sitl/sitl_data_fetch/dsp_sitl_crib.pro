mms_init

timespan, '2016-04-17/12:00:00', 13, /hour

sc_id = 'mms1'

; New way to plot improved spectral products.

; Get e-field spectrum
mms_sitl_get_edp, sc_id = sc_id, datatype='hfesp', level = 'l2', data_rate='srvy'
;
espec = sc_id + '_edp_srvy_hfesp_l2'

options, espec, 'spec', 1
ylim, espec, 0, 64000
options, espec, 'zlog', 1
options, espec, 'ylog', 1
ylim, espec, 600, 65536

; Get b-field spectrum

mms_sitl_get_dsp, sc_id = sc_id, datatype = 'bpsd', level = 'l2', data_rate='fast'
bspec = sc_id + '_dsp_bpsd_omni_fast_l2'
options, bspec, 'spec', 1
options, bspec, 'zlog', 1
options, bspec, 'ylog', 1
ylim, bspec, 32, 4000

tplot, [espec, bspec]


end