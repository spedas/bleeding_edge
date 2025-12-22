;+
; PROCEDURE:
;
;   what_fa_sees
;
; PURPOSE:
;
;   Animation shows view of the Earth from FAST perspective.
;   Includes Auroral ovals, footprint, and geographic path.
;   Objects are correct at all time points rather than at just
;   one reference point.
;   This is just a skeleton of a procedure.
;
; ARGUMENTS:
;
;   orbit
;
;-
pro what_fa_sees, orbit

; Colors

n_colors = !d.n_colors          ; Number of colors already loaded
black = 0                       ; Assuming loadct2, 39
white = n_colors - 1
blue = fix(.33*float(n_colors))
col_seas = blue
col_cont = fix(.81*float(n_colors))
col_term = 5
col_oval = 4
col_fast = 6
col_tags=white

; Orbit data

success = get_fa_orbit_times(orbit, t1, t2)
if success NE 1 then message, 'Unable to get epoch of orbit '+strtrim(orbit,2)
get_fa_orbit, /all, t1, t2, delta_t=100, /no_store, struc=data, status=error
if error NE 0 then $
  message, 'Unable to get orbit data for '+time_to_str(t1)+' '+time_to_str(t2)

; Animation setup

winsize = 512
window, /free, xsize=winsize, ysize=fix(winsize*1.031), /PIXMAP
nframes = n_elements(data.time)
xinteranimate, set=[winsize, fix(winsize*1.031), nframes]

;; Find where FAST passes from N to S hem.

eqxlat = min(abs(data.lat(3:(nframes-4))), eqxind)
eqxind = eqxind + 3
if data.lat(eqxind LT 0) then eqxind = eqxind - 1
Ngamma = data.lng(0) - data.lng
Sgamma = (data.lng(0) - data.lng(eqxind)) - (data.lng(eqxind+1) - data.lng)

; Frame creation
for i=0, nframes-1 do begin
    ;; SCALE is ratio of real distance to distance at map center.
    ;; SCALE is "scaled" by ratio of angles subtended.
    ;; Object subtended is short distance on surface of globe.
    ;; Use small angle approximation.
    scale = 81.25e06/9./(float(winsize)/640.) * (data.alt(i)/342.)
    height = data.alt(i)/6380. + 1.0
    gamma = Ngamma(i)*float(data.lat(i) GE 0.) + $
      Sgamma(i)*float(data.lat(i) LT 0.)
    map_set, /satellite, sat_p=[height,0.,gamma], $
      data.lat(i), data.lng(i), 0., $
      /noborder, /horizon, e_horizon={fill:2, color:blue}, scale=scale, $
      title=time_to_str(data.time(i)) + $
      string(data.alt(i), format='(f8.1)') + ' km' ;;, $
      ;;limit=[-90,-180,90,-90,90,180,-90,180]
    map_continents, /fill, color=col_cont
    ;;map_continents, /countries, color=6
    ;;map_continents, /rivers, color=blue
    map_grid, glinestyle=0, color=0, label=2, latlab=-20, latalign=0.5, $
      lats = [-90,-75,-60,-45,-30,-15,0,15,30,45,60,75,90], $
      lonlab=.75*90., lonalign=0.5, $
      lons = [-180,-135,-90,-45,0,45,90,135,135,180]
    
    ;; Plot the orbit data
    
    oplot, data.flng, data.flat, color=col_fast, linestyle=0, thick=3
    oplot, data.lng, data.lat, color=col_term, thick=2, linestyle=0
    oplot, [data.flng(i), data.lng(i)],[data.flat(i), data.lat(i)], $
      psym=4, symsize=1.0
    
    ;; AURORAL OVALS
    
    mlt = findgen(241)/10.
    act = 3
    nelat = auroral_zone(mlt,act,/lat) ; Corr. Geomag. Lat for all MLT
    nplat = auroral_zone(mlt,act,/lat,/pole) ; Northern poleward
    selat = auroral_zone(mlt,act,/lat,/south) ; Southern equatorward
    splat = auroral_zone(mlt,act,/lat,/south,/pole) ; Southern poleward
    
    ;; Time formatting
    
    time_N = data.time(i)
    date_time = str_sep(time_to_str(time_N), '/')   ; time_N is reference time
    year = fix(strmid(date_time(0), 0, 4)) ; 4-digit integer
    N_hms = fix(str_sep(date_time(1),':')) ; [hh,mm,ss]
    UT_hrs = N_hms(0) + N_hms(1)/60. ; Hours into UT day
    
    ;; Convert MLT to MLNG using UT and get MLNG of Sun

    sun_lng = [!pi - UT_hrs*(!pi/12.)] ; LNG of Sun
    sun_lat = [0.]
    mag_to_geo, sun_lat, sun_lng, /mag ; MLNG of Sun
    azon_mlng = mlt*(!pi/12.) + sun_lng(0) - !pi ; MLNG of oval
    nelon = azon_mlng
    nplon = nelon
    selon = nelon
    splon = nelon
    
    ;; Convert auroral ovals from MAG to GEO

    transform_mag_geo, nelat, nelon, tnelat, tnelon, year=year
    transform_mag_geo, nplat, nplon, tnplat, tnplon, year=year
    transform_mag_geo, selat, selon, tselat, tselon, year=year
    transform_mag_geo, splat, splon, tsplat, tsplon, year=year

    rerange, tnelon, tnelat, /deg
    rerange, tnplon, tnplat, /deg
    rerange, tselon, tselat, /deg
    rerange, tsplon, tsplat, /deg

    ;; Plot the Ovals
    
    oplot, tnelon, tnelat, color=col_oval, thick=2
    oplot, tnplon, tnplat, color=col_oval, thick=2
    oplot, tselon, tselat, color=col_oval, thick=2
    oplot, tsplon, tsplat, color=col_oval, thick=2
    
    ;; Put a dot on the ovals at MLT=12, 24

    dot_lng = [tnelon(240), tnplon(240), tselon(240), tsplon(240), $
               tnelon(120), tnplon(120), tselon(120), tsplon(120)]
    dot_lat = [tnelat(240), tnplat(240), tselat(240), tsplat(240), $
               tnelat(120), tnplat(120), tselat(120), tsplat(120)]
    oplot, psym=4, symsize=.5, dot_lng, dot_lat, color=black
    
    ;; Render the frame
    
    print, string(bytarr(25 + strlen(strtrim(nframes, 2)))+8b), $
      'Rendering ' + strtrim(nframes, 2) + ' Frames... ', $
      100*float(i)/float(nframes-1.), '%', format='(a,a,i3,a,$)'
    xinteranimate, frame=i, window=!d.window
endfor

; View the animation

print
xinteranimate, 30

end
