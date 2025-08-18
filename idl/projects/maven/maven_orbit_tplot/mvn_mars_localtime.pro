;+
;PROCEDURE:   mvn_mars_localtime
;PURPOSE:
;  Uses SPICE to determine the local solar time on Mars at a given longitude
;  and UTC.  The result is stored as tplot variables and optionally returned
;  via keyword.  You can specify arrays of times and longitudes as inputs, or
;  this information can be obtained from the maven_orbit_tplot common block.
;
;  It is assumed that you have already initialized SPICE.  (See 
;  mvn_swe_spice_init for an example.)
;
;USAGE:
;  mvn_mars_localtime, time, lon, result=dat  ; user provides time and lon
;
;  mvn_mars_localtime, result=dat             ; time & lon from common block
;
;INPUTS:
;       time:      An array of times, in any format accepted by time_double.
;                  Optional.  Required if lon is specified.
;
;       lon:       An array of IAU_MARS east longitudes (units = degrees).
;                  Optional.  Required if time is specified.
;
;                  Both time and lon must have the same number of elements.
;                  If only one is specified or they don't have the same
;                  number of elements, an error is generated, and the
;                  routine will exit without doing anything.
;
;                  If both are unspecified (zero elements), then this
;                  routine will attempt to get time and lon from the 
;                  maven_orbit_tplot common block.
;
;KEYWORDS:
;       RESULT:    Structure containing the result:
;
;                    time  : unix time (seconds since 1970)
;                    lon   : east longitude at time (deg)
;                    lst   : local solar time (Mars hours, 0 = midnight)
;                    slon  : sub-solar point east longitude (deg)
;                    slat  : sub-solar point latitude (deg)
;                    frame : reference frame for longitudes and latitudes
;
;       PANS:      Returns the names of any tplot variables created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-02-20 11:27:29 -0800 (Tue, 20 Feb 2024) $
; $LastChangedRevision: 32448 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mvn_mars_localtime.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro mvn_mars_localtime, t, l, result=result, pans=pans

  @maven_orbit_common

; Get the time(s) and longitude(s) when/where local time is desired

; time = t --> disabled because this can overwrite time in the common
;              block with an unknown or undefined value

  nt = n_elements(t)
  nl = n_elements(l)

  if (nt ne nl) then begin
    print,"The time and longitude arrays must have the same number of elements."
    result = 0
    return
  endif

; Get times and longitudes from the maven_orbit_tplot common block

  if (nt eq 0) then begin
    nt = n_elements(time)
    if (nt eq 0) then begin
      print,"You must provide time and lon arrays, or run maven_orbit_tplot first."
      result = 0
      return
    endif
    tt = time
    l = lon
  endif else tt = time_double(t)

; From this point on, use copies of the time (tt) and longitude (l) arrays

; Get ready to use SPICE

  from_frame = 'MAVEN_MSO'
  to_frame = 'IAU_MARS'
  chk_frame = mvn_frame_name('spacecraft')

  mk = spice_test('*', verbose=-1)
  ok = max(stregex(mk,'maven_v[0-9]{2}.tf',/subexpr,/fold_case)) gt (-1)

  if (not ok) then begin
    print,"MAVEN frames kernel (maven_v??.tf) not loaded. Can't determine local time."
    result = 0
    return
  endif

; Sun is at MSO coordinates of [X, Y, Z] = [1, 0, 0]

  smso = [1D, 0D, 0D] # replicate(1D, nt)
  sgeo = spice_vector_rotate(smso, tt, from_frame, to_frame, check=chk_frame)
  slon = reform(atan(sgeo[1,*], sgeo[0,*])*!radeg)
  slat = reform(asin(sgeo[2,*])*!radeg)

  jndx = where(slon lt 0., count)
  if (count gt 0L) then slon[jndx] = slon[jndx] + 360.

; Local time is IAU_MARS longitude relative to sub-solar longitude

  lst = (l - slon)*(12D/180D) - 12D  ; 0 = midnight, 12 = noon
  lst -= 24D*double(floor(lst/24D))  ; wrap to 0-24 range

  store_data,'lst',data={x:tt, y:lst}
  ylim,'lst',0,24,0
  options,'lst','yticks',4
  options,'lst','yminor',6
  options,'lst','psym',3
  options,'lst','ytitle','LST (hrs)'
  
  store_data,'Lss',data={x:tt, y:slat}
  options,'Lss','ytitle','Sub-solar!CLat (deg)'

  pans = ['lst', 'Lss']

  result = {time:tt, lon:l, lst:lst, slon:slon, slat:slat, frame:'IAU_MARS'}

  return

end
