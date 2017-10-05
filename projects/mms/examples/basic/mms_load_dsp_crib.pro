;+
; MMS DSP crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-08-01 15:53:36 -0700 (Mon, 01 Aug 2016) $
; $LastChangedRevision: 21586 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_dsp_crib.pro $
;-
timespan, '2015-10-16', 1, /day

mms_load_dsp, data_rate='fast', probes=[1, 2, 3, 4], datatype='epsd', level='l2'
    
options, 'mms?_dsp_epsd_*', spec=1, zlog=1, ylog=1
options, 'mms?_dsp_epsd_omni', zrange=[1e-14, 1e-4], yrange=[30, 1e5]

; show the omni-directional electric spectral density for all MMS spacecraft
tplot, 'mms?_dsp_epsd_omni'
stop

window, 1
tplot, 'mms1_dsp_epsd_?', window=1
stop

; now download the SCM spectral density
mms_load_dsp,  data_rate='fast', probes=[1, 2, 3, 4], datatype='bpsd', level='l2'

options, 'mms?_dsp_bpsd_*', spec=1, zlog=1, ylog=1
options, 'mms?_dsp_bpsd_omni_fast_l2', zrange=[1e-14, 10], yrange=[10, 1e4]

window, 2
; show the omni-directional SCM spectral density for all MMS spacecraft
tplot, 'mms?_dsp_bpsd_omni_fast_l2', window=2
stop

window, 3
; show the components of the SCM spectral density for MMS1
tplot, 'mms1_dsp_bpsd_scm?_fast_l2', window=3
stop

end