;+
;PROCEDURE:   mvn_swe_flatfield_test
;PURPOSE:
;
;USAGE:
;  mvn_swe_flatfield_test
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-11-07 16:17:37 -0800 (Tue, 07 Nov 2023) $
; $LastChangedRevision: 32219 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_flatfield_test.pro $
;
;CREATED BY:    David L. Mitchell  2016-09-28
;FILE: mvn_swe_flatfield_test.pro
;-
pro mvn_swe_flatfield_test, time

  @mvn_swe_com

  if (size(time,/type) ne 0) then begin
    n = n_elements(time)
    t = time_double(time)
  endif else begin
    t0 = time_double('2014-03-22')
    t1 = time_double(time_string(max(t_mcp),prec=-3))
    dt = 3600D*4D  ; time resolution (6 hours)
    n = floor((t1 - t0)/dt) + 1L
    t = t0 + dt*dindgen(n)
  endelse
  
  ff = replicate(1.,96,n)
  frac = fltarr(n)
  for i=0L,(n-1L) do begin
    ff[*,i] = mvn_swe_flatfield(t[i],/nominal,/silent,test=test)
    frac[i] = test
  endfor
  
  store_data,'ff',data={x:t, y:transpose(ff), v:findgen(96)+0.5}
  ylim,'ff',0,96,0
  zlim,'ff',0.7,1.3,0
  options,'ff','yticks',6
  options,'ff','spec',1
  options,'ff','x_no_interp',1
  options,'ff','y_no_interp',1
  options,'ff','ytitle','SWEA Solid Angle Bin'
  options,'ff','ztitle','Flatfield Calibration Factor'

  store_data,'frac',data={x:t, y:frac}
  ylim,'frac',0,max(frac)+1,0
  options,'frac','constant',findgen(ceil(max(frac))+2)

  store_data,'cc',data={x:t, y:mvn_swe_crosscal(t)}
  ylim,'cc',1,7,0
  options,'cc','ytitle','SWE-SWI Cross Calibration Factor'

  return

end
