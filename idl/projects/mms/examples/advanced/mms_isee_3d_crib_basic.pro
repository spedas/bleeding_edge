;+
;Purpose:
;   A crib sheet for visualizing MMS 3D distribution function data (L2) 
;   by using an interactive visualization tool, ISEE3D, developed by 
;   Institute for Space-Earth Environmental Research (ISEE), Nagoya University, Japan.
;
;Notes:
;   This crib sheet shows usage of the wrapper routine - mms_part_isee3d
;   Please use the latest version of SPEDAS bleeding edges. 
;
;See also:
;   mms_isee_3d_crib.pro - for examples of calling isee_3d directly without the wrapper
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
;$LastChangedRevision: 31999 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_isee_3d_crib_basic.pro $
;-


;=============================================================
; FPI - L2
;=============================================================

del_data,'*'

;setup
probe = '1'
species = 'i'
data_rate = 'fast'
level = 'l2'

;use short time range for data due to high resolution (saves time/memory)
;time range must include at least three sample times
;use longer time range for support data to ensure we have enough to work with
;timespan, '2015-10-20/05:56:30', 4, /sec
timespan, '2015-11-18/02:10:00', 10, /sec

mms_part_isee3d, probe=probe, species=species, data_rate=data_rate, level=level
stop


;=============================================================
; HPCA - L2
;=============================================================

del_data,'*'

;setup
probe = '1'
data_rate = 'srvy' ;only srvy available for l2
level = 'l2'
species='hplus'

timespan, '2015-10-20/05:56:30', 60, /sec

mms_part_isee3d, instrument='hpca', probe=probe, species=species, data_rate=data_rate, level=level
stop

end