
;+
;
;Procedure: thm_part_slice_extract
;
;Purpose: Returns a 2-D slice of a scattered 3-D distribution along 
;         the designated plane.  Points near the slice plane are 
;         projected onto the plane and then interpolated onto a regular 
;         grid using the nearest neighbor method.
;
;Arguments:
; DATA: An array of N datapoints to be used.
; VECTORS: An array of N x 3 datapoints designating, respectively, 
;          the x,y,z values for each point in DATA 
; RESOLUTION: The number of points along each dimention of the 
;             interpolated slice
;
;Input Keywords:
; CENTER: A vector designating the slice plane's center, default = [0,0,0]
; NORMAL: A vector designating the slice plane's normal, default = [0,0,1]
; XVEC: A vector whose projection into the slice plane will form its
;       x-axis. The data's x-axis is used by default, if no projection 
;       exists an error will be returned
; SLICE_WIDTH: The width of the slice given in % (of data range) 
;
;Output Keywords:
; XGRID: Array of x-locations for the slice.
; YGRID: Array of y-locations for the slice.
; FAIL: This keyword will contain a message in the event of an error
;
;-

function thm_part_slice_extract, data, vectors, resolution, $
                                 center, normal, xvec, slice_width=slice_width, $
                                 xgrid=xgrid, ygrid=ygrid, shift=shift, fail=fail

    compile_opt idl2


; Defaults
tolerance = 10.0 * 1.19209290e-07
method = 'NearestNeighbor'
;method = 'NaturalNeighbor'
fail=''

if ~keyword_set(center) then begin
  dprint, 'Using default center'
  center = [0,0,0]
endif
if ~keyword_set(normal) then begin
  dprint, 'Using default orientation'
  normal = [0,0,1]
  xvec = [1,0,0]
endif
if ~keyword_set(xvec) then xvec = [1,0,0]
if ~keyword_set(slice_width) then begin
  width = 0.03
endif else begin
  width = slice_width/100.
endelse  


;; Get new x, y, and z axes
;z = normal / sqrt(total(normal^2))
;x_tmp = xvec / sqrt(total(xvec^2))
;x = crossp(normal,crossp(x_tmp, normal))
;if total(abs(x)) lt tolerance then begin
;  xstr = '('+strjoin(strtrim(xvec,2),',')+')'
;  fail = 'Specified x-axis '+xstr+' has no projection into slice plane.'
;  dprint, fail
;  return, -1
;endif else begin
;  x = x  / sqrt(total(x^2))
;endelse
;y = crossp(z, x)


; Prepare data for transformation
v = [ [vectors[*,0]], $
      [vectors[*,1]], $
      [vectors[*,2]], $
      [replicate(1,n_elements(vectors[*,0]))] ]


;; Create transformation matrix
;orig_pt = !p.t
;
;t3d, /reset
;
;rotm = fltarr(4,4)
;rotm[0:2,0:2] = [[x],[y],[z]] 
;rotm[3,3] = 1
;
;!p.t = rotm ## !p.t
;
;t3d, translate = float(-center)

m = thm_part_slice_trans(normal, xvec, center, fail=fail)
if keyword_set(fail) then return, -1

; Transform Data
v = v # m
if keyword_set(shift) then begin 
  shift = [[shift],[1]] # float(!p.t)
  xshift = shift[0]
  yshift = shift[1]
endif else begin
  xshift = 0.
  yshift = 0.
endelse

;!p.t = orig_pt ;reset

; Pull slice from distribution
zr = minmax(vectors[*,2])
zrange = zr[1] - zr[0]
points = where( abs(v[*,2]) le (width*zrange)/2., np)
if np lt (0.1*resolution)^2 then begin
  fail = 'Not enough data points found within specified slice width.'
  dprint, fail
  return, -1
endif


; For testing only
;tdata = data[points]
;tv = v[points,*]
;ww = where(tdata gt 0, nww)
;rg2 = [-1,1] * max(v)
;iplot, tv[ww,0], tv[ww,1], tv[ww,2], linestyle=6, sym_index=1, $
;       xrange = rg2, yrange=rg2, zrange=rg2, $
;       rgb_table=13, vert_colors=bytscl(alog10(tdata[ww]))
;qq = where(tdata eq 0, nqq)
;iplot, tv[qq,0], tv[qq,1], tv[qq,2], linestyle=6, sym_index=1, $
;       xrange = rg2, yrange=rg2, zrange=rg2 


; Create new variables for triangulation
slice_x = v[points,0]
slice_y = v[points,1]
datapoints = data[points]


; Required triangulation
triangulate, slice_x, slice_y, triangles, repeats=repeats


; Average duplicate points
if repeats[0] ne -1 then begin

  ;This block is in case of 3 or more identical points (unlikely)
  rsorted = repeats[sort(repeats)]
  multiples = where( rsorted[1:n_elements(rsorted)-1] - $
                     rsorted[0:n_elements(rsorted)-2] eq 0, nm)
  if nm ne 0 then begin
    mlist = rsorted[multiples]
    mlist = mlist[uniq(mlist)]
    for j=0, n_elements(mlist)-1 do begin
      idxs = where(repeats eq mlist[j])
      rlist = repeats[*, idxs/2L]
      rlist = rlist[uniq(rlist,sort(rlist))]
      datapoints[rlist] = mean(datapoints[rlist])
    endfor 
  endif

  ;In case of only one pair
  if n_elements(repeats) eq 2 then begin
    repeats = reform(repeats, 2, 1)
  endif

  ;Average duplicate points
  for i=0, (size(repeats,/dim))[1]-1 do begin
    datapoints[repeats[*,i]] = mean(datapoints[repeats[*,i]])
  endfor
  
endif

; Interpolate data to regular grid using nearest neighbor method
slice = griddata(slice_x, slice_y, datapoints, $
                 method=method, triangles=triangles, $
                 /grid, xout=xgrid, yout=ygrid)


; Remove data outside the slice's (instrument's) range
nx = n_elements(xgrid)
ny = n_elements(ygrid)
xygrid = ((xgrid+xshift) # replicate(1,ny))^2  +  (replicate(1,nx) # (ygrid+yshift))^2
gtz = where(datapoints gt 0, ngtz)
if ngtz eq 0 then gtz = lindgen(n_elements(slice_x))
outside = where(  xygrid lt  min(slice_x^2+slice_y^2)   or   $
                  xygrid gt  max((slice_x[gtz]+xshift)^2+(slice_y[gtz]+yshift)^2), noutside)
if noutside gt 0 then begin
  slice[outside] = 0.
endif


return, slice

end
