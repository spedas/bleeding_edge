;+
; NAME:
;   jbt_extrema (function)
;
; PURPOSE:
;   Find extrema in a numerical array and return their indices.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   result = jbt_extrema(array, interp_nan = interp_nan, min_only = min_only, $
;     max_only = max_only, threshold = threshold)
;
; ARGUMENTS:
;   array: (In, required) The array to find extrema in.
;
; KEYWORDS:
;   /interp_nan: If set, remove NaNs by linear interpolation before searching
;         for extrema.
;   /min_only: If set, only return minima.
;   /max_only: If set, only return maxima.
;   threshold: (In, optional) Threshold for changing sense. For example, if
;         threshold is 10 and A[i] and A[i+1] are two adjacent points in a local
;         segment that generally has positive slope, then the segment will be
;         treated as a full positive-slope segment if A[i+1]-A[i] > -10.
;         Default = 0.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;     ; IDL code example
;     npt = 100
;     a = randomn(seed, npt)
;     x = findgen(npt)
;     ind = jbt_extrema(a)
;     plot, x, a
;     oplot, x[ind], a[ind], psym = 2, color = 6
;
; SEE ALSO:
;
; HISTORY:
;   2012-11-10: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-12: Initial release in TDAS. JBT, SSL/UCB.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-11-12 08:36:20 -0800 (Mon, 12 Nov 2012) $
; $LastChangedRevision: 11219 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/jbt_extrema.pro $
;
;-

function jbt_extrema, array, interp_nan = interp_nan, min_only = min_only, $
  max_only = max_only, threshold = threshold

compile_opt idl2

npt = n_elements(array)
if npt lt 3 then begin
  dprint, 'Too few elements. Abort.'
  return, -1
endif

ind = where(finite(array, /nan), nind)
if nind gt 0 then begin
  if keyword_set(interp_nan) then begin
    dum = findgen(npt)
    arr = interp(array, dum, dum, /ignore_nan)
  endif else begin
    dprint, 'NaNs or Infs exist in the input array. Abort.'
    return, -1
  endelse
endif else arr = array

if n_elements(threshold) eq 0 then threshold = 0d

mincon = intarr(npt)
maxcon = intarr(npt)

darr = arr[1:*] - arr

; Slope > -threshold
ind = where(darr ge -threshold, nind)
if nind eq 0 then begin
  dprint, 'Monotonic input. Abort.'
  return, -1
endif
seg_irange = jbt_iconsec(ind)
ista = reform(seg_irange[*,0])
iend = reform(seg_irange[*,1])
imin = ista
imax = iend + 1
mincon[imin] = 1
maxcon[imax] = 1

maxcon[0] = 0
maxcon[npt-1] = 0
mincon[0] = 0
mincon[npt-1] = 0

imin = where(mincon, n_min)
imax = where(maxcon, n_max) 

if keyword_set(min_only) then return, imin
if keyword_set(max_only) then return, imax

iex = where(mincon or maxcon, n_ex)

return, iex


; ; Algorithm: -- Obsolete
; ; 1. Start.
; ; 2. March forward until hit an extremum.
; ; 3. Record the extremum.
; ; 4. Repeat
; 
; ista = 1L
; while ista lt npt - 1 do begin
;   ; Mark the sense: towards a maximum or a minimum.
;   if arr[ista] gt arr[ista-1] then sense = 1   ; towards a maximum
;   if arr[ista] lt arr[ista-1] then sense = -1  ; towards a minimum
;   if arr[ista] eq arr[ista-1] then begin
;     ista++
;     continue
;   endif
; 
;   i = ista
;   while 1 do begin
;     ; Maximum
;     if sense gt 0 then begin
;       if arr[i] - arr[i-1] ge thres_max then begin
;         i++
;         if i ge npt then begin
;           ista = i
;           break
;         endif
;         continue
;       endif else begin
;         maxcon[i-1] = 1
;         ista = i
;         break
;       endelse
;     endif
;     ; Minimum
;     if sense lt 0 then begin
;       if arr[i] - arr[i-1] le thres_min then begin
;         i++
;         if i ge npt then begin
;           ista = i
;           break
;         endif
;         continue
;       endif else begin
;         mincon[i-1] = 1
;         ista = i
;         break
;       endelse
;     endif
;   endwhile
; endwhile
; 
; imin = where(mincon, n_min)
; imax = where(maxcon, n_max) 
; 
; if keyword_set(min_only) then return, imin
; if keyword_set(max_only) then return, imax
; 
; iex = where(mincon or maxcon, n_ex)
; return, iex

end
