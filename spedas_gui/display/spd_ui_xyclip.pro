;+
;
;Procedure: spd_ui_xyclip
;
;; NOTE: This code has been incorporated into the draw object.  
; spd_ui_xyclip is no longer called directly
;
;Purpose:
;  helper routine for draw object.  It performs some processing
;  on the x,y,z trace inputs
;
;Inputs:
;  onePtr: the values being clipped
;  twoPtr: the axis for which paired values must also be removed
;  zPtr: the z for spectral plots
;  range: the range for the clipping
;  scale: the scaling for the axis(0:linear,1:log10,2:logN)
;  
;Keywords: fail: 1: indicates that the routine failed
;       
;          transposez: if this keyword is set, then one is a y-axis not an x-axis
;
;   
;Notes:
;  Scales & Clips the x,y axes. Mutates onePtr,twoPtr,zPtr
;
;   
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/spd_ui_xyclip.pro $
;-

pro spd_ui_xyclip,onePtr,twoPtr,zPtr,range,scale,fail=fail,transposez=transposez,yaxis=yaxis,mirrorptr=mirrorptr

  compile_opt idl2

  fail = 1
  
  out1 = ptrarr(n_elements(onePtr))
  out2 = ptrarr(n_elements(twoPtr))
  outz = ptrarr(n_elements(zptr))
  if keyword_set(mirrorptr) then begin
    outmirror = ptrarr(n_elements(mirrorptr))
  endif
  
  for i = 0,n_elements(onePtr)-1 do begin
   
    if ~ptr_valid(onePtr[i]) || $
       ~ptr_valid(twoPtr[i]) then continue
   
    one = *onePtr[i]
    two = *twoPtr[i]
    
    if keyword_set(mirrorptr) && $
       ptr_valid(mirrorptr[i]) then begin
       
       mirror = *mirrorptr[i]
       
    endif else begin
       
       mirror = 0
    
    endelse  
     
    
    if ptr_valid(zPtr[i]) then z = *zptr[i]

    ;if we've got a logarithmic scale remove out of bounds values
    if scale eq 1 || scale eq 2 then begin

      ;this section adds NaNs to the yaxis of line plots
      if keyword_set(yaxis) && ~ptr_valid(zPtr[i]) then begin
        idx = where(one lt 0,c)
        
        if c ne 0 then begin
          one[idx] = !VALUES.D_NAN
        endif
        
        if keyword_set(mirror) then begin
        
          idx = where(mirror lt 0,c)
          
          if c ne 0 then begin
            mirror[idx] = !VALUES.D_NAN
          endif
        
        endif
        
      endif else begin ;this section clips subzero values for x-axes & for line plots and xy z-plot axes
        idx = where(one gt 0,c)

        if c eq 0 then continue
      
        if ptr_valid(zPtr[i]) then begin
          
          minidx = min(idx)-1
          if minidx ge 0 then begin
            idx = [minidx,idx]
          endif
          
          maxidx = max(idx)+1
          if maxidx lt n_elements(one) then begin
            idx = [idx,maxidx]
          endif 
          
          one = one[idx]
          
          if transposez then begin
             z = z[*,idx]
          endif else begin
             z = z[idx,*]
          endelse
        endif else begin
          one = one[idx]
          two = two[idx]
          if keyword_set(mirror) then mirror=mirror[idx]
        endelse
      endelse
    
      if scale eq 1 then one = alog10(one)
      if scale eq 2 then one = alog(one)
      
      if keyword_set(mirror) && keyword_set(yaxis) then begin
        if scale eq 1 then mirror = alog10(mirror)
        if scale eq 2 then mirror = alog(mirror)
      endif
      
    endif
  
    ;Now clip into range
  
    ;This section replaces y-axis line plot values with NaNs
    if keyword_set(yaxis) && ~ptr_valid(zPtr[i]) then begin
      idx = where(one lt range[0] or one gt range[1],c)
      
      if c ne 0 then begin
        one[idx] = !VALUES.D_NAN
      endif
      
      if keyword_set(mirror) then begin
        
        idx = where(mirror lt range[0] or mirror gt range[1],c)
          
        if c ne 0 then begin
          mirror[idx] = !VALUES.D_NAN
        endif
        
      endif
      
    endif else begin ;this section clips out of range values for x-axes & for line plots and xy z-plot axes
    
      idx = where(one ge range[0] and one le range[1],c)
   
      if c eq 0 then begin
      
        tmp = min(abs(one - range[0]),idx1)
        tmp = min(abs(one - range[1]),idx2)
        
        if idx1 eq idx2 then begin
          idx = [idx1]
        endif else begin
          idx = [idx1,idx2]
        endelse
      
  ;      out1[i] = ptr_new()
  ;      out2[i] = ptr_new()
  ;      if ptr_valid(zPtr[i]) then outz[i] = ptr_new()
  ;      continue
      endif
    
      ;this code clips the zvalues while the axis is clipped
      if ptr_valid(zPtr[i]) then begin
      
          ;this code makes sure we don't clip too far 
          minidx = min(idx)-1
          if minidx ge 0 then begin
            idx = [minidx,idx]
          endif
          
          maxidx = max(idx)+1
          if maxidx lt n_elements(one) then begin
            idx = [idx,maxidx]
          endif 
      
          one = one[idx]
      
        if transposez then begin
          z = z[*,idx]
        endif else begin
          z = z[idx,*]
        endelse
      endif else begin
        one = one[idx]
        two = two[idx]
        if keyword_set(mirror) then mirror = mirror[idx]
      endelse
    
    endelse
    
    out1[i] = ptr_new(one)
    out2[i] = ptr_new(two)
    if ptr_valid(zPtr[i]) then outz[i] = ptr_new(z)
    if keyword_set(mirror) then outmirror[i] = ptr_new(mirror)
    
  endfor
 
  ptr_free,onePtr
  ptr_free,twoPtr
  onePtr = out1
  twoPtr = out2
  zPtr = outz
  
  if keyword_set(outmirror) then mirrorptr = outmirror
  
  fail = 0
  
  return 

end
