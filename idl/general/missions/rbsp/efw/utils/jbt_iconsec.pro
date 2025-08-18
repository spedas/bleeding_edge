;+
; NAME:
;   jbt_iconsec (function)
;
; CATEGORY:
;
; PURPOSE:
;   Given an array of indices, find consecutive sections in the array, and
;   return the starting and ending indices of each section. The returned value
;   has dimension [nsec, 2]
;
; CALLING SEQUENCE:
;   result = jbt_iconsec(indarr, nsec = nsec, npt = npt)
;
; ARGUMENTS:
;   indarr: (In, required) An index array.
;
; KEYWORDS:
;   nsec: (Out, optional) Number of consective sections in indarr.
;   npt: (Out, optional) Number of points in each section.
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2011-05-20: Created by Jianbao Tao (JBT), CU/LASP.
;   2012-11-12: Initial release in TDAS. JBT, SSL/UCB.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-11-12 08:36:20 -0800 (Mon, 12 Nov 2012) $
; $LastChangedRevision: 11219 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/jbt_iconsec.pro $
;
;-

function jbt_iconsec, indarr, nsec = nsec, npt = npt

; nsec: number of consecutive sections.
; npt: number of points in each section.

  ; Check indarr.
  if (size(indarr))[0] eq 0 then begin
    dprint, 'An array of indcies must be given. Exiting...'
    return, -1
  endif

  ; Deal with one-element indarr.
  if n_elements(indarr) eq 1 then begin
    ista = indarr
    iend = indarr
    nsec = 1L
    npt = [1L]
    return, [[ista], [iend]]
  endif

  ; Normal case, i.e., n_elements(indarr) > 1.
  ind = indarr
  dind = ind[1:*] - ind
  ; ind2 indices into ind of ending points of a consecutive points.
  ind2 = where(dind gt 1, nind2) 
  if nind2 gt 0 then begin
    iend = ind[ind2]
    ista = ind[ind2 + 1L]
    ; Adjust for starting and ending periods.
    iend = [iend, max(ind)]
    ista = [min(ind), ista]
  endif else begin
    ista = [min(ind)]
    iend = [max(ind)]
  endelse

  nsec = n_elements(ista)
  npt = iend - ista + 1L
  return, [[ista], [iend]]

end
