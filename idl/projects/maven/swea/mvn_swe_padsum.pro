;+
;FUNCTION:   mvn_swe_padsum
;PURPOSE:
;  Sums multiple PAD data structures.  This is done by summing raw counts
;  corrected by deadtime and then setting dtc to unity.  Also, note that 
;  summed PAD's can be "blurred" by a changing magnetic field direction, 
;  so summing only makes sense for short intervals.  The theta, phi, and 
;  omega tags can be hopelessly confused if the MAG direction changes much.
;
;USAGE:
;  padsum = mvn_swe_padsum(pad)
;
;INPUTS:
;       pad:           An array of PAD structures to sum.
;
;KEYWORDS:
;
;       QLEVEL:        Minimum quality level to sum (0-2, default=0):
;                        2B = good
;                        1B = uncertain
;                        0B = affected by low-energy anomaly
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-11-13 11:17:05 -0800 (Wed, 13 Nov 2024) $
; $LastChangedRevision: 32956 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padsum.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_padsum.pro
;-
function mvn_swe_padsum, pad, qlevel=qlevel

  if (size(pad,/type) ne 8) then return, 0
  npts = n_elements(pad)
  if (npts eq 1) then return, pad
  qlevel = (n_elements(qlevel) gt 0L) ? byte(qlevel[0]) : 0B

; Quality filter

  str_element, pad, 'quality', success=ok
  if (ok) then begin
    indx = where(pad.quality ge qlevel, npts)
    if (npts eq 0L) then begin
      print, "No PAD data to sum with quality >= ", qlevel, format='(a,i1)'
      return, 0
    endif
    pad = pad[indx]
  endif else print, "Quality level not yet defined for L2 data."

  old_units = pad[0].units_name  
  mvn_swe_convert_units, pad, 'counts'            ; convert to raw counts
  padsum = pad[0]

; Sum the data

  padsum.met = mean(pad.met)
  padsum.time = mean(pad.time)
  padsum.end_time = max(pad.end_time)
  start_time = min(pad.time - (pad.delta_t/2D))
  padsum.delta_t = (padsum.end_time - start_time) > pad[0].delta_t
  padsum.dt_arr = total(pad.dt_arr,3)             ; normalization for the sum
    
  padsum.pa = total(pad.pa,3)/float(npts)         ; pitch angles can be blurred
  padsum.dpa = total(pad.dpa,3)/float(npts)
  padsum.pa_min = total(pad.pa_min,3)/float(npts)
  padsum.pa_max = total(pad.pa_max,3)/float(npts)

  padsum.sc_pot = mean(pad.sc_pot, /nan)
  padsum.Baz = mean(pad.Baz, /nan)
  padsum.Bel = mean(pad.Bel, /nan)

  padsum.magf[0] = mean(pad.magf[0], /nan)
  padsum.magf[1] = mean(pad.magf[1], /nan)
  padsum.magf[2] = mean(pad.magf[2], /nan)
  padsum.v_flow[0] = mean(pad.v_flow[0], /nan)
  padsum.v_flow[1] = mean(pad.v_flow[1], /nan)
  padsum.v_flow[2] = mean(pad.v_flow[2], /nan)

  nrm = pad.data
  var = pad.var
  nrm[*] = 1.
  bndx = where(~finite(pad.data), count)
  if (count gt 0L) then begin
    nrm[bndx] = 0.
    var[bndx] = !values.f_nan
  endif
  nrm = total(nrm,3)/float(npts)

  padsum.data = total(pad.data/pad.dtc,3,/nan)/nrm  ; corrected counts
  padsum.var = total(var/pad.dtc,3,/nan)/nrm        ; variance of sum
  padsum.dtc = 1.         ; summing corrected counts is not reversible
  padsum.bkg = total(pad.bkg,3)/float(npts)

  if (ok) then padsum.quality = min(pad.quality) else str_element, padsum, 'quality', 1B, /add

  mvn_swe_convert_units, pad, old_units
  mvn_swe_convert_units, padsum, old_units

  return, padsum

end
