;+
;spd_ui_draw_object method: xclip
;
;This routine, performs prepocessing with respect to the x-axis
;
;1. translates data from linear to log space, if necessary
;2. Removes invalid values because:
;    a. non-finite
;    b. out of range
;    c. le 0 on log axis
;    
;3. Performs analogous removals on y/z/mirror data
;
;Inputs:
;
;xPtr(array of pointers to arrays):  A list of the data quantities for all x-values used in the panel. 
;                     The number of pointers should match the number of pointers in y and z.  
;                     If an x/y has no z(ie line plot), the corresponding element should be a null pointer
;yPtr(array of pointers to arrays) : A list of the data quantities for all y-values used in the panel. 
;                     The number of pointers should match the number of pointers in x and z. 
;                     If an x/y has no z(ie line plot), the corresponding element should be a null pointer
;zPtr(array of pointers to arrays) : A list of the data quantities for all z-values used in the panel. 
;                     The number of pointers should match the number of pointers in x and y.            
;                     If an x/y has no z(ie line plot), the corresponding element should be a null pointer     
;  
;range(2-element double) : The min and max x-range that the data should be clipped to.
;
;scale(long) : The scaling method to be used on this axis(0: linear,1:log10,2:logN)
;
;mirrorPtr(array of pointers to arrays) : A list of the data quantities for all mirror-values used in the panel. 
;                     The number of pointers should match the number of pointers in x,y, z            
;                     If an x/y has no mirror the corresponding element should be a null pointer      
;
;Outputs: 
;  xPtr(array of pointers to arrays): Input data replaced with clipped data. Format is the same
;  yPtr(array of pointers to arrays): Input data replaced with clipped data. Format is the same
;  zPtr(array of pointers to arrays): Input data replaced with clipped data. Format is the same
;  fail(named variable keyword):  Will store 1 if routine fails, 0 otherwise
;
;NOTES:
; This routine is a partial replacement for spd_ui_xyclip, which became unwieldy to maintain
; as the reponsibilities of the routine diverged.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__xclip.pro $
;-

pro spd_ui_draw_object::xclip,xPtr,yPtr,zPtr,range,scale,mirrorptr=mirrorptr,fail=fail

  compile_opt idl2,hidden

  fail = 1
  
  ;allocate output arrays
  outx = ptrarr(n_elements(xPtr))
  outy = ptrarr(n_elements(yPtr))
  outz = ptrarr(n_elements(zptr))
  
  if keyword_set(mirrorptr) then begin
    outmirror = ptrarr(n_elements(mirrorptr))
  endif
  
  ;loop over traces
  for i = 0,n_elements(xPtr)-1 do begin
  
    ;skip any traces that are invalid for any reason
    if ~ptr_valid(xPtr[i]) || $
       ~ptr_valid(yPtr[i]) then continue
   
    ;temporary allocations for the purpose of this algorithm
    x = temporary(*xPtr[i])
    y = temporary(*yPtr[i])
  
    if keyword_set(mirrorptr) && $
       ptr_valid(mirrorptr[i]) then begin
       mirror = temporary(*mirrorptr[i])
    endif else begin
       mirror = 0
    endelse  
    
    if ptr_valid(zPtr[i]) then begin
      z = temporary(*zPtr[i])
    endif else begin
      z = 0
    endelse
    
    ;apply logarithmic scaling to x values, out of range values will be marked by translation in -Inf, then removed when we screen out of range values
    if scale eq 1 then begin
      x = alog10(x)
    endif else if scale eq 2 then begin
      x = alog(x)
    endif
    
    ;sort x if spectral quantity
    if keyword_set(z) then begin
    
      sortidx = bsort(x)
      x = x[sortidx]
      
      if ndimen(y) eq 2 then begin
        y = y[sortidx,*]
      endif
      
      z = z[sortidx,*]
    
    endif
  
    ;identify out of range values
    idx = where(x lt range[0],c)
    
    if ~keyword_set(z) then begin
      ;add some margin, if possible
      if c gt 1 then begin
        idx = idx[0:n_elements(idx)-2]
        x[idx] = !values.d_nan
      endif
;      if c gt 0 then begin
;        x[idx] = !values.d_nan
;      endif
    endif else begin
      if c eq n_elements(x) then begin
        x[idx] = !values.d_nan
      endif else if c gt 1 then begin
        ;if we can, add a little bit of margin to the spectral plot
        ;this way we won't have blank edges when we zoom
        idx = idx[0:c-2]
        x[idx] = !values.d_nan
      endif
    endelse
    
    idx = where(x gt range[1],c)
    
    if ~keyword_set(z) then begin
;     if c gt 0 then begin
;       x[idx] = !values.d_nan
;     endif
      ;this code adds a little bit of margin
      ;to prevent gaps from clipping
      if c gt 1 then begin
        idx = idx[1:n_elements(idx)-1]
        x[idx] = !values.d_nan
      endif
    endif else begin
      if c eq n_elements(x) then begin
        x[idx] = !values.d_nan
      endif else if c gt 1 then begin
        ;if we can, add a little bit of margin to the spectral plot
        ;this way we won't have blank edges when we zoom
        idx = idx[1:c-1]
        x[idx] = !values.d_nan
      endif
    endelse
     
    ;now clip out of range values
    
    idx = where(finite(x),c)
     
    ;if no legitimate values are available, then the outptrs are left as null
    if c gt 0 then begin
    
      x = x[idx]
    
      ; clipping z-values entails 2-dimensional clipping
      if keyword_set(z) then begin
         
        if ndimen(y) eq 2 then begin
          y = y[idx,*]
        endif

        z = z[idx,*]
        
        outz[i] = ptr_new(temporary(z))
    
      endif else begin
   
       ;clipping z-values, is 1-d but may also entail clipping a mirror
        y = y[idx]
        
        if keyword_set(mirror) then begin
          mirror = mirror[idx]
          outmirror[i] = ptr_new(temporary(mirror))
        endif
    
      endelse
      
      outx[i] = ptr_new(temporary(x))
      outy[i] = ptr_new(temporary(y))
    endif
    
  endfor
  
  ;replace input data with output
  ptr_free,xPtr,yPtr,zPtr
  
  if keyword_set(mirrorptr) then begin
    ptr_free,mirrorPtr
    mirrorPtr = outmirror
  endif
  
  xPtr = outx
  yPtr = outy
  zPtr = outz
  
  fail = 0
       
end
