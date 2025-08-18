;+
;Procedure:
;  mms_mva_crib
;
;Purpose:
;  A crib on showing how to transform tplot variables into 
;  minimum variance analysis coordinates
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_mva_crib.pro $
;-



;clear tplot variables
del_data,'*'

timespan,'2015-10-16', 1, /day

mms_load_fgm, probe='1', /time_clip


;=======================================================================
; Single transformation - limited time range
;=======================================================================

; the default call makes a single transformation matrix that covers the entire interval
;   -use TSTART and TSTOP keywords to limit the rime range considered
;   -use NEWNAME keyword to specify a name for the output, otherwise
;    matrices are stored as input_name + "_mva_mat"
minvar_matrix_make, 'mms1_fgm_b_gse_srvy_l2_bvec', newname='mva_mat_day', $
                    tstart='2015-10-16/13:00', tstop='2015-10-16/14:00'

; apply transformation to tplot variable
;   -applies a right handed rotation
tvector_rotate, 'mva_mat_day', 'mms1_fgm_b_gse_srvy_l2_bvec', newname='mva_data_day'

; update the labels for the transformed variable
options, 'mva_data_day', labels='B'+['i', 'j', 'k']+' GSE'

; update the ysubtitle for the transformed variable
options, 'mva_data_day', ysubtitle='single transformation!C[nT]'

;limit time range to plot
timespan, '2015-10-16/13:00', 1, /hour
tplot, 'mms1_fgm_b_gse_srvy_l2_bvec  mva_data_day'

print,'Heres the FGM data translated into MVA coordinates using a single transformation matrix'

stop


;=======================================================================
; Multiple transformations - 1 hours sliding average (5 min increment)
;=======================================================================

; use sliding average of 1 hour every 5 minutes
minvar_matrix_make, 'mms1_fgm_b_gse_srvy_l2_bvec', newname='mva_mat_hour', $
                    twindow=3600, tslide=300

tvector_rotate, 'mva_mat_hour', 'mms1_fgm_b_gse_srvy_l2_bvec', newname='mva_data_hour'

; update the labels for the transformed variable
options, 'mva_data_hour', labels='B'+['i', 'j', 'k']+' GSE'

; update the ysubtitle for the transformed variable
options, 'mva_data_hour', ysubtitle='1 hour sliding avg!C[nT]'

timespan, '2015-10-16/13:00', 1, /hour
tplot, 'mms1_fgm_b_gse_srvy_l2_bvec  mva_data_hour'

print,'Heres the FGM data translated into MVA coordinates using a different transformation every hour'

stop


;=======================================================================
; Multiple transformations - 5 min sliding average (2:30 min increment)
;=======================================================================

; use sliding average of 5 minutes hour every 2.5 minutes
;   -set start/stop time to make calculation faster
minvar_matrix_make, 'mms1_fgm_b_gse_srvy_l2_bvec', newname='mva_mat_min_tlim', $
                    twindow=300, tslide=150

tvector_rotate,'mva_mat_min_tlim', 'mms1_fgm_b_gse_srvy_l2_bvec', newname='mva_data_min_tlim'

; update the labels for the transformed variable
options, 'mva_data_min_tlim', labels='B'+['i', 'j', 'k']+' GSE'

; update the ysubtitle for the transformed variable
options, 'mva_data_min_tlim', ysubtitle='5 min sliding avg!C[nT]'

timespan, '2015-10-16/13:40', 10, /min
tplot, 'mms1_fgm_b_gse_srvy_l2_bvec  mva_data_min_tlim'

print,'Heres the FGM data translated into MVA coordinates using a different transformation every 5 minutes'

stop

;===========================
; Plot all Examples
;===========================

timespan, '2015-10-16/13:00', 1, /hour
tplot, 'mms1_fgm_b_gse_srvy_l2_bvec  mva_data_*'

end

