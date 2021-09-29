;+
;Input a mxn array. Rescale it to a larger set of pixels, for plotting using tv.
;
;arrayin: data array to be up scaled [mxn]
;factor: the scaling factor by which to multiply arrayin. Must be an integer. Eg, if input array is [4x16], with factor=2,
;        the output array will be 8x32, where each 2x2 square is equivalent to a 1x1 square in the original array.
;        If you set xfact and yfact below, you do not need to set factor.
;
; xfact, yfact: scaling factors for x and y dimensions independently. Same as above, but apply to X and Y dimensions separately.
;               Setting these will overwrite factor. If you set one, both must be set, as factor will be ignored.
;
;output: the upscaled array.
;
;e.g.
;array1 = fltarr(4,8)
;mvn_sta_scale_array, array1, 2, output=array2
;
;-

pro mvn_sta_scale_array, arrayin, factor, output=output, success=success, xfact=xfact, yfact=yfact

  if size(xfact,/type) ne 0 and size(yfact,/type) ne 0 then begin
    xscale = round(xfact)
    yscale = round(yfact)
  endif else begin
    if size(factor,/type) eq 0 then begin
      print, ""
      print, "Set factor, or xfact and yfact."
      success=0
      return
    endif
    xscale = round(factor)
    yscale = round(factor)
  endelse

  if xscale lt 1 or yscale lt 1 then begin
    print, ""
    print, "Scaling factor must be >1, I can only upscale."
    success=0
    return
  endif

  neleX = n_elements(arrayin[*,0])
  neleY = n_elements(arrayin[0,*])

  nXnew = (neleX*xscale)
  nYnew = (neleY*yscale)

  output = fltarr(nXnew, nYnew)

  xi = (findgen(neleX)*xscale)  ;indices at start of each block in new array
  yi = (findgen(neleY)*yscale)

  ;Cycle through and populate array:
  for xx = 0l, neleX-1l do begin

    x1 = xi[xx]
    x2 = x1+(xscale)-1l
    xinds=[x1:x2]

    for yy = 0l, neleY-1l do begin
      val0 = arrayin[xx,yy]  ;original value

      y1 = yi[yy]
      y2 = yi[yy]+(yscale)-1l
      yinds=[y1:y2]

      ;Cycle through each of the "new" rows, as IDL won't fill in a block of points at once:
      for yyy = 0l, (yscale)-1l do output[xinds, yinds[yyy]] = val0

    endfor

  endfor

  success=1

end
