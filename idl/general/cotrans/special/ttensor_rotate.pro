;+
;NAME:
; ttensor_rotate
;PURPOSE:
; Wrapper for tvector_rotate, to allow rotation of pressure and
; momentum flux tensors defined as ntimes, 6 arrays
; CALLING SQEUENCE: (same as tvector_rotate)
;  Using tplot variables:
;    ttensor_rotate, 'matrix_var', 'tensor_var' [,newname='out_var'] 
;                    [,invert=invert] [,suffix=suffix] [,error=error]
;                    [,/vector_skip_nonmonotonic]
;                    [,/matrix_skip_nonmonotonic]
;
;Arguments:
; mat_var_in: The name of the tplot variable storing input matrices
;             The y component of the tplot variable's data struct should be
;             an Mx3x3 array, storing a list of transformation matrices. 
; tens_var_in: The name of tplot variable(s) storing a pressure or mf tensor
;              The y component of the tplot variable's data
;              struct should be an Nx6 array. 
; newname(optional): the name of the output variable, defaults to 
;                    tens_var_in + '_rot'
;                    Newname should only be used if a single tensor
;                    variable is rotated
; suffix: The suffix to be appended to the tplot variable(s)
;         (Default: '_rot')
; error(optional): named variable in which to return the error state
; of the computation.  1 = success 0 = failure
;NOTES: the program will change the input tensor or tplot variable(s)
;       to mx3x3 inputs suitable for tvector_rotate and reset at the end
;SEE ALSO:  tvector_rotate.pro, mva_matrix_make.pro,
;           fac_matrix_make.pro,rxy_matrix_make
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-02-05 15:58:04 -0800 (Tue, 05 Feb 2019) $
; $LastChangedRevision: 26557 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/ttensor_rotate.pro $
;-
Pro ttensor_rotate, mat_var_in, tens_var_in, newname=newname, $
                    invert=invert,suffix=suffix,error=error, $
                    vector_skip_nonmonotonic = vector_skip_nonmonotonic,$
                    matrix_skip_nonmonotonic = matrix_skip_nonmonotonic

  mat_var = tnames(mat_var_in)
  tens_var = tnames(tens_var_in)
;Subscripts for returning tensor to 3x3
  map3x3 = [[0,3,4],[3,1,5],[4,5,2]]
;subscripts for creating 6 element tensor from 3x3 symmetric tensor
  mapt = [0,4,8,1,2,5]
;check data variables, if the array is nx6, then reform to 3x3 and
;process
  If(~is_string(mat_var) || ~is_string(tens_var)) Then Begin
     dprint, 'Invalid rotation matrix variable or tensor variable'
     Return
  Endif
  ntens = n_elements(tens_var)
  For j = 0, ntens-1 Do Begin
     get_data, tens_var[j], data = t
     If(~is_struct(t)) Then Begin
        dprint, dlevel=2, tens_var[j]+' has no data'
        Continue
     Endif
     nyt = n_elements(t.y[0,*])
     If(nyt Eq 6) Then Begin    ;Do the rotation
        nx = n_elements(t.y[*,0])
        tynew = replicate(t.y[0,0], nx, 3, 3) & tynew[*] = 0
        For k = 0, nx-1 Do tynew[k, *, *] = t.y[k, map3x3]
        store_data, tens_var[j], data = {x:t.x, y:tynew}
;Catch tvector rotate errors here
        errj = 0
        catch, errj
        If(errj Ne 0) Then Begin
           errj = 0
           catch, /cancel
           dprint, 'Error Caught, resetting '+tens_var[j]
;Reset original tensor to nX6, and continue
           If(is_struct(t)) Then Begin
              store_data, tens_var[j], data = t
              undefine, t
           Endif
           Continue
        Endif
        tvector_rotate, mat_var, tens_var[j], $
                        newname=newname,suffix=suffix,$
                        vector_skip_nonmonotonic=vector_skip_nonmonotonic,$
                        matrix_skip_nonmonotonic=matrix_skip_nonmonotonic,$
                        error=error,invert=invert,/tensor_rotate
;Convert back into ntimesX6 arrays
        If(keyword_set(newname)) Then nnew = newname $
        Else If(keyword_set(suffix)) Then nnew = tens_var[j]+suffix $
        Else nnew = tens_var[j]+'_rot'
        get_data, nnew, data = t1
        If(is_struct(t1)) Then Begin
           nx = n_elements(t1.y[*, 0])
           tynew = replicate(t1.y[0, 0], nx, 6) & tynew[*] = 0
           For k = 0, nx-1 Do Begin
              tyk = reform(t1.y[k, *, *])
              tynew[k, *] = tyk[mapt]
           Endfor
           store_data, nnew, data = {x:t1.x, y:tynew}
           undefine, t1, tynew
        Endif
;original needs to be transformed back too
        store_data, tens_var[j], data = t
        undefine, t
     Endif Else Begin
        dprint, dlevel=2, tens_var[j]+' is not an nX6 tensor variable'
     Endelse
  Endfor
  Return
End

  
