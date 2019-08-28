;+
;FUNCTION:   mvn_swe_specsum
;PURPOSE:
;  Sums multiple SPEC data structures.  This is done by summing raw counts
;  corrected by deadtime and then setting dtc to unity.
;
;USAGE:
;  specsum = mvn_swe_specsum(spec)
;
;INPUTS:
;       spec:           An array of SPEC structures to sum.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-08-27 14:06:18 -0700 (Tue, 27 Aug 2019) $
; $LastChangedRevision: 27682 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_specsum.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_specsum.pro
;-
function mvn_swe_specsum, spec

  if (size(spec,/type) ne 8) then return, 0
  if (n_elements(spec) eq 1) then return, spec

  old_units = spec[0].units_name  
  mvn_swe_convert_units, spec, 'counts'     ; convert to raw counts
  specsum = spec[0]
  npts = n_elements(spec)

  specsum.met = mean(spec.met)
  specsum.time = mean(spec.time)
  specsum.end_time = max(spec.end_time)
  start_time = min(spec.time - (spec.delta_t/2D))
  specsum.delta_t = (specsum.end_time - start_time) > spec[0].delta_t
  specsum.dt_arr = total(spec.dt_arr, 2)

  nrm = spec.data
  var = spec.var
  nrm[*] = 1.
  bndx = where(~finite(spec.data), count)
  if (count gt 0L) then begin
    nrm[bndx] = 0.
    var[bndx] = !values.f_nan
  endif
  nrm = total(nrm,2)/float(npts)

  specsum.data = total(spec.data/spec.dtc, 2, /nan)/nrm  ; corrected counts
  specsum.var = total(var/spec.dtc, 2, /nan)/nrm         ; variance of sum
  specsum.dtc = 1.         ; summing corrected counts is not reversible
  specsum.bkg = total(spec.bkg, 2)/float(npts)

  specsum.sc_pot = mean(spec.sc_pot, /nan)
  specsum.magf[0] = mean(spec.magf[0], /nan)
  specsum.magf[1] = mean(spec.magf[1], /nan)
  specsum.magf[2] = mean(spec.magf[2], /nan)
  
  mvn_swe_convert_units, spec, old_units
  mvn_swe_convert_units, specsum, old_units

  return, specsum

end
