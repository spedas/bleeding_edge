;+
; PROCEDURE:
;         geotail_load_data
;
; PURPOSE:
;         Crib sheet showing how to load and plot GEOTAIL data on the command line
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-03-07 11:40:11 -0800 (Wed, 07 Mar 2018) $
; $LastChangedRevision: 24846 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/geotail/geotail_load_data_crib.pro $
;-

; load 1 month of density, temperature, magnetic field and S/C position data
geotail_load_data, trange=['2004-02-01', '2004-03-01']

tplot, ['Ni', 'T', 'BGSM', 'GSM_POS']

stop
end