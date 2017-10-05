;+
;Procedure: spin_tones_cleaning_vec_v5
;
;Purpose:  compute an averaged signal with a specified averaging window duration
;          and substract this averaged signal to raw signal
;
;keywords: none
; input :t_vec,VEC,wind_dur,samp_per
;        t_vec is a time array
;        VEC is a time vector
;        wind_dur is the duration of the averaging,
;        samp_per is the sample period of t_vec and VEC
; output :VEC_AV has the duration of VEC but is obtained by
;                duplicating the average signal over one averaging window
;                along the whole time period
;                the average signal is obtained by summing all averaging
;                windows within the whole time period
;         VEC_CLEANED is equal to VEC-VEC_AV,
;         nbwind is the number of averaging window within the whole time period,
;         nbpts_cl is the number of points within the whole time period
;                i.e. also the dimension of t_vec_cleaned and VEC_CLEANED
;Example:
;   spin_tones_cleaning_vector, t_vec,VEC,wind_dur,samp_per,$
;                               t_vec_cleaned,VEC_AV,VEC_CLEANED,nbwind,nbpts_cl
;Notes:
;  This routine is (should be) platform independent.
;
;History:
; 12 june 2007, written by Olivier Le Contel
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2012-01-26 16:43:03 -0800 (Thu, 26 Jan 2012) $
;$LastChangedRevision: 9624 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/spin_tones_cleaning_vector_v5.pro $
;-

pro spin_tones_cleaning_vector_v5, t_vec,VEC,wind_dur,samp_per,$
                                   t_vec_cleaned,VEC_AV,VEC_CLEANED,nbwind,nbpts_cl

nbpts = n_elements(t_vec)
dprint, 'npbts =', nbpts

nbwind  = floor(nbpts*samp_per/wind_dur,/L64)
dprint, 'nbwind =', nbwind
nbpts_wind = floor(wind_dur/samp_per,/L64)
dprint, 'nbpts_wind =',nbpts_wind

nbpts_cl =  nbwind*nbpts_wind
dprint, 'nbpts_cl(=nbwind*nbpts_wind)= ',nbpts_cl
If(nbpts_cl Eq 0) Then Begin ;short batches will return NaN, jmm, 9-feb-2009
  dprint,' warning: No points, returning 1 NaN value'
  vec_cleaned = vec[0, *] & vec_cleaned[*] = !values.f_nan
  vec_av = vec_cleaned
  t_vec_cleaned = t_vec[0]
  nbpts_cl = 1
  Return
Endif
if (nbpts_cl ne nbpts) then dprint, 'warning: the cleaned waveform will be shorter than the raw waveform'

t_vec_cleaned = dblarr(nbpts_cl)
VEC_AV = dblarr(nbpts_cl,3)*0.
VEC_CLEANED = dblarr(nbpts_cl,3)*0.
t_vec_wind = dblarr(nbpts_wind,nbwind)
VEC_AV_WIND = dblarr(nbpts_wind,3)*0.
VEC_AV_3D = dblarr(nbpts_wind,nbwind,3)

k = 0L
;computation of averaged noise by superposing nbwind windows of wind_dur duration (in sec)
while (k le nbwind-1L) do begin
	ind_wind = indgen(nbpts_wind,/L64)+k*nbpts_wind

	VEC_AV_WIND(*,0)   = VEC_AV_WIND(*,0) + VEC(ind_wind,0)
	VEC_AV_WIND(*,1)   = VEC_AV_WIND(*,1) + VEC(ind_wind,1)
	VEC_AV_WIND(*,2)   = VEC_AV_WIND(*,2) + VEC(ind_wind,2)
	t_vec_wind(*,k)    = t_vec(ind_wind)

	k = k + 1L
endwhile

VEC_AV_WIND = VEC_AV_WIND/nbwind

;building of averaged noise waveform for the whole time period
;by duplicating nbwind times the one window duration averaged noise
for j=0L,nbwind-1L do begin
	VEC_AV_3D(*,j,0) = VEC_AV_WIND(*,0)
	VEC_AV_3D(*,j,1) = VEC_AV_WIND(*,1)
	VEC_AV_3D(*,j,2) = VEC_AV_WIND(*,2)
endfor

VEC_AV(*,0) = VEC_AV_3D(*,*,0)
VEC_AV(*,1) = VEC_AV_3D(*,*,1)
VEC_AV(*,2) = VEC_AV_3D(*,*,2)

t_vec_cleaned(*) = t_vec_wind(*,*)


; substracting the averaged noise waveform to the raw waveform

VEC_CLEANED(*,0) = VEC(*,0) - VEC_AV(*,0)
VEC_CLEANED(*,1) = VEC(*,1) - VEC_AV(*,1)
VEC_CLEANED(*,2) = VEC(*,2) - VEC_AV(*,2)

return
end

