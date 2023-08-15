;+
;
;  This crib sheet shows how to create HPCA angle-angle and angle-energy plots from the distribution functions
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
;$LastChangedRevision: 31998 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_hpca_angle_angle_crib.pro $
;-

; create angle-angle and angle-energy plots for burst mode H+
; warning/note: since these are taken at a single data point (and not spin-summed)
; the phi (azimuthal) range on the figures will be limited
mms_hpca_ang_ang, '2015-10-16/13:06:43', species='hplus', data_rate='brst'
stop

; create angle-angle and angle-energy plots for burst mode O+
mms_hpca_ang_ang, '2015-10-16/13:06:43', species='oplus', data_rate='brst'
stop

; plot burst mode H+ and limit the energy range (1keV-20keV)
mms_hpca_ang_ang, '2015-10-16/13:06:43', energy_range = [1000, 20000], species='hplus', data_rate='brst'

stop
end