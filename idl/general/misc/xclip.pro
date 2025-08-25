;+ NAME: 
; xclip 
;PURPOSE:
; Replaces with FLAGs the values of the array that are BEYOND
; the limits specified.
;CALLING SEQUENCE:
; xclip, amin, amax, y, flag=flag, _extra=_extra
;INPUT:
; amin, amax = the minumum and maximum values
; y = the input array
;OUTPUT:
; y = set to flag for points less than amin or greater than amax
;KEYWORDS:
; flag = the value that clipped data will be set to, the default is
;           -0.0/0.0 (NaN)
; clip_adjacent = if set, then clip the vales adjacent to the bad
;                 ones, as in tdespike_ae.pro
; interior_clip (optional): removes data inside the selected region instead of outside the selected region
; 
;HISTORY:
; 2-feb-2007, jmm, jimm.ssl.berkeley.edu from Vassilis'
; clip_deflag.pro
; 9-feb-2007, change big value to Nan
; 9-oct-2007, added option to clip the points adjacent to the bad
;             ones, as in tdespike_ae.pro 
; 20-Oct-2007, Jmm, Added this comment to test commit comand
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
;$LastChangedRevision: 33563 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/xclip.pro $
;-
Pro xclip, amin, amax, y, flag = flag, clip_adjacent = clip_adjacent, interior_clip=interior_clip, $
           _extra = _extra

  If size(flag, /type) GT 1 Then big = flag Else big = !values.f_nan

;More than max value? ;less than min value?
  if keyword_set(interior_clip) then begin
    ss = where(y gt amin and y lt amax, nss)
  endif else begin
    ss = where(y Lt amin or y Gt amax, nss)
  endelse
  
  If(nss Gt 0) Then Begin
    If(keyword_set(clip_adjacent)) Then Begin
;Y can be 1, 2 or 3 dimensional, the clipping will happen in the first
;dimension
      szy = size(y)
      Case szy[0] Of
        1:begin
          for k = 0l, nss-1l do begin
            i = ss[k]
            imin = (i-2) > 0
            imax = (i+2) < (n_elements(y)-1)
            y[imin:imax] = big
          endfor
        end
        2:begin
          For j = 0, szy[2]-1 Do Begin
            ty = y[*, j]
            xclip, amin, amax, ty, flag = flag, interior_clip=interior_clip, /clip_adjacent
            y[*, j] = ty
          Endfor
        end
        3:begin
          For k = 0, szy[3]-1 Do For j = 0, szy[2]-1 Do Begin
            ty = y[*, j, k]
            xclip, amin, amax, ty, flag = flag, interior_clip=interior_clip, /clip_adjacent
            y[*, j, k] = ty
          Endfor
        end
        else: dprint, 'xclip, /clip_adjacent only will deal with 1 2 or 3d arrays'
      Endcase
    Endif Else y[ss] = big
  Endif
;All Done
  Return
End
