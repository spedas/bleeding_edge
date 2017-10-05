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
;HISTORY:
; 2-feb-2007, jmm, jimm.ssl.berkeley.edu from Vassilis'
; clip_deflag.pro
; 9-feb-2007, change big value to Nan
; 9-oct-2007, added option to clip the points adjacent to the bad
;             ones, as in tdespike_ae.pro 
; 20-Oct-2007, Jmm, Added this comment to test commit comand
;$LastChangedBy$
;$LastChangedDate$
;$LastChangedRevision$
;$URL$
;-
Pro xclip, amin, amax, y, flag = flag, clip_adjacent = clip_adjacent, $
           _extra = _extra

  If size(flag, /type) GT 1 Then big = flag Else big = !values.f_nan

;More than max value? ;less than min value?
  ss = where(y Lt amin Or y Gt amax, nss)
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
            xclip, amin, amax, ty, flag = flag, /clip_adjacent
            y[*, j] = ty
          Endfor
        end
        3:begin
          For k = 0, szy[3]-1 Do For j = 0, szy[2]-1 Do Begin
            ty = y[*, j, k]
            xclip, amin, amax, ty, flag = flag, /clip_adjacent
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
