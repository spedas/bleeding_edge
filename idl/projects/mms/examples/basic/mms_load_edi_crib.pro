;+
; MMS EDI crib sheet
; 
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;     
;     
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_edi_crib.pro $
;-

timespan, '2015-12-23', 1, /day
probe = '1'

; load the E-field data
mms_load_edi, probes=probe, data_rate='srvy', datatype='efield', level='l2'

; plot the data
tplot, 'mms'+probe+['_edi_e_gsm_srvy_l2', $ electric field 
                    '_edi_vdrift_gsm_srvy_l2'] ; ExB drift velocity

end