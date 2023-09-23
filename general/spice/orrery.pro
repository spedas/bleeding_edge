;+
;PROCEDURE:   orrery
;PURPOSE:
;  Plots the orbits of the planets to scale as viewed from the north
;  ecliptic pole, based on the latest JPL planetary ephemeris.  Planet
;  locations are shown by colored disks at the time(s) provided.  If 
;  time is an array, then colored arcs are drawn to show the orbital 
;  positions spanned by the input time array.  In this case, colored 
;  disks mark the beginning, middle and end of each arc.  Time can 
;  also be input by clicking in a tplot window (see keyword MOVIE).
;
;  By default, this routine shows the inner planets (Mercury to Mars).
;  Use keyword OUTER to show all the planets plus Pluto.  In this case, 
;  the inner planets will be crowded together in the center.
;
;  This routine was originally designed (long ago in the Great Valley)
;  to show only Earth and Mars.  Some useful Earth-Mars geometry is 
;  calculated and can be shown using LABEL=2.  Information includes:
;
;    Earth-Sun-Mars angle (amount of solar rotation E -> M)
;    Sun-Mars-Earth angle (elongation of Earth from Mars)
;    Sun-Earth-Mars angle (elongation of Mars from Earth)
;    One-way light time (Mars to Earth, min)
;    Subsolar latitude on Mars (deg)
;
;  Use keyword PLANET to calculate the same geometry for any other 
;  planet.
;
;  Optionally returns (keyword EPH) the orbital positions of the 
;  planets plus Pluto for the entire ephemeris time period.
;
;  Note: This routine uses long-range predict kernels for Solar Probe 
;  and Solar Orbiter.  These kernels use a format that cannot be read 
;  by earlier versions of ICY/SPICE.  You may need to update ICY/SPICE 
;  to see the positions of these two spacecraft.  Version 1.8.0 is 
;  known to work.
;
;USAGE:
;  orrery [, time] [,KEYWORD=value, ...]
;
;INPUTS:
;       time:      Show planet positions at this time(s).  Valid times
;                  are from 1900-01-05 to 2100-01-01 in any format
;                  accepted by time_double().
;
;                  If not specified, use the current system time.
;
;KEYWORDS:
;       NOPLOT:    Skip the plot (useful with keyword EPH).
;
;       NOBOX:     Hide the axis box.
;
;       LABEL:     Controls the amount of text labels.
;                    0 = no labels
;                    1 = a few labels (default)
;                    2 = all labels (incl. E-M geometry)
;
;       PLABEL:    Print the name of each planet next to its symbol.
;
;       SLABEL:    Print the name of each spacecraft next to its symbol.
;
;       PLANET:    Planet number or name for calculating geometry
;                  with respect to Earth.  Numbering starts at 1.
;                  For string input, case-folded minimum matching
;                  is performed.
;
;                    1 = Mercury, 2 = Venus, ..., 9 = Pluto.
;                    Default = 4 or 'Mars'.
;                    A value of 3 or 'Earth' is invalid.
;
;                  The plot limits will be set to include this and
;                  all interior planets.
;
;       FIXPLANET: Rotate the all planet and satellite positions 
;                  about the Z axis so that the specified planet is
;                  fixed at the same longitude.  Set this keyword
;                  to a scalar or two-element array:
;
;                    fix[0] : fixed longitude (0-360 deg)
;                    fix[1] : planet number (1-9); default = 3
;
;                  Applies only to plotting - does not affect the 
;                  returned EPH structure.
;
;       SCALE:     Scale factor for adjusting the size of the
;                  plot window.  Default = 1.
;
;       EPH:       Named variable to hold structure of planet and
;                  satellite ephemeris data (1900-2100, or as 
;                  available).
;
;       CSS:       Plot the location of Comet Siding Spring.
;                    Coverage: 2000-01-01 to 2016-01-01
;
;       STEREO:    Plot the locations of the STEREO spacecraft,
;                  when available.  (The Stereo-B ephemeris has
;                  an error near the beginning of the mission,
;                  associated with a maneuver to place it in the
;                  "behind" orbit.  This routine deletes the bad
;                  ephemeris values and interpolates across the 
;                  gap.)
;                    Coverage:
;                      Stereo A: 2006-10-26 to 2023-01-25
;                      Stereo B: 2006-10-26 to 2014-09-28
;
;       SORB:      Plot the location of Solar Orbiter.  Includes a
;                  predict ephemeris.
;                    Coverage: 2020-02-10 to 2030-11-20
;
;       PSP:       Plot the location of Parker Solar Probe. Includes
;                  a predict ephemeris.
;                    Coverage: 2018-08-12 to 2025-08-31
;
;       SALL:      Plot all of the above spacecraft locations.
;
;       RELOAD:    Reload the ephemerides.  (Does not reinitialize
;                  SPICE -- use cspice_kclear for that.)
;
;       SPIRAL:    Plot the Parker (Archimedean) spiral of the
;                  solar wind magnetic field.  Spiral is shown out
;                  to the orbit of Saturn, where the magnetic field
;                  is nearly tangential to the orbit.
;
;       VSW:       Solar wind velocity for calculating the spiral.
;                  Default = 400 km/s.  (Usually within the range
;                  of 250 to 750 km/s.)
;
;       SROT:      Solar siderial rotation period in days for 
;                  calculating the spiral.  Default = 25.38 days
;                  (i.e., Carrington), which gives the typically 
;                  observed Parker spiral angle at Earth (47 deg) 
;                  for a solar wind velocity of 400 km/s.
;
;       MOVIE:     Click on an existing tplot window and/or drag the 
;                  cursor for a movie effect.
;
;       KEEPWIN:   Just keep the plot window (don't ask).
;
;       WINDOW:    Window number for the snapshot window.  This is a number
;                  from 0 to 31 (same range as WINDOW command).  Any value
;                  outside this range will invoke the FREE keyword.
;
;       MONITOR:   Put snapshot windows in this monitor.  Monitors are numbered
;                  from 0 to N-1, where N is the number of monitors recognized
;                  by the operating system.  See win.pro for details.
;
;       PNG:       Set this to the full filename (including path) of a png.
;                  No snapshot window is created.  All graphics output is
;                  written to the png file instead.  MOVIE = 0 is enforced.
;
;       OUTER:     Plot the outer planets.  The inner planets will
;                  be crowded together in the center.  Pluto's orbit
;                  is incomplete over the 1900-2100 ephemeris range.
;
;       XYRANGE:   Plot range in X and Y (AU).  Overrides default.
;                  If one value is supplied, plot range is -XYRANGE
;                  to +XYRANGE.  If two or more values are supplied,
;                  then plot range is min(XYRANGE) to max(XYRANGE).
;                  If set, then all planets within the plot window
;                  are shown, and the Archimedean spiral (if set)
;                  extends out to the orbit of Saturn.
;
;       TPLOT:     Create Earth-PLANET geometry and spacecraft position
;                  tplot variables.
;
;       VARNAMES:  Standard set of tplot variables to plot.
;
;       VERBOSE:   Controls verbosity of file_retrieve.
;                  Default = 0 (no output).  Try a value > 2 to see
;                  more messages; > 4 for lots of messages.
;
;       FULL:      Show everything: planets, all spacecraft, Parker
;                  spiral, and all labels.
;
;       BLACK:     Use a black background for the orbit snapshot.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-25 08:36:05 -0700 (Fri, 25 Aug 2023) $
; $LastChangedRevision: 32062 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/orrery.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro orrery, time, noplot=noplot, nobox=nobox, label=label, scale=scale, eph=eph, $
                  spiral=spiral, Vsw=Vsw, srot=srot, movie=movie, stereo=stereo, $
                  keepwin=keepwin, tplot=tplot, reload=reload, outer=outer, $
                  xyrange=range, planet=planet2, sorb=sorb2, psp=psp2, sall=sall, $
                  verbose=verbose, full=full, fixplanet=fixplanet, monitor=monitor, $
                  window=window, png=png, varnames=varnames, plabel=plabel, slabel=slabel, $
                  css=css2, black=black, key=key

  common planetorb, planet, css, sta, stb, sorb, psp, orrkey
  @putwin_common

  if (size(windex,/type) eq 0) then win, config=0  ; win acts like window
  colstr = get_colors()

; Load any keyword defaults

  orrery_options, get=key, /silent
  ktag = tag_names(key)
  tlist = ['NOPLOT','NOBOX','LABEL','SCALE','EPH','SPIRAL','VSW','SROT','MOVIE', $
           'STEREO','KEEPWIN','TPLOT','RELOAD','OUTER','XYRANGE','PLANET2','SORB2', $
           'PSP2','SALL','VERBOSE','FULL','FIXPLANET','MONITOR','WINDOW','PNG', $
           'VARNAMES','PLABEL','SLABEL','CSS2','BLACK']
  for j=0,(n_elements(ktag)-1) do begin
    i = strmatch(tlist, ktag[j]+'*', /fold)
    case (total(i)) of
        0  : ; keyword not recognized -> do nothing
        1  : begin
               kname = (tlist[where(i eq 1)])[0]
               ok = execute('kset = size(' + kname + ',/type) gt 0',0,1)
               if (not kset) then ok = execute(kname + ' = key.(j)',0,1)
             end
      else : print, "Keyword ambiguous: ", ktag[j]
    endcase
  endfor

  if (size(verbose,/type) eq 0) then verbose = 0

  oneday = 86400D
  au = 1.495978707d13  ; Astronomical Unit (cm)
  Rs = 6.957d10        ; Radius of Sun (cm), photosphere
  Rmars = 3.3895D8     ; Radius of Mars (cm), volumetric
  c = 2.99792458d10    ; Speed of light (cm/s)
  suncol = 5           ; Sun color
  sunsze = 5           ; Sun symbol size
  pkscol = 4           ; Parker spiral color

  pname = ['MERCURY','VENUS','EARTH','MARS','JUPITER','SATURN','URANUS','NEPTUNE','PLUTO']
  pstr = ['H','V','E','M','J','S','U','N','P']  ; planet letters
  pcol = [ 4, 204, 3,  6, 204, 4,  5,  3,  1 ]  ; planet colors
  psze = [ 3,  4,  4,  3,  6,  5,  4,  4,  3 ]  ; planet symbol sizes
  pday = [89, 226, 367, 688, 4334, 10757, 30689, 60192, 90562]  ; days per orbit
  tspan = time_double(['1900-01-05','2100-01-01'])  ; range covered by mar097.bsp
  nplan = n_elements(pname)

  cname = 'SIDING SPRING'
  clab = 'CSS'
  csym = 8
  ccol = 5
  csze = 3
  cday = 5845  ; 2000-01-01 to 2016-01-01 (siding_spring_s46.bsp)

  sname = ['STEREO AHEAD','STEREO BEHIND','SOLAR ORBITER','SOLAR PROBE PLUS']
  slab = ['STA','STB','SO','PSP']
  ssym = [ 1,   1,   5,   6 ]  ; spacecraft symbols
  scol = [ 4,   5,   6,   1 ]  ; spacecraft colors
  ssze = [ 2,   2,  1.5, 1.5]  ; spacecraft symbol sizes
  sday = [367, 367, 150,  90]  ; days per orbit (typical)

  xsize = 792
  ysize = 765
  reset = 1
  eph = 0

; Archimedean spiral parameters

  if (size(Vsw,/type) eq 0) then Vsw = 400.     ; km/s
  if (size(srot,/type) eq 0) then srot = 25.38  ; days
  omega = (2d*!dpi)/(srot*oneday)               ; radians/sec
  Vsw = (Vsw*1d5)/au                            ; AU/sec
  spts = 2000
  smax = 12.      ; maximum radial distance for spiral (AU)

; Process keywords

  if (size(planet2,/type) eq 0) then planet2 = 4      ; default is Mars
  if (size(planet2,/type) eq 7) then begin
    ok = 0
    i = strmatch(pname, planet2+'*', /fold)
    case total(i) of
       0   : print, "Planet name not recognized: ", planet2
       1   : begin
               planet2 = (where(i eq 1))[0] + 1
               ok = 1
             end
      else : print, "Planet name ambiguous: ", planet2
    endcase
    if (not ok) then return
  endif
  pnum = (fix(planet2 - 1) > 0) < (nplan - 1)
  if (pnum eq 2) then begin
    print,"Keyword PLANET cannot be 'Earth'.  Using Mars."
    pnum = 3
  endif

  ipmax = pnum > 3  ; at least show Mercury to Mars
  case ipmax of
     3   : xyrange = [-2,2]
     4   : xyrange = [-6,6]
     5   : xyrange = [-11,11]
     6   : xyrange = [-22,22]
     7   : xyrange = [-33,33]
    else : begin
             xyrange = [-40,50]
             ipmax = nplan - 1
           end
  endcase

  if keyword_set(outer) then begin
    xyrange = [-40,50]
    ipmax = nplan - 1
  endif

  loff = psze*(xyrange[1] - xyrange[0])/400.

  sflg = keyword_set(stereo)
  oflg = keyword_set(sorb2)
  pflg = keyword_set(psp2)
  cflg = keyword_set(css2)

  if keyword_set(full) then begin
    sall = 1
    label = 2
    spiral = 1
  endif
  if keyword_set(sall) then begin
    sflg = 1
    oflg = 1
    pflg = 1
  endif
  mflg = keyword_set(movie)

  case n_elements(range) of
     0   : ; do nothing
     1   : begin
             xyrange = [-abs(range), abs(range)]
             ipmax = nplan - 1
           end
    else : begin
             xyrange = minmax(range)
             ipmax = nplan - 1
           end
  endcase

  if (size(label,/type) eq 0) then label = 1
  dolab = label < 2

  plab = replicate(0,nplan)
  nlab = n_elements(plabel)
  case nlab of
     0   : ; do nothing
     1   : begin
             plab[*] = plabel
             if (ipmax gt 4) then plab[0:3] = 0
           end
    else : for i=0,(nlab-1) do plab[i] = plabel[i]
  endcase

  clabel = max(plab)
  slabel = keyword_set(slabel)

  kflg = keyword_set(keepwin)

  if (size(png,/type) eq 7) then begin
    pngname = png
    dopng = 1
    mflg = 0
  endif else dopng = 0

  if keyword_set(reset) then Owin = -1

  case n_elements(fixplanet) of
      0  : fflg = 0
      1  : begin
             fflg = 1
             flon = fixplanet[0]
             fnum = 2
           end
    else : begin
             fflg = 1
             flon = fixplanet[0]
             fnum = fix(fixplanet[1]) - 1
             if ((fnum lt 0) or (fnum gt ipmax)) then begin
               print,'Invalid planet to fix!'
               fflg = 0
             endif
           end
  endcase

  varnames = ['S-M','Lss','STEREO','R-SORB','Lat-SORB','R-PSP']

; Check the version of ICY/SPICE

  iflg = 1
  help, 'icy', /dlm, output=lines
  nlines = n_elements(lines)
  if (strmatch(lines[0], '*Unknown*') or (nlines lt 3)) then begin
    print,'This routine requires ICY/SPICE.  Check your installation or'
    print,'download from: https://naif.jpl.nasa.gov/naif/toolkit_IDL.html'
    return
  endif
  words = strsplit(strtrim(lines[1],2),' ,',/extract)
  indx = strmatch(words, 'Version:')
  i = where(indx gt 0, count)
  if (count gt 0) then begin
    icyver = fix(strsplit(words[i+1],'.',/extract))
    if ((icyver[0] lt 2) and (icyver[1] lt 8)) then begin
      print,'Your version of ICY/SPICE (' + words[i+1] + ') is out of date.'
      print,'Upgrade to 1.8.0 or later to show Solar Probe and Solar Orbiter locations.'
      print,'Download from: https://naif.jpl.nasa.gov/naif/toolkit_IDL.html'
      oflg = 0
      pflg = 0
      iflg = 0
    endif
  endif else begin
    print,'Cannot determine the version of ICY/SPICE:'
	for i=0,(nlines-1) do print,lines[i]
    print,'Good luck!'
  endelse

; Get the time

  if (size(time,/type) eq 0) then time = systime(/sec,/utc)

  tmin = min(time_double(time), max=tmax)
  ndays = long((tmax - tmin)/oneday)

  if (ndays gt 0L) then begin
    tavg = (tmin + tmax)/2D
    tref = [tmin, tavg, tmax]
    t = [(tmin + dindgen(ndays)*oneday), tmax]
  endif else begin
    tavg = tmin
    tref = [tmin, tmin, tmin]
    t = [tmin]
  endelse
  npts = n_elements(t)

; Load ephemerides into the common block

  if (keyword_set(reload) or (data_type(planet) ne 8)) then begin

    ssrc = mvn_file_source(archive_ext='')  ; don't archive old files

; Locate the Siding Spring ephemeris, but do not load it yet
;   The position of this kernel in the loadlist matters!

    path = 'misc/spice/naif/generic_kernels/spk/comets/'
    pathname = path + 'siding_spring_s46.bsp'
    css_ker = (mvn_pfp_file_retrieve(pathname,source=ssrc,verbose=verbose))[0]

; Check for standard SPICE kernels; load them if necessary

    mk = spice_test('*', verbose=-1)
    indx = where(mk ne '', count)
    if (count eq 0) then begin
      print,'Initializing SPICE ... ', format='(a,$)'
      dprint,' ', getdebug=bug, dlevel=4
      dprint,' ', setdebug=0, dlevel=4
      std_kernels = spice_standard_kernels(/mars,verbose=-1)
      std_kernels = [std_kernels[0:1], css_ker, std_kernels[2:*]]
      spice_kernel_load, std_kernels
      dprint,' ', setdebug=bug, dlevel=4
      mk = spice_test('*', verbose=-1)
      print,'done'
    endif

; Add the ID's for Solar Probe and Solar Orbiter

    path = 'misc/spice/naif/generic_kernels/'
    pathname = path + 'name_id_map.tf'
    fname = (mvn_pfp_file_retrieve(pathname,source=ssrc,verbose=verbose))[0]
    indx = where(mk eq fname, count)
    if (count eq 0) then begin
      cspice_furnsh, fname
      mk = spice_test('*', verbose=-1)
      indx = where(mk eq fname, count)
      if (count eq 0) then begin
        print,"Could not load name-to-id kernel:"
        print,"  " + root_data_dir() + pathname
      endif
    endif

; Test that all kernels are loaded

    success = 0B

    ok = max(stregex(mk,'naif[0-9]{4}\.tls',/subexpr,/fold_case)) gt (-1)
    if (not ok) then print,"No leap seconds kernel: naif????.tls"
    success += ok

    ok = max(stregex(mk,'pck[0-9]{5}\.tpc',/subexpr,/fold_case)) gt (-1)
    if (not ok) then print,"No planet geometry kernel: pck?????.tpc"
    success += ok

    ok = max(stregex(mk,'de[0-9]{3}.*\.bsp',/subexpr,/fold_case)) gt (-1)
    if (not ok) then print,"No planet orbit kernel: de????.bsp"
    success += ok

    ok = max(stregex(mk,'mar[0-9]{3}\.bsp',/subexpr,/fold_case)) gt (-1)
    if (not ok) then print,"No Mars/Phobos/Deimos kernel: mar???.bsp"
    success += ok

    if (success lt 4B) then return

; STEREO

    path = 'misc/spice/naif/STEREO/kernels/spk/'
    pathname = path + 'STEREO-A_merged.bsp'
    fname = (mvn_pfp_file_retrieve(pathname,source=ssrc,verbose=verbose))[0]
    indx = where(mk eq fname, count)
    if (count eq 0) then begin
      cspice_furnsh, fname
      mk = spice_test('*', verbose=-1)
      indx = where(mk eq fname, count)
      if (count eq 0) then begin
        print,"Could not load STEREO A spk:"
        print,"  " + root_data_dir() + pathname
      endif
    endif

    pathname = path + 'STEREO-B_merged.bsp'
    fname = (mvn_pfp_file_retrieve(pathname,source=ssrc,verbose=verbose))[0]
    indx = where(mk eq fname, count)
    if (count eq 0) then begin
      cspice_furnsh, fname
      mk = spice_test('*', verbose=-1)
      indx = where(mk eq fname, count)
      if (count eq 0) then begin
        print,"Could not load STEREO B spk:"
        print,"  " + root_data_dir() + pathname
      endif
    endif

; Solar Orbiter

    if (iflg) then begin
      path = 'misc/spice/naif/Solar_Orbiter/kernels/spk/'
      pathname = path + 'solo_ANC_soc-orbit_20200210-20301120_L016_V2_00025_V01.bsp'
      fname = (mvn_pfp_file_retrieve(pathname,source=ssrc,verbose=verbose))[0]
      indx = where(mk eq fname, count)
      if (count eq 0) then begin
        cspice_furnsh, fname
        mk = spice_test('*', verbose=-1)
        indx = where(mk eq fname, count)
        if (count eq 0) then begin
          print,"Could not load Solar Orbiter spk:"
          print,"  " + root_data_dir() + pathname
        endif
      endif

; Parker Solar Probe

      path = 'misc/spice/naif/PSP/kernels/spk/'
      pathname = path + 'spp_nom_20180812_20250831_v039_RO6.bsp'
      fname = (mvn_pfp_file_retrieve(pathname,source=ssrc,verbose=verbose))[0]
      indx = where(mk eq fname, count)
      if (count eq 0) then begin
        cspice_furnsh, fname
        mk = spice_test('*', verbose=-1)
        indx = where(mk eq fname, count)
        if (count eq 0) then begin
          print,"Could not load Parker Solar Probe spk:"
          print,"  " + root_data_dir() + pathname
        endif
      endif
    endif

    mvn_spice_stat, info=sinfo, /silent

    print,'Initializing ephemeris ... ', format='(a,$)'

; Get ephemeris time

    i = where(sinfo.obj_name eq 'EARTH BARYCENTER')
    tsp = time_double(sinfo[max(i)].trange)
    t0 = tspan[0] > tsp[0]
    t1 = tspan[1] < tsp[1]
    ndays = floor((t1 - t0)/oneday)
    tt = t0 + oneday*dindgen(ndays)
    et = time_ephemeris(tt)

; Calculate ephemeris for each planet

    planet = {name  : ''                  , $
              time  : replicate(0D,ndays) , $
              x     : replicate(0D,ndays) , $
              y     : replicate(0D,ndays) , $
              z     : replicate(0D,ndays) , $
              r     : replicate(0D,ndays) , $
              d2x   : replicate(0D,ndays) , $
              d2y   : replicate(0D,ndays) , $
              d2z   : replicate(0D,ndays) , $
              owlt  : replicate(0D,ndays) , $
              latss : replicate(0D,ndays) , $
              d2l   : replicate(0D,ndays) , $
              units : ['AU','SEC','DEG']  , $
              frame : 'ECLIPJ2000'           }

    planet = replicate(planet,nplan)
    planet.name = pname
    obj_name = planet.name + ' BARYCENTER'

    for k=0,(nplan-1) do begin
      cspice_spkpos, obj_name[k], et, 'ECLIPJ2000', 'NONE', 'Sun', pos, ltime
      pos = transpose(pos)/(au/1.d5)
      planet[k].time = tt
      planet[k].x    = pos[*,0]
      planet[k].y    = pos[*,1]
      planet[k].z    = pos[*,2]
      planet[k].r    = sqrt(total(pos[*,0:2]^2.,2))
      planet[k].d2x  = spl_init(planet[k].time, planet[k].x, /double)
      planet[k].d2y  = spl_init(planet[k].time, planet[k].y, /double)
      planet[k].d2z  = spl_init(planet[k].time, planet[k].z, /double)
      print, strmid(planet[k].name,0,1), format='(a1," ",$)'
    endfor

    for k=0,(nplan-1) do begin
      if (k ne 2) then begin
        dx = planet[k].x - planet[2].x
        dy = planet[k].y - planet[2].y
        dz = planet[k].z - planet[2].z
        ds = sqrt(dx*dx + dy*dy + dz*dz)
        planet[k].owlt = ds*(au/c)
      endif
    endfor
    print,".",format='(a1,$)'

; --------- MARS SUBSOLAR LATITUDE ---------

    latss = dblarr(ndays)
    for i=0L,(ndays-1L) do begin
      cspice_subslr, 'Intercept: ellipsoid', 'Mars', et[i], 'IAU_MARS', 'NONE', 'Sun', $
                     subsun, trgepc, srfvec
      r = sqrt(total(subsun*subsun))
      latss[i] = asin(subsun[2]/r)*!radeg
    endfor
    planet[3].latss = latss
    planet[3].d2l = spl_init(planet[3].time, planet[3].latss, /double)
    print,".",format='(a1,$)'

; Place holder for missing ephemeris data

    missing = { name  : ''                        , $
                time  : time_double('1800-01-01') , $
                x     : 0D                        , $
                y     : 0D                        , $
                z     : 0D                        , $
                owlt  : 0D                        , $
                units : ['','','']                , $
                frame : 'INVALID'                    }

; --------- COMET SIDING SPRING ---------

    i = where(sinfo.obj_name eq cname, count)
    if (count gt 0L) then begin
      tsp = time_double(sinfo[i].trange)
      tsp = minmax(tsp)
      ndays = floor(2D*(tsp[1] - tsp[0])/oneday)
      dt = (tsp[1] - tsp[0])/double(ndays)
      tt = tsp[0] + dt*dindgen(ndays)
      et = time_ephemeris(tt)

      cspice_spkpos, cname[0], et, 'ECLIPJ2000', 'NONE', 'Sun', css, ltime
      css = transpose(css)/(au/1.d5)
      css = { name  : cname[0]     , $
              time  : tt           , $
              x     : css[*,0]     , $
              y     : css[*,1]     , $
              z     : css[*,2]     , $
              owlt  : ltime        , $
              units : ['AU','SEC'] , $
              frame : 'ECLIPJ2000'    }

      d2x = spl_init(css.time, css.x, /double)
      d2y = spl_init(css.time, css.y, /double)
      d2z = spl_init(css.time, css.z, /double)
      str_element, css, 'd2x', d2x, /add
      str_element, css, 'd2y', d2y, /add
      str_element, css, 'd2z', d2z, /add

      r = sqrt(css.x^2. + css.y^2. + css.z^2.)
      lat = asin(css.z/r)*!radeg
      str_element, css, 'lat', lat, /add

;     OWLT with respect to Mars, not Earth

      xe = spl_interp(planet[3].time, planet[3].x, planet[3].d2x, css.time)
      ye = spl_interp(planet[3].time, planet[3].y, planet[3].d2y, css.time)
      ze = spl_interp(planet[3].time, planet[3].z, planet[3].d2z, css.time)
      dx = css.x - xe
      dy = css.y - ye
      dz = css.z - ze
      ds = sqrt(dx*dx + dy*dy + dz*dz)
      css.owlt = ds*(au/c)

    endif else css = missing
    print,".",format='(a1,$)'

; Calculate ephemeris for each spacecraft

; --------- STEREO AHEAD ---------

    i = where(sinfo.obj_name eq sname[0], count)
    if (count gt 0L) then begin
      tsp = time_double(sinfo[i].trange)
      tsp = minmax(tsp)
      ndays = floor(2D*(tsp[1] - tsp[0])/oneday)
      dt = (tsp[1] - tsp[0])/double(ndays)
      tt = tsp[0] + dt*dindgen(ndays)
      et = time_ephemeris(tt)

      cspice_spkpos, sname[0], et, 'ECLIPJ2000', 'NONE', 'Sun', sta, ltime
      sta = transpose(sta)/(au/1.d5)
      sta = { name  : sname[0]     , $
              time  : tt           , $
              x     : sta[*,0]     , $
              y     : sta[*,1]     , $
              z     : sta[*,2]     , $
              owlt  : ltime        , $
              units : ['AU','SEC'] , $
              frame : 'ECLIPJ2000'    }

      d2x = spl_init(sta.time, sta.x, /double)
      d2y = spl_init(sta.time, sta.y, /double)
      d2z = spl_init(sta.time, sta.z, /double)
      str_element, sta, 'd2x', d2x, /add
      str_element, sta, 'd2y', d2y, /add
      str_element, sta, 'd2z', d2z, /add

      xe = spl_interp(planet[2].time, planet[2].x, planet[2].d2x, sta.time)
      ye = spl_interp(planet[2].time, planet[2].y, planet[2].d2y, sta.time)
      ze = spl_interp(planet[2].time, planet[2].z, planet[2].d2z, sta.time)
      dx = sta.x - xe
      dy = sta.y - ye
      dz = sta.z - ze
      ds = sqrt(dx*dx + dy*dy + dz*dz)
      sta.owlt = ds*(au/c)

    endif else sta = missing

; --------- STEREO BEHIND ---------

    i = where(sinfo.obj_name eq sname[1], count)
    if (count gt 0L) then begin
      tsp = time_double(sinfo[i].trange)
      ndays = floor(2D*(tsp[1] - tsp[0])/oneday)
      dt = (tsp[1] - tsp[0])/double(ndays)
      tt = tsp[0] + dt*dindgen(ndays)
      et = time_ephemeris(tt)

      cspice_spkpos, sname[1], et, 'ECLIPJ2000', 'NONE', 'Sun', stb, ltime
      stb = transpose(stb)/(au/1.d5)
      j = where(stb[*,1] lt 1.3, count)  ; keep only good values
      if (count gt 0L) then begin
        tt = tt[j]
        stb = stb[j,*]
        ltime = ltime[j]

        stb = { name  : sname[1]     , $
                time  : tt           , $
                x     : stb[*,0]     , $
                y     : stb[*,1]     , $
                z     : stb[*,2]     , $
                owlt  : ltime        , $
                units : ['AU','SEC'] , $
                frame : 'ECLIPJ2000'    }

        d2x = spl_init(stb.time, stb.x, /double)
        d2y = spl_init(stb.time, stb.y, /double)
        d2z = spl_init(stb.time, stb.z, /double)
        str_element, stb, 'd2x', d2x, /add
        str_element, stb, 'd2y', d2y, /add
        str_element, stb, 'd2z', d2z, /add

        xe = spl_interp(planet[2].time, planet[2].x, planet[2].d2x, stb.time)
        ye = spl_interp(planet[2].time, planet[2].y, planet[2].d2y, stb.time)
        ze = spl_interp(planet[2].time, planet[2].z, planet[2].d2z, stb.time)
        dx = stb.x - xe
        dy = stb.y - ye
        dz = stb.z - ze
        ds = sqrt(dx*dx + dy*dy + dz*dz)
        stb.owlt = ds*(au/c)
      endif else stb = missing

    endif else stb = missing
    print,".",format='(a1,$)'

; --------- Solar Orbiter ---------

    i = where(sinfo.obj_name eq sname[2], count)
    if (count gt 0L) then begin
      tsp = time_double(sinfo[i].trange)
      tsp = minmax(tsp)
      ndays = floor(2D*(tsp[1] - tsp[0])/oneday)
      dt = (tsp[1] - tsp[0])/double(ndays)
      tt = tsp[0] + dt*dindgen(ndays)
      et = time_ephemeris(tt)

      cspice_spkpos, sname[2], et, 'ECLIPJ2000', 'NONE', 'Sun', sorb, ltime
      sorb = transpose(sorb)/(au/1.d5)
      sorb = { name  : sname[2]           , $
               time  : tt                 , $
               x     : sorb[*,0]          , $
               y     : sorb[*,1]          , $
               z     : sorb[*,2]          , $
               owlt  : ltime              , $
               units : ['AU','SEC','DEG'] , $
               frame : 'ECLIPJ2000'          }

      d2x = spl_init(sorb.time, sorb.x, /double)
      d2y = spl_init(sorb.time, sorb.y, /double)
      d2z = spl_init(sorb.time, sorb.z, /double)
      str_element, sorb, 'd2x', d2x, /add
      str_element, sorb, 'd2y', d2y, /add
      str_element, sorb, 'd2z', d2z, /add

      r = sqrt(sorb.x^2. + sorb.y^2. + sorb.z^2.)
      lat = asin(sorb.z/r)*!radeg
      str_element, sorb, 'lat', lat, /add

      xe = spl_interp(planet[2].time, planet[2].x, planet[2].d2x, sorb.time)
      ye = spl_interp(planet[2].time, planet[2].y, planet[2].d2y, sorb.time)
      ze = spl_interp(planet[2].time, planet[2].z, planet[2].d2z, sorb.time)
      dx = sorb.x - xe
      dy = sorb.y - ye
      dz = sorb.z - ze
      ds = sqrt(dx*dx + dy*dy + dz*dz)
      sorb.owlt = ds*(au/c)

    endif else sorb = missing
    print,".",format='(a1,$)'

; --------- Parker Solar Probe ---------

    i = where(sinfo.obj_name eq sname[3], count)
    if (count gt 0L) then begin
      tsp = time_double(sinfo[i].trange)
      tsp = minmax(tsp)
      ndays = floor(2D*(tsp[1] - tsp[0])/oneday)
      dt = (tsp[1] - tsp[0])/double(ndays)
      tt = tsp[0] + dt*dindgen(ndays)
      et = time_ephemeris(tt)

      cspice_spkpos, sname[3], et, 'ECLIPJ2000', 'NONE', 'Sun', psp, ltime
      psp = transpose(psp)/(au/1.d5)
      psp = { name  : sname[3]     , $
              time  : tt           , $
              x     : psp[*,0]     , $
              y     : psp[*,1]     , $
              z     : psp[*,2]     , $
              owlt  : ltime        , $
              units : ['AU','SEC'] , $
              frame : 'ECLIPJ2000'    }

      d2x = spl_init(psp.time, psp.x, /double)
      d2y = spl_init(psp.time, psp.y, /double)
      d2z = spl_init(psp.time, psp.z, /double)
      str_element, psp, 'd2x', d2x, /add
      str_element, psp, 'd2y', d2y, /add
      str_element, psp, 'd2z', d2z, /add

      xe = spl_interp(planet[2].time, planet[2].x, planet[2].d2x, psp.time)
      ye = spl_interp(planet[2].time, planet[2].y, planet[2].d2y, psp.time)
      ze = spl_interp(planet[2].time, planet[2].z, planet[2].d2z, psp.time)
      dx = psp.x - xe
      dy = psp.y - ye
      dz = psp.z - ze
      ds = sqrt(dx*dx + dy*dy + dz*dz)
      psp.owlt = ds*(au/c)

    endif else psp = missing

    print,".",format='(a1,$)'

    print,' done'
  endif

  if (cflg and (css.frame eq 'INVALID')) then begin
    print, 'Warning: Siding Spring ephemeris not loaded.'
    cflg = 0
  endif
  if (sflg and (sta.frame eq 'INVALID')) then begin
    print, 'Warning: Stereo-A ephemeris not loaded.'
    sflg = 0
  endif
  if (sflg and (stb.frame eq 'INVALID')) then begin
    print, 'Warning: Stereo-B ephemeris not loaded.'
  endif
  if (oflg and (sorb.frame eq 'INVALID')) then begin
    print, 'Warning: Solar Orbiter ephemeris not loaded.'
    oflg = 0
  endif
  if (pflg and (psp.frame eq 'INVALID')) then begin
    print, 'Warning: Solar Probe ephemeris not loaded.'
    pflg = 0
  endif

  eph = {planet:planet, css:css, stereo_A:sta, stereo_B:stb, solar_orb:sorb, psp:psp}

  if ((tmin lt min(planet[2].time)) or (tmax gt max(planet[2].time))) then begin
    tsp = time_string(minmax(planet[2].time),prec=-3)
    print, "Time is out of ephemeris range (", tsp[0], " to ", tsp[1], ")"
    return
  endif

; Create TPLOT variables

  if keyword_set(tplot) then begin
    xm = planet[pnum].x
    ym = planet[pnum].y
    zm = planet[pnum].z
    rm = sqrt(xm*xm + ym*ym + zm*zm)
    phi_m = atan(ym,xm)*!radeg

    xe = planet[2].x
    ye = planet[2].y
    ze = planet[2].z
    re = sqrt(xe*xe + ye*ye + ze*ze)
    phi_e = atan(ye,xe)*!radeg

    ds = planet[pnum].owlt * (c/au)

    tname = 'E-' + pstr[pnum]
    store_data,tname,data={x:planet[pnum].time, y:ds}
    options,tname,'ytitle','E-' + pstr[pnum] + ' (AU)'
    options,tname,'ynozero',1

    tname = 'OWLT-' + pstr[pnum]
    if (pnum le 5) then begin
      store_data,tname,data={x:planet[pnum].time, y:planet[pnum].owlt/60D}
      options,tname,'ytitle','E-' + pstr[pnum] + '!cOWLT (min)'
    endif else begin
      store_data,tname,data={x:planet[pnum].time, y:planet[pnum].owlt/3600D}
      options,tname,'ytitle','E-' + pstr[pnum] + '!cOWLT (hrs)'
    endelse
    options,tname,'ynozero',1

    tname = 'S-' + pstr[pnum]
    store_data,tname,data={x:planet[pnum].time, y:planet[pnum].r}
    msg = strupcase(strmid(pname[pnum],0,1)) + strlowcase(strmid(pname[pnum],1))
    options,tname,'ytitle','Sun-' + msg + ' (AU)'
    options,tname,'ynozero',1

    dphi = phi_m - phi_e
    indx = where(dphi lt 0., count)
    if (count gt 0) then dphi[indx] += 360.
    indx = where(dphi gt 360., count)
    if (count gt 0) then dphi[indx] -= 360.

    tname = 'ES' + pstr[pnum]
    store_data,tname,data={x:planet[pnum].time, y:dphi}
    ylim,tname,0,360,0
    options,tname,'ytitle','!uE!nS!u' + pstr[pnum] + '!n (deg)'
    options,tname,'yticks',4
    options,tname,'yminor',3

    elong = acos((rm*rm + ds*ds - re*re)/(2.*rm*ds))*!radeg
    tname = 'S' + pstr[pnum] + 'E'
    store_data,tname,data={x:planet[pnum].time, y:elong}
    options,tname,'ytitle','!uS!n' + pstr[pnum] + '!uE!n (deg)'

    elong = acos((re*re + ds*ds - rm*rm)/(2.*re*ds))*!radeg
    tname = 'SE' + pstr[pnum]
    store_data,tname,data={x:planet[pnum].time, y:elong}
    options,tname,'ytitle','!uS!nE!u' + pstr[pnum] + '!n (deg)'

    if (pnum eq 3) then begin
      store_data,'latss',data={x:planet[3].time, y:planet[3].latss}
      options,'latss','ytitle','Mars!cLss (deg)'
    endif

    if (css.frame ne 'INVALID') then begin
      tname = 'OWLT-CSS'
      store_data,tname,data={x:css.time, y:css.owlt/60D}
      options,tname,'ytitle','SIDING SPRING!cOWLT (min)'
      options,tname,'colors',ccol
      options,tname,'ynozero',1

      tname = 'R-CSS'
      store_data,tname,data={x:css.time, y:css.owlt*(c/Rmars)}
      ylim,tname,0,0,1
      options,tname,'ytitle','Siding Spring!cDistance (R!dM!n)'
      options,tname,'colors',ccol

      tname = 'Lat-CSS'
      store_data,tname,data={x:css.time, y:css.lat}
      options,tname,'ytitle','Siding Spring!cLatitude (deg)'
      options,tname,'constant',0
      options,tname,'colors',ccol
    endif

    if (sta.frame ne 'INVALID') then begin
      tname = 'OWLT-STA'
      store_data,tname,data={x:sta.time, y:sta.owlt/60D}
      options,tname,'ytitle','STEREO A!cOWLT (min)'
      options,tname,'ynozero',1

      tname = 'OWLT-STB'
      store_data,tname,data={x:stb.time, y:stb.owlt/60D}
      options,tname,'ytitle','STEREO B!cOWLT (min)'
      options,tname,'ynozero',1

      tname = 'STEREO'
      store_data,tname,data=['OWLT-STA','OWLT-STB']
      options,tname,'ytitle','STEREO!cOWLT (min)'
      options,tname,'colors',[4,6]
      options,tname,'labels',['A','B']
      options,tname,'labflag',1
    endif

    if (sorb.frame ne 'INVALID') then begin
      tname = 'OWLT-SORB'
      store_data,tname,data={x:sorb.time, y:sorb.owlt/60D}
      options,tname,'ytitle','Solar Orbiter!cOWLT (min)'
      options,tname,'ynozero',1

      tname = 'R-SORB'
      r = sqrt(sorb.x^2. + sorb.y^2. + sorb.z^2.)
      store_data,tname,data={x:sorb.time, y:r*(au/Rs)}
      options,tname,'ytitle','Solar Orbiter!cRadius (R!dS!n)'
      options,tname,'constant',[minmax(planet[0].r), mean(planet[1].r), 1.]*(au/Rs)
      options,tname,'colors',scol[2]

      tname = 'Lat-SORB'
      store_data,tname,data={x:sorb.time, y:sorb.lat}
      options,tname,'ytitle','Solar Orbiter!cLatitude (deg)'
      options,tname,'constant',0
      options,tname,'colors',scol[2]
    endif

    if (psp.frame ne 'INVALID') then begin
      tname = 'OWLT-PSP'
      store_data,tname,data={x:psp.time, y:psp.owlt/60D}
      options,tname,'ytitle','Solar Probe!cOWLT (min)'
      options,tname,'ynozero',1
      options,tname,'colors',scol[3]

      tname = 'R-PSP'
      r = sqrt(psp.x^2. + psp.y^2. + psp.z^2.)
      store_data,tname,data={x:psp.time, y:r*(au/Rs)}
      options,tname,'ytitle','Solar Probe!cRadius (R!dS!n)'
      options,tname,'constant',[minmax(planet[0].r), mean(planet[1].r), 1.]*(au/Rs)
      options,tname,'colors',scol[3]
    endif

  endif

; Make the plot

  if keyword_set(noplot) then return

  if not keyword_set(scale) then scale = 1.

  if keyword_set(nobox) then begin
    xsty = 4
    ysty = 4
  endif else begin
    xsty = 1
    ysty = 1
  endelse

  a = 0.5
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  if (not dopng) then begin
    Twin = !d.window

    undefine, mnum
    if (size(monitor,/type) gt 0) then begin
      if (windex eq -1) then win, /config
      mnum = fix(monitor[0])
    endif else begin
      if (size(secondarymon,/type) gt 0) then mnum = secondarymon
    endelse

    undefine, wnum
    if (size(window,/type) gt 0) then wnum = fix(window[0])
  endif

  if (mflg) then begin
    if (keyword_set(black) and (!p.background ne 0L)) then begin
      revvid
      vswap = 1
    endif else vswap = 0

    win, /free, monitor=mnum, xsize=xsize, ysize=ysize, dx=10, dy=10, scale=scale
    Owin = !d.window
    zscl = 1.
    csize = 1.5*zscl*scale

    wset,Twin
    ctime2,trange,npoints=1,/silent,button=button

    if (data_type(trange) eq 2) then begin
      wdelete, Owin  ; window never used
      wset, Twin
      return
    endif
    t = trange[0]
    ok = 1

    while (ok) do begin
      wset, Owin

      xp = replicate(!values.f_nan, (ipmax+1))
      yp = xp
      zp = xp
      rp = xp

      cosp = 1.
      sinp = 0.

      inbounds = nn2(planet[3].time, t, maxdt=oneday) ge 0L
      if (inbounds) then begin
        for k=0,ipmax do begin
          xp[k] = spl_interp(planet[k].time, planet[k].x, planet[k].d2x, t)
          yp[k] = spl_interp(planet[k].time, planet[k].y, planet[k].d2y, t)
          zp[k] = spl_interp(planet[k].time, planet[k].z, planet[k].d2z, t)
          rp[k] = sqrt(xp[k]*xp[k] + yp[k]*yp[k] + zp[k]*zp[k])
        endfor
        if (fflg) then begin
          phi = atan(yp[fnum], xp[fnum]) - (flon*!dtor)
          cosp = cos(phi)
          sinp = sin(phi)
          x =  xp*cosp + yp*sinp
          y = -xp*sinp + yp*cosp
          xp = x
          yp = y
        endif
      endif

      if (cflg) then begin
        xcss = !values.f_nan
        ycss = xcss
        icss = nn2(css.time, t, maxdt=oneday)
        if (icss ge 0L) then begin
          xcss = spl_interp(css.time, css.x, css.d2x, t)
          ycss = spl_interp(css.time, css.y, css.d2y, t)
          if (fflg) then begin
            x =  xcss*cosp + ycss*sinp
            y = -xcss*sinp + ycss*cosp
            xcss = x
            ycss = y
          endif
        endif
      endif

      if (sflg) then begin
        xsta = !values.f_nan
        ysta = xsta
        i = nn2(sta.time, t, maxdt=oneday)
        if (i ge 0L) then begin
          xsta = spl_interp(sta.time, sta.x, sta.d2x, t)
          ysta = spl_interp(sta.time, sta.y, sta.d2y, t)
          if (fflg) then begin
            x =  xsta*cosp + ysta*sinp
            y = -xsta*sinp + ysta*cosp
            xsta = x
            ysta = y
          endif
        endif

        xstb = !values.f_nan
        ystb = xstb
        i = nn2(stb.time, t, maxdt=oneday)
        if (i ge 0L) then begin
          xstb = spl_interp(stb.time, stb.x, stb.d2x, t)
          ystb = spl_interp(stb.time, stb.y, stb.d2y, t)
          if (fflg) then begin
            x =  xstb*cosp + ystb*sinp
            y = -xstb*sinp + ystb*cosp
            xstb = x
            ystb = y
          endif
        endif
      endif

      if (oflg) then begin
        xsorb = !values.f_nan
        ysorb = xsorb
        isorb = nn2(sorb.time, t, maxdt=oneday)
        if (isorb ge 0L) then begin
          xsorb = spl_interp(sorb.time, sorb.x, sorb.d2x, t)
          ysorb = spl_interp(sorb.time, sorb.y, sorb.d2y, t)
          if (fflg) then begin
            x =  xsorb*cosp + ysorb*sinp
            y = -xsorb*sinp + ysorb*cosp
            xsorb = x
            ysorb = y
          endif
        endif
      endif

      if (pflg) then begin
        xpsp = !values.f_nan
        ypsp = xpsp
        ipsp = nn2(psp.time, t, maxdt=oneday)
        if (ipsp ge 0L) then begin
          xpsp = spl_interp(psp.time, psp.x, psp.d2x, t)
          ypsp = spl_interp(psp.time, psp.y, psp.d2y, t)
          if (fflg) then begin
            x =  xpsp*cosp + ypsp*sinp
            y = -xpsp*sinp + ypsp*cosp
            xpsp = x
            ypsp = y
          endif
        endif
      endif

      plot, [0.], [0.], xrange=xyrange, yrange=xyrange, xsty=xsty, ysty=ysty, $
                        charsize=csize, xtitle='Ecliptic X (AU)', ytitle='Ecliptic Y (AU)'

      if keyword_set(spiral) then begin
        ds = smax/float(spts)
        rs = ds*findgen(spts)
        dt = rs/Vsw
        phi = omega*dt
        xs = rs*cos(phi)
        ys = -rs*sin(phi)

        if (finite(rp[pnum]) and (pnum lt 6)) then begin
          dr = min(abs(rs - rp[pnum]), k)
          dx = xs[k+1] - xs[k-1]
          dy = ys[k+1] - ys[k-1]
          alpha = abs((atan(dy,dx) - atan(ys[k],xs[k])))*!radeg
          if (alpha gt 180.) then alpha = 360. - alpha
        endif else alpha = -1.

        for i=0,11 do begin
          xs = rs*cos(phi)
          ys = -rs*sin(phi)
          oplot, xs, ys, color=pkscol, line=1
          phi = phi + (30.*!dtor)
        endfor

      endif

      pday = pday < (n_elements(planet[3].x)-1)
      for k=0,ipmax do begin
        xx = planet[k].x[0:pday[k]]
        yy = planet[k].y[0:pday[k]]
        if (fflg) then begin
          x =  xx*cosp + yy*sinp
          y = -xx*sinp + yy*cosp
          xx = x
          yy = y
        endif
        oplot, xx, yy
      endfor
      for k=0,ipmax do begin
        oplot, [xp[k]], [yp[k]], psym=8, symsize=psze[k]*zscl, color=pcol[k]
        if (plab[k]) then xyouts, [xp[k]+loff[k]], [yp[k]+loff[k]], pname[k], color=pcol[k], charsize=scale
      endfor
      oplot, [0.], [0.], psym=8, symsize=sunsze*zscl, color=suncol

      if (cflg) then if (finite(xcss)) then begin
        imin = (icss - cday) > 0L
        imax = (icss + cday) < (n_elements(css.time) - 1L)
        xx = css.x[imin:imax]
        yy = css.y[imin:imax]
        if (fflg) then begin
          x =  xx*cosp + yy*sinp
          y = -xx*sinp + yy*cosp
          xx = x
          yy = y
        endif

        initct, 1072, /rev, previous_ct=pct, previous_rev=prev
          ll = css.lat[imin:imax] + 60.
          lscale = float(colstr.top_c - colstr.bottom_c)/120.
          lcol = (round(ll*lscale) + colstr.bottom_c) > colstr.bottom_c < colstr.top_c
          for k=0L,(n_elements(yy)-2L) do oplot, xx[k:k+1L], yy[k:k+1L], color=lcol[k], thick=2
          oplot, [xcss], [ycss], psym=csym, symsize=csze*zscl, color=ccol
          visible = (xcss ge xyrange[0]) and (xcss le xyrange[1]) and (ycss ge xyrange[0]) and (ycss le xyrange[1])
          if (clabel and visible) then xyouts, [xcss+loff[3]], [ycss+loff[3]], clab, color=ccol, charsize=scale
          draw_color_scale, range=[-60,60], brange=[colstr.bottom_c, colstr.top_c], charsize=scale, $
                            position=[0.88,0.1,0.9,0.2], title='Lat (deg)', yticks=2, ytickval=[-60,0,60]
        initct, pct, rev=prev
      endif

      if (sflg) then begin
        oplot, [xsta], [ysta], psym=ssym[0], symsize=ssze[0]*zscl, color=scol[0]
        if (slabel) then xyouts, [xsta+loff[3]], [ysta+loff[3]], slab[0], color=scol[0], charsize=scale
        oplot, [xstb], [ystb], psym=ssym[1], symsize=ssze[1]*zscl, color=scol[1]
        if (slabel) then xyouts, [xstb+loff[3]], [ystb+loff[3]], slab[1], color=scol[1], charsize=scale
      endif

      if (oflg) then if (finite(xsorb)) then begin
        imin = (isorb - sday[2]) > 0L
        imax = (isorb + sday[2]) < (n_elements(sorb.time) - 1L)
        xx = sorb.x[imin:imax]
        yy = sorb.y[imin:imax]
        if (fflg) then begin
          x =  xx*cosp + yy*sinp
          y = -xx*sinp + yy*cosp
          xx = x
          yy = y
        endif

        oplot, xx, yy, color=scol[2]
        oplot, [xsorb], [ysorb], psym=ssym[2], symsize=ssze[2]*zscl, color=scol[2]
        if (slabel) then xyouts, [xsorb+loff[3]], [ysorb+loff[3]], slab[2], color=scol[2], charsize=scale

      endif

      if (pflg) then if (finite(xpsp)) then begin
        imin = (ipsp - sday[3]) > 0L
        imax = (ipsp + sday[3]) < (n_elements(psp.time) - 1L)
        xx = psp.x[imin:imax]
        yy = psp.y[imin:imax]
        if (fflg) then begin
          x =  xx*cosp + yy*sinp
          y = -xx*sinp + yy*cosp
          xx = x
          yy = y
        endif
        oplot, xx, yy, color=scol[3]  
        oplot, [xpsp] , [ypsp] , psym=ssym[3], symsize=ssze[3]*zscl, color=scol[3]
        if (slabel) then xyouts, [xpsp+loff[3]], [ypsp+loff[3]], slab[3], color=scol[3], charsize=scale
      endif

      if (inbounds and (dolab gt 0)) then begin
        xs = 0.77  ; upper right
        ys = 0.92
        dys = 0.03

        if (dolab gt 1) then begin
          phi_e = atan(yp[2], xp[2])*!radeg
          phi_m = atan(yp[pnum], xp[pnum])*!radeg

          dphi = phi_m - phi_e

          nwrap = floor(dphi/360.)
          dphi = dphi - nwrap*360.

          if (dphi gt 180.) then dphi = 360. - dphi

          msg = string(pstr[pnum], round(dphi), format = '("ES",a1," = ",i," deg")')
          msg = strcompress(msg)
          xyouts,  xs, ys,  msg, /norm, charsize=csize
          ys -= dys

          ds = [(xp[pnum] - xp[2]), (yp[pnum] - yp[2]), (zp[pnum] - zp[2])]
          ds = sqrt(total(ds*ds))
    
          sme = acos((rp[pnum]*rp[pnum] + ds*ds - rp[2]*rp[2])/(2.*rp[pnum]*ds))*!radeg

          msg = string(pstr[pnum], round(sme), format = '("S",a1,"E = ",i," deg")')
          msg = strcompress(msg)
          xyouts,  xs, ys,  msg, /norm, charsize=csize
          ys -= dys

          sem = acos((rp[2]*rp[2] + ds*ds - rp[pnum]*rp[pnum])/(2.*rp[2]*ds))*!radeg

          msg = string(pstr[pnum], round(sem), format='("SE",a1," = ",i," deg")')
          msg = strcompress(msg)
          xyouts,  xs, ys,  msg, /norm, charsize=csize
          ys -= dys

          if (pnum le 5) then begin
            owlt = (double(ds) * (au/c))/60D
            msg = string(owlt, format='("OWLT = ",f5.2," min")')
          endif else begin
            owlt = (double(ds) * (au/c))/3600D
            msg = string(owlt, format='("OWLT = ",f5.2," hrs")')
          endelse
          msg = strcompress(msg)
          xyouts,  xs, ys, msg, /norm, charsize=csize
          ys -= dys

          if (pnum eq 3) then begin
            Lss = spl_interp(planet[3].time, planet[3].latss, planet[3].d2l, t)
            if (Lss ge 0.) then ns = ' N' else ns = ' S'
            msg = string(abs(Lss), format='("Lss = ",f8.1)') + ns
            msg = strcompress(msg)
            xyouts, xs, ys,  msg, /norm, charsize=csize
          endif
        endif

        xs = 0.14  ; lower left
        ys = 0.17

        if keyword_set(spiral) then begin
          msg = string(round(Vsw*au/1d5), format='("Vsw = ",i," km/s")')
          msg = strcompress(msg)
          xyouts, xs, ys, msg, /norm, charsize=csize, color=4
          ys -= dys
          if (alpha gt -1.) then begin
            msg = string(pstr[pnum], round(alpha), format='("Asw at ",a1," = ",i," deg")')
            msg = strcompress(msg)
            xyouts, xs, ys, msg, /norm, charsize=csize, color=4
            ys -= dys
          endif
        endif

        if (sflg) then begin
          if (finite(xsta[0]) and finite(xstb[0])) then begin
            phi_a = atan(ysta[0], xsta[0])*!radeg
            phi_b = atan(ystb[0], xstb[0])*!radeg

            dphi = phi_a - phi_b

            nwrap = floor(dphi/360.)
            dphi = dphi - nwrap*360.

            if (dphi gt 180.) then dphi = 360. - dphi

            msg = string(round(dphi), format = '("AB = ",i," deg")')
          endif else msg = ""
          msg = strcompress(msg)
          xyouts,  xs, ys,  msg, /norm, charsize=csize, color=5
        endif

        xs = 0.14  ; upper left
        ys = 0.92

        tmsg = time_string(t)
        xyouts, xs, ys, tmsg, /norm, charsize=csize
        ys -= dys

      endif

      wset,Twin
      ctime2,trange,npoints=1,/silent,button=button

      if (data_type(trange) eq 5) then begin
        t = trange[0]
        ok = 1
      endif else ok = 0

    endwhile

    if (vswap) then revvid
    if (not kflg) then wdelete, Owin
    wset,Twin

    return

  endif

  xp = replicate(!values.f_nan, (ipmax+1), n_elements(t))
  yp = xp
  zp = xp
  rp = zp

  cosp = 1.
  sinp = 0.

  i = nn2(planet[3].time, t, maxdt=oneday)
  j = where(i ge 0L, count)
  inbounds = count gt 0L
  if (inbounds) then begin
    for k=0,ipmax do begin
      xp[k,j] = spl_interp(planet[k].time, planet[k].x, planet[k].d2x, t[j])
      yp[k,j] = spl_interp(planet[k].time, planet[k].y, planet[k].d2y, t[j])
      zp[k,j] = spl_interp(planet[k].time, planet[k].z, planet[k].d2z, t[j])
      rp[k,j] = sqrt(xp[k,j]*xp[k,j] + yp[k,j]*yp[k,j] + zp[k,j]*zp[k,j])
    endfor
    if (fflg) then begin
      phi = atan(yp[fnum], xp[fnum]) - (flon*!dtor)
      cosp = cos(phi)
      sinp = sin(phi)
      x =  xp*cosp + yp*sinp
      y = -xp*sinp + yp*cosp
      xp = x
      yp = y
    endif
  endif

  if (cflg) then begin
    xcss = replicate(!values.f_nan, n_elements(t))
    ycss = xcss
    i = nn2(css.time, t, maxdt=oneday)
    j = where(i ge 0L, count)
    if (count gt 0L) then begin
      icss = round(mean(i[j]))
      xcss[j] = spl_interp(css.time, css.x, css.d2x, t[j])
      ycss[j] = spl_interp(css.time, css.y, css.d2y, t[j])
      if (fflg) then begin
        x =  xcss*cosp + ycss*sinp
        y = -xcss*sinp + ycss*cosp
        xcss = x
        ycss = y
      endif
    endif
  endif

  if (sflg) then begin
    xsta = replicate(!values.f_nan, n_elements(t))
    ysta = xsta
    i = nn2(sta.time, t, maxdt=oneday)
    j = where(i ge 0L, count)
    if (count gt 0L) then begin
      xsta[j] = spl_interp(sta.time, sta.x, sta.d2x, t[j])
      ysta[j] = spl_interp(sta.time, sta.y, sta.d2y, t[j])
      if (fflg) then begin
        x =  xsta*cosp + ysta*sinp
        y = -xsta*sinp + ysta*cosp
        xsta = x
        ysta = y
      endif
    endif

    xstb = replicate(!values.f_nan, n_elements(t))
    ystb = xstb
    i = nn2(stb.time, t, maxdt=oneday)
    j = where(i ge 0L, count)
    if (count gt 0L) then begin
      xstb[j] = spl_interp(stb.time, stb.x, stb.d2x, t[j])
      ystb[j] = spl_interp(stb.time, stb.y, stb.d2y, t[j])
      if (fflg) then begin
        x =  xstb*cosp + ystb*sinp
        y = -xstb*sinp + ystb*cosp
        xsta = x
        ysta = y
      endif
    endif
  endif

  if (oflg) then begin
    xsorb = replicate(!values.f_nan, n_elements(t))
    ysorb = xsorb
    i = nn2(sorb.time, t, maxdt=oneday)
    j = where(i ge 0L, count)
    if (count gt 0L) then begin
      isorb = round(mean(i[j]))
      xsorb[j] = spl_interp(sorb.time, sorb.x, sorb.d2x, t[j])
      ysorb[j] = spl_interp(sorb.time, sorb.y, sorb.d2y, t[j])
      if (fflg) then begin
        x =  xsorb*cosp + ysorb*sinp
        y = -xsorb*sinp + ysorb*cosp
        xsorb = x
        ysorb = y
      endif
    endif
  endif

  if (pflg) then begin
    xpsp = replicate(!values.f_nan, n_elements(t))
    ypsp = xpsp
    i = nn2(psp.time, t, maxdt=oneday)
    j = where(i gt 0L, count)
    if (count gt 0L) then begin
      ipsp = round(mean(i[j]))
      xpsp[j] = spl_interp(psp.time, psp.x, psp.d2x, t[j])
      ypsp[j] = spl_interp(psp.time, psp.y, psp.d2y, t[j])
      if (fflg) then begin
        x =  xpsp*cosp + ypsp*sinp
        y = -xpsp*sinp + ypsp*cosp
        xpsp = x
        ypsp = y
      endif
    endif
  endif

  if (dopng) then begin
    current_dev = !d.name
    set_plot, 'z'
    device, set_resolution=[xsize*1.010, ysize]*scale, set_pixel_depth=24, decompose=0
    zscl = 0.8
  endif else begin
    if (Owin eq -1) then begin
      win, wnum, mnum, xsize=xsize, ysize=ysize, dx=10, dy=10, scale=scale
      Owin = !d.window
    endif
    zscl = 1.
  endelse

  csize = 1.5*zscl*scale

  plot, [0.], [0.], xrange=xyrange, yrange=xyrange, xsty=xsty, ysty=ysty, $
                    charsize=csize, xtitle='Ecliptic X (AU)', ytitle='Ecliptic Y (AU)'

  if keyword_set(spiral) then begin
    ds = smax/float(spts)
    rs = ds*findgen(spts)
    dt = rs/Vsw
    phi = omega*dt
    xs = rs*cos(phi)
    ys = -rs*sin(phi)

    rp3 = median([rp[pnum,*]])
    if (finite(rp3) and (pnum lt 6)) then begin
      dr = min(abs(rs - rp3), k)
      dx = xs[k+1] - xs[k-1]
      dy = ys[k+1] - ys[k-1]
      alpha = abs((atan(dy,dx) - atan(ys[k],xs[k])))*!radeg
      if (alpha gt 180.) then alpha = 360. - alpha
    endif else alpha = -1.

    for i=0,11 do begin
      xs = rs*cos(phi)
      ys = -rs*sin(phi)
      oplot, xs, ys, color=pkscol, line=1
      phi = phi + (30.*!dtor)
    endfor
  endif

  pday = pday < (n_elements(planet[3].x)-1)
  for k=0,ipmax do begin
    xx = planet[k].x[0:pday[k]]
    yy = planet[k].y[0:pday[k]]
    if (fflg) then begin
      x =  xx*cosp + yy*sinp
      y = -xx*sinp + yy*cosp
      xx = x
      yy = y
    endif
    oplot, xx, yy
  endfor
  for i=0,ipmax do oplot, [xp[i,*]], [yp[i,*]], color=pcol[i], thick=2
  oplot, [0.], [0.], psym=8, symsize=sunsze*zscl, color=suncol

  count = n_elements(xp[2,*])
  j = [0L, (count/2L), (count-1L)]
  for i=0,ipmax do begin
    oplot, [xp[i,j]], [yp[i,j]], psym=8, symsize=psze[i]*zscl, color=pcol[i]
    if (plab[i]) then xyouts, [xp[i,j[1]]+loff[i]], [yp[i,j[1]]+loff[i]], pname[i], color=pcol[i], chars=scale
  endfor

  if (cflg) then if (max(finite(xcss))) then begin
    imin = (icss - cday) > 0L
    imax = (icss + cday) < (n_elements(css.time) - 1L)
    xx = css.x[imin:imax]
    yy = css.y[imin:imax]
    if (fflg) then begin
      x =  xx*cosp + yy*sinp
      y = -xx*sinp + yy*cosp
      xx = x
      yy = y
    endif
    oplot, xx, yy, color=ccol
    oplot, [xcss], [ycss], psym=csym, symsize=csze*zscl, color=ccol
    if (slabel) then xyouts, [xcss+loff[3]], [ycss+loff[3]], clab, color=ccol, charsize=scale
  endif

  if (sflg) then begin
    oplot, [xsta], [ysta], psym=ssym[0], symsize=ssze[0]*zscl, color=scol[0]
    if (slabel) then xyouts, [xsta+loff[3]], [ysta+loff[3]], slab[0], color=scol[0], charsize=scale
    oplot, [xstb], [ystb], psym=ssym[1], symsize=ssze[1]*zscl, color=scol[1]
    if (slabel) then xyouts, [xstb+loff[3]], [ystb+loff[3]], slab[1], color=scol[1], charsize=scale
  endif

  if (oflg) then if (max(finite(xsorb))) then begin
    imin = (isorb - sday[2]) > 0L
    imax = (isorb + sday[2]) < (n_elements(sorb.time) - 1L)
    xx = sorb.x[imin:imax]
    yy = sorb.y[imin:imax]
    if (fflg) then begin
      x =  xx*cosp + yy*sinp
      y = -xx*sinp + yy*cosp
      xx = x
      yy = y
    endif
    oplot, xx, yy, color=scol[2]  
    oplot, [xsorb], [ysorb], psym=ssym[2], symsize=ssze[2]*zscl, color=scol[2]
    if (slabel) then xyouts, [xsorb+loff[3]], [ysorb+loff[3]], slab[2], color=scol[2], charsize=scale
  endif

  if (pflg) then if (max(finite(xpsp))) then begin
    imin = (ipsp - sday[3]) > 0L
    imax = (ipsp + sday[3]) < (n_elements(psp.time) - 1L)
    xx = psp.x[imin:imax]
    yy = psp.y[imin:imax]
    if (fflg) then begin
      x =  xx*cosp + yy*sinp
      y = -xx*sinp + yy*cosp
      xx = x
      yy = y
    endif
    oplot, xx, yy, color=scol[3]  
    oplot, [xpsp], [ypsp], psym=ssym[3], symsize=ssze[3]*zscl, color=scol[3]
    if (slabel) then xyouts, [xpsp+loff[3]], [ypsp+loff[3]], slab[3], color=scol[3], charsize=scale
  endif

  if (inbounds and (dolab gt 0)) then begin
    xs = 0.77  ; upper right
    ys = 0.92
    dys = 0.03
    csize = 1.5*zscl*scale  ; character size for labels

    if (dolab gt 1) then begin
      phi_e = atan(yp[2,j[1]], xp[2,j[1]])*!radeg
      phi_m = atan(yp[pnum,j[1]], xp[pnum,j[1]])*!radeg

      dphi = phi_m - phi_e

      nwrap = floor(dphi/360.)
      dphi = dphi - nwrap*360.

      if (dphi gt 180.) then dphi = 360. - dphi

      msg = string(pstr[pnum], round(dphi), format = '("ES",a1," = ",i," deg")')
      msg = strcompress(msg)
      xyouts, xs, ys, msg, /norm, charsize=csize
      ys -= dys

      ds = [(xp[pnum,j[1]] - xp[2,j[1]]), (yp[pnum,j[1]] - yp[2,j[1]]), (zp[pnum,j[1]] - zp[2,j[1]])]
      ds = sqrt(total(ds*ds))
    
      sme = acos((rp[pnum,j[1]]^2. + ds^2. - rp[2,j[1]]^2.)/(2.*rp[pnum,j[1]]*ds))*!radeg

      msg = string(pstr[pnum], round(sme), format = '("S",a1,"E = ",i," deg")')
      msg = strcompress(msg)
      xyouts, xs, ys, msg, /norm, charsize=csize
      ys -= dys

      sem = acos((rp[2,j[1]]^2. + ds^2. - rp[pnum,j[1]]^2.)/(2.*rp[2,j[1]]*ds))*!radeg

      msg = string(pstr[pnum], round(sem), format='("SE",a1," = ",i," deg")')
      msg = strcompress(msg)
      xyouts, xs, ys, msg, /norm, charsize=csize
      ys -= dys

      if (pnum le 5) then begin
        owlt = (double(ds) * (au/c))/60D
        msg = string(owlt, format='("OWLT = ",f5.2," min")')
      endif else begin
        owlt = (double(ds) * (au/c))/3600D
        msg = string(owlt, format='("OWLT = ",f5.2," hrs")')
      endelse
      msg = strcompress(msg)
      xyouts, xs, ys, msg, /norm, charsize=csize
      ys -= dys

      if (pnum eq 3) then begin
        Lss = spl_interp(planet[3].time, planet[3].latss, planet[3].d2l, tavg)
        if (Lss ge 0.) then ns = ' N' else ns = ' S'
        msg = string(abs(Lss), format='("Lss = ",f8.1)') + ns
        msg = strcompress(msg)
        xyouts,  xs, ys, msg, /norm, charsize=csize
      endif
    endif

    xs = 0.14  ; lower left
    ys = 0.17

    if keyword_set(spiral) then begin
      msg = string(round(Vsw*au/1d5), format='("Vsw = ",i," km/s")')
      msg = strcompress(msg)
      xyouts, xs, ys, msg, /norm, charsize=csize, color=4
      ys -= dys
      if (alpha gt -1.) then begin
        msg = string(pstr[pnum], round(alpha), format='("Asw at ",a1," = ",i," deg")')
        msg = strcompress(msg)
        xyouts, xs, ys, msg, /norm, charsize=csize, color=4
        ys -= dys
      endif
    endif

    if (sflg) then begin
      if (finite(xsta[0]) and finite(xstb[0])) then begin
        phi_a = atan(ysta[0], xsta[0])*!radeg
        phi_b = atan(ystb[0], xstb[0])*!radeg

        dphi = phi_a - phi_b

        nwrap = floor(dphi/360.)
        dphi = dphi - nwrap*360.

        if (dphi gt 180.) then dphi = 360. - dphi

        msg = string(round(dphi), format = '("AB = ",i," deg")')
      endif else msg = ""
      msg = strcompress(msg)
      xyouts,  xs, ys,  msg, /norm, charsize=csize, color=5
    endif

    xs = 0.14  ; upper left
    ys = 0.92

    if (npts gt 1) then begin
      tmsg = strmid(time_string(tmin),0,10)
      xyouts, xs, ys, tmsg, /norm, charsize=csize
      ys -= dys
      tmsg = strmid(time_string(tmax),0,10)
      xyouts, xs, ys, tmsg, /norm, charsize=csize
      ys -= dys
    endif else begin
      tmsg = time_string(tavg)
      xyouts, xs, ys, tmsg, /norm, charsize=csize
      ys -= dys
    endelse
  endif

; Determine fate of plot window

  if ((not dopng) and (not kflg)) then begin
    msg = 'Button 1: Keep window.   Button 3: Delete window.'
    xs = 0.54
    ys = 0.975
    xyouts, xs, ys, msg, color=6, /norm, align=0.5, charsize=csize
    tvcrs,0.5,0.5,/norm
    cursor,x,y,/up
    while (!mouse.button eq 2) do begin
      tvcrs,0.5,0.5,/norm
      cursor,x,y,/up
    endwhile
    if (!mouse.button eq 1) then begin
      xyouts, xs, ys, msg, color=!p.background, /norm, align=0.5, charsize=csize
    endif else begin
      wdelete, Owin
      Owin = -1
    endelse
  endif

; Create a png file, if requested

  if (dopng) then begin
    print, "Writing png file: ",pngname," ... ",format='(3a,$)'
    img = tvrd()
    tvlct, red, green, blue, /get
    write_image, pngname, 'png', img, red, green, blue
    print, "done"
    set_plot, current_dev
  endif else wset, Twin

  return

end
