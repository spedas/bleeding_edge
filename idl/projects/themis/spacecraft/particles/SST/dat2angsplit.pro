;+
;PROCEDURE: dat2angsplit
;
;HELPER function
;take the dat component of a structure and splits it into an array
;ordered in terms of theta =  energy*angle->energy*theta*phi
;dimensions 16*64->16*4*16,  phi is guaranteed to be contiguous but
;not necessarily ascending(some phi may be out of phase by 180 degrees)
;returns indices to perform this transformation

; $LastChangedBy: lphilpott $
; $LastChangedDate: 2012-06-14 10:44:44 -0700 (Thu, 14 Jun 2012) $
; $LastChangedRevision: 10559 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/dat2angsplit.pro $
;-
function dat2angsplit,dat

  compile_opt idl2,hidden
  
  index = indgen(16,64)
  t_sort = bsort(dat.theta[0,*])
  index = index[*,t_sort]
  return,transpose(reform(index,16,16,4),[0,2,1]) ; this magic properly reforms and orders the dimensions  

end