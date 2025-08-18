;+
;Function: tinterpol
;
;Purpose:
;Wrapper for tinterpol_mxn.  Performs interpolation on tplot variables.
;Interpolates xv_tvar to match uz_tvar.  Can also interpolate with non-tvar types
;and return non-tvar types. (Helpful for interpolating matrices and time-series vectors)
;
;This function works on any n or nxm dimensional vectors. Interpolation always occurs along first dimension(time)
;
;              
;Arguments:
;            xv_tvar = tplot variable to be interpolated, the y component
;            can have any dimesions, can use globbing to interpolate
;            many values at once
;            uses x component for x abcissa values
;            Can also pass in a struct with the same format as the 
;            data component for a tplot variable:
;            {x:time_array,y:data_array,v:optional_y_axis_abcissas}
;            
;            uz_tvar = tplot variable that V will be fit to
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
;            /LINEAR = pass this argument to specify linear
;            interpolation(this is the default behavior)
;            
;            /QUADRATIC = pass this argument to specify quadratic
;            interpolation
;            
;            /SPLINE = pass this argument to specify spline
;            interpolation
;            
;            /NEAREST_NEIGHBOR = pass this argument to specify repeat
;            nearest neighbor 'interpolation' 
;            
;            /NO_EXTRAPOLATE = pass this argument to prevent
;            extrapolation of data values in V passed it's start and
;            end points
;            
;            /NAN_EXTRAPOLATE = pass this argument to extrapolate past
;            the endpoints using NaNs as a fill value
;
;            /REPEAT_EXTRAPOLATE = pass this argument to repeat nearest value past the endpoints
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
;           tinterpol,'tplot_var1','tplot_var2',newname='tplot_var_out'
;           tinterpol,'tplot_var1','tplot_var2',/NO_EXTRAPOLATE
;           tinterpol,'tplot_var1','tplot_var2',/SPLINE
;           tinterpol,'tplot_var1','tplot_var2',out=out_data_struct ;doesn't create tplot variable, instead returns struct
;           tinterpol,'tplot_var1',time_array ;This calling method doesn't require second tplot variable
;           tinterpol,{x:time_array,y:data_array},'tplot_var2' ;This calling method doesn't require first tplot variable
;           tinterpol,{x:time_array,y:data_array,v:y_scale_vals},time_array,out=out_data_struct ; You can mix and match calling types. This calling method doesn't use any tplot variables
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
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-10-17 08:33:58 -0700 (Mon, 17 Oct 2016) $
; $LastChangedRevision: 22105 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tinterpol.pro $
;-

;This procedure shown here so users can see argument list:
;pro tinterpol_mxn, xv_tvar, uz_tvar, newname = newname,no_extrapolate = no_extrapolate,nan_extrapolate=nan_extrapolate,error=error,suffix=suffix,overwrite=overwrite,out=out_d,  _extra = _extra

pro tinterpol,xv_tvar, uz_tvar,_ref_extra=ex

  tinterpol_mxn,xv_tvar, uz_tvar,_extra=ex
  
end