;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orb_ql
;
; Cleaned up wrapper for David Brain's quicklook of an orbit routine that
; was by Bryan Harter for the LASP QL product.
;
; Syntax: mvn_orb_ql
;
; Inputs:
;	None required - will pull the local time range for the orbits
; 	to plot and output.
;	optional -
;      tstring   - UTC time string if looking for orbit at a specific time
;	   orbnum    - orbit number if looking at specific orbit
;	   periapse  - view orbit with periapse at the center of the track
;      apoapse   - view orbit with apoapse at the center of the track 
;	   saveplot  - use the Z device to write a jpeg to disk
; 	   plot_sc_position - plot a marker at s/c position at tstring time 
;

; Dependencies:
;	from SPEDAS:
;		- mvn_spice_kernels
;		- mvn_orbit_num
;		- mvn_altitude
;	from local:
;		- br_360x180_pc.sav - GEO binned MGS data, n_lon x n_lat
;		- mvn_orb_ql_multiplot.pro - makes multipanel plot using device 'Z'
;			- mvn_orbql_geo2mso_crustal_field_map.pro - loads Br map
;			- mvn_orbql_barebones_eph.pro - loads ephemeris info into tplot vars
;      		- mvn_orbql_orbproj_panel.pro - makes a projection plot
;      		- mvn_orbql_cylplot_panel.pro - makes a cylindrical coords plot
;      		- mvn_orbql_groundtrack_panel.pro - makes a groundtrack
;      		- mvn_orbql_3d_projection_panel.pro - makes a 3D projection
;	   - mvn_orbql_plotposn.pro - positions a plot
;	   - mvn_orbql_colorscale.pro - scales a color map (Dave Brain version of bytscl.pro)
;	   - mvn_orbql_overlay_map.pro - plots a 2d map
;	   - mvn_orbql_symcat.pro - gives special plotting symbols
;
;
; Examples:
;
; ; Load a day
; timespan, '2023 12 9'
;
; ; Makes a plot in the main window for each orbit
; ; Hit enter while running to skip to next orbit
; ; cntrl-alt-del to escape
; mvn_orb_ql
;
; ; Uses the Z device to save a plot
; mvn_orb_ql, /saveplot
;
; ; Makes a plot of a specific orbit
; 	mvn_orb_ql, orb=870
;
; ; Plot a specific time, with a marker where the s/c is
; ; (centers the spacecraft trace over [-0.5, 0.5] the 
; ; concurrent orbit time)
; mvn_orb_ql, tstring='2017 9 10 14:00', /plot_sc_position
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro mvn_orb_ql, tstring=tstring, orbnum=orbnum, periapse=periapse, apoapse=apoapse,$
	saveplot=saveplot, plot_sc_position=plot_sc_position, crustal_field_path=crustal_field_path,$
	savedir=savedir

	IF ~keyword_set(crustal_field_path) THEN begin
		local_dir = FILE_DIRNAME(ROUTINE_FILEPATH('mvn_orb_ql'), /mark)
		crustal_field_path = local_dir + 'br_360x180_pc.sav'
	endif

	; Spacing of the orbit track colored dots in the each plot panel
	; (in seconds)
	res = 60d0
	; Spacing of the orbit track black dots (ticks) in each plot panel
	; (in seconds)
	tickinterval = 600d0

	;Set the resolution so that the screen is about 45x18 cm, may require tweaking on other systems

	if keyword_set(saveplot) then begin
		set_plot, 'Z'
		; window, 0, xs=1400, ys=700
		resolution = [2340, 936]*2
		device, set_resolution=resolution, Decomposed=0, Set_Pixel_Depth=24
		!P.Color = '000000'xL
		!P.Background = 'FFFFFF'xL
		!P.Font = 1
		erase
	endif else begin
	    window, 0, xs=1400, ys=700
	endelse

	showcrustal = 1
	showbehind = 1
	showperiapsis = 1
	showapoapsis = 0
	; showorbit = 1

	; default - center to periapse
	if not keyword_set(apoapse) and not keyword_set(periapse) and not keyword_set(tstring) then periapse = 1


	if keyword_set(plot_sc_position) then interest_time = tstring

	if not keyword_set(tstring) and not keyword_set(orbnum) then begin
		trange = timerange()
		orbnum_range = mvn_orbit_num(time=trange)

		; seek the closest periapse
		orbnum_range = round(orbnum_range)
		; seek the closest apoapse
		if keyword_set(apoapse) then orbnum_range = floor(orbnum_range) + 0.5

		n_orb = orbnum_range[1] - orbnum_range[0]

		orbnum = indgen(n_orb) + orbnum_range[0]
		; print, orbnum
		; stop


	endif else begin
		n_orb = 1

		if keyword_set(tstring) then begin
			orbnum = mvn_orbit_num(time=tstring)
		endif

		; Center on periapse (which is on integer orbit number)
		if keyword_set(periapse) then orbnum = round(orbnum)

		; Center track on apoapse (which is at the halfway orbit number)
		if keyword_set(apoapse) then orbnum = floor(orbnum) + 0.5

		trange = [mvn_orbit_num(orbnum=orbnum - 0.5), mvn_orbit_num(orbnum=orbnum + 0.5)]

		orbnum = [orbnum]

	endelse

	k = mvn_spice_kernels(['STD', 'LSK', 'SCK', 'SPK', 'FRM'], trange=trange, /load)


	for i = 0, n_orb - 1 do begin

		orbnum_i = orbnum[i]

		if not keyword_set(tstring) or n_orb gt 1 then begin
		  tstring = time_string(mvn_orbit_num(orbnum=orbnum_i))
		endif

		title_string = "Orb. " + strtrim(orbnum_i, 2)
		filename_i = 'Ql_Orb' + strtrim(orbnum_i, 2)

		if keyword_set(apoapse) then begin
			title_string += "(Apoapse),"
			filename_i += "_Apoapse_"
		endif

		if keyword_set(periapse) then begin
			title_string += "(Periapse),"
			filename_i += "_Periapse_"
		endif

		title_string += " T=" + time_string(tstring, tformat="YYYY-MM-DD hh:mm:ss")
		filename_i += '_T' + time_string(tstring, tformat="YYYYMMDDhhmmss")

		if keyword_set(savedir) then filename_i = savedir + filename_i

		; create time range that spans from halfway before to halfway after
		trange_i = [mvn_orbit_num(orbnum=orbnum_i - 0.5), mvn_orbit_num(orbnum=orbnum_i + 0.5)]
		; print, trange_i
		; stop
		print, showperiapsis

		mvn_orbql_multiplot, trange_i, filename_i,$
			crustal_field_file=crustal_field_path, showcrustal=showcrustal,$
			showbehind=showbehind, res=res, tickinterval=tickinterval,$
			showorbit=showorbit, /showperiapsis,$
			showapoapsis=showapoapsis,$
			title_string=title_string, saveplot=saveplot,$
			interest_time=interest_time


		next = ''
		if not keyword_set(saveplot) and n_orb ne 1 then begin
			read, next, prompt='Click enter to plot next orbit: '
		endif

		if n_orb gt 1 then erase

	endfor


	if keyword_set(saveplot) then begin
		erase
		set_plot, 'X'

		device, decomposed=0
		!p.background = 255
		!p.color = 0
		; !p.region = [0,0,0,0]
		; !p.position = [0,0,0,0]
	    ; !p.multi = [0,0,0,0,0]
	    !p.charsize = 1
	    !p.charthick = 1
		ans = mvn_orbql_plotposn(/winsize)
	endif

	; Fix tplot properties
	; Note: the hhmm column still is plotting offset,
	; unsure how to fix.
	tplot_options, 'region', [0.075, 0.1, 0.95, 0.95]
	tplot_options, 'noerase', 0
	tplot_options, 'charsize', 1
	time_stamp, /on


end