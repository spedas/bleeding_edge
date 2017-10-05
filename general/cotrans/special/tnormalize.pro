;+
;PROCEDURE: TNORMALIZE
;Purpose:
;  Vectorized routine to normalize all the vectors stored in a tplot
;  variable
;
;
;Arguments: 
; v: The name or number of the tplot variable storing the vectors to be
; normalized, or an array of vectors to be normalized.  NOTE, if the input is
; not a tplot variable, this routine will not generate a tplot variable for output
; newname(optional): The name of the output tplot variable. Defaults
; to v+'_normalized'
; error(optional): Named variable in which to return the error state
; of the computation, 1 = success, 0 = failure
; out(optional):  If set to a named variable, the output will be stored
;              in out, rather than a tplot variable.
; 
;
;NOTES:
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-23 16:21:34 -0800 (Mon, 23 Jan 2012) $
; $LastChangedRevision: 9592 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/tnormalize.pro $
;-

;helper function
;calculates the norm of a bunch of vectors simultaneously
function ctv_norm_vec_helper,v

COMPILE_OPT HIDDEN

if not keyword_set(v) then return, -1L

if size(v,/n_dim) ne 2 then return,-1L

return, sqrt(total(v^2,2))

end

;helper function
;normalizes a bunch of vectors simultaneously
function ctv_normalize_vec_helper,v

COMPILE_OPT HIDDEN

if ~keyword_set(v) then return, -1L

dim = dimen(v)

if n_elements(dim) ne 2 then begin
 v = reform(v,1,dim[0])
endif

n_a = ctv_norm_vec_helper(v)

if(size(n_a,/n_dim) eq 0 && n_a eq -1L) then return,-1L

v_s = size(v,/dimension)

;calculation is pretty straight forward
;we turn n_a into an N x D so computation can be done element by element
n_b = rebin(n_a,v_s[0],v_s[1])

return,v/n_b

end

pro tnormalize,v,newname=newname,error=error,out=out_d

if arg_present(error) then error = 0

if ~keyword_set(v) then begin

    dprint,'TNORMALIZE: input vector v must be set'

    return

endif 

if is_string(v) || n_elements(v) eq 1 then begin

  v_name = tnames(v)

  if v_name eq '' then begin
  
      dprint,'TNORMALIZE: input vector v must be set'
  
      return
  
  endif 
  
  get_data,v_name,data=d,limits=l,dlimits=dl
  
  if ~is_struct(d) || ~in_set(strlowcase(tag_names(d)),'y') then begin
    dprint,v_name + ' has bad data'
    return
  endif
  
  data = d.y
 
endif else begin
  data = v
  v_name = 'var' 
endelse

if ~keyword_set(newname) then newname = v_name + '_normalized'

out_d = ctv_normalize_vec_helper(data)

if(size(out_d,/n_dim) eq 0 && out_d[0] eq -1L) then begin
    
    dprint,'TNORMALIZE: failed to normalize input vector'

    return

endif

if ~arg_present(out_d) then begin

  if ~is_struct(d) then begin
    dprint, 'Tplot argument not present, cannot construct tplot output'
    return
  endif 

  str_element,d,'v',SUCCESS=s
  
  if(s) then $
    d = {x:d.x,y:out_d,v:d.v} $
  else $
    d = {x:d.x,y:out_d} 
  
  store_data,newname,data=d,limits=l,dlimits=dl
  
endif

error = 1

return

end
