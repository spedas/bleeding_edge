;+
;PROCEDURE:   mvn_flyz_bar
;PURPOSE:
;  Creates a bar indicating planned times of fly-plus-Z.  Time ranges
;  are drawn from the Science Constraints spreadsheet, which is
;  produced by Lockheed Martin once a year in mid-summer.  You can
;  find the latest spreadsheet (sci_constraints_YYYY.xlsx) here:
;
;    https://lasp.colorado.edu/galaxy/display/MAVEN/Science+Operations+Spreadsheets
;
;  You need to have a MAVEN account on Galaxy to access this file.
;
;  This routine is accurate up through 2025.  After that, I have used
;  the predict ephemeris to estimate when fly-plus-Z periods will occur.
;  These estimates will be adjusted as new information becomes available.
;
;USAGE:
;  mvn_flyz_bar
;
;INPUTS:
;       none
;
;KEYWORDS:
;       COLOR:    Bar color index.  Default is the current foreground color.
;                 This can be changed later using options.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-07-07 10:42:02 -0700 (Fri, 07 Jul 2023) $
; $LastChangedRevision: 31940 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mvn_flyz_bar.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_flyz_bar, color=color

  bname = 'mvn_flyz_bar'

; Official fly-plus-Z periods from Constraints spreadsheet

  tstart = time_double(['2022-11-03','2023-04-06','2023-08-03','2024-01-24'])
  tstop  = time_double(['2022-12-29','2023-06-15','2023-10-19','2024-03-07'])

; Estimated fly-plus-Z periods from eyeballing the ephemeris

  estart = time_double(['2026-06-16','2026-11-01','2027-03-21','2030-01-11','2030-05-22','2030-10-09'])
  estop  = time_double(['2026-08-17','2027-01-02','2027-05-28','2030-03-13','2030-07-24','2030-12-16'])

  tstart = [tstart, estart]
  tstop  = [tstop, estop]

  oneday = 86400D
  ndays = floor((max(tstop) - min(tstart))/oneday) + 3L
  t = min(tstart) + oneday*(dindgen(ndays) - 1L)

  y = replicate(!values.f_nan,ndays)
  for i=0L,(n_elements(tstart)-1L) do begin
    indx = where((t ge tstart[i]) and (t lt tstop[i]), count)
    if (count gt 0L) then y[indx] = 3.
  endfor

  store_data,bname,data={x:t, y:y}
  ylim,bname,0,6,0
  options,bname,'ytitle',''
  options,bname,'no_interp',1
  options,bname,'thick',8
  options,bname,'xstyle',4
  options,bname,'ystyle',4
  if keyword_set(color) then options,bname,'colors',fix(color[0])
  
  return

end
