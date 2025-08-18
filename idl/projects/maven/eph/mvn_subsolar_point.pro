; The purpose of this regime is to calculate the subsolar point on
; Mars for any time

; INPUTS: 
;    times: UNIX times for which subsolar latitudes and longitudes are
;               desired

; OUTPUTS:
;    elonss: subsolar longitudes
;    latss: subsolar latitudes

pro mvn_subsolar_point, times,elonss, latss

  kernel_files = spice_standard_kernels(/mars,/load)
  et = time_ephemeris (times)

  method = 'NEAR POINT/ELLIPSOID'
  target = 'MARS'
  fixref = 'IAU_MARS'
  abcorr = 'NONE'
  obsrvr = 'SUN'

  nt = n_elements (times)
  elonss = fltarr (nt)
  latss = elonss
  for k = 0, nt-1 do begin
     cspice_subslr, method, target, et[k], fixref, abcorr, $
                     obsrvr, spoint, trgepc, srfvec
     cart2latlong, spoint [0], spoint [1], spoint [2], radius, lat, elon
     elonss [k] = elon
     latss [k] = lat
  endfor
end
