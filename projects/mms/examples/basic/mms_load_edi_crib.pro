;+
; MMS EDI crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-01 12:00:15 -0700 (Fri, 01 Apr 2016) $
; $LastChangedRevision: 20700 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_edi_crib.pro $
;-

timespan, '2015-12-23', 1, /day
probe = '1'

; load the E-field data
mms_load_edi, probes=probe, data_rate='srvy', datatype='efield', level='l2'

; set the colors
options, 'mms'+probe+'_edi_*_gsm_srvy_l2', colors=[2, 4, 6]

; plot the data
tplot, 'mms'+probe+['_edi_e_gsm_srvy_l2', $ electric field 
                    '_edi_vdrift_gsm_srvy_l2'] ; ExB drift velocity

end