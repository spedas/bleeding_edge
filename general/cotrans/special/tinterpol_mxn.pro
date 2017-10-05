;+
;Function: tinterpol_mxn
;
;Purpose:
;  Performs interpolation on tplot variables.
;Interpolates xv_tvar to match uz_tvar.  Can also interpolate with non-tvar types
;and return non-tvar types. (Helpful for interpolating matrices and time-series vectors)
;
;This function works on any n or nxm dimensional vectors. Interpolation always occurs along first dimension(time)
;
;              
;Arguments:
;            xv_tvar(source) = tplot variable to be interpolated, the y component
;            can have any dimesions, can use globbing to interpolate
;            many values at once
;            uses x component for x abcissa values
;            Can also pass in a struct with the same format as the 
;            data component for a tplot variable:
;            {x:time_array,y:data_array,v:optional_y_axis_abcissas}
;            
;            uz_tvar(target) = tplot variable that V will be fit to
;            uses x component for u abcissa values.  Can also
;            pass in an array of time values rather than a tplot 
;            variable.
;            
;            newname = output tplot variable name(optional) defaults to
;            xv_tvar+'_interp'.  If you want vector output, use the keyword "out"
;            
;            suffix = a suffix other than interp you can use,
;            particularily useful when using globbing
;            
;            overwrite=set this variable if you just want
;            the original variable overwritten instead of using
;            newname or suffix
;
;            Use only newname or suffix or overwrite. If you combine
;            them the naming behavior may be erratic
;
;            /LINEAR = set this keyword to specify linear
;            interpolation(this is the default behavior)
;            
;            /QUADRATIC = set this keyword to specify quadratic
;            interpolation
;            
;            /SPLINE = set this keyword to specify spline
;            interpolation
;            
;            /NEAREST_NEIGHBOR = set this keyowrd to specify repeat
;            nearest neighbor 'interpolation' 
;            
;            /NO_EXTRAPOLATE = set this keyword to prevent
;            extrapolation of data values in V passed it's start and
;            end points
;            
;            /NAN_EXTRAPOLATE = set this keyword to extrapolate past
;            the endpoints using NaNs as a fill value
;            
;            /REPEAT_EXTRAPOLATE = set this keyword to repeat nearest value past the endpoints
;            
;            /IGNORE_NANS = set this keyword to remove nans in the data before interpolation
;
;            ERROR(optional): named variable in which to return the error state
;            of the computation.  1 = success 0 = failure
;
;Outputs(optional):
;   out:
;     Returns output as a data struct. If this argument is present, no tplot variable will be created.
;     Note that only one result can be returned through this keyword.(ie You can't use this keyword with tplot name-globbing)  
;
;CALLING SEQUENCE;
;           tinterpol_mxn,'tplot_var1','tplot_var2',newname='tplot_var_out'
;           tinterpol_mxn,'tplot_var1','tplot_var2',/NO_EXTRAPOLATE
;           tinterpol_mxn,'tplot_var1','tplot_var2',/SPLINE
;           tinterpol_mxn,'tplot_var1','tplot_var2',out=out_data_struct ;doesn't create tplot variable, instead returns struct
;           tinterpol_mxn,'tplot_var1',time_array ;This calling method doesn't require second tplot variable
;           tinterpol_mxn,{x:time_array,y:data_array},'tplot_var2' ;This calling method doesn't require first tplot variable
;           tinterpol_mxn,{x:time_array,y:data_array,v:y_scale_vals},time_array,out=out_data_struct ; You can mix and match calling types. This calling method doesn't use any tplot variables
;         
;Output: an N by D1 by D2 by ... array stored in an output tplot variabel
;
;Notes: 
;Uses a for loop over D1*D2*..., but I'm operating under the assumption that
;D1*D2... << M (D1 * D2 *... is waaaay less than M)
;
;It uses a little bit of modular arithmatic so this function is
;generalized to any array dimensionality(IDL limits at 8)
;
;Examples:
; if the input is an array of 3-d vectors(say 1,1,1 and 2,2,2) and we
; want 3 vectors out the output is 1,1,1 1.5 1.5 1.5 2,2,2
; if the input is an array of 3x3 matrices(say all ones and all twos) 
; and we want three matrices then output is all 1s all 1.5s all 2s 
; 
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-10-31 11:32:53 -0700 (Mon, 31 Oct 2016) $
; $LastChangedRevision: 22236 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/tinterpol_mxn.pro $
;-

;Helper function
;a method for nearest neighbour interpolation in cases where you need an irregular grid
; In cases where you are simply scaling the input array you can use congrid instead.
;NB: this function is the same as thm_ui_nearestneighbor in thm_ui_interpolate because the interpolate
; code is already repeated in thm_ui_interpolate. If you find a bug here, fix it in the other version too.
function ctv_nearestneighbor, v, x, u
; v: these are the actual values that will be interpolated (interpolates along one dimension)
; x: these are the x values (probably time) corresponding to the data (v) values (one dim array) - must be monotonically incr or decr
; u: this is the new array of x values, again 1 dim

compile_opt hidden

n_u = n_elements(u)
n_x = n_elements(x)

;-------------------------------------------------------------------------------------
;Method 1: should work even if x is not monotonically incr. But can be very slow or
;run out of memory for large arrays
;-------------------------------------------------------------------------------------
;;this puts into the variable index the index of the closest value in x to each value in u
;; the resulting index is a one-dim subscript of a 2-dim array and thus must be manipulated further
;mindiff = min(abs(rebin(x,n_x,n_u) - rebin(transpose(u),n_x,n_u)),index,dimension=1)
;; convert index to multidim subscript
;index2d = array_indices([n_x,n_u],index,/dimensions)
;; only the first column of index2d is useful, containing index into x of nearest neigbor to each point in u
;; second column is just 0,1,2,3,..etc
;actualindex = transpose(index2d[0,*])

;-------------------------------------------------------------------------------------
;Method 2: only works if x is monotonically increasing or decreasing (same is true for interpol)
;Should be faster than above method for large arrays.
;-------------------------------------------------------------------------------------
;value_locate brackets each u in x
nearvalue = transpose(value_locate(x,u))
neararray = [nearvalue>0, (nearvalue+1)<(n_x-1)]; form an array with columns nearvalue and nearvalue +1, but restrict to valid indices into n_x
mindiff = min(abs(x[neararray]-rebin(transpose(u),2,n_u)),index, dimension=1)
; index gives you the (1 dim) index in neararray, indicating whether nearvalue or nearvalue+1 is closer
; the mod converts simply to 0 or 1
actualindex = transpose(nearvalue>0 + (index mod 2))


output = v[actualindex]
return, output
end

;helper function
;actually does the bulk of the work
function ctv_interpol_vec_mxn,v,x,u,nearest_neighbor=nearest_neighbor,ignore_nans=ignore_nans,_extra=_extra

COMPILE_OPT HIDDEN

n = n_elements(u)

if n le 0 then return,-1L

;if the value is atomic return it
if(size(v,/n_dim) eq 0) then begin 
    error=1
    return,replicate(v,n_elements(u))
endif

v_s = size(v,/dimensions)

;handle single input case...it should extrapolate a constant matrix
if(v_s[0] eq 1) then begin
    v_s[0] = 2
    v = rebin(v,v_s)
    x = rebin([x],2)
    x[1] = x[0] + 1.0 ;so the timeseries ascends
endif

;I think I actually handled the 1 case generally
;if(n_elements(v_s) eq 1) then return,interpol(v,n)

v_s_o = v_s

v_s_o[0] = n

out = dindgen(v_s_o)

;the transpose and the reverse make the indexing scheme work out
;cause the in variables(and tplot variables) work more or less in row
;row major, but idl indexes column major
out_idx = transpose(lindgen(reverse(v_s_o)))

in_idx = transpose(lindgen(reverse(v_s)))

;calculate the number of elements in each matrix/vectors/whatever

product = 1

if n_elements(v_s) gt 1 then begin
  product = product(v_s[1:*])
endif

;for i = 1,n_elements(v_s) - 1L do begin
;
;    product *= v_s[i]
;
;endfor

for i = 0,product-1L do begin

    idx1 = where((out_idx mod product) eq i)
    idx2 = where((in_idx mod product) eq i)

    if(size(idx1,/n_dim) eq 0 || $
       n_elements(idx1) ne n || $
       size(idx2,/n_dim) eq 0 || $
       n_elements(idx2) ne v_s[0]) $
       then return, -1L
       
    if not keyword_set(u) then begin
      if keyword_set(nearest_neighbor) then begin
        out[idx1] = congrid( v[idx2],n)
      endif else begin
         ;temporarily disabled until we can come up with a solution that works for IDL 7 or earlier. pcruce 2014-10-27
         ;out[idx1] = interpol(v[idx2],n,nan=ignore_nans,_extra=_extra)
         if keyword_set(ignore_nans) then begin
           idx3 = where(~finite(v[idx2],/nan),c)
           if c gt 0 then begin
             out[idx1] = interpol(v[idx2[idx3]],n,_extra=_extra)
           endif else begin ;if data is all NANs, you get all NANs
             out[idx1] = interpol(v[idx2],n,_extra=_extra)
           endelse
         endif else begin
           out[idx1] = interpol(v[idx2],n,_extra=_extra)
         endelse
      endelse
    endif else begin
      if keyword_set(nearest_neighbor) then begin
        out[idx1] = ctv_nearestneighbor(v[idx2],x,u)
      endif else begin
        ;temporarily disabled until we can come up with a solution that works for IDL 7 or earlier. pcruce 2014-10-27
        ;out[idx1] = interpol(v[idx2],x,u,nan=ignore_nans,_extra=_extra)
        if keyword_set(ignore_nans) then begin
          idx3 = where(~finite(v[idx2],/nan),c)
          if c gt 0 then begin
            out[idx1] = interpol(v[idx2[idx3]],x[idx3],u,_extra=_extra)
          endif else begin ;if data is all NANs, you get all NANs
            out[idx1] = interpol(v[idx2],x,u,_extra=_extra)
          endelse
        endif else begin
          out[idx1] = interpol(v[idx2],x,u,_extra=_extra)
        endelse
      endelse
    endelse

endfor
; for nearest neighbor case cast the output type to the input type
; This is so that if you interpolate bit-packed data you will still be
; able to use bitplot to plot it. It may be that all data should be cast
; to its input type - or maybe not.
if keyword_set(nearest_neighbor) then begin
  out = fix(out, type=size(v, /type))
endif

return,out

end

;Helper function to fill the rows of dat with repeated values.
;Just call twice to do it on both the high and low side
pro ctv_repeat_fill_idx,dat,repeat_range_idx,repeat_value_idx
  
  compile_opt hidden

  if repeat_range_idx[0] ne -1 && repeat_value_idx[0] ne -1 then begin
    
    if ndimen(dat) eq 1 then begin
      dat[repeat_range_idx] = dat[repeat_value_idx]
    endif else begin
      dat[repeat_range_idx,*] = dat[repeat_value_idx,*] ## (make_array(n_elements(repeat_range_idx),type=size(dat,/type))+1)
    endelse
    
  endif

end

;This helper function fills rows of dat with nans.
;idx is the rows to be filled.  dat can have any number of dimensions
pro ctv_nan_fill_idx,dat,idx

  compile_opt hidden

  if idx[0] eq -1 then return
  
  dat_dim = dimen(dat)
  
  if n_elements(dat_dim) eq 1 then begin
    dat[idx] = !VALUES.D_NAN
  endif else begin
    multiplier = product(dat_dim[1:*]) 
    nan_idx = rebin(idx,n_elements(idx),multiplier)+dat_dim[0]*transpose(lindgen(multiplier,n_elements(idx)) mod multiplier)
    dat[nan_idx] = !VALUES.D_NAN
  endelse

end

pro tinterpol_mxn, xv_tvar, uz_tvar,$
                  newname = newname,$
                  no_extrapolate = no_extrapolate,$
                  nan_extrapolate=nan_extrapolate,$
                  repeat_extrapolate=repeat_extrapolate,$
                  error=error,$
                  suffix=suffix,$
                  overwrite=overwrite,$
                  nearest_neighbor=nearest_neighbor,$
                  ignore_nans=ignore_nans,$
                  out=out_d,$
                  _extra = _extra

error=0

if not keyword_set(xv_tvar) then begin
  dprint, 'xv_tvar must be set for tinterpol_mxn to work'
  return
endif

if is_string(xv_tvar) then begin
  tn = tnames(xv_tvar)
  if size(tn,/n_dim) eq 0 && tn eq '' then begin
    dprint, 'xv_tvar must be set for tinterpol_mxn to work'
    return
  endif
endif else if is_struct(xv_tvar) then begin
  tn = strtrim(lindgen(n_elements(xv_tvar)),2)
endif else begin
  dprint, 'xv_tvar must be set for tinterpol_mxn to work'
  return
endelse

if not keyword_set(uz_tvar) then begin
  dprint, 'uz_tvar must be set for tinterpol_mxn to work'
  return
endif

if is_string(uz_tvar) then begin

  tn_match = tnames(uz_tvar)

  if tn_match eq '' then begin
    dprint, 'uz_tvar must be set for tinterpol_mxn to work'
    return
  endif
  
  get_data, tn_match, data = match_d
  
  match_d_x = match_d.x
  
endif else begin

  match_d_x = uz_tvar
  
endelse

;these naming keywords can interfere
;it is left to the user not to use them simultaneously

if keyword_set(suffix) then begin 
   newname = [tn+suffix] 
endif else if keyword_set(newname) then begin
   newname = [newname]
endif else if keyword_set(overwrite) then begin
   newname = [tn]
endif else begin
   newname = [tn + '_interp']
endelse

for i = 0, n_elements(tn) -1L do begin

   if ~is_struct(xv_tvar) then begin
     get_data,tn[i], data = in_d, limits = in_l, dlimits = in_dl
   endif else begin
     in_d = xv_tvar[i]
     in_l = 0
     in_dl = 0
   endelse

   if keyword_set(no_extrapolate) then begin

      in_min = min(in_d.x,max=in_max)

      idx = where(match_d_x ge in_min and match_d_x le in_max)

      if idx[0] eq -1L then begin
         dprint, 'tinterpol_mxn cannot interpolate any values without extrapolating, skipping'

         continue

      endif

      match_d_x = match_d_x[idx]

   endif else if keyword_set(nan_extrapolate) then begin

      in_min = min(in_d.x,max=in_max)

      nan_idx = where(match_d_x lt in_min or match_d_x gt in_max)
       
   endif else if keyword_set(repeat_extrapolate) then begin
     in_min = min(in_d.x,max=in_max)
     
     repeat_low_idx = where(match_d_x lt in_min)
     repeat_high_idx = where(match_d_x gt in_max)
     
     repeat_min_idx =  min(where(match_d_x ge in_min and match_d_x le in_max),max=repeat_max_idx)
     
   endif

   out_d_y = ctv_interpol_vec_mxn(in_d.y, in_d.x, match_d_x,nearest_neighbor=nearest_neighbor,ignore_nans=ignore_nans, _extra = _extra)

   if(size(out_d_y,/n_dim) eq 0 && out_d_y[0] eq -1L) then begin

      dprint,'TINTERPOL_MXN: interpolation Y-component calculation failed'

      return

   endif
   
   ;fill nans for d.y component
   if keyword_set(nan_extrapolate) then begin
   
     ctv_nan_fill_idx,out_d_y,nan_idx
   
   endif else if keyword_set(repeat_extrapolate) then begin

     ctv_repeat_fill_idx,out_d_y,repeat_low_idx,repeat_min_idx
     ctv_repeat_fill_idx,out_d_y,repeat_high_idx,repeat_max_idx
    
   endif

   str_element,in_d,'v',success=s

   if s eq 1 then begin
   
     v_dim = dimen(in_d.v)
     
     y_dim = dimen(in_d.y)
     
     if is_num(in_d.v) && n_elements(v_dim) eq n_elements(y_dim) && v_dim[0] eq y_dim[0] then begin
     
       out_d_v = ctv_interpol_vec_mxn(in_d.v, in_d.x, match_d_x,nearest_neighbor=nearest_neighbor,ignore_nans=ignore_nans, _extra = _extra)
       
       if(size(out_d_y,/n_dim) eq 0 && out_d_y[0] eq -1L) then begin
       
         dprint,'TINTERPOL_MXN: interpolation V-component calculation failed'
         
         return
         
       endif
       
       ;fill nans for d.v component
       if keyword_set(nan_extrapolate) then begin
   
         ctv_nan_fill_idx,out_d_v,nan_idx
   
       endif else if keyword_set(repeat_extrapolate) then begin
        
         ctv_repeat_fill_idx,out_d_v,repeat_low_idx,repeat_min_idx
         ctv_repeat_fill_idx,out_d_v,repeat_high_idx,repeat_max_idx
         
       endif
      
       out_d = {x:match_d_x, y:out_d_y, v:out_d_v}
      
     endif else begin
      
       out_d = {x:match_d_x, y:out_d_y, v:in_d.v}
       
     endelse 
   endif else begin
   
     out_d = {x:match_d_x,y:out_d_y}
     
   endelse

   if ~arg_present(out_d) then begin
     store_data, newname[i], data = out_d, limits = in_l, dlimits = in_dl
   endif

endfor

error=1

return

end
