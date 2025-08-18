;+
; Purpose:
;   Crib sheet demonstrating how to use older SPEDAS particle routines (e.g., plot3d_new, spec3d)
;   to visualize MMS FPI data
;
;
; Note: results not yet validated as of 1/8/2018
;
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
;$LastChangedRevision: 31999 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_plot3d_fpi_crib.pro $
;-

; load 1-min of burst mode DES data
mms_load_fpi, datatype='des-dist', trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', /time_clip

; convert the DES tplot variable containing distribution data into a spd_slice2d data structure
data = mms_get_fpi_dist('mms3_des_dist_brst', /structure)

; convert to a data structure that's accepted by plot3d_new i.e., (energy, theta, phi) -> (energy, bins)
reformed_data = reform_3d_struct(data[0])

; plot the distribution at each energy
plot3d_new, reformed_data, units='df_cm', /log
 
stop
end
