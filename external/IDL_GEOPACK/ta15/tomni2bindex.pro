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
; $LastChangedDate: 2022-01-31 22:37:47 -0800 (Mon, 31 Jan 2022) $
; $LastChangedRevision: 30552 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta15/tomni2bindex.pro $
;-

pro tomni2bindex, yimf_tvar=yimf_tvar,zimf_tvar=zimf_tvar, N_p_tvar=N_p_tvar, V_p_tvar=V_p_tvar, newname=newname,trange=trange

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
   


   if not keyword_set(trange) then tlims = timerange(/current) else tlims=trange

   ;identify the number of 5 minute time intervals in the specified range
   n = fix(tlims[1]-tlims[0],type=3)/300 +1
   ;the geopack parameter generating functions only work on 5 minute intervals

   ;construct a time array
   ntimes=dindgen(n)*300+tlims[0]
   
   ; Interpolate input variables to 5-minute grid, ensuring no NaNs in output
   tinterpol_mxn,yimf_tvar,ntimes,/ignore_nans,out=yimf_interp
   tinterpol_mxn,zimf_tvar,ntimes,/ignore_nans,out=zimf_interp
   tinterpol_mxn,V_p_tvar,ntimes,/ignore_nans,out=V_p_interp
   tinterpol_mxn,N_p_tvar,ntimes,/ignore_nans,out=N_p_interp
   
   yimf=yimf_interp.y
   zimf=zimf_interp.y
   vp=V_p_interp.y
   np=N_p_interp.y

   b_index = omni2bindex(yimf=yimf, zimf=zimf, N_p=np, V_p=vp)   

   if n_elements(newname) eq 0 then newname='b_index'

   store_data,newname,data={x:ntimes, y:b_index}
end
