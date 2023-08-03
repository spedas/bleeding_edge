;+
;FUNCTION:   mvn_swe_getspec
;PURPOSE:
;  Returns a SWEA SPEC data structure constructed from L0 data or extracted
;  from L2 data.  This routine automatically determines which data are loaded.
;  Optionally sums the data over a time range, propagating uncertainties.
;
;USAGE:
;  spec = mvn_swe_getspec(time)
;
;INPUTS:
;       time:          An array of times for extracting one or more SPEC data structure(s).
;                      Can be in any format accepted by time_double.  If more than one time
;                      is specified, then all spectra between the earliest and latest times
;                      in the array is returned.
;
;KEYWORDS:
;       ARCHIVE:       Get SPEC data from archive instead (APID A5).
;
;       BURST:         Synonym for ARCHIVE.
;
;       SUM:           If set, then sum all spectra selected.
;
;       UNITS:         Convert data to these units.  Default = 'EFLUX'.
;
;       SHIFTPOT:      Correct for spacecraft potential (must call mvn_scpot first).
;
;       YRANGE:        Returns the data range, excluding zero counts.
;
;       QLEVEL:        Minimum quality level to load (0-2, default=0):
;                        2B = good
;                        1B = uncertain
;                        0B = affected by low-energy anomaly
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-02 11:14:38 -0700 (Wed, 02 Aug 2023) $
; $LastChangedRevision: 31975 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_getspec.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_getspec.pro
;-
function mvn_swe_getspec, time, archive=archive, sum=sum, units=units, yrange=yrange, burst=burst, $
                          shiftpot=shiftpot, qlevel=qlevel

  @mvn_swe_com  

  if (size(time,/type) eq 0) then begin
    print,"You must specify a time."
    return, 0
  endif
  
  npts = n_elements(time)
  tmin = min(time_double(time), max=tmax)
  if keyword_set(burst) then archive = 1
  qlevel = n_elements(qlevel) gt 0L ? byte(qlevel[0]) < 2B : 0B

  if keyword_set(archive) then begin
    if (size(mvn_swe_engy_arc, /type) ne 8) then begin
      print, "No SPEC archive data."
      return, 0
    endif
  endif else begin
    if (size(mvn_swe_engy, /type) ne 8) then begin
      print, "No SPEC survey data."
      return, 0
    endif
  endelse

  if (size(units,/type) ne 7) then units = 'EFLUX'
  if (keyword_set(shiftpot) and (max(abs(mvn_swe_engy.sc_pot)) eq 0.)) then begin
    if (n_elements(swe_sc_pot) lt 2) then mvn_scpot
    mvn_swe_engy.sc_pot = swe_sc_pot.potential
  endif

  if keyword_set(archive) then begin
    if (npts gt 1) then begin
      iref = where((mvn_swe_engy_arc.time ge tmin) and $
                   (mvn_swe_engy_arc.time le tmax), count)
    endif else begin
      dt = min(abs(mvn_swe_engy_arc.time - tmin), iref)
      count = 1
    endelse
    if (count eq 0L) then begin
        print,'No SPEC archive data within selected time range.'
        return, 0
    endif
    spec = mvn_swe_engy_arc[iref]
  endif else begin
    if (npts gt 1) then begin
      iref = where((mvn_swe_engy.time ge tmin) and $
                   (mvn_swe_engy.time le tmax), count)
    endif else begin
      dt = min(abs(mvn_swe_engy.time - tmin), iref)
      count = 1
    endelse
    if (count eq 0L) then begin
      print,'No SPEC survey data within selected time range.'
      return, 0
    endif
    spec = mvn_swe_engy[iref]
  endelse

; Quality check

  str_element, spec, 'quality', quality, success=ok
  if (ok) then begin
    indx = where(quality ge qlevel, npts)
    if (npts gt 0L) then spec = spec[indx] else return, 0
  endif else print,"Quality level not defined."

; Sum the data

  if keyword_set(sum) then spec = mvn_swe_specsum(spec)

; Correct for spacecraft potential and convert units

  if keyword_set(shiftpot) then begin
    if (stregex(units,'flux',/boo,/fold)) then mvn_swe_convert_units, spec, 'df'
    for n=0L,(n_elements(spec)-1L) do spec[n].energy -= spec[n].sc_pot
  endif

  mvn_swe_convert_units, spec, units

; Convenient plot limits (returned via keyword)

  indx = where(spec.data gt 0., count)
  if (count gt 0L) then begin
    yrange = minmax((spec.data)[indx])
    yrange[0] = 10.^(floor(alog10(yrange[0])))
    yrange[1] = 10.^(ceil(alog10(yrange[1])))
  endif else yrange = 0

  return, spec

end
