;+
;FUNCTION:   mvn_swe_3dsum
;PURPOSE:
;  Sums multiple 3D data structures.  This is done by summing raw counts
;  corrected by deadtime and then setting dtc to unity.  Also, note that 
;  summed 3D's can be "blurred" by a changing magnetic field direction, 
;  so summing only makes sense for short intervals.  The theta, phi, and 
;  omega tags can be hopelessly confused if the MAG direction changes much.
;
;USAGE:
;  dddsum = mvn_swe_3dsum(ddd)
;
;INPUTS:
;       ddd:           An array of 3D structures to sum.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-02-28 12:41:25 -0800 (Sun, 28 Feb 2021) $
; $LastChangedRevision: 29708 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_3dsum.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_3dsum.pro
;-
function mvn_swe_3dsum, ddd

  if (size(ddd,/type) ne 8) then return, 0
  npts = n_elements(ddd)
  if (npts eq 1) then return, ddd

  old_units = ddd[0].units_name  
  mvn_swe_convert_units, ddd, 'counts'     ; convert to raw counts
  dddsum = ddd[0]

  dddsum.met = mean(ddd.met)
  dddsum.time = mean(ddd.time)
  dddsum.end_time = max(ddd.end_time)
  start_time = min(ddd.time - (ddd.delta_t)/2D)
  dddsum.delta_t = (dddsum.end_time - start_time) > ddd[0].delta_t
  dddsum.dt_arr = total(ddd.dt_arr,3)      ; normalization for the sum

  dddsum.sc_pot = mean(ddd.sc_pot, /nan)    
  dddsum.bkg = mean(ddd.bkg, /nan)

  dddsum.magf[0] = mean(ddd.magf[0], /nan)
  dddsum.magf[1] = mean(ddd.magf[1], /nan)
  dddsum.magf[2] = mean(ddd.magf[2], /nan)
  dddsum.v_flow[0] = mean(ddd.v_flow[0], /nan)
  dddsum.v_flow[1] = mean(ddd.v_flow[1], /nan)
  dddsum.v_flow[2] = mean(ddd.v_flow[2], /nan)

  nrm = ddd.data
  var = ddd.var
  nrm[*] = 1.
  bndx = where(~finite(ddd.data), count)
  if (count gt 0L) then begin
    nrm[bndx] = 0.
    var[bndx] = !values.f_nan
  endif
  nrm = total(nrm,3)/float(npts)

  dddsum.data = total(ddd.data/ddd.dtc,3,/nan)/nrm  ; corrected counts
  dddsum.var = total(var/ddd.dtc,3,/nan)/nrm        ; variance of sum
  dddsum.dtc = 1.         ; summing corrected counts is not reversible

  mvn_swe_convert_units, ddd, old_units
  mvn_swe_convert_units, dddsum, old_units

  return, dddsum

end
