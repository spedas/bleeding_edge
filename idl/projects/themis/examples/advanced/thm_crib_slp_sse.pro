;+
;Name:
;  thm_crib_slp_sse
;
;Purpose:
;  Crib to demonstrate how to use Solar Lunar Planetary Data,
;  And how to perform SSE transformation
;
;Notes:
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-05-14 17:01:41 -0700 (Thu, 14 May 2015) $
; $LastChangedRevision: 17619 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_slp_sse.pro $
;-


;=============================
; Notes
;=============================
;
;     SSE is defined as:
;        X: Moon->Sun Line
;        Y: Ecliptic North cross X
;        Z: X cross Y
;         
;     GSE is defined as:
;        X: Earth Sun Line(naturally in the ecliptic plane)
;        Y: Z x X
;        Z: Ecliptic North


;=============================
; Crib
;=============================

;set the time
timespan,'2007-03-23'

;download some fgm data to demostrate transform on
thm_load_fgm, probe = 'a', coord = 'gse', level = 'l2'

;load slp data
;detailed descriptions of loaded quantities
;can be found in the thm_load_slp.pro header
;Calling this routine is necessary for thm_cotrans to do the transform
thm_load_slp

thm_cotrans,'tha_fgl_gse','tha_fgl_sse',out_coord='sse'

;The difference here should be very small.
;Rotation is on the order of 1 degree
tplot,['tha_fgl_gse','tha_fgl_sse']

thm_load_state,probe='a'

thm_cotrans,'tha_state_pos','tha_state_pos_sse',out_coord='sse'

;The difference here should be pretty big
;thm_cotrans performs an affine transformation when going to 'sse'
;if the data's dlimits label it as a position.  This means that the
;rotation is performed, and the frame of reference is translated to moon-center
tplot,['tha_state_pos','tha_state_pos_sse']

stop

;if you want to coord transform a position without the translational component use
;  -position/velocity/acceleration/none labels can be found in
;   dlimits.data_att.st_type, allowed values are 'pos','vel','acc','none'
thm_cotrans,'tha_state_pos',in_coord='gei','tha_state_pos_sse',out_coord='sse',/ignore_dlimits

tplot,['tha_state_pos','tha_state_pos_sse']

stop

end
