;+
;
;function: Logical_xor
;
;
;Purpose:
;  IDL has logical_and, and logical_or, but not logical_xor
;  This routine add this capability 
; 
; $LastChangedBy: pcruce $
; $LastChangedDate: 2009-06-12 11:33:39 -0700 (Fri, 12 Jun 2009) $
; $LastChangedRevision: 6178 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/SSW/logical_xor.pro $
;- 


function logical_xor,arg1,arg2

  return,(arg1 || arg2) && (~arg1 || ~arg2) 
  
end