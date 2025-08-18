;+
;PROCEDURE:	plot_fa_crossing
;
;PURPOSE:
;
;	Plots magnetic footprint of spacecraft across earth. (FLAT,FLNG)
;	Shows the night/day terminator, auroral ovals, apogee and perigee
;	footprints, etc.  (See examples below.)
;
;       Keywords are grouped into categories: TIMESPAN, VIEW, DISPLAY,
;       AURORAL ZONE, MISCELLANEOUS.
;
; TIMESPAN KEYWORDS:
;
;	ORBIT	The orbit to plot. If unset, will plot over interval
;		containing present time and show craft position right now
;		(unless TMIN and TMAX are set).  ORBIT cannot be greater than
;		the last orbit listed in the predicted orbit almanac file.
;  TMIN, TMAX	Time points to be included on the chart.  Use these if
;               you want to display timespan in distant future.
;               Should not be more than a couple hours apart.  Format
;               of TMIN and TMAX must be the type of string accepted
;               by time_double() or a double float in seconds since
;               1970.  ORBIT must not be set if these keywords are to
;               be used.  These times will be labeled on the map as t1
;               and t2.  (Good for showing AOS and LOS taken from
;               contact schedules.)
;	XMARK	Set this to a time (string or double float) to have that point
;               labeled on the map as a big X.  If none of ORBIT,
;               TMIN, TMAX are set then this time will be used as the
;               reference time for which to create the plot.  (Good
;               for showing conjunctions.)
;
; VIEW KEYWORDS:
;
;   KIRUNA, POKER, WALLOPS, MCMURDO, CANBERRA, SANTIAGO, BERKELEY:
;		Set any of these for an overhead view of the station.
;   VIEWPOINT   This allows arbitrary views of the Earth. Should be a
;               3-element array designating lattitude, longitude, and
;               rotation in degrees.
;	WHOLE	If set, will not confine plot to polar regions.
;	SOUTH	Set to view earth from directly over South Pole.
;     MAGPOLE   View from above the magnetic pole with magnetic local
;               noon at the top of the plot.  Gridlines are still
;               geographic.  Poles are not symmetric because of the
;               eccentric dipole.  (When this keyword is not set
;               the display defaults to above the geographic poles,
;               with geographic local noon at the top.)
;        ZOOM   Enlarges the map. 1 is normal, 2 is twice as big.
;               See WINSIZE keyword for zooming in postscript mode.
;
; DISPLAY KEYWORDS:
;
;     WINSIZE	The width of the plot window in pixels. Default width is
;               640.  Height is scaled automatically so that lattitude
;               lines will be circular when output on a Tek printer:
;               H = W * 1.031.  In PostScript mode (POST keyword set),
;               WINSIZE acts like a magnification factor; WINSIZE=10
;               is normal.
;	  PC	Set this to nonzero if you are using a windowing system
;		that does not provide backing store to retain hidden
;		windows.  This keyword also sets the VECTOR_FONTS keyword.
;	GREY	Set this keyword to output the plot in greyscale.
;		(Run @startup to restore colortable.)
;       FILL    Fills oceans and continents with solid color to make a
;               pretty plot.  Setting this keyword when printing to
;               a color printer is discouraged.
;  VECTOR_FONTS Disable switch to device (hardware) font from
;               (default) Hershey vector-drawn fonts.  Device fonts
;               may be prettier, but vector fonts are device
;               independent.
;	POST    Set this to a filename to direct the ouput to an 8-bit color
;               postscript file instead of the graphics window.  When
;               viewing the postscript file, be sure your viewer is
;               set to 8 bits, not 24, and that it is displaying
;               "perfect colors".  (Do not add ".ps" to the name.)
;        GIF    Captures the image on the output graphics window to a
;               GIF file.  (Add ".gif" to the name yourself.)
;
; AURORAL ZONE KEYWORDS:
;
;    ACTIVITY	Set the Activity Index of aurora. ( 0-6, default 3)
;     SSCZONE   Show the auroral zone used by the Satellite Situation
;               Center instead of the one from Holzworth and Meng.
;               (THIS IS NOT PERFECTED YET.) See auroral_zone_ssc.pro
;               and notes below.
;
; MISCELLANEOUS KEYWORDS:
;
;      POLAR    Plots the magnetic footprint of the POLAR spacecraft
;               and information about its closest approach to that of
;               FAST.  Good for finding conjunctions or displaying
;               known ones. (For a description of how POLAR orbit data
;               is obtained, see the documentation for
;               get_po_orbit.pro.)
;   DRAG_PROP   If set, the orbit propagator will include the effects
;               of atmospheric drag.  The orbit track may be
;               inaccurate by a few degrees for propagations as short
;               as a few weeks.  This keyword minimizes this error.
;ALMANAC_INFO   Prints a line under the plot title telling the orbit
;               file used, the last epoch in that orbit file, and
;               whether or not drag was included in the orbit propagation.
;
;   EXAMPLES:   Show what FAST is doing now, and make it pretty:
;
;               IDL>  plot_fa_crossing, /fill
;
;               Show what FAST is doing for Christmas, make output
;               greyscale, and copy output to a GIF file:
;
;               IDL>  plot_fa_crossing, xmark='98-12-25/00:00:00', $
;                     gif='~/images/northpole.gif', /grey
;
;               Show the polar crossing of orbit 3000 from a
;               bird's-eye view over Canberra, and send the output to
;               an 8-bit color postscript file:
;
;               IDL>  plot_fa_crossing, /can, post='~/images/orb3000', $
;                     orbit=3000
;
;NOTES ON THE
;AURORAL ZONE:	The auroral zone is drawn using a procedure by Jim
;               Clemens (suggested by Holzworth & Meng, and corrected
;               by Mike Temerin).  The source for this procedure is
;               "Mathematical Representation of the Auroral Oval",
;               R.H. Holzworth and C.-I. Meng, Geophysical Research
;               Letters, Vol.2, No.9, Sept 1975.
;
;               The mathematical representation of the auroral ovals
;               is found by fitting Feldstein statistical ovals in
;               corrected geomagnetic coordinates to a 7-parameter
;               Fourier series:
;	
;		theta =  A1  +  A2 cos(phi + A3)
;		      +  A4 cos(2phi + 2A5)
;		      +  A6 cos(3phi + 3A7)
;
;		theta = corrected geomagnetic co-lattitude
;		phi = 2(pi)(MLT)/(24hrs)
;
;               The best fit constants are found for each value of
;               Q=0..6, where Q is the activity index which describes
;               how quiet (0) or active (6) the Feldstein auroral
;               ovals are.  The characteristic radius A1 of the ovals
;               increases monotonically with Q. (Source: Holzworth and
;               Meng.)
;
;               The function azonloc.pro generates the southern
;               auroral oval by reflection of the northern oval
;               through the magnetic equator.
;
;               The formula in Holzworth and Meng gives the ovals in
;               corrected geomagnetic coordinates.  The procedure
;               transform_mag_geo.pro converts them to geograhic
;               coordinates using the eccentric dipole model.
;
;CREATED BY:    J.Rauchleiba            96-12-20
;-
pro plot_fa_crossing, $
	ORBIT=orbit, $
	TMIN=time1, $
	TMAX=time2, $
        XMARK=xmarkin, $
        ZOOM=zoom, $
        DRAG_PROP=drag_prop, $
        ALMANAC_INFO=almanac_info, $
	WHOLE=whole, $
	VIEWPOINT=pov, $
	KIRUNA=kir, $
	POKER=pok, $
	WALLOPS=wal, $
	MCMURDO=mcm, $
	CANBERRA=can, $
	SANTIAGO=san, $
	BERKELEY=ber, $
        SOUTH=south, $
        MAGPOLE=magpole, $
        SSCZONE=ssc, $
	ACTIVITY=act, $
	WINSIZE=win, $
	PC=pc, $
        GREY=grey, $
        FILL=fill, $
        VECTOR_FONTS=vdf, $
        POST=psfile, $
        GIF=giffile, $
                      POLAR=polar, $
                      USER_OVERPLOT = uop

thm_init
loadct2,43
cols=get_colors()
window,10,xsize=500,ysize=500

; FIDDLE WITH THE COLORS

;n_colors = !d.n_colors		; Number of colors already loaded
n_colors = !d.table_size		; Number of colors already loaded
black = 0			; Assuming loadct2, 39
white = n_colors - 1
blue = fix(.33*float(n_colors))
if keyword_set(grey) then begin		; Make Greyscale colortable
    g1 = indgen(256)
    g2 = indgen(256)
    g3 = indgen(256)
    g1 = congrid(g1, n_colors)	; Sample n_colors of new table
    g2 = congrid(g2, n_colors)	; so size of new table equal to
    g3 = congrid(g3, n_colors)	; size of old table.
    tvlct, g1, g2, g3
    col_seas = white		; Seas
    col_cont = fix(n_colors*4/5) ; Continents
    col_fast = fix(n_colors/4)	; Spacecraft
    col_term = fix(n_colors/2)	; Terminator line
    col_oval = fix(n_colors/3)	; Auroral Ovals
    col_tags = black		; Various Labels
    erase, white                ; PS device non-supportive
endif else begin
    col_seas = blue
    col_cont = fix(.81*float(n_colors))
    col_fast = 6
    if keyword_set(fill) then col_term=5 else col_term=blue
    col_oval = 4
    if keyword_set(fill) then col_tags=white else col_tags=black
    ;; PS device does not support erase command.
    ;; Must use polyfill if /FILL in this case.
    if !d.name EQ 'PS' AND keyword_set(fill) then begin
        polyfill, [0,1,1,0,0], [0,0,1,1,0], /normal, col=black
    endif else begin 
        if keyword_set(fill) then erase, black else erase, white
    endelse
endelse

; FONT SETUP

oldfont = !p.font
if NOT keyword_set(vdf) and NOT keyword_set(pc) then !p.font = 0

; VIEWPOINT AND PLOT LIMITS

case 1 of
	keyword_set(kir): 	pov = [67.883,21.067,0 ]
	keyword_set(pok): 	pov = [64.8,-147.85,0 ]
	keyword_set(wal):	pov = [37.9,-75.4,0]
	keyword_set(mcm):	pov = [-77.85,166.62,0]
	keyword_set(can):	pov = [-35.35,149.167,0]
	keyword_set(san):	pov = [-33.433,-70.667,0]
        keyword_set(ber):	pov = [37.9,-122.1,0]
        else:
endcase
if keyword_set(whole) then latlim=[-90, 90] else latlim = [40, -40]
if keyword_set(south) then begin
    lat_ref = -90.
endif else begin
    if keyword_set(pov) then lat_ref = pov(0) else lat_ref = 90.
endelse
;;ns_sign = (lat_ref/abs(lat_ref) + 1)/2  ; 1:0 ::  N:S

; GET THE MAGNETIC PRINT DATA OF FAST

;get_fa_orbit, tmin, tmax, /all, orbit_file=orbit_file, drag_prop=drag_prop,/no_sto, struc=fa_orbit, status=status
fa_orbitrange,orbit
trange=timerange()
orbits=fa_time_to_orbit(trange)
if orbits[0] eq orbits[1] then orbit_string = string(orbits[0]) else orbit_string=string(orbit[0])+'-'+string(orbit[1])

fa_k0_load,'orb'
;if status NE 0 then message, 'Error returned by get_fa_orbit.'
get_data, 'flat', data=tmp1	
get_data, 'flng', data=tmp2
clock = tmp1.x
flat = tmp1.y
flng = tmp2.y
tmin = trange(0)
tmax = trange(1)
;clock = fa_orbit.TIME
;flat = fa_orbit.FLAT
;flng = fa_orbit.FLNG
Mtheta = flat
Mphi = flng

; Set time_N to when craft nearest N/S pole if orbit keyword set
; or median of tmin and tmax if they are specified
; or right now if no time specification.
; middle_time will be set to either of the latter two if orbit not set.
; This variable used by both the terminator and auroral oval generators.

if keyword_set(orbit) then begin
    dummy = min(abs(lat_ref - Flat), sub_N) 
    time_N = clock(sub_N) 
endif else time_N=middle_time


; GET LAT AND LNG OF SUN 

center_time = time_N
if (!VERSION.RELEASE LE '5.4') then begin
    hr_min = (str_sep((str_sep(time_string(center_time),'/'))(1),':'))(0:1)
endif else begin
    hr_min = (strsplit((strsplit(time_string(center_time),'/',/EXTRACT))(1),':',/EXTRACT))(0:1)
endelse
gmt_hrs = float(hr_min(0)) + float(hr_min(1))/60.0
noon_long  = (!pi - gmt_hrs*(!pi/12.)) MOD (2*!pi)
t0 = time_double('96-12-21/0:00') ;
ang = (center_time - t0)/(365.25d*24d*3600d)*2d*!pi
tilt = .410152
noon_lat = -(tilt * cos(ang))

; HANDLE SPECIAL POLE VIEWS

if keyword_set(magpole) then begin ; MAG pole view
    if keyword_set(south) then begin
        pov = [-75.3, 118.6, 0.0] ; override
        rotcoeff = -1
        rot_add = 0.0
    endif else begin
        pov = [82.7, -92.0, 0.0]  ; override
        rotcoeff = +1
        rot_add = !pi
    endelse
    mnoon_long = noon_long -pov(1)*!dtor ; Sm pole is 92 deg W of 0.
    rotate = (mnoon_long)*rotcoeff + rot_add
    rerange, rotate, /deg
    pov(2) = rotate
endif else if NOT keyword_set(pov) then begin ; GEO pole view
    if keyword_set(south) then begin
        pov = [-90., 0., 0.]
        rotcoeff = -1
        rot_add = 0.0
    endif else begin
        pov = [90., 0., 0.]
        rotcoeff = +1
        rot_add = !pi
    endelse
    rotate = noon_long*rotcoeff + rot_add
    rerange, rotate, /deg
    pov(2) = rotate
endif

; MAKE THE MAP (This sets up the plotting axes.)

if keyword_set(orbit) $
  then maptitle = 'ORBIT ' + strtrim(string(orbit), 2)+'  '+time_string(tmin) $
else maptitle = time_string(tmin) + '  ' + time_string(tmax)

maptitle = '!3' + maptitle
if keyword_set(zoom) then scale = 81.25e6/float(zoom)/(win/640.)
map_set, /ortho, pov(0), pov(1), pov(2), /noerase, /noborder, scale=scale, $
  horizon=keyword_set(fill), e_horizon={fill:keyword_set(fill), color:blue}

xyouts, .5, .975, /norm, align=.5, color=col_tags, charsize=1.3, maptitle
map_continents, fill=fill, color=col_cont
map_grid, glinestyle=0, color=0, label=2, latlab=-20, latalign=0.5, $
  lats = [-90,-75,-60,-45,-30,-15,0,15,30,45,60,75,90], $
  lonlab=.75*lat_ref, lonalign=0.5, $
  lons = [-180,-135,-90,-45,0,45,90,135,135,180]

; If ORBIT PROPAGATION INFO IS DESIRED

if keyword_set(almanac_info) then begin
    if (!VERSION.RELEASE LE '5.4') then begin
        ofpieces = str_sep(orbit_file, '/')
    endif else begin
        ofpieces = strsplit(orbit_file, '/', /EXTRACT)
    endelse
    ofname = ofpieces(n_elements(ofpieces) - 1)
    if keyword_set(drag_prop) then drag_inclu='with drag.' $
    else drag_inclu='without drag.'
    last_epoch = time_string(find_last_epoch(orbit_file))
    propinfo = 'Propagation: '+ofname+' ('+last_epoch+') '+drag_inclu
    xyouts, .29, .955, propinfo, /norm, color=col_tags, charsize=.90
endif

; SHOW SOME GROUND STATIONS AND OTHER POINTS OF INTEREST

citylng = [-147.85,21.067,-70.667,-75.4,166.62,149.167,-122.2,-92.0,118.6]
citylat = [64.8,67.883,-33.433,37.9,-77.85,-35.35,37.9,82.7,-75.3]
citytag = ['!3 Poker',' Kiruna',' Santiago',' Wallops',' McMurdo',$
           ' Canberra',' Berkeley',' !6N!3',' !6S!3']
oplot, citylng, citylat, psym=2, color=black
xyouts, citylng, citylat, citytag, color=black

;;xyouts, -147.85, 64.8, '!3*Poker', color=black
;;xyouts, 21.067, 67.883, '*Kiruna', color=black
;;xyouts, -70.667, -33.433, '*Santiago', color=black
;;xyouts, -75.4, 37.9, '*Wallops', color=black
;;xyouts, 166.62, -77.85, '*McMurdo', color=black
;;xyouts, 149.167, -35.35, '*Canberra', color=black
;;xyouts, -122.2, 37.9, '*Berkeley', color=black
;;xyouts, -92.0, 82.7, '*!6N!3', color=black  ; Magnetic North
;;xyouts, 118.6, -75.3, '*!6S!3', color=black ; Magnetic South

; GET POSITION OF FAST IN GSE TO FIND WHEN IN SHADOW

;;get_data, 'fa_pos', data=tmp	
get_data,'r',data=tmp	
;pos_arr = fa_orbit.fa_pos/6372.1 ; Position in GEI, km --> Re
store_data, 'fa_pos_re', data={x:clock, y:tmp.y/6372.1}
cotrans, 'fa_pos_re', 'fa_pos_gse', /GEI2GSE
get_data, 'fa_pos_gse', data=gse_stc
store_data, 'fa_pos_re', /delete
store_data, 'fa_pos_gse', /delete

; Array shade holds indices of data that are in shadow
; Craft in shade if x < 0 and y^2 + z^2 < Re^2 (1)

shade = where( gse_stc.y(*,0) LT 0 AND $
	(gse_stc.y(*,1)*gse_stc.y(*,1) +  gse_stc.y(*,2)*gse_stc.y(*,2)) LE 1 )
n_datapts = n_elements(gse_stc.x)
n_shadepts = n_elements(shade)
if shade(0) NE -1 then begin		; If there are  points in shade
	; The index to the shade array of the last shade point before sunrise:
	shade_break = (where(shade NE indgen(n_shadepts)+shade(0))) (0) - 1
	; data_break is index of last data point in shade before sunrise.
	; If the data pts ref'd by shade not all adjacent, 
	; set data_break to the index of the last point in the continuous segment, 
	; otherwise just set it to last point ref'd by shade.
	; (If there was no break in the shade then shade_break equals -2)
	if shade_break NE -2 then data_break = shade(shade_break) $
	else data_break = shade(n_shadepts - 1)
	; Assume, if shaded (shade(0) ne -1), data_break is either the last point
	; in continuous shade before sunlight (shade_break EQ -2), or is the last
	; point in the first interval of shade where the shade is broken up into
	; two intervals (shade_break NE -2).  data_break is never the last point
	; in the data array unless daybreak happens just before timespan.  In this
	; case, data_break = n_datapts - 1 AND shade_break EQ -2.
endif
	
; PLOT THE PATH OF THE CRAFT IN N AND S POLAR REGIONS (UNLESS /WHOLE).

oplot, Mphi, Mtheta, min_value=latlim(0), color=col_fast, linestyle=0, thick=3

; If we didn't already plot all the necessary points with the last plot command

if not keyword_set(whole) then $
oplot, Mphi, Mtheta, max_value=latlim(1), color=col_fast, linestyle=0, thick=3

;if defined(uop) then begin ; user-defined overplot routine
if keyword_set(uop) then begin ; user-defined overplot routine
    call_procedure, uop
endif


; OVERPLOT A BLACK LINE WHERE CRAFT IS IN SHADOW

if shade(0) NE -1 then begin		; if there are some points in shade
	oplot, Mphi(shade(0):data_break), Mtheta(shade(0):data_break), $
	min_value=latlim(0), color=black, linestyle=0, thick=2
	if not keyword_set(whole) then begin	; if we didn't aready plot all
		oplot, Mphi(shade(0):data_break), Mtheta(shade(0):data_break), $
		max_value=latlim(1), color=black, linestyle=0, thick=2
	endif

	; We must plot the remaining shady points if there was a break in the shade

	if data_break LT (n_datapts - 1) AND shade_break NE -2 then begin
		last_shade = shade(n_elements(shade) - 1)
		oplot, Mphi(shade(shade_break+1):last_shade), $
		Mtheta(shade(shade_break+1):last_shade), $
		min_value=latlim(0), color=black, linestyle=0, thick=2
		if not keyword_set(whole) then begin
			oplot, Mphi(shade(shade_break+1):last_shade), $
			Mtheta(shade(shade_break+1):last_shade), $
			max_value=latlim(1),color=black,linestyle=0,thick=2
		endif
	endif	
endif


if 0 then begin			; this is no longer needed

; Show print of craft right now if "now" is between tmin, tmax.
; Write text to plot window telling UT, ORBIT, FLAT, FLNG right now.

if (plot_craft) then begin
	dt = min( abs(clock - now_time), pos_ind)	; pos_ind=nowdataindex
	oplot, [Flng(pos_ind)], [Flat(pos_ind)], psym=6, syms=3, col=col_fast
        ;;get_data, 'ORBIT', data=orbit_nums
	get_data
;        orbit_nums = fa_orbit.ORBIT
        orbit_nums = fa_orbit.ORBIT
	current_orb = orbit_nums(pos_ind)
        if (!VERSION.RELEASE LE '5.4') then begin
	  xyouts, .8, .95, /norm, color=col_tags, $
            'CURRENT FAST INFO' + $
            '!C------------' + $
            '!CUT: ' + (str_sep(time_string(now_time), '/'))(1) + $
            '!CORBIT: ' + strtrim(string(current_orb), 2) + $
            '!CFLAT: ' + string(format='(F6.1)', Flat(pos_ind)) + $
            '!CFLNG: ' + string(format='(F6.1)', Flng(pos_ind))
        endif else begin
	  xyouts, .8, .95, /norm, color=col_tags, $
            'CURRENT FAST INFO' + $
            '!C------------' + $
            '!CUT: ' + (strsplit(time_string(now_time), '/', /EXTRACT))(1) + $
            '!CORBIT: ' + strtrim(string(current_orb), 2) + $
            '!CFLAT: ' + string(format='(F6.1)', Flat(pos_ind)) + $
            '!CFLNG: ' + string(format='(F6.1)', Flng(pos_ind))
        endelse
endif

endif

;; ADD TIME TICKS, LABELS TO PATH

label_foot_ticks, time=clock, latitude=Flat, longitude=Flng, interval=300, $
  latlim=45, color=col_tags

; LABEL TIME1 AND TIME2 IF SUPPLIED EXPLICITLY BY USER

if keyword_set(time1s) AND keyword_set(time2s) AND NOT keyword_set(orbit) $
then begin
	dt1 = min( abs(clock - time1s), time1_ind )
	dt2 = min( abs(clock - time2s), time2_ind )
	xyouts, Flng(time1_ind), Flat(time1_ind), '.t1', $
		align=0.0, color=col_tags
	xyouts, Flng(time2_ind), Flat(time2_ind), '.t2', $
		align=0.0, color=col_tags
endif

; PUT AN X MARK AT XMARK 

if keyword_set(xmark) then begin
    dtx = min( abs(clock - xmark), x_ind )
    oplot, [Flng(x_ind)], [Flat(x_ind)], psym=7, symsize=3.0, color=col_tags
endif

; PLOT THE TERMINATOR

terminator, time=time_N, tlat, tlng	; tlat, tlng as yet undefined
; The use of max_value and min_value below is a patch to remove ugly line
if pov(0) EQ 90 then min_term = 10 else min_term = -90
if pov(0) EQ -90 then max_term = -10 else max_term = 90
oplot, tlng, tlat, thick=3, color=col_term, min_val=min_term, max_val=max_term

; APOGEE, PERIGEE

;;get_data, 'ALT', data=alt
;;get_data, 'LAT', data=Glat
get_data,'alt',data=tmp & alt=tmp.y
get_data,'ilat',data=tmp & ilat=tmp.y
;alt = fa_orbit.ALT
;Glat = fa_orbit.LAT
max_alt = max(alt, app_sub)
min_lat = min(alt, per_sub)
xyouts, Flng(app_sub), Flat(app_sub), 'A', /data, color=col_tags
xyouts, Flng(per_sub), Flat(per_sub), 'P', /data, color=col_tags
;apogee_lat = Glat(app_sub)	; Geographic lattitude of apogee
apogee_lat = ilat(app_sub)	; Invariant lattitude of apogee
perigee_lat = ilat(per_sub)	; Invariant lattitude of apogee

; AURORAL OVALS

IF n_elements(act) NE 1 then act = 3		; Default activity index

; Get Corrected Geomagnetic Lattitudes for all MLT

mlt = findgen(241)/10.          ; [.1, .2, ..., 23.9, 24.0]
if keyword_set(ssc) then begin
    nelat = auroral_zone_ssc(mlt, poleward=nplat)
    selat = auroral_zone_ssc(mlt, poleward=splat, /south)
endif else begin
    nelat = auroral_zone(mlt,act,/lat) ; Corr. Geomag. Lat for all MLT
    nplat = auroral_zone(mlt,act,/lat,/pole) ; Northern poleward
    selat = auroral_zone(mlt,act,/lat,/south) ; Southern equatorward
    splat = auroral_zone(mlt,act,/lat,/south,/pole) ; Southern poleward
endelse

if (!VERSION.RELEASE LE '5.4') then begin
    date_time = str_sep(time_string(time_N), '/')	; time_N is reference time
    year = fix(strmid(date_time(0), 0, 4))		; 4-digit integer
    N_hms = fix(str_sep(date_time(1),':'))		; [hh,mm,ss]
    UT_hrs = N_hms(0) + N_hms(1)/60.		; Hours into UT day
endif else begin
    date_time = strsplit(time_string(time_N), '/', /EXTRACT)	; time_N is reference time
    year = fix(strmid(date_time(0), 0, 4))		; 4-digit integer
    N_hms = fix(strsplit(date_time(1),':', /EXTRACT))		; [hh,mm,ss]
    UT_hrs = N_hms(0) + N_hms(1)/60.		; Hours into UT day
endelse

; Convert MLT to MLNG using UT and get MLNG of Sun

sun_lng = [!pi - UT_hrs*(!pi/12.)] ; LNG of Sun
sun_lat = [0.]
mag_to_geo, sun_lat, sun_lng, /mag ; MLNG of Sun
azon_mlng = mlt*(!pi/12.) + sun_lng(0) - !pi ; MLNG of oval
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

; Plot the ovals

oplot, tnelon, tnelat, color=col_oval, thick=2
oplot, tnplon, tnplat, color=col_oval, thick=2
oplot, tselon, tselat, color=col_oval, thick=2
oplot, tsplon, tsplat, color=col_oval, thick=2

; Put a dot on the ovals at MLT=12, 24

dot_lng = [tnelon(240), tnplon(240), tselon(240), tsplon(240), $
           tnelon(120), tnplon(120), tselon(120), tsplon(120)]
dot_lat = [tnelat(240), tnplat(240), tselat(240), tsplat(240), $
           tnelat(120), tnplat(120), tselat(120), tsplat(120)]
oplot, psym=4, symsize=.5, dot_lng, dot_lat, color=black

; COLOR-CODED LEGEND, LABELS, ETC.

leg_loc = convert_coord(.02, .95, /norm, /to_device)
line_xpos = make_array(8, /int, value=leg_loc(0))
line_ypos = intarr(8)
if !d.name EQ 'PS' then linewidth=500 else linewidth=12
for p=0,7 do line_ypos(p) = leg_loc(1) - p*linewidth
colors = [col_tags, col_tags, $
          col_fast, col_fast, $
          col_tags, col_tags, $
          col_term, col_oval]
ds = string("260B)              ;" degree symbol
legend = ['LEGEND', $
          '----------', $
;          '[] FAST Position Now', $
          '+ FAST Path', $
          'A Apogee (' + string(format='(F5.1)', apogee_lat) + ds + ' ilat)', $
          'P Perigee(' + string(format='(F5.1)', perigee_lat) + ds + ' ilat)', $
          '- Terminator', $
          '- Auroral Oval']
xyouts, line_xpos, line_ypos, /device, legend, color=colors

; Tell when craft enters and exits shade. Must have shade(0) NE -1
; True transition from shade to sunlight if data_break NE n_datapts-1
; True transition from sunlight to shade if shade(0) NE 0.

if shade(0) NE -1 then begin
    if (!VERSION.RELEASE LE '5.4') then begin
      if data_break NE (n_datapts - 1) $
        then ecl_ex = 'Eclipse Ext: '+(str_sep(time_string(gse_stc.x(data_break)), '/'))(1) $
      else ecl_ex = ''
      if shade(0) NE 0 $
        then ecl_en = 'Eclipse Ent: '+(str_sep(time_string(gse_stc.x(shade(0))), '/'))(1) $
      else ecl_en = ''
    endif else begin
      if data_break NE (n_datapts - 1) $
        then ecl_ex = 'Eclipse Ext: '+(strsplit(time_string(gse_stc.x(data_break)), '/', /EXTRACT))(1) $
      else ecl_ex = ''
      if shade(0) NE 0 $
        then ecl_en = 'Eclipse Ent: '+(strsplit(time_string(gse_stc.x(shade(0))), '/', /EXTRACT))(1) $
      else ecl_en = ''
    endelse
    ecl_label = [ecl_ex, ecl_en]
    leg_loc = convert_coord(.98, .05, /norm, /to_device)
    line_xpos = make_array(2, /int, value=leg_loc(0))
    line_ypos = intarr(2)
    if !d.name EQ 'PS' then linewidth=500 else linewidth=12
    for p=0,1 do line_ypos(p) = leg_loc(1) - p*linewidth
    xyouts, line_xpos, line_ypos, /device, ecl_label, color=col_tags, align=1.0
endif

; Write TMIN and TMAX, or XMARK

if keyword_set(time1) AND keyword_set(time2) then begin
    if (!VERSION.RELEASE LE '5.4') then begin
        t12_label = ['t1 = '+(str_sep(time_string(time1s),'/'))(1), $
                     't2 = '+(str_sep(time_string(time2s),'/'))(1)  ]
    endif else begin
        t12_label = ['t1 = '+(strsplit(time_string(time1s),'/',/EXTRACT))(1), $
                     't2 = '+(strsplit(time_string(time2s),'/',/EXTRACT))(1)  ]
    endelse
    leg_loc = convert_coord(.02, .05, /norm, /to_device)
    line_xpos = make_array(2, /int, value=leg_loc(0))
    line_ypos = intarr(2)
    if !d.name EQ 'PS' then linewidth=500 else linewidth=12
    for p=0,1 do line_ypos(p) = leg_loc(1) - p*linewidth
    xyouts, line_xpos, line_ypos, /device, t12_label, color=col_tags
endif
if keyword_set(xmark) then xyouts, .02, .05, /normal, col=col_tags, $
  'X = '+time_string(xmark)

; Add POLAR spacecraft footprint if requested

if keyword_set(polar) then begin
    fast_flat = double(flat*!dtor)
    fast_flng = double(flng*!dtor)
    fast_times = clock
    plot_po_overlay, tag_color=col_tags, $
      time=clock, FLAT=polar_flat, FLNG=polar_flng
    ;;get_data, 'FLAT', data=po_flat_stc
    ;;get_data, 'FLNG', data=po_flng_stc
    polar_flat = polar_flat*!dtor
    polar_flng = polar_flng*!dtor
    
    ;; Find closest approach of footprints
    
    fx = cos(fast_flat)*cos(fast_flng)
    px = cos(polar_flat)*cos(polar_flng)
    fy = cos(fast_flat)*sin(fast_flng)
    py = cos(polar_flat)*sin(polar_flng)
    fz = sin(fast_flat)
    pz = sin(polar_flat)
    linesep = min(sqrt((fx-px)^2 + (fy-py)^2 + (fz-pz)^2), cji)
    ;;angsep = asin(linesep/2d)*!radeg
    ;;print, 'Geocent Ang Sep: ', time_string(fast_times(cji)), angsep, ds
    
    ;; Label Conjunction
    
    if (!VERSION.RELEASE LE '5.4') then begin
        cnj_time = (str_sep(time_string(fast_times(cji)), '/'))(1)
    endif else begin
        cnj_time = (strsplit(time_string(fast_times(cji)), '/', /EXTRACT))(1)
    endelse

    d_lat = string((fast_flat(cji) - polar_flat(cji))*!radeg, format='(F5.1)')
    d_lng = string((fast_flng(cji) - polar_flng(cji))*!radeg, format='(F5.1)')
    cnj_loc = convert_coord(.02, .17, /normal, /to_device)
    cnj_xpos = make_array(4, /int, value=cnj_loc(0))
    cnj_ypos = intarr(4)
    for p=0,3 do cnj_ypos(p) = cnj_loc(1) - p*linewidth
    cnj_stg = ['CONJUNCTION:', cnj_time, '!4D!3Lat '+d_lat, '!4D!3Lng '+d_lng]
    xyouts, cnj_xpos, cnj_ypos, /device, cnj_stg, color=col_tags
    ;;oplot, [fast_flng(cji),polar_flng(cji)]*!radeg, $
    ;;  [fast_flat(cji),polar_flat(cji)]*!radeg,color=col_oval
endif

; Close postscript file if opened

if keyword_set(psfile) then pclose

; Write to GIF file if desired

if keyword_set(giffile) AND (!d.name EQ 'X' OR !d.name EQ 'Z') then begin
    tvlct, /get, roy, gee, biv
    write_gif, giffile, tvrd(), roy, gee, biv
endif

; Reset to original font system and plot window

!p.font = oldfont
if keyword_set(orig_plot_pos) then !p.position=orig_plot_pos

; Message

print, 'Plot_fa_crossing graphical interface: PFCGUI.PRO'

end
