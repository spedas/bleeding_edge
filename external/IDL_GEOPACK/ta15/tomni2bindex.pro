;+
;Procedure: tomni2bindex
;
;Purpose: Generate the B-index parameter for the TA15B field model and store the result in a tplot variable.  Input parameters
;    will be smoothed on 30 minute intervals preceding each sample, and interpolated to a common time base before performing the calculation,
;
;Input:
;
;Keywords:
;         yimf_tvar:  (input) Name of a tplot variable giving the IMF Y component in GSM coordinates, e.g, OMNI_HRO_5min_Y_GSM
;
;         zimf_tvar:  (input) Name of a tplot variable giving the IMF Z component in GSM coordinates, e.g. OMNI_HRO_5min_Z_GSM
;
;         V_p_tvar:   (input) Solar wind (proton) speed, expressed as a scalar, in km/sec, e.g OMNI_HRO_5min_flow_speed
;         
;         N_p_tvar:   (input) Solar wind (proton) density, units cm^-3.  e.g. OMNI_HRO_5min_proton_density
;
;         times: (optional input) Array of timestamps at which the index will be calculated.   If not provided, the yimf times will be used.
;
;         newname: (optional) Name of the tplot variable to use for the output.  If not provided, 'b_index' will be used.
;
;Example:
;          tomni2bindex,yimf_tvar='OMNI_HRO_5min_BY_GSM',zimf_tvar='OMNI_HRO_5min_BZ_GSM',V_p_tvar='OMNI_HRO_5min_flow_speed', $
;                    N_p_tvar='OMNI_HRO_5min_proton_density',newname='b_index', times=times
;
;Notes:
;  See Boynton 2011 for details:
;  https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2010JA015505
;;
;  TA15B and TA15N model description:
;  https://geo.phys.spbu.ru/~tsyganenko/TA15_Model_description.pdf
;
;  The B-index calculation is implemented in omni2bindex.pro
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta15/tomni2bindex.pro $
;-

pro tomni2bindex, yimf_tvar=yimf_tvar,zimf_tvar=zimf_tvar, N_p_tvar=N_p_tvar, V_p_tvar=V_p_tvar, newname=newname, times=times

   if ~keyword_set(yimf_tvar) || (size(yimf_tvar,/type) ne 7) then begin
      dprint,'Required yimf_tvar parameter missing or invalid'
      return
   endif
   
   if ~keyword_set(zimf_tvar) || (size(zimf_tvar,/type) ne 7) then begin
     dprint,'Required zimf_tvar parameter missing or invalid'
     return
   endif

   if ~keyword_set(N_p_tvar) || (size(N_p_tvar,/type) ne 7) then begin
     dprint,'Required N_p_tvar parameter missing or invalid'
     return
   endif

   if ~keyword_set(V_p_tvar) || (size(V_p_tvar,/type) ne 7) then begin
     dprint,'Required V_p_tvar parameter missing or invalid'
     return
   endif

   if ~keyword_set(newname) || (size(newname,/type) ne 7) then begin
     dprint,'Required newname parameter missing or invalid'
     return
   endif
   
   if tnames(yimf_tvar) eq '' then dprint,yimf_tvar+' is not a valid tplot variable name.'
   if tnames(zimf_tvar) eq '' then dprint,zimf_tvar+' is not a valid tplot variable name.'
   if tnames(N_p_tvar) eq '' then dprint,N_p_tvar+' is not a valid tplot variable name.'
   if tnames(V_p_tvar) eq '' then dprint,V_p_tvar+' is not a valid tplot variable name.'
   
   tsmooth_in_time,yimf_tvar,1800.0,/smooth_nans,/backward,newname='BY_smooth'
   tsmooth_in_time,zimf_tvar,1800.0,/smooth_nans,/backward,newname='BZ_smooth'
   tsmooth_in_time,V_p_tvar,1800.0,/smooth_nans,/backward,newname='VP_smooth'
   tsmooth_in_time,N_p_tvar,1800.0,/smooth_nans,/backward,newname='NP_smooth'
   
   get_data,'BY_smooth',data=yimf_d
   get_data,'BZ_smooth',data=zimf_d
   get_data,'VP_smooth',data=vp_d
   get_data,'NP_smooth',data=np_d
   
   ; Interpolate onto common time base, using YIMF variable if none provided
   ; The smoothing operations above should have removed any NaNs -- if that changes, the interpolation should probably
   ; be changed to use tinterpol_mxn, /ignore_nans to avoid propagating NaNs into the modeling routines.
   
   if n_elements(times) eq 0 then times=yimf_d.x
   yimf = interp(yimf_d.y,yimf_d.x,times)
   zimf = interp(zimf_d.y,zimf_d.x,times)
   vp = interp(vp_d.y,vp_d.x,times)
   np = interp(np_d.y,np_d.x,times)

   b_index = omni2bindex(yimf=yimf, zimf=zimf, N_p=np, V_p=vp)   

   if n_elements(newname) eq 0 then newname='b_index'

   store_data,newname,data={x:times, y:b_index}
end
