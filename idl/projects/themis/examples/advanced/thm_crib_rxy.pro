;+
;Procedure:
;  rxy_crib.pro
;
;Purpose:
;  A crib showing how to transform data into the RXY coordinate system. This
;  coordinate system is a variant of GSM that has the GSM Z axis, but the XY-plane is 
;  rotated so that the X-axis is on the Earth->Spacecraft line, and more positive values
;  are further from the earth.
;
;Notes:
;  Code heavily based on make_mat_Rxy.pro & transform_gsm_to_rxy.pro by Christine Gabrielse(cgabrielse@ucla.edu)
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-05-14 16:11:04 -0700 (Thu, 14 May 2015) $
; $LastChangedRevision: 17618 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_rxy.pro $
;-

probe = 'a'
timespan,'2008-03-23'

thm_load_state,probe=probe,coord='gsm'

rxy_matrix_make,'th'+probe+'_state_pos'

thm_load_fgm,probe=probe,coord='gsm',level='l2'

tvector_rotate,'th'+probe+'_state_pos_rxy_mat','th'+probe+'_fgl_gsm'

tplot,['th'+probe+'_fgl_gsm','th'+probe+'_fgl_gsm_rot','th'+probe+'_state_pos']

end