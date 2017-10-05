;+
;function: thm_interpolate_state
;
;Purpose: interpolates the low res STATE file
;
;         all variables are structures as produced by get_data
;
;keywords:
;
;
;Examples:
;      tha_spinper_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_spinper=thx_spinper) --> linear interpolation
;      tha_spinphase_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_spinper=thx_spinper,thx_spinphase=thx_spinphase) --> phase constructed according to the nearest neighbor spin phase, spin period
;      tha_spinras_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_spinras=thx_spinras) --> linear interpolation
;      tha_spindec_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_spindec=thx_spindec) --> linear interpolation
;      tha_spinalpha_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_spinalpha=thx_spinalpha) --> linear interpolation
;      tha_spinbeta_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_spinbeta=thx_spinbeta) --> linear interpolation
;      tha_pos_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_pos=thx_pos) --> spline interpolation
;      tha_vel_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_vel=thx_vel) --> spline interpolation
;
;Notes: under construction!!
;
;Written by Hannes Schwarzl
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-06-13 17:51:42 -0700 (Thu, 13 Jun 2013) $
; $LastChangedRevision: 12531 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/thm_interpolate_state.pro $
;-


function thm_interpolate_state,thx_xxx_in=thx_xxx_in,thx_spinper=thx_spinper,thx_spinphase=thx_spinphase,thx_spinras=thx_spinras,thx_spindec=thx_spindec,thx_spinalpha=thx_spinalpha,thx_spinbeta=thx_spinbeta,$
		thx_pos=thx_pos,thx_vel=thx_vel


timeV=thx_xxx_in.X

is_kew_comb=0

if keyword_set(thx_xxx_in) && keyword_set(thx_spinper) then begin
	is_kew_comb=1
	;linearly interpolate the spinperiod
	sperInterp = interpol( thx_spinper.Y,thx_spinper.X,thx_xxx_in.X)

	thx_xxx_out = CREATE_STRUCT('X',timeV ,'Y',sperInterp,'V',000.0)


endif

if keyword_set(thx_xxx_in) && keyword_set(thx_spinphase) && keyword_set(thx_spinper) then begin
	is_kew_comb=1
        thm_sunpulse, thx_spinphase.x, thx_spinphase.y, thx_spinper.y, $
                      sunpulse, sunpulse_spinper
        thm_spin_phase, thx_xxx_in.x, phase, sunpulse, sunpulse_spinper

	thx_xxx_out = CREATE_STRUCT('X',timeV ,'Y',phase,'V',000.0)

endif



if keyword_set(thx_xxx_in) && keyword_set(thx_spinras) then begin
	is_kew_comb=1
	;linearly interpolate the right ascencion angle
	rasInterp = interpol( thx_spinras.Y,thx_spinras.X,thx_xxx_in.X)
	thx_xxx_out = CREATE_STRUCT('X',timeV ,'Y',rasInterp,'V',000.0)
endif

if keyword_set(thx_xxx_in) && keyword_set(thx_spindec) then begin
	is_kew_comb=1
	;linearly interpolate the elevation angle
	decInterp = interpol( thx_spindec.Y,thx_spindec.X,thx_xxx_in.X)
	thx_xxx_out = CREATE_STRUCT('X',timeV ,'Y',decInterp,'V',000.0)
endif



if keyword_set(thx_xxx_in) && keyword_set(thx_spinalpha) then begin
	is_kew_comb=1
	;linearly interpolate the alpha angle
	alphaInterp = interpol( thx_spinalpha.Y,thx_spinalpha.X,thx_xxx_in.X)
	thx_xxx_out = CREATE_STRUCT('X',timeV ,'Y',alphaInterp,'V',000.0)
endif

if keyword_set(thx_xxx_in) && keyword_set(thx_spinbeta) then begin
	is_kew_comb=1
	;linearly interpolate the beta angle
	betaInterp = interpol( thx_spinbeta.Y,thx_spinbeta.X,thx_xxx_in.X)
	thx_xxx_out = CREATE_STRUCT('X',timeV ,'Y',betaInterp,'V',000.0)
endif



if keyword_set(thx_xxx_in) && keyword_set(thx_vel) then begin
	is_kew_comb=1
	;spline interpolate the velocity
	count=n_elements(thx_xxx_in.X)
	velInterp=indgen(count,3,/float)
	velInterp[*,0] = interpol( thx_vel.Y,thx_vel.X,thx_xxx_in.X,/SPLINE)
	velInterp[*,1] = interpol( thx_vel.Y,thx_vel.X,thx_xxx_in.X,/SPLINE)
	velInterp[*,2] = interpol( thx_vel.Y,thx_vel.X,thx_xxx_in.X,/SPLINE)
	thx_xxx_out = CREATE_STRUCT('X',timeV ,'Y',velInterp,'V',000.0)
endif

if keyword_set(thx_xxx_in) && keyword_set(thx_pos) then begin
	is_kew_comb=1
	;spline interpolate the position
	count=n_elements(thx_xxx_in.X)
	posInterp=indgen(count,3,/float)
	posInterp[*,0] = interpol( thx_pos.Y[*,0],thx_pos.X,thx_xxx_in.X,/SPLINE)
	posInterp[*,1] = interpol( thx_pos.Y[*,1],thx_pos.X,thx_xxx_in.X,/SPLINE)
	posInterp[*,2] = interpol( thx_pos.Y[*,2],thx_pos.X,thx_xxx_in.X,/SPLINE)
	thx_xxx_out = CREATE_STRUCT('X',timeV ,'Y',posInterp,'V',000.0)
endif

if	is_kew_comb eq 0 then begin
	dprint, 'wrong combination of input arguments'
	stop
endif

RETURN, thx_xxx_out
end

