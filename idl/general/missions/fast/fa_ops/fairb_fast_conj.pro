;+
; PROCEDURE:
;
; fairbanks.pro
;
; PURPOSE:
;
; Finds times when FAST has a conjunction with a ground point near
; MLT=0000.
;
; OUTPUT:
;
; times
;
; An array of times within the designated interval for which FAST
; satisfies the conjunction criteria.
;
; KEYWORDS:
;
; LAT, LNG
;
; The geographic lattitude and longitude of the ground point FAST is
; to intersect. Default is Fairbanks. May not work so well for other
; ground points.
;
; MLTTOL, LATTOL, LNGTOL
;
; Tolerance in hours for MLT or in degrees for LAT and LNG. (Default
; 2.0, 15.0, 20.0)
;
; FOOT
;
; Look for a magnetic conjunction instead of an optical one.
;
; DRAG
;
; Include drag factor when propagating the orbit into the future.
;
; NOLOAD
;
; Don't bother reloading the orbit data; use the data already loaded.
;
; FILE
;
; Set this keyword to the name of a file in which to save the conjunction
; times and MLTs.
;
;-

pro fairb_FAST_conj, t1in, t2in, times, $
               LAT=gndlat, $
               LNG=gndlng, $
               MLTTOL=mlttol, $
               LATTOL=lattol, $
               LNGTOL=lngtol, $
               FOOT=foot, $
               DRAG=drag, $
               NOLOAD=noload, $
               FILE=file

print,'Must set keyword FOOT if want magnetic footprint conjunction'

if data_type(t1in) EQ 7 then t1=str_to_time(t1in) else t1=t1in
if data_type(t2in) EQ 7 then t2=str_to_time(t2in) else t2=t2in
gnd_mlt = 0.0
if NOT keyword_set(gndlat) then gndlat=64.8 ; Fairbanks, AK
if NOT keyword_set(gndlng) then gndlng=212.15 ; Fairbanks, AK
if NOT keyword_set(mlttol) then mlttol=2.0
if NOT keyword_set(lattol) then lattol=15.0
if NOT keyword_set(lngtol) then lngtol=25.0


if NOT keyword_set(noload) then get_fa_orbit, drag=drag, /all, stat=st, t1, t2

get_data, 'MLT', data=mlt
get_data, 'ALT',data=alt
if keyword_set(foot) then begin
    get_data, 'FLAT', data=lat
    get_data, 'FLNG', data=lng
endif else begin
    get_data, 'LAT', data=lat
    get_data, 'LNG', data=lng
endelse

; Make longitudes go from 0-360

lng.y(where(lng.y LT 0.0)) = 180.0 + (180.0 + lng.y(where(lng.y LT 0.0)))

; MLT limits

max_mlt = 0.0 + mlttol
min_mlt = 24.0 - mlttol

; LAT limits

max_lat = gndlat + lattol
min_lat = gndlat - lattol
if max_lat GT 90.0 then max_lat=90.0
if min_lat LT -90.0 then min_lat=-90.0

; LNG limits

max_lng = gndlng + lngtol
min_lng = gndlng - lngtol
if max_lng GT 360.0 then max_lng=360.0
if min_lng LT 0.0 then min_lng=0.0

conj_ind = where( (lat.y LE max_lat AND lat.y GE min_lat) AND $
                  (lng.y LE max_lng AND lng.y GE min_lng) AND $
                  ((mlt.y LE max_mlt AND mlt.y GE 0.0) OR $
                   (mlt.y LE 24.0 AND mlt.y GE min_mlt)) )

if conj_ind(0) NE -1 then times=mlt.x(conj_ind) else begin
    print, 'No Conjunctions.'
    times=0
endelse

if keyword_set(file) then begin
    openw, unit, file, /get_lun
    for i=0, (n_elements(conj_ind)-1) $
      do printf, unit, time_to_str(mlt.x(conj_ind(i))),alt.y(conj_ind(i)), mlt.y(conj_ind(i)),lat.y(conj_ind(i)),lng.y(conj_ind(i))
    close, unit
endif

return

end
