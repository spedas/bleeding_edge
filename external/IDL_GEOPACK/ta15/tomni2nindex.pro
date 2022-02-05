;+
;Procedure: tomni2nindex
;
;Purpose: Generate the N-index parameter for the TA15N field model and store the result in a tplot variable.  Input parameters
;    will be smoothed on 30 minute intervals preceding each sample, and interpolated to a common time base before performing the calculation,
;
;Input:
;
;Keywords:
;         yimf_tvar:  (input) Name of a tplot variable giving the IMF Y component in GSM coordinates, e.g, OMNI_HRO_5min_Y_GSM
;         
;         zimf_tvar:  (input) Name of a tplot variable giving the IMF Z component in GSM coordinates, e.g. OMNI_HRO_5min_Z_GSM
;         
;         V_p_tvar:   (input) Solar wind (proton) speed, expressed as a scalar, in km/sec, e.g OMNI_HRO_5min_proton_speed
;
;         times: (optional input) Array of timestamps at which the index will be calculated.   If not provided, the yimf times will be used.
;
;         newname: (optional) Name of the tplot variable to use for the output.  If not provided, 'n_index' will be used.
;         
;Example:
;        tomni2nindex,yimf='OMNI_HRO_5min_BY_GSM',zimf='OMNI_HRO_5min_BZ_GSM',V_p='OMNI_HRO_5min_flow_speed',newname='n_index',times=times
;
;Notes:
;  See Newell 2007 for details:
;  https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2006JA012015
;  
;  TA15B and TA15N model description:
;  https://geo.phys.spbu.ru/~tsyganenko/TA15_Model_description.pdf
;  
;  The N-index calculation is implemented in omni2nindex.pro
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2022-02-03 22:14:10 -0800 (Thu, 03 Feb 2022) $
; $LastChangedRevision: 30558 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta15/tomni2nindex.pro $
;-

pro tomni2nindex, yimf_tvar=yimf_tvar,zimf_tvar=zimf_tvar, V_p_tvar=V_p_tvar,trange=trange,newname=newname

   if ~keyword_set(yimf_tvar) || (size(yimf_tvar,/type) ne 7) then begin
      dprint,'Required yimf_tvar parameter missing or invalid'
      return
   endif
   
   if ~keyword_set(zimf_tvar) || (size(zimf_tvar,/type) ne 7) then begin
     dprint,'Required zimf_tvar parameter missing or invalid'
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
   
   if tnames(yimf_tvar) eq '' then begin
    dprint,yimf_tvar+' not a valid tplot variable'
    return
   endif
 
   if tnames(zimf_tvar) eq '' then begin
     dprint,zimf_tvar+' not a valid tplot variable'
     return
   endif

   if tnames(V_p_tvar) eq '' then begin
     dprint,V_p_tvar+' not a valid tplot variable'
     return
   endif
   
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
 
   yimf=yimf_interp.y
   zimf=zimf_interp.y
   vp=V_p_interp.y
   
   n_index = omni2nindex(yimf=yimf, zimf=zimf, V_p=vp)
   
   if n_elements(newname) eq 0 then newname='n_index'   

   store_data,newname,data={x:ntimes, y:n_index}
end
