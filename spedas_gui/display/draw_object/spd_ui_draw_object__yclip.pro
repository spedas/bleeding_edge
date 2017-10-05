;+
;spd_ui_draw_object method: yclip
;
;This routine, performs prepocessing with respect to the y-axis
;
;1. translates data from linear to log space, if necessary
;2. Removes invalid values or marks with NaNs depending on whether trace in spectrographic and spec geometry.
;   Reasons for marking/removing
;    a. non-finite.
;    b. out of range
;    c. le 0 on log axis
;    
;3. Performs analogous removals on z/mirror data
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
;range(2-element double) : The min and max y-range that the data should be clipped to.
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
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__yclip.pro $
;-
pro spd_ui_draw_object::yclip,xPtr,yPtr,zPtr,range,scale,mirrorptr=mirrorptr,fail=fail

  compile_opt idl2,hidden
  
  fail = 1
  
  ;allocate output arrays
  outx = ptrarr(n_elements(xPtr))
  outy = ptrarr(n_elements(yPtr))
  outz = ptrarr(n_elements(zptr))
  
  if keyword_set(mirrorptr) then begin
    outmirror = ptrarr(n_elements(mirrorptr))
  endif
  
  for i = 0,n_elements(yPtr)-1 do begin
  
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
    
    ;sort 1 dimensional y-axis....I'm not sure what to do with 2-d ones here
    ;This is descending, as per the convention in tplot/spedas data
    ;If the y is ascending, the data will have vertical inversion and probably other problems
    if keyword_set(z) && ndimen(y) eq 1 then begin
    
      idx = reverse(bsort(y))
      
      y = y[idx]
      z = z[*,idx]
    
    endif
       
    ;apply logarithmic scaling to x values, out of range values will be marked by translation in -Inf, then removed when we screen out of range values
    if scale eq 1 then begin
      y = alog10(y)
    endif else if scale eq 2 then begin
      y = alog(y)
    endif 
    
    if keyword_set(mirror) then begin
      if scale eq 1 then begin
        mirror = alog10(mirror)
      endif else if scale eq 2 then begin
        mirror = alog(mirror)
      endif
      
;      idx = where(mirror lt range[0] or mirror gt range[1],c)
;      
;      if c ne 0 then begin
;        mirror[idx] = !VALUES.D_NAN
;      endif
      
      outmirror[i] = ptr_new(temporary(mirror))
      
    endif

   ;doesn't remove non-spec data, NaN marks is sufficient, and prevents ugly clips of line plots
    if ~keyword_set(z) then begin
    
;      idx = where(y lt range[0] or y gt range[1],c)
;      if c gt 0 then begin
;        y[idx] = !VALUES.D_NAN
;      endif
      
    endif else begin
    
      ;Spectral plots are created
      ;using bin-centers.  So if we clip to the range
      ;we clip out 1/2 a bin.  This code leaves 1-bin of margin, to 
      ;prevent blank edges from clipping.


      ;Lower Bound Clip Block

      ;this code assumes that the y-axis is sorted and descending, which happens to
      ;be the convention used with tplot variables.    
      idx = where(y lt range[0],c)
      
      if c eq n_elements(y) then continue
      
      if c gt 1 then begin
      
        if ndimen(y) eq 1 then begin
        
          idx = idx[1:c-1]    
          y[idx] = !VALUES.D_NAN
          z[*,idx] = !VALUES.D_NAN
        
        endif else begin
          ;this code should perform the same operation as was performed on the 1-d data
          ;but it performs it for each column of y's.
          ;It requires some complex index manipulations to do vectorized
          idx2 = self->indexMagic(y,idx,/less)
          
          ;it returns 2-d indices, so we should expect at least 2 elements if we have any clipping to do.
          if n_elements(idx2) gt 1 then begin
         
            y[idx2[0,*],idx2[1,*]] = !VALUES.D_NAN
            z[idx2[0,*],idx2[1,*]] = !VALUES.D_NAN
            
          endif
        
        endelse
      
      endif
      
      ;Upper Bound Clip Block
      
      
      ;this code assumes that the y-axis is sorted and descending, which happens to
      ;be the convention used with tplot variables.    
      idx = where(y gt range[1],c)
      
      if c eq n_elements(y) then continue
      
      if c gt 1 then begin
      
        if ndimen(y) eq 1 then begin
        
          idx = idx[0:c-2]    
          y[idx] = !VALUES.D_NAN
          z[*,idx] = !VALUES.D_NAN
        
        endif else begin
        
         ;this code should perform the same operation as was performed on the 1-d data
          ;but it performs it for each column of y's
          idx2 = self->indexMagic(y,idx)
          
          ;it returns 2-d indices, so we should expect at least 2 elements if we have any clipping to do.
          if n_elements(idx2) gt 1 then begin
         
            y[idx2[0,*],idx2[1,*]] = !VALUES.D_NAN
            z[idx2[0,*],idx2[1,*]] = !VALUES.D_NAN
            
          endif
          
        endelse
           
      endif
    
      ;now clip.  Why clip?  Performance improves significantly if we can pare down the data-set
      if ndimen(y) eq 1 then begin
      
        idx = where(finite(y),c)
           
        ;don't draw if there are no valid points
        if c eq 0 then continue
      
        y = y[idx]
        z = z[*,idx]
      
      endif else begin
      
        ;this expression will only have a nan at any position if every value in the row at that position is NaN 
        max_val = max(y,dimension=1,/nan)
      
        ;interior rows should not be removed, unless their neighboring rows are also all NaNs
        ;this fun code identifies these rows
        ;This vector technique operates something like the game minesweeper
        idx = where(finite(max_val),c,complement=comp)
        
        if c ne 0 then begin
          max_val[idx] = 1
        endif
        
        if c ne n_elements(max_val) then begin
          max_val[comp] = 0
        endif
        
        ;0 pad to prevent the computation from getting messed up
        row_indicator = [0,max_val,0]
        
        row_indicator = shift(row_indicator,1)+row_indicator+shift(row_indicator,-1)
        
        ;clip off the padding
        row_indicator = row_indicator[1:n_elements(row_indicator)-2]
         
        valid = where(row_indicator gt 0,c)
        
        if c eq 0 then begin
          ;don't draw if there are no valid points
          continue
        endif
        
        ;remove any leading rows that are all nans
        if valid[0] eq 0 && max_val[0] eq 0 && n_elements(valid) gt 1 then begin
          valid = valid[1:n_elements(valid)-1]
        endif 
        
        ;remove any trailing rows that are all nans
        if valid[n_elements(valid)-1] eq n_elements(max_val)-1 && max_val[n_elements(max_val)-1] eq 0 && n_elements(valid) gt 1 then begin
          valid = valid[0:n_elements(valid)-2]
        endif
        
        ;clip the rows off
        y = y[*,valid]
        z = z[*,valid]
         
      endelse
    
      outz[i] = ptr_new(temporary(z))
    
    
    endelse   
    
    outx[i] = ptr_new(temporary(x))
    outy[i] = ptr_new(temporary(y))
  
  endfor
  
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
