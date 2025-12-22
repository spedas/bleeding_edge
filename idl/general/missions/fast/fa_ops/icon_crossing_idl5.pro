;+
;PROCEDURE:	icon_crossing_idl5.pro
;
;PURPOSE:	
;	Add a small plot to the summary plots showing the auroral region and
;	the path of FAST.  This procedure must use IDL 5 or greater
;	due to a bug in earlier versions.
;
;KEYWORDS:
;	ORBIT:	The orbit number
;	SOUTH:  Set this keyword to plot the south polar region.  The default
;               is the north polar region.
;
;CREATED BY:   Sandra Wittenbrock
;ADAPTED FROM: plot_fa_crossing.pro by J.Rauchleiba
;-

function icon_scale, percent, siz, devsize=devsize
if keyword_set(devsize) then begin
	 x_cent1 = 1-siz(0)*(1-percent(0))/devsize(0)
	 x_cent2 = 1-siz(0)*(1-percent(2))/devsize(0)
	 y_cent1 = percent(1)*siz(1)/devsize(1)
	 y_cent2 = percent(3)*siz(1)/devsize(1)
endif else begin
	 x_cent1 = 1-siz(0)*(1-percent(0))/!d.x_size
	 x_cent2 = 1-siz(0)*(1-percent(2))/!d.x_size
	 y_cent1 = percent(1)*siz(1)/!d.y_size
	 y_cent2 = percent(3)*siz(1)/!d.y_size
endelse
dims = [x_cent1,y_cent1,x_cent2,y_cent2]
return, dims
end

pro icon_crossing_idl5, $
	ORBIT=orbit, $
	SOUTH=south

; Scaling stuff

;devsize=[!d.x_size,!d.y_size]
position=icon_scale([0.91,0.0132,0.99,0.117],[640,512])
;position=icon_scale([0.90,0.032,0.98,0.47],[640,512])
black=icon_scale([0.902,0.,1.0,0.13],[640,512],devsize=devsize)
x=[black(0),black(0),black(2),black(2)]
y=[black(1),black(3),black(3),black(1)]
one=icon_scale([0.868,0.0665,0,0],[640,512],devsize=devsize)
two=icon_scale([0.9801,0.0665,0,0],[640,512],devsize=devsize)
three=icon_scale([0.935,0.117,0,0],[640,512],devsize=devsize)
four=icon_scale([0.947,0.003,0,0],[640,512],devsize=devsize)
;five=icon_scale([0.93,0.0665,0,0],[640,512],devsize=devsize)

; Clear part of the screen to make room for this plot

polyfill, x, y, color = 0 ,/normal

; SET ORBIT FILE AND CURRENT TIME

almanac_dir = fa_almanac_dir()
if almanac_dir EQ '-error-' then message, 'Almanac directory not found.'
almanac_orb_dir = almanac_dir + '/orbit'
def_orbit_file = findfile(almanac_orb_dir + '/definitive')
pre_orbit_file = findfile(almanac_orb_dir + '/predicted')
if def_orbit_file(0) EQ '' then message,'Orbit file '+almanac_orb_dir+' missing'
if pre_orbit_file(0) EQ '' then message,'Orbit file '+almanac_orb_dir+' missing'

; Shell out to extract orbit epoch from almanac file.

last_def_epoch = find_last_epoch(def_orbit_file(0), ORBIT=latest_deforbit)
last_pre_epoch = find_last_epoch(pre_orbit_file(0), ORBIT=latest_preorbit)
if orbit GT latest_deforbit then begin
    if orbit GT latest_preorbit then $
      message, 'Orbit files only updated to orbit '+strtrim(latest_preorbit,2)
    print, 'Switching to predicted orbit file.'
    orbit_file = pre_orbit_file(0)
endif else orbit_file = def_orbit_file(0)
tmin = get_orbfile_epoch(orbit, orbit_file=orbit_file)
tmax = tmin + 7990d

; Set up the colors.

n_colors = !d.n_colors          ; Number of colors already loaded
black = 0                       ; Assuming loadct2, 39
white = n_colors - 1
brown = fix(.81*float(n_colors))
blue = fix(.33*float(n_colors))
col_seas = blue
col_cont = brown
col_fast = 6
col_term = 5
col_oval = 4
col_tags = white

; Get the magnetic print data of FAST

get_fa_orbit, tmin, tmax, /all, orbit_file=orbit_file, $
  /no_sto, struc=fa_orbit, status=status
if status NE 0 then message, 'Error returned by get_fa_orbit called by icon_crossing'
clock = fa_orbit.TIME
flat = fa_orbit.FLAT
flng = fa_orbit.FLNG
Mtheta = flat
Mphi = flng

; Set time_N to when craft nearest pole
; This variable used by the auroral oval; generators.

if keyword_set(south) then lat_ref = -90.0 else lat_ref = 90.0
dummy = min(abs(lat_ref - Flat), sub_N)
time_N = clock(sub_N)

; GET LAT AND LNG OF SUN 

center_time = time_N
hr_min = (str_sep((str_sep(time_to_str(center_time),'/'))(1),':'))(0:1)
gmt_hrs = float(hr_min(0)) + float(hr_min(1))/60.0
noon_long  = (!pi - gmt_hrs*(!pi/12.)) MOD (2*!pi)
t0 = str_to_time('96-12-21/0:00') ;
ang = (center_time - t0)/(365.25d*24d*3600d)*2d*!pi
tilt = .410152
noon_lat = -(tilt * cos(ang))

; VIEWPOINTS AND PLOT LIMITS
; View is above GEO pole

latlim = [50, -50]
if keyword_set(south) then begin
    lim = [-90.0,-180.0,-40.0,180.0]
    ;;pov = [-75.3, 118.6, 0.0]
    pov = [-90.0, 0.0, 0.0]
    rotcoeff = -1
    rot_add = 0.0
endif else begin
    lim = [40.0,-180.0,90.0,180.0]
    ;;pov = [82.7, -92.0, 0.0]
    pov = [90.0, 0.0, 0.0]
    rotcoeff = +1
    rot_add = !pi
endelse
;mnoon_long = noon_long -pov(1)*!dtor 
;rotate = (mnoon_long)*rotcoeff + rot_add
rotate = (noon_long)*rotcoeff + rot_add
rerange, rotate, /deg
pov(2) = rotate

; Make the map (Here the plotting axes are set up)

map_set, pov(0), pov(1), pov(2), /noerase, /noborder, $
  /ortho, clip=0, pos=position, $
  limit=lim, charsize=0.7, /advance,/isotropic
map_grid, glinestyle=0, glinethick=0.5, color=brown, $
  lats=[-40.0, 40.0], lons=[0.0,90.0,180.0,-90.0]

; LABELS

if keyword_set(south) then begin
    pcoord = convert_coord(0.0, -90.0, /to_dev)
    lcoord0 = convert_coord(0.0, -51.0, /to_dev)
    lcoord9 = convert_coord(90.0, -51.0, /to_dev)
endif else begin
    pcoord = convert_coord(0.0, 90.0, /to_dev)
    lcoord0 = convert_coord(0.0, 51.0, /to_dev)
    lcoord9 = convert_coord(90.0, 51.0, /to_dev)
endelse
lrt0 = (lcoord0(0) - pcoord(0))/abs(lcoord0(0) - pcoord(0))
lrt9 = (lcoord9(0) - pcoord(0))/abs(lcoord9(0) - pcoord(0))
lup0 = (lcoord0(1) - pcoord(1))/abs(lcoord0(1) - pcoord(1))
lup9 = (lcoord9(1) - pcoord(1))/abs(lcoord9(1) - pcoord(1))
rad = sqrt((lcoord0(0) - pcoord(0))^2 + (lcoord0(1) - pcoord(1))^2) 
xyouts, /dev, lcoord0(0)+lrt0*8, lcoord0(1)+lup0*8, '0', $
  align=.5, charsize=.8, col=col_tags
xyouts, /dev, lcoord9(0)+lrt9*8, lcoord9(1)+lup9*8, '90', $
  align=.5, charsize=.8, col=col_tags
xyouts, /dev, fix(pcoord(0)), fix(pcoord(1)+1.4*rad), '*',color=col_term, align=.5

; Plot the path of the craft in North and South polar regions

oplot, Mphi, Mtheta, min_value=latlim(0), color=col_fast, linestyle=0, thick=2
; If last plot cmd did not plot all points desired
if not keyword_set(whole) then $
oplot, Mphi, Mtheta, max_value=latlim(1), color=col_fast, linestyle=0, thick=2


; Add time ticks, labels to path
; N. polar region

;all points in N40 may not be adjacent, as when FAST in S. hem.
N40 = where(Flat GE 45)      ; indices of data points >= 45 deg N (changed)
if N40(0) NE -1 then begin     ; if there are points above 45 deg N
       ticktime = dblarr(24)   ; array to hold times of each tick
       ticklat = fltarr(24)    ; array to hold lattitudes of each tick
       ticklng = fltarr(24)    ; array to hold longitudes of each tick
        ;get index to data point nearest a 5min mark that is within 1st 26 pts
       if n_elements(N40) GT 25 then begin
               ;subind is an index to a subarray of the data
               rem = min( clock(N40(0:25)) MOD 300.D, subind )
       endif else subind = 0
       firstind = N40(0) + subind
       tickind = firstind      ; Index of data point where 1st tick will be
       p = 0                   ; Initialize to first tick mark
       ; Make lat, lng, time arrays holding info for each tickmark
       repeat begin
               ticktime(p) = clock(tickind)
               ticklat(p) = Flat(tickind)
               ticklng(p) = Flng(tickind)
               p = p + 1
               ;get index of point nearest first point plus p times 5 min
               dt = min( abs((clock(firstind) + p*300.D) - clock), tickind )
       endrep until (Flat(tickind) LT 40) OR (p EQ 24)
       ticktime = ticktime(where(ticktime NE 0)) ; trim off trailing zero elements
       ticklat = ticklat(where(ticktime NE 0))
       ticklng = ticklng(where(ticktime NE 0))
       nticks = n_elements(ticktime)
;       oplot, ticklng, ticklat, psym=1, symsize=1.8, color = black
;       xyouts, ticklng(0), ticklat(0), $
;               strmid(time_to_str(ticktime(0)),11,8), color=col_fast
;       xyouts, ticklng(nticks-1), ticklat(nticks-1), $
;               strmid(time_to_str(ticktime(nticks-1)),11,8), color=col_fast
	arrow, /data, color=col_fast, ticklng(nticks-2), ticklat(nticks-2), $
		ticklng(nticks-1), ticklat(nticks-1), hthick=2
endif

; S. polar region

S40 = where(Flat LE -45)      ; indices of data points <= -45 deg N
if S40(0) NE -1 then begin      ; if there are points below -45 deg N
        ticktime = dblarr(24)   ; array to hold times of each tick

        ticklat = fltarr(24)    ; array to hold lattitudes of each tick
        ticklng = fltarr(24)    ; array to hold longitudes of each tick
        ;get index to data point nearest a 5min mark that is within 1st 26 pts
        if n_elements(S40) GT 25 then begin
                ;subind is an index to a subarray of the data
                rem = min( clock(S40(0:25)) MOD 300.D, subind)
        endif else subind = 0
        firstind = S40(0) + subind
        tickind = firstind      ; Index of data point where 1st tick will be
        p = 0                   ; Initialize to first tick mark
        ; Make lat, lng, time arrays to hold info for each tickmark
        repeat begin
                ticktime(p) = clock(tickind)
                ticklat(p) = Flat(tickind)
                ticklng(p) = Flng(tickind)
                p = p + 1
                dt = min( abs((clock(firstind) + p*300.D) - clock), tickind )
        endrep until (Flat(tickind) GT -40) OR (p EQ 24)
        ticktime = ticktime(where(ticktime NE 0)) ; trim off trailing zero elements
        ticklat = ticklat(where(ticktime NE 0))
        ticklng = ticklng(where(ticktime NE 0))
        nticks = n_elements(ticktime)
;        oplot, ticklng, ticklat, psym=1, symsize=1.8, color = black
;       xyouts, ticklng(0), ticklat(0), $
;               strmid(time_to_str(ticktime(0)),11,8), color = col_fast
;       xyouts, ticklng(nticks-1), ticklat(nticks-1), $
;               strmid(time_to_str(ticktime(nticks-1)),11,8), color=col_fast
	arrow, /data, color=col_fast, ticklng(nticks-2), ticklat(nticks-2), $
		ticklng(nticks-1), ticklat(nticks-1), hthick=2
endif

; Auroral Ovals

act = 3    ; Default activity index

; Get Corrected Geomagnetic Lattitudes for all MLT

mlt = findgen(10.*24.+1)/10.			; [.1, .2, ..., 23.9, 24.0]
nelat = auroral_zone(mlt,act,/lat)            ; Corr. Geomag. Lat for all MLT
nplat = auroral_zone(mlt,act,/lat,/pole)      ; Northern poleward
selat = auroral_zone(mlt,act,/lat,/south)     ; Southern equatorward
splat = auroral_zone(mlt,act,/lat,/south,/pole)       ; Southern poleward

date_time = str_sep(time_to_str(time_N), '/') ; time_N is reference time
year = fix(strmid(date_time(0), 0, 4))                ; 4-digit integer
N_hms = fix(str_sep(date_time(1),':'))          ; [hh,mm,ss]
UT_hrs = N_hms(0) + N_hms(1)/60.                ; Hours into UT day

; Convert MLT to MLNG using UT

sun_lng = [!pi - UT_hrs*(!pi/12.)] ; LNG of Sun
sun_lat = [0.]
mag_to_geo, sun_lat, sun_lng, /mag ; MLNG of Sun
azon_mlng = mlt*(!pi/12.) + sun_lng(0) - !pi   ; MLNG of oval
nelon = azon_mlng
nplon = nelon
selon = nelon
splon = nelon

; Convert auroral ovals from MAG to GEO

transform_mag_geo, nelat, nelon, tnelat, tnelon, year=year
transform_mag_geo, nplat, nplon, tnplat, tnplon, year=year
transform_mag_geo, selat, selon, tselat, tselon, year=year
transform_mag_geo, splat, splon, tsplat, tsplon, year=year

rerange, tnelon, tnelat, /deg
rerange, tnplon, tnplat, /deg
rerange, tselon, tselat, /deg
rerange, tsplon, tsplat, /deg

oplot, tnelon, tnelat, color=col_oval, thick=1
oplot, tnplon, tnplat, color=col_oval, thick=1
oplot, tselon, tselat, color=col_oval, thick=1
oplot, tsplon, tsplat, color=col_oval, thick=1

end
