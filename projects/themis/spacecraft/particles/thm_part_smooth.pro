;+
;
;Procedure: thm_part_smooth
;
;Purpose: 
;  This routine applies time-smoothing to particle data using a convolution method.  Default is boxcar, 
;    but other kernels may be supplied by the user.
;
;Inputs:
;  dist_data:
;     The data to be smoothed.  Data should have been loaded using thm_part_dist_array.pro.  This data will be modified 
;     during the operation of this routine.
;     
;Keywords:
;  width=width The width of a boxcar smooth.  (Default=3,just creates a boxcar kernel.)
;  kernel=kernel  A 1-d array containing a kernel to be applied by CONVOL across time.  If you don't want to shift the levels of the data,
;         total(kernel) should equal 1.0d.  If kernel= is set, width= is ignored. 
;  scale_factor=scale_factor  A scale_factor to be applied to the convol.  (See convol documentation for details)
;  trange=trange: Specify a time based subset of the data for the smoothing to be applied to.  Allows different smoothing parameters to be applied at
;    different times by calling this routine multiple times.
;  _extra=ex:  You can provide any of the normal convol keywords when using this routine(e.g. /edge_wrap, /edge_truncate,invalid=i,missing=i,/nan,etc...)
;  error=error:  After completion, will be set 1 if error occured, zero otherwise
;  
;  
;Notes:
;  #1. The CONVOL routine is applied separately to each mode.  This is because the cadence and shape of the dist array will change across mode boundaries.
;    Be aware that this can cause strange artifacts at mode boundaries in smoothed particle data.
;  #2. See the CONVOL documentation in the IDL help for more info on how the smoothing is performed.
;  
;Examples:
;  ;5-point boxcar smooth
;  thm_part_smooth,dist_data,width=5,/edge_truncate,/nan
;  ;21-point boxcar smooth
;  thm_part_smooth,dist_data,kernel=(dblarr(21)+1)/21d,/edge_wrap
;  ;Manually normalized gaussian smooth
;  x= dindgen(101)/10.-5.
;  nonnorm_kernel=deriv(gaussint(x))
;  thm_part_smooth,dist_data,kernel=nonnorm_kernel/total(nonnorm_kernel)
;  
;  ;automatically normalized gaussian smooth
;  x= dindgen(101)/10.-5.
;  thm_part_smooth,dist_data,kernel=deriv(gaussint(x)),/normalize
;   
;See also: thm_part_dist_array.pro,thm_crib_part_extrapolate.pro,CONVOL(in IDL help)
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-09-21 16:55:28 -0700 (Fri, 21 Sep 2012) $
; $LastChangedRevision: 10943 $
; $URL $
;-
pro thm_part_smooth,dist_data,width=width,kernel=kernel,scale_factor=scale_factor,trange=trange,_extra=ex,error=error

  compile_opt idl2,hidden

  error = 1

  ;check inputs
  if size(dist_data,/type) ne 10 then begin
    dprint,dlevel=1,"ERROR: dist_data undefined or has wrong type"
    return
  endif
  
  if ~keyword_set(width) then begin
    width=3
  endif
  
  if ~keyword_set(kernel) then begin
    kernel=(dblarr(double(width))+1)/double(width)
  endif
  
  if n_elements(scale_factor) eq 0 then begin
    scale_factor=1.0
  endif

  if n_elements(trange) ne 0 then begin
    if n_elements(trange) ne 2 then begin
      dprint,dlevel=1,"ERROR: trange, should be a 2-element array"
      return
    endif
    trange_dbl=time_double(trange) ;ensure that string inputs are converted to doubles
  endif

  ;loop over modes
  for i=0,n_elements(dist_data)-1 do begin  
    
    if n_elements(trange_dbl) ne 0 then begin
      ;dedekind cut
      idx = where((*dist_data[i]).time ge trange[0] and (*dist_data[i]).time lt trange[1],n_samples) 
    endif else begin
      ;dummy values, all elements in the mode
      n_samples=n_elements(*dist_data[i])
      idx = dindgen(n_samples)
    endelse
      
    
    if n_samples lt n_elements(kernel) then begin
      dprint,'WARNING: Too few points in mode: ' + strtrim(i+1) + '. No smoothing applied this mode.',dlevel=2
      continue
    endif
    
    for j = 0,n_elements((*dist_data[i])[0].data)-1 do begin
      (*dist_data[i])[idx].data[j] = convol((*dist_data[i])[idx].data[j],kernel,scale_factor,_extra=ex) 
    endfor
   
  endfor
  
  error=0

end