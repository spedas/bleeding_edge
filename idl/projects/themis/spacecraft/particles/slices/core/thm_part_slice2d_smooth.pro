;+
;Procedure:
;  thm_part_slice2d_smooth
;  
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Smooths the output data by applying a gaussian blur.
;  
;
;Input:
;  part_slice: (float) N x N array containing the slice data
;  width: (int) width of smoothing window in points in both x and y 
;
;
;Output:
;  None, modifies part_slice.
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_smooth.pro $
;
;-

; Smooths slice output using a 2D gaussian convolution.
; Smoothing window should be an odd # of points >= 3
; 
pro thm_part_slice2d_smooth, part_slice, width

    compile_opt idl2, hidden


  smooth = round(width)

  if smooth ge 2 then begin
    
    ;ensure kernel with odd # of elements in [3:slice resolution]
    n = smooth > 3. < dimen1(part_slice)
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
    
    part_slice = convol(part_slice, kernel, /edge_zero)
    
;    part_slice = smooth(part_slice, smooth)
;    negidx = where(part_slice lt 0, nneg)
;    if nneg gt 0 then begin
;      part_slice[negidx] = 0
;    endif

  endif else begin
    dprint, dlevel=1, 'Smoothing not applied.  Smoothing value must be >= 2'
  endelse

  return

end

