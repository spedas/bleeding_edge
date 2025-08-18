
;+
; 
; Name: thm_part_slice2d_2di.pro
; 
; Purpose:  Helper function for thm_part_slice2d.pro
;           Produces slice using 2D linear interpolation
;           
; Note: This code is meant to preserve the functionality of
;       thm_esa_slice2d for the new set of slices routines.
;
;-
pro thm_part_slice2d_2di, datapoints, xyz, resolution, $
                          thetarange=thetarange, zdirrange=zdirrange, $ 
                          part_slice=part_slice, $
                          xgrid=xgrid, ygrid=ygrid, $
                          fail=fail

    compile_opt idl2, hidden


  ;catch common "points colinear" error from triangulate
  catch, err
  if err ne 0 then begin
    catch, /cancel
    if strmessage(err,/name) eq 'IDL_M_POINTS_COLINEAR' then begin
      fail = strjoin(['WARNING: 2D Interpolation cannot be used for this data. ', $
             ' 3D Interpolation is recommended if the data is free of large gaps in look direction and energy.', $
             ' Otherwise use the Geometric method with low resolution (50-150) and smoothing (3-5pts). '],string(10b))
    endif else begin
      message, /reissue_last
    endelse
    return
  endif


  ; Cut by theta value
  if keyword_set(thetarange) then begin
  
    thetarange = minmax(thetarange)
    
    r = sqrt(xyz[*,0]^2 + xyz[*,1]^2 + xyz[*,2]^2)
    eachangle = asin(xyz[*,2]/r)/!dtor
    
    index = where(eachangle le thetarange[1] and eachangle ge thetarange[0], $
                  count, ncomplement=ncount)
    if count ne 0 then begin
      if ncount ne 0 then begin
        xyz = xyz[index,*]
        datapoints = datapoints[index]
      endif
    endif else begin
      fail = 'No data points in given theta range'
      return
    endelse
    
  ;Cut by z-axis value
  endif else if keyword_set(zdirrange) then begin
    
    zdirrange = minmax(zdirrange)
    
    index = where(xyz[*,2] ge zdirrange[0] and xyz[*,2] le zdirrange[1], $
                  count, ncomplement=ncount)
    if count ne 0 then begin
      if ncount ne 0 then begin
        xyz = xyz[index,*]
        datapoints = datapoints[index]
      endif
    endif else begin
      fail = 'No data points in given Z direction range'
      return
    endelse  
  endif

  ;copy vars, ignoring z comp
  x = xyz[*,0]
  y = temporary(xyz[*,1]) ;save mem

  ; Average duplicate points the long way
  ; (kept from thm_esa_slice2d)-----------------
  uni2=uniq(x)
  uni1=[0,uni2[0:n_elements(uni2)-2]+1]
  
  kk=0
  for i=0,n_elements(uni2)-1 do begin
      yi=y[uni1[i]:uni2[i]]
      xi=x[uni1[i]:uni2[i]]
      datapointsi=datapoints[uni1[i]:uni2[i]]
  
      xi=xi[sort(yi)]
      datapointsi=datapointsi[sort(yi)]
      yi=yi[sort(yi)]
  
    index2=uniq(yi)
    if n_elements(index2) eq 1 then begin
        index1=0
    endif else begin
        index1=[0,index2[0:n_elements(index2)-2]+1]
    endelse
  
      for j=0,n_elements(index2)-1 do begin
          y[kk]=yi[index1[j]]
          x[kk]=xi[index1[j]]
          if index1[j] eq index2[j] then begin
              datapoints[kk]=datapointsi[index1[j]]
          endif else begin
              datapoints_moment=moment(datapointsi[index1[j]:index2[j]])
              datapoints[kk]=datapoints_moment[0]
          endelse
          kk=kk+1
      endfor
  endfor

  y=y[0:kk-1]
  x=x[0:kk-1]
  datapoints=datapoints[0:kk-1]
  ; ---------------


  ; Create triangulation
;  triangulate,x,y,tr,b

  ;testing qhull instead
  qhull, x, y, tr, /delaunay
  
  ; Remove triangles whose total x-y plane velocity is less than
  ; minimum velocity from distribution (prevents interpolation over
  ; lower energy limits)
  index = where( 1./9 * total( x[tr[0:2,*]] ,1 )^2 + $
                 1./9 * total( y[tr[0:2,*]] ,1 )^2 $
                  gt min(x^2+y^2), $
                  count, ncomplement=ncomp)
  if count gt 0 then begin
    if ncomp gt 0 then begin
      tr=tr[*,index]
    endif
  endif else begin
    fail = 'Unknown error in triangulation; cannot interpolate data.'
    return
  endelse 
  
  ; Set spacing
  xmax = max(abs([y,x]))
  xrange = [-1*xmax,xmax]
  spacing = (xrange[1]-xrange[0])/(resolution-1)
  
  ; Interpolate to regular grid (slice data)
  part_slice = trigrid(x,y,datapoints,tr,[spacing,spacing], $
                       [xrange[0],xrange[0],xrange[1],xrange[1]],   $
                       xgrid = xgrid,ygrid = ygrid )


end
