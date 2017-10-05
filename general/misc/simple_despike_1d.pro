Function nnmedian, array, width
;nnmedian is a function that returns median values of the nearest
;neighbors in 1d, not including the value of the point

width = width > 1
n = n_elements(array)
otp = array
For j = 0L, n-1 Do Begin
    x1 = (j-width) > 0
    x2 = (j+width) < (n-1)
    If(j eq 0) Then Begin
        otp[j] = median(array[j+1:x2])
    Endif Else If(j Eq n-1) Then Begin
        otp[j] = median(array[x1:j-1])
    Endif Else Begin
        otp[j] = median([array[x1:j-1], array[j+1:x2]])
    Endelse
Endfor
Return, otp
End

;+
; Simple 1d despike, hacked from SXI_despike
; CALLING SEQUENCE:
; result=simple_despike_1d(image)
; INPUTS:
; image	= 1-D image array (float or integer) to be cleaned
; OUTPUTS:
; result = Cleaned 1-D image array (float)
; KEYWORDS:
; spike_threshold = Median filter threshold for	good pixel map
; width = width of median filter in each direction, default is 3
;         points
; use_nan = if set, instead of using the median value as a replacement
;           for a spike, insert a NaN value
; jmm, 2013-02-12, testing SVN messaging
; jmm, 2013-02-12, testing SVN messaging, yet again
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-12 13:21:15 -0800 (Wed, 12 Feb 2014) $
;$LastChangedRevision: 14361 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/simple_despike_1d.pro $
;-

function simple_despike_1d, image, spike_threshold = spike_threshold, $
                            width = width,alt_spike_threshold = alt_spike_threshold, $
                            use_nan = use_nan, _extra = _extra

;Set default for spike_threshold if not passed
if keyword_set(spike_threshold) then threshold=spike_threshold else begin
;    threshold=5
    threshold = 10.0*stddev(abs(image))
endelse

;Exit and return unaltered image if threshold set to -1
result=image
if threshold eq -1 then begin
    return,result
endif

If(keyword_set(width)) Then w = width Else w = 3
rimage = nnmedian(image, w)
If(keyword_set(alt_spike_threshold)) Then Begin
    good_pixmap = float(abs(image-rimage) Lt abs(alt_spike_threshold*rimage))
    bad_pixmap = where(abs(image-rimage) Ge abs(alt_spike_threshold*rimage), nbad)
Endif Else Begin
    good_pixmap = float(threshold gt abs(image-rimage))
    bad_pixmap = where(threshold le abs(image-rimage), nbad)
Endelse

If(keyword_set(use_nan)) Then Begin
    If(nbad Gt 0) Then result[bad_pixmap]=!values.f_nan
Endif Else Begin
    result= good_pixmap*image + (1.0-good_pixmap)*rimage
Endelse

return,result
end
