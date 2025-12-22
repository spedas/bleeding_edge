;;+
;; PROCEDURE:     ilat_cross.pro
;; 
;; PURPOSE:       Find times when FAST crosses a given ILAT
;;                specification.  (Also works for geographic and
;;                magnetic footprint latitudes.  See GEOLAT and FOOTLAT.)
;;
;; ARGUMENTS:     
;;
;;   TIME1        A date string or double float time scalar or array.
;;                For time arrays set the TIME_ARRAY keyword.
;;   TIME2        A date string or double float time scalar.
;;
;; KEYWORDS:
;;
;;   TIME_ARRAY   Set this keyword if the first time argument is an
;;                array and the second time argument is to be ignored.
;;
;;   GEOLAT       Set this to nonzero for geographic latitude
;;                crossings.
;;   FOOTLAT      Set this to nonzero for magnetic footprint latitude
;;                crossings.
;;
;;   LAT          The latitude point in degrees (-90 <= LAT <= 90 ).
;;                Default is LAT=60.0
;;
;;   OUTGOING     The spacecraft crosses any given latitude twice an
;;                orbit.  Set OUTGOING to get the second time it
;;                crosses the input LAT.  The default is to get the
;;                incoming crossing.
;;
;;   FILE         The name of the output file.  Defaults to STDOUT.
;;
;;   DELTA_T      Spacing in seconds of computed points.  Ignored of
;;                TIME_ARRAY set.  (passed to get_fa_orbit.pro)
;;   DRAG_PROP    If set, the call to the orbitprop library will use
;;                an orbit propagator that includes the effects of 
;;                atmospheric drag.  (passed to get_fa_orbit.pro)
;;
;;   ORBIT        Named variable to receive output orbit
;;                array. (optional, described in OUTPUT section below.)
;;   OUTTIME      Named variable to receive output time
;;                array. (optional)
;;   OUTLAT      Named variable to receive output latitude
;;                array. (optional)
;;
;;
;; OUTPUT:        Output will be to the terminal (STDOUT) unless the
;;                FILE keyword is set.  Output is three columns:
;;                Orbit, Time, and LAT.  The number in the LAT
;;                column is the exact latitude at the time specified by
;;                the first two columns.  LAT may not be exactly
;;                equal to the input LAT because the propagator has
;;                finite resolution.
;;
;;                The column entries orbit, time, and LAT may be
;;                output to arrays by setting ORBIT, TIME, and OUTLAT
;;                keywords to named variables.
;;
;; NOTES:         The first and last orbit in the specified timespan
;;                will be ignored to avoid incomplete orbits, and thus
;;                strange outputs.
;;
;;                Be careful choosing ILAT or FLAT near the equator 
;;                because it is not well-behaved there.
;;
;; BY:            J. Rauchleiba     Jan 12, 1999
;;-

pro ilat_cross, time1, time2, $
        TIME_ARRAY=time_array, $
        GEOLAT=geolat, $
        FOOTLAT=footlat, $
        LAT=cross, $
        FILE=file, $
        OUTGOING=out, $
        DELTA_T=dt, $
        DRAG_PROP=drag_prop, $
        ORBIT=onorbits, $
        OUTTIME=ontimes, $
        OUTLAT=onlats

if NOT keyword_set(time1) then message, 'Must set start time.'
if NOT keyword_set(time2) AND NOT keyword_set(time_array) $
  then message, 'Must supply stop time or set TIME_ARRAY.'


;; Input times could be strings or double floats

if NOT keyword_set(time_array) then begin
    if data_type(time1) EQ 7 then t1 = str_to_time(time1) else t1 = double(time1)
    if data_type(time2) EQ 7 then t2 = str_to_time(time2) else t2 = double(time2)
endif else begin
    if data_type(time1) EQ 7 then t1 = str_to_time(time1) else t1 = double(time1)
    t2=0d
endelse

;; Check LAT setting

if not keyword_set(cross) then cross=60.0
cross = float(cross)
if cross LT -90.0 OR cross GT 90.0 then message, 'LAT spec out of range.'

;; Check propagation interval

If not keyword_set(dt) then dt=60d

;; Propagate the orbit

get_fa_orbit, t1, t2, $
  TIME_ARRAY=time_array, $
  DELTA_T=dt, DRAG_PROP=drag_prop, $
  /NO_STORE, STRUC=data, $
  ALL=(keyword_set(geolat) OR keyword_set(footlat)), $
  STATUS=status
if status NE 0 then message, 'ERROR in get_fa_orbit'

npts = n_elements(data.time)
firstorb = data.orbit(0)
lastorb = data.orbit(npts - 1)

;; Grab data for requested latitude type

case (1) of
    keyword_set(geolat):  latdata = data.lat
    keyword_set(footlat): latdata = data.flat
    else:                 latdata = data.ilat
endcase

;; Exclude first and last orbits because they are probably incomplete

n_whole_orbits = ( (lastorb-1) - (firstorb+1) + 1 )

;; Initialize output arrays

ontimes = dblarr(n_whole_orbits)
onlats = fltarr(n_whole_orbits)
onorbits = lonarr(n_whole_orbits)

;; Loop through each WHOLE orbit and collect desired point

count = 0
for orbiter=(firstorb+1), (lastorb-1) do begin
    
    ;; Confine to specific orbit, hemisphere, monotonic interval
    
    if cross GE 0.0 then begin
        
        ;; Northern Hemisphere
        
        if NOT keyword_set(out) then begin
            
            ;; Incoming North
            
            outn = where( data.orbit EQ orbiter AND $
                          latdata GE 0.0 AND $
                          deriv(latdata) GT 0.0 )
        endif else begin
            
            ;; Outgoing North
            
            outn = where( data.orbit EQ orbiter AND $
                          latdata GE 0.0 AND $
                          deriv(latdata) LT 0.0 )
        endelse
    endif else begin
        
        ;; Southern Hemisphere
        
        if NOT keyword_set(out) then begin
            
            ;; Incoming South
            
            outn = where( data.orbit EQ orbiter AND $
                          latdata LT 0.0 AND $
                          deriv(latdata) LT 0.0 )
        endif else begin
            
            ;; Outgoing South
            
            outn = where( data.orbit EQ orbiter AND $
                          latdata LT 0.0 AND $
                          deriv(latdata) GT 0.0 )
        endelse
    endelse
    
    
    ;; Take subarrays
    
    outn_lat = latdata(outn)
    outn_time = data.time(outn)
    outn_orbit = data.orbit(outn)
    
    ;; Find point nearest desired LAT value
    
    on = min( abs(outn_lat - cross), min_ind )
    
    ;; Collect the point into output arrays
    
    ontimes(count) = outn_time(min_ind)
    onlats(count) = outn_lat(min_ind)
    onorbits(count) = outn_orbit(min_ind)
    
    count = count + 1
endfor

;; Format output to STDOUT or file

if NOT keyword_set(file) then begin
    for event=0, (n_elements(ontimes) - 1) do begin
        print, format='(I,"  ",A,F)', $
          onorbits(event), time_to_str(ontimes(event)), onlats(event)
    endfor
endif else begin
    openw, /get_lun, output, file
    for event=0, (n_elements(ontimes) - 1) do begin
        printf, output, format='(I,"  ",A,F)', $
          onorbits(event), time_to_str(ontimes(event)), onlats(event)
    endfor
    close, output
endelse


end
