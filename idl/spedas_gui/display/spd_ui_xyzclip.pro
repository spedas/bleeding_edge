;+
;
;Procedure: spd_ui_xyclip
;
;Purpose:
;  helper routine for draw object.  It performs some processing
;  on the z trace inputs
;
;Inputs:
;  zptr: array of ptrs to z values for this trace(2-d array)
;  zrange: the range for the z-axis on this panel
;  zscale: scaling for z-axis(0:linear,1:log10,2:logN) 
;      
;  
;Keywords: fail: 1: indicates that the routine failed
;          
;          
;
;   
;Notes:
;  Scales & Clips the axes and the z-plot correspondingly
;  Mutates Zptr
;
;   
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/spd_ui_xyzclip.pro $
;-
pro spd_ui_xyzclip,zptr,zrange,zscale,fail=fail

  compile_opt idl2
 
  fail = 1
  
  outz = ptrarr(n_elements(zptr))

  for i = 0,n_elements(zptr)-1 do begin
  
    if ptr_valid(zptr[i]) then begin
    
      z = *zptr[i]
    
      if zscale eq 1 then z = alog10(z)
      if zscale eq 2 then z = alog(z)
    
      idx = where(z lt zrange[0] and z gt zrange[1],c)
      
      if c then z[idx] = !VALUES.D_NAN
  
      outz[i] = ptr_new(z)
      
    endif
  
  endfor

  ptr_free,zPtr
  zPtr = outz

  fail = 0
  
  return

end
