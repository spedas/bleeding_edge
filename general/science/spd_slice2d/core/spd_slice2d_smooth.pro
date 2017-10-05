;+
;Procedure:
;  spd_slice2d_smooth
;  
;
;Purpose:
;  Helper function for spd_slice2d.
;  Smooths the output data by applying a gaussian blur.
;  
;
;Input:
;  slice: (float) N x N array containing the slice data
;  width: (int) width of smoothing window in points in both x and y 
;
;
;Output:
;  None, modifies slice array.
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_smooth.pro $
;
;-

; Smooths slice output using a 2D gaussian convolution.
; Smoothing window should be an odd # of points >= 3
; 
pro spd_slice2d_smooth, slice, width

    compile_opt idl2, hidden


  smooth = round(width)

  if smooth ge 2 then begin
    
    ;ensure kernel with odd # of elements in [3:slice resolution]
    n = smooth > 3. < dimen1(slice)
    if n mod 2 eq 0 then n--
    
    ;Increase the STDV with the smoothing width to allow CONVOL to
    ;effectively smooth over a greater area. Simply extending the
    ;width with constant STDV adds negligable terms to the kernel.
    ;Allowing the STDV to grow too quickly results in flat distributions.
    c = alog(n) - .25 ;There's no simple solution for c = f(n) for small n
                      ;so this was partly arrived at empirically. It
                      ;should allow the width of the gaussian to increase 
                      ;with the smoothing window without becoming flat
                      ;(too quick) or adding negligible terms (to slow).
    
    ;set up for kernel
    s = findgen(n) - floor(n/2.)
    sx = s ## replicate(1.,n)
    sy = s # replicate(1.,n)
    
    ;2D normalized gaussian kernel
    kernel = exp( (-.5) * ((sx/c)^2 + (sy/c)^2) )  ;/  (2*!pi*c^2)
    kernel = kernel / total(kernel)
    
    slice = convol(slice, kernel, /edge_zero)
    
;    slice = smooth(slice, smooth)
;    negidx = where(slice lt 0, nneg)
;    if nneg gt 0 then begin
;      slice[negidx] = 0
;    endif

  endif else begin
    dprint, dlevel=1, 'Smoothing not applied.  Smoothing value must be >= 2'
  endelse

  return

end

