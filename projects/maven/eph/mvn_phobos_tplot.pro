;+
;FUNCTION: MVN_PHOBOS_TPLOT
;PURPOSE:
;     Create tplot variable for the distance between MAVEN and Phobos
;
;USAGE:
;    IDL> mvn_phobos_tplot
;
;INPUTS:
;
;KEYWORDS:
;   trange:     time interval
;   loadspice:  In case you need to load spice variables
;   rm:         Use units of Mars radii instead of [km]
;
;CREATED BY:    Roberto Livi  03-30-15
;- 


pro mvn_phobos_tplot,trange=trange, loadspice=loadspice, rm=rm

  ;;-------------------------------------------
  ;;Get time range
  if (n_elements(trange) gt 1L) then tt = minmax(time_double(trange)) $
                                else tt  = timerange()

  ;;-------------------------------------------
  ;;1 Second resolution
  time  = dindgen(tt[1]-tt[0])+tt[0]
  utc = time_string(time)

  
  ;;-------------------------------------------
  ;;Check SPICE and load kernels
  if keyword_set(loadspice) then mvn_spice_load

  ;;-------------------------------------------
  ;;Get MAVEN to Phobos J2000 coordinates
  cspice_str2et,utc,et
  target   = 'PHOBOS'
  ref      = 'J2000'
  abcorr   = 'LT+S'
  observer = 'MAVEN'
  cspice_spkezr, target, $
                 et, $
                 ref, $
                 abcorr, $
                 observer, $
                 result,$
                 ltime
  location=sqrt(total(result[0:2,*]^2,1))

  ;;-------------------------------------------
  ;;Generate tplot variable
  if keyword_set(rm) then location=location/3391.D
  store_data,'Phobos-MAVEN',data={x:time,y:location}

end
