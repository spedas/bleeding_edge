

;+
; 
; Name: thm_part_slice2d_2di.pro
; 
; Purpose:  Helper function for thm_part_slice2d.pro
;           Produces slice by interpolating the volume
;           in three dimensions then extracting a slice.
;
;-
pro thm_part_slice2d_3di, datapoints, xyz, resolution, $
                          drange=drange, displacement=displacement, $
                          part_slice=part_slice, $
                          xgrid=xgrid, ygrid=ygrid, $
                          fail=fail

    compile_opt idl2, hidden


  ;Error checks
  normal = [0,0,1.]
  xvec = [1.,0,0]

  ; Create cube grid
  mm = [ [minmax(xyz[*,0])], [minmax(xyz[*,1])], [minmax(xyz[*,1])] ]
  xgrid = interpol(mm[*,0], resolution)
  ygrid = interpol(mm[*,1], resolution)
  zgrid = interpol(mm[*,2], resolution)

  ; Get slice's center point
  center = ( (normal * displacement)/(mm[1,*]-mm[0,*]) + 0.5) * resolution
  if in_set(center le 0 or center gt resolution, 1) then begin
    fail = 'Error: Slice displacement is outside the data range.'
    return
  endif  

  ; Must be copied to new variables for qhull
  x = xyz[*,0]
  y = xyz[*,1]
  z = temporary(xyz[*,2])
  
  qhull, x, y, z, th, /DELAUNAY
  
  ; Remove tetrahedra whose total velocity (centroid) is less than
  ; minimum velocity from distribution (prevents interpolation over
  ; lower energy limits)
  index = where( 1./16 * total(  x[th[0:3,*]] ,1 )^2 + $
                 1./16 * total(  y[th[0:3,*]] ,1 )^2 + $
                 1./16 * total(  z[th[0:3,*]] ,1 )^2  $
                  gt min(x^2+y^2+z^2), $
                  count, ncomplement=ncomp)
  if count gt 0 then begin
    if ncomp gt 0 then begin
      th=th[*,index]
    endif
  endif else begin
    fail = 'Unknown error in triangulation; cannot interpolate data.'
    return
  endelse 

  ; Interpolate data to regular 3D grid
  vol = qgrid3(x, y, z, datapoints, th, dimension=replicate(resolution,3))
  
  ; Remove erroneous data points (also helps prevent interpolation over gaps)
  derp = where(abs(vol) lt drange[0] or abs(vol) gt drange[1], nderp)
  if nderp gt 0 then begin
    vol[derp] = 0
  endif 

  ; Extract slice from regular grid
  part_slice=extract_slice(vol, resolution, resolution, $
                           center[0], center[1], center[2], $
                           normal, xvec, /sample)

;  ; For testing only: shows 3-D distribution of non-zero data (using valid scaling)
;  ww = where(vol gt 0, nww)
;  tmparr = bytscl(alog10(vol[ww]))
;  x_idxs = where(   vol[ww] eq min( (vol[ww])[where(vol[ww] ge orange[0])] )   )
;  x = float( tmparr[x_idxs[0]] )
;  m = -255./(x-255)
;  c = (255.*x)/(x-255)
;  tmparr = m*tmparr + c
;  ltz = where(tmparr lt 0, nltz)
;  if nltz gt 0 then tmparr[ltz] = 0
;  ;tmparr[where(tmparr gt 255)] = 255
;  tmparr = byte(round(tmparr))
;  x_idx = ww mod n_elements(xgrid) 
;  y_idx = (ww / n_elements(xgrid)) mod n_elements(ygrid)
;  z_idx = ww / (n_elements(xgrid)*n_elements(ygrid))
;  rg2 = [-max(xgrid),max(xgrid)]
;  iplot, xgrid[x_idx], ygrid[y_idx], zgrid[z_idx], linestyle=6, sym_index=1, $
;         xrange = rg2, yrange=rg2, zrange=rg2, $
;         rgb_table=13, vert_colors=tmparr


;  ; For testing only: View volume in IDL medical imaging software
;  mm = minmax(vol, min_value=0)
;  vol= temporary(vol)/mm[0]
;  vol = alog10(temporary(vol))
;  mm = minmax(vol, min_value=0)
;  vol = BYTSCL(temporary(vol), min=mm[0], max=mm[1])
;  hData = PTR_NEW(vol) ; slicer3 needs a pointer to the volume data 
;  slicer3, hData

end
