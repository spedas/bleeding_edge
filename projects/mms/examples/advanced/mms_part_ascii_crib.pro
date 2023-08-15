;+
;
; PURPOSE:
;   This crib sheet shows how to save the full MMS 3D velocity distribution data to ASCII files
;
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
;$LastChangedRevision: 31999 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_part_ascii_crib.pro $
;-

trange=['2015-10-16/13:06', '2015-10-16/13:07']

mms_load_fpi, trange=trange, datatype='dis-dist', /time_clip, /center_measurement

; first, convert the velocity distribution data to the standard SPEDAS particle data structure
data = mms_get_dist('mms3_dis_dist_fast')
stop

; then call spd_pgs_export with the data structure; by default, this routine 
; uses data.project, data.spacecraft and data.data_name to form the 
; output filenames; you can set your own filenames with the filename keyword
; note: this routine creates 5 ASCII files: 
;       - [filename]_data.txt: the distribution data
;       - [filename]_energy.txt: the energies
;       - [filename]_bins.txt: active bins (0 for inactive, 1 for active)
;       - [filename]_phi.txt: phi angles
;       - [filename]_theta.txt: theta angles
spd_pgs_export, data ;, filename='mms3_dis_dist_fast'
stop

; this also works with burst mode data
mms_load_fpi, trange=trange, datatype='des-dist', data_rate='brst', /time_clip, /center_measurement

; and you can select individual time indices by specifying them in the second argument
; e.g., to only return the first 3 times:
data = mms_get_dist('mms3_des_dist_brst', [0, 1, 2])

spd_pgs_export, data
stop

; this also works for exporting HPCA velocity distribution data
mms_load_hpca, trange=trange, datatype='ion', data_rate='brst', /time_clip, /center_measurement

data = mms_get_dist('mms1_hpca_hplus_phase_space_density')

spd_pgs_export, data
stop

end