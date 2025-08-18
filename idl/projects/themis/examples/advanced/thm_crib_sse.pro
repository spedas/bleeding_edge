;+
;Procedure:
;  thm_crib_sse
;
;Purpose:
;  A crib showing how to transform data from GSE to SSE coordinate system. 
;
;See also:
;  thm_crib_cotrans
;
;Notes:
;  -Code heavily based on make_mat_Rxy.pro & transform_gsm_to_rxy.pro 
;   by Christine Gabrielse(cgabrielse@ucla.edu)
;  -SSE is defined as:
;     X: Moon->Sun Line projected into the ecliptic plane
;     Y: Z x X
;     Z: Ecliptic north
;
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-05-18 16:11:30 -0700 (Mon, 18 May 2015) $
; $LastChangedRevision: 17643 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_sse.pro $
;-


;==================================================
; Load data
;==================================================

probe = 'a'

timespan,'2008-03-23'

;load solar/lunar position data
thm_load_slp

cotrans,'slp_sun_pos','slp_sun_pos_gse',/gei2gse
cotrans,'slp_lun_pos','slp_lun_pos_gse',/gei2gse

;create series of rotation matrices
sse_matrix_make,'slp_sun_pos_gse','slp_lun_pos_gse',newname='sse_mat'

;load fgm data to be transformed
thm_load_fgm,probe=probe,coord='gse',level=2

;load state data to be transformed
thm_load_state,probe=probe


;==================================================
; Simple rotation
;==================================================

;because fgm data is not specified relative to the coordinate system's
;frame of reference the transformation is rotational only
tvector_rotate,'sse_mat','th'+probe+'_fgl_gse'

;data appears identical as the gse -> sse rotation is very small
;use get_data or check in GUI to verify numerically
options, 'th'+probe+'_fgl_gse_rot', ytitle='th'+probe+'_fgl_sse', ysubtitle='[nt SSE]'
tplot,['th'+probe+'_fgl_gse','th'+probe+'_fgl_gse_rot']

stop


;==================================================
; Inverse rotation
;==================================================

tvector_rotate,'sse_mat','th'+probe+'_fgl_gse_rot',newname='th'+probe+'_fgl_gse_inv',/invert

options, 'th'+probe+'_fgl_gse_inv', ytitle='th'+probe+'_fgl_gse_inv', ysubtitle='[nt GSE]'
tplot, 'th'+probe+'_fgl_gse' + ['','_inv','_rot']

stop


;==================================================
; Position transformation
;==================================================

;position is trickier, because it is measured with respect to coordinate center
;We need to perform an affine transformation which we do in 3 steps.

;transform position data
cotrans,'th'+probe+'_state_pos','th'+probe+'_state_pos',/gei2gse

;first interpolate the moon position onto state position
tinterpol_mxn,'slp_lun_pos_gse','th'+probe+'_state_pos'

;next subtract the moon position from the state position to account for relative position of coordinate frames
calc,'"th'+probe+'_state_pos_sub"="th'+probe+'_state_pos"-"slp_lun_pos_gse_interp"',/verbose

;last perform the rotational component of the transformation.
tvector_rotate,'sse_mat','th'+probe+'_state_pos_sub',newname='th'+probe+'_state_pos_sse'

options, 'th'+probe+'_state_pos_sse', ytitle='pos SSE', ysubtitle='[km]'
tplot, 'th'+probe+'_state_pos' + ['','_sse']

stop


;==================================================
; Velocity transformation
;==================================================

;velocity is even trickier, because the coordinate systems are in motion themselves.

;Note:
; 1. This same affine transformation can be done for accelerations, 
;    by taking an additional derivative.
; 2. Taking discrete derivatives will lead to approximation errors
;    on the edges of the time series

;first generate spacecraft velocity in gse coordinates.
;Cotrans cannot properly account for relative velocity of coordinate systems
;when transforming, thus this is best done with derivative not cotrans or thm_cotrans.
deriv_data,'th'+probe+'_state_pos',newname='th'+probe+'_state_vel'

;second generate the lunar velocity in gse coordinates by
;taking the derivative of the lunar position in gse coordinates
deriv_data,'slp_lun_pos_gse',newname='slp_lun_vel_gse'

;third interpolate lunar velocity onto state velocity
tinterpol_mxn,'slp_lun_vel_gse','th'+probe+'_state_vel' 

;next subtract moon velocity from the state velocity to account for relative motion of coordinate frames
calc,'"th'+probe+'_state_vel_sub"="th'+probe+'_state_vel"-"slp_lun_vel_gse_interp"',/verbose

;finally rotate the data into the new coordinate system
tvector_rotate,'sse_mat','th'+probe+'_state_vel_sub',newname='th'+probe+'_state_vel_sse'

options, 'th'+probe+'_state_vel_sse', ytitle='vel SSE', ysubtitle='[km/s]'
tplot, 'th'+probe+'_state_vel' + ['','_sse']

stop


;==================================================
; Inverse velocity transformation
;==================================================

;just do the transformation backwards.  First invert rotation, then invert offset
tvector_rotate,'sse_mat','th'+probe+'_state_vel_sse',newname='th'+probe+'_state_vel_sub_inv',/invert

calc,'"th'+probe+'_state_vel_sse_inv"="th'+probe+'_state_vel_sub_inv"+"slp_lun_vel_gse_interp"',/verbose

tplot, 'th'+probe+'_state_vel' + ['','_sse_inv','_sse']


stop


end