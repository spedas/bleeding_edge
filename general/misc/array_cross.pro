;+
; FUNCTION array_cross(l1,l2)
; Purpose:
;    returns a 2*n array, where n = n_elements(l1)*n_elements(l2)
;    each pair is a combination of l1 and l2
;    the total list represents all possible pairings of l1 and l2
;
; Written by Patrick Cruce
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2009-03-11 11:10:36 -0700 (Wed, 11 Mar 2009) $
; $LastChangedRevision: 5255 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/array_cross.pro $
;-
function array_cross, l1, l2

  a = n_elements(l1)
  b = n_elements(l2)

  ;p1 is a list of replicated elements, ie ['a','a','a','b','b','b']
  p1 = l1[ul64indgen(a*b)/b] 
  
  ;p1 is a list of alternating elements, ie ['ffw_16','ffw_32','ffw_64','ffp_16','ffp_16','ffp_32','ffp_64']
  p2 = l2[ul64indgen(a*b)mod b]

  return, transpose([[p1], [p2]])

end
