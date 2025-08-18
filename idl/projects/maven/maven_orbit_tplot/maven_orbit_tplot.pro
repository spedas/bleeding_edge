;+
;PROCEDURE:   maven_orbit_tplot
;PURPOSE:
;  Loads MAVEN ephemeris information, currently in the form of IDL save files produced
;  with maven_spice_eph.pro, and plots the spacecraft trajectory as a function of time
;  (using tplot).  The plots are color-coded according to the nominal plasma regime, 
;  based on conic fits to the bow shock and MPB from Trotignon et al. (PSS 54, 357-369, 
;  2006).  The wake region is either the EUV or optical shadow in MSO coordinates:
;  (sqrt(y*y + z*z) < Rm ; x < 0), where Rm is the Mars radius appropriate for optical
;  or EUV wavelengths.
;
;  The available coordinate frames are:
;
;   GEO = body-fixed Mars geographic coordinates (non-inertial) = IAU_MARS
;
;              X ->  0 deg E longitude, 0 deg latitude
;              Y -> 90 deg E longitude, 0 deg latitude
;              Z -> 90 deg N latitude (= X x Y)
;              origin = center of Mars
;              units = kilometers
;              full rotation once per Mars day
;
;   MSO = Mars-Sun-Orbit coordinates (approx. inertial)
;
;              X -> from center of Mars to center of Sun
;              Y -> opposite to Mars' orbital angular velocity vector
;              Z = X x Y
;              origin = center of Mars
;              units = kilometers
;              full rotation once per Mars year
;
;USAGE:
;  maven_orbit_tplot
;INPUTS:
;
;KEYWORDS:
;       TRANGE: A date or date range in any format accepted by time_double.
;               Only the date is used (hh:mm:ss is ignored).  If not specified,
;               then try to get the time range from tplot_com (TRANGE_FULL).
;               If that fails, then prompt the user for the time range.
;
;               Ephemeris data are loaded from one day before to one day after
;               TRANGE.  This ensures that interpolation is well defined even at
;               the edges of your date range.
;
;       RESET_TRANGE: OBSOLETE.  This keyword has no effect.  Timespan is reset
;                 only when EXTENDED is set (see below).
;
;       TIMECROP: OBSOLETE.  This keyword has no effect.
;
;       NOCROP:   OBSOLETE.  This keyword has no effect.
;
;       STAT:     Named variable to hold the plasma regime statistics.
;
;       SWIA:     Calculate viewing geometry for SWIA, based on nominal s/c
;                 pointing.
;
;       DATUM:    String for specifying the datum, or reference surface, for
;                 calculating altitude.  Can be one of "sphere", "ellipsoid",
;                 "areoid", or "surface".  Default = 'ellipsoid'.
;                 Minimum matching is used for this keyword.
;                 See mvn_altitude.pro for more information.
;
;       IALT:     Ionopause altitude.  Highly variable, but nominally ~400 km.
;                 For display only - not included in statistics.  Default is NaN.
;
;       SHADOW:   Choose shadow boundary definition:
;                    0 : optical shadow at spacecraft altitude
;                    1 : EUV shadow at spacecraft altitude (default)
;                    2 : EUV shadow at electron absorption altitude
;
;       SEGMENTS: Plot nominal altitudes for orbit segment boundaries as dotted
;                 horizontal lines.  Closely spaced lines are transitions, during
;                 which time the spacecraft is reorienting.  The actual segment 
;                 boundaries vary with orbit period.
;
;       RESULT:   Named variable to hold the MSO ephemeris with some calculated
;                 quantities.  OBSOLETE.  Still works, but use keyword EPH instead.
;
;       EPH:      Named variable to hold the MSO and GEO state vectors along with 
;                 some calculated values.
;
;       CURRENT:  Load the ephemeris from MOI to the current date + 2 weeks.  This
;                 uses reconstructed SPK kernels, as available, then predicts.
;                 This is the default.  OBSOLETE.
;
;       SPK:      String array with an even number of elements >= 2 containing the 
;                 names of the MSO and GEO save/restore ephemerides to use instead 
;                 of the standard set.  Multiple MSO and GEO files can be specified,
;                 but each MSO file must have a corresponding GEO file.  (These are
;                 made in pairs - see maven_orbit_makeeph).
;
;                 Used for long range predict and special events kernels.  Replaces
;                 keywords EXTENDED and HIRES.
;
;       EXTENDED: If set to a value from 1 to 8, loads one of eight long-term predict
;                 ephemerides.  Most have a density scale factor (DSF) of 2.5, which
;                 is a weighted average over several Mars years.  They differ in the
;                 number and timing of apoapsis, periapsis, and inclination maneuvers
;                 (arm, prm, inc) and total fuel usage (meters per second, or ms).
;                 The date when the ephemeris was generated is given at the end of 
;                 the filename (YYMMDD).  More recent dates better reflect actual 
;                 past perfomance and current mission goals.  When in doubt, use the
;                 most recent.
;
;                   0 : use timerange() to load short-term predicts
;                   1 : trj_orb_250407-350702_dsf2.0_prm_4.4ms_250402.bsp
;                   2 : trj_orb_240821-331231_dsf2.0_prm_4.4ms_240820.bsp
;                   3 : trj_orb_230322-320101_dsf2.5-arm-prm-inc-17.5ms_230320.bsp
;                   4 : trj_orb_230322-320101_dsf1.5-prm-3.5ms_230320.bsp
;                   5 : trj_orb_220810-320101_dsf2.5_arm_prm_19.2ms_220802.bsp
;                   6 : trj_orb_220101-320101_dsf2.5_arms_18ms_210930.bsp
;                   7 : trj_orb_220101-320101_dsf2.5_arm_prm_13.5ms_210908.bsp
;                   8 : trj_orb_210326-301230_dsf2.5-otm0.4-arms-prm-13.9ms_210330.bsp
;
;                 Default = 0.
;
;                 For short-term predictions (< 3-4 months in the future) it's better to
;                 set the desired timespan and run this routine without setting EXTENDED.
;                 That will load the short-term predict spk kernels, which are more 
;                 accurate than any of the above long-term predicts.
;
;       HIRES:    OBSOLETE.  This keyword has no effect.
;
;       LOADONLY: Create the TPLOT variables, but do not plot.
;
;       NOLOAD:   Don't load or refresh the ephemeris information.  Just fill in any
;                 keywords and exit.
;
;       LINE_COLORS: Line color scheme for altitude panel.  This can be an integer [0-10]
;                 to select one of 11 pre-defined line color schemes.  It can also be array
;                 of 24 (3x8) RGB values: [[R,G,B], [R,G,B], ...] that defines the first 7
;                 colors (0-6) and the last (255).  For details, see line_colors.pro and 
;                 color_table_crib.pro.  Default = 5.
;
;       COLORS:   An array with up to 3 elements to specify color indices for the
;                 plasma regimes: [sheath, pileup, wake].  Passed to maven_orbit_tplot.
;                 Defaults are:
;
;                   regime       index       LINE_COLORS=5
;                   -----------------------------------------
;                   sheath         4         green
;                   pileup         5         orange
;                   wake           2         blue
;                   -----------------------------------------
;
;                 The colors you get depend on your line color scheme.  The solar wind
;                 is always displayed in the foreground color (usually white or black).
;
;                 Note: Setting LINE_COLORS and COLORS here is local to this routine and
;                       affects only the altitude panel.
;
;       VARS:     Array of TPLOT variables created.
;
;       NOW:      Plot a vertical dotted line at the current time.
;
;       PDS:      Plot vertical dashed lines separating the PDS release dates.
;
;       VERBOSE:  Verbosity level passed to mvn_pfp_file_retrieve.  Default = 0
;                 (suppress most messages).  Try a value > 2 to see more
;                 messages; > 4 for lots of messages.
;
;                 Also used to control the verbosity of spd_download_plus by
;                 temporarily setting the debug level for dprint to VERBOSE.
;
;       CLEAR:    Clear the common block and exit.
;
;       SAVE:     Make a save file for all tplot variables and the common block.
;
;       RESTORE:  Restore tplot variables and the common block from a save file.
;
;       MISSION:  Restore save files that span from Mars orbit insertion to the 
;                 present.  These files are refreshed periodically.  Together, 
;                 the save files are 17 GB in size (as of December 2024), so this 
;                 keyword is only useful for computers with sufficient memory.
;
;                   Latest refresh: 2024-12-16
;                   Range 1: 2014-09-21 to 2025-01-18
;                            -- gap --
;                   Range 2: 2025-02-01 to 2025-04-05
;
;                 The first range is derived from reconstructed spk kernels plus
;                 short-term predict kernels.  The second range is derived from 
;                 medium-term predict kernels.
;
;                 Using the where command, you can identify times that meet an
;                 arbitrary set of ephemeris conditions.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-04-05 14:34:27 -0700 (Sat, 05 Apr 2025) $
; $LastChangedRevision: 33230 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_tplot.pro $
;
;CREATED BY:	David L. Mitchell  10-28-11
;-
pro maven_orbit_tplot, trange=trange, stat=stat, swia=swia, ialt=ialt, result=result, $
                       extended=extended, eph=eph, current=current, loadonly=loadonly, $
                       vars=vars, hires=hires, now=now, colors=colors, reset_trange=reset_trange, $
                       spk=spk, segments=segments, shadow=shadow, datum=datum2, noload=noload, $
                       pds=pds, verbose=verbose, clear=clear, success=success, save=save, $
                       restore=restore, mission=mission, timecrop=timecrop, nocrop=nocrop, $
                       line_colors=lcol, fatmars=fatmars

  @maven_orbit_common

  rootdir = 'maven/anc/spice/sav/'
  ssrc = mvn_file_source(archive_ext='')  ; don't archive old files
  moi = time_double('2014-09-22/02:24')   ; Mars orbit insertion
  oneday = 86400D

; Clear the common block and return

  if keyword_set(clear) then begin
    time = 0
    state = 0
    ss = 0
    wind = 0
    sheath = 0
    pileup = 0
    wake = 0
    sza = 0
    torb = 0
    period = 0
    lon = 0
    lat = 0
    hgt = 0
    datum = 0
    lst = 0
    slon = 0
    slat = 0
    mex = 0
    rcols = 0
    orbnum = 0
    orbstat = 0
    return
  endif

; Quick access to the state vector (obsolete: use maven_orbit_eph instead)

  if keyword_set(noload) then begin
    if (size(orbstat,/type) gt 0) then stat = orbstat
    if (size(state,/type) gt 0) then eph = state
    success = 1
    return
  endif

  if (size(verbose,/type) eq 0) then verbose = 0

  success = 0

; Create a save file

  if (size(save,/type) eq 7) then begin
    if (n_elements(time) lt 2) then begin
      print, "No ephemeris to save."
      return
    endif

    path = root_data_dir() + rootdir
    fname = path + save + '.sav'
    save, time, state, ss, wind, sheath, pileup, wake, sza, torb, period, $
          lon, lat, hgt, datum, lst, slon, slat, mex, rcols, orbnum, orbstat, file=fname

    fname = path + save
    tplot_save, file=fname
    return
  endif

; Restore mission-to-date from save files

  if keyword_set(mission) then begin
    fname = 'maven_moi_present.sav'
    file = mvn_pfp_file_retrieve(rootdir+fname,last_version=0,source=ssrc,verbose=verbose)
    nfiles = n_elements(file)
    if (nfiles eq 1) then restore, file else print,"File not found: " + fname

    fname = 'maven_moi_present.tplot'
    file = mvn_pfp_file_retrieve(rootdir+fname,last_version=0,source=ssrc,verbose=verbose)
    nfiles = n_elements(file)
    if (nfiles eq 1) then tplot_restore, file=file else print,"File not found: " + fname

    timefit, var='alt'
    options, 'alt2', 'datagap', 2D*oneday
    return
  endif

; Geodetic parameters for Mars from the IAU Report:
;   Archinal et al., Celest Mech Dyn Astr 130, Article 22, 2018
;     DOI 10.1007/s10569-017-9805-5
;  These values are based on the MGS-MOLA Gridded Data Record, 
;  which was published in 2003.

  R_equ = 3396.19D  ; +/- 0.1
  R_pol = 3376.20D  ; N pole = 3373.19 +/- 0.1 ; S pole = 3379.21 +/- 0.1
  R_vol = 3389.50D  ; +/- 0.2  (volumetric mean radius)

  if keyword_set(fatmars) then R_m = R_equ else R_m = R_vol

; Load any keyword defaults

  maven_orbit_options, get=key, /silent
  ktag = tag_names(key)
  active = ['STAT','SWIA','IALT','RESULT','EXTENDED','EPH','LOADONLY','VARS', $
           'TRANGE','NOW','COLORS','SPK','SEGMENTS','SHADOW','DATUM2','NOLOAD', $
           'PDS','VERBOSE','CLEAR','SUCCESS','SAVE','RESTORE','MISSION', $
           'LINE_COLORS']
  obsolete = ['TIMECROP','NOCROP','RESET_TRANGE','HIRES','CURRENT']
  tlist = [active, obsolete]
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

  for i=0,(n_elements(obsolete)-1) do begin
    ok = execute('kset = size(' + obsolete[i] + ',/type) gt 0',0,1)
    if (kset) then print,'Keyword ',obsolete[i],' is obsolete.  It has no effect.'
  endfor

; Determine the reference surface for calculating altitude

  dlist = ['sphere','ellipsoid','areoid','surface']
  if (size(datum2,/type) ne 7) then datum2 = dlist[1]
  i = strmatch(dlist, datum2+'*', /fold)
  case (total(i)) of
     0   : begin
             print, "Datum not recognized: ", datum2
             return
           end
     1   : datum = (dlist[where(i eq 1)])[0]
    else : begin
             print, "Datum is ambiguous: ", dlist[where(i eq 1)]
             return
           end
  endcase

; Determine if extended predict ephemeris is requested

  if (n_elements(extended) gt 0) then begin
    extended = fix(extended[0])
    extflg = (extended ge 1) or (extended le 6)
  endif else extflg = 0B

; Get the time range

  treset = 0
  case n_elements(trange) of
      0  : begin
             tplot_options, get=topt
             str_element, topt, 'trange_full', tspan
             if ((tspan[1] eq 0D) and ~extflg) then begin
               timespan
               tplot_options, get=topt
               str_element, topt, 'trange_full', tspan
             endif
           end
      1  : tspan = time_double(time_string(trange,prec=-3)) + [0D, oneday]
    else : begin
             tspan = time_double(time_string(minmax(time_double(trange)),prec=-3))
             if ((tspan[1] - tspan[0]) lt oneday) then tspan[1] = tspan[0] + oneday
           end
  endcase

  tspan = tspan + [-oneday, oneday]  ; pad by one day before and after

  sflg = (size(shadow,/type) gt 0) ? fix(shadow[0]) > 0 : 1
  if not keyword_set(ialt) then ialt = !values.f_nan

  mname = 'maven_spacecraft_mso_??????' + '.sav'
  gname = 'maven_spacecraft_geo_??????' + '.sav'

; Check for non-standard input ephemerides

  if (size(spk,/type) eq 7) then begin
    indx = where(strmatch(spk,"*_mso_*") eq 1, mfiles)
    if (mfiles eq 0) then begin
      print, "Can't find MSO ephemeris."
      return
    endif
    mname = spk[indx]

    indx = where(strmatch(spk,"*_geo_*") eq 1, gfiles)
    if (gfiles eq 0) then begin
      print, "Can't find GEO ephemeris."
      return
    endif
    gname = spk[indx]
    
    if (mfiles ne gfiles) then begin
      print, "MSO and GEO ephemerides do not correspond."
      return
    endif
  endif
  
  str_element, topt, 'title', ttitle, success=ok
  if (not ok) then ttitle = ''

  if (size(extended,/type) gt 0) then begin
    case extended of
       0   : ; do nothing (don't use extended predict ephemeris)
       1   : begin
               mname = 'maven_spacecraft_mso_250407-350702_dsf2.0_prm_4.4ms_250402.sav'
               gname = 'maven_spacecraft_geo_250407-350702_dsf2.0_prm_4.4ms_250402.sav'
               ename = 'maven_spacecraft_eph_250407-350702_dsf2.0_prm_4.4ms_250402.sav'
               timespan, ['2025-04-07','2035-07-01']
               treset = 1
               print,"Using extended predict ephemeris."
               print,"  SPK = trj_orb_250407-350702_dsf2.0_prm_4.4ms_250402.bsp"
               ttitle = "trj_orb_250407-350702_dsf2.0_prm_4.4ms_250402.bsp"
             end
       2   : begin
               mname = 'maven_spacecraft_mso_240821-331231_dsf2.0_prm_4.4ms_240820.sav'
               gname = 'maven_spacecraft_geo_240821-331231_dsf2.0_prm_4.4ms_240820.sav'
               ename = 'maven_spacecraft_eph_240821-331231_dsf2.0_prm_4.4ms_240820.sav'
               timespan, ['2024-08-21','2034-01-01']
               treset = 1
               print,"Using extended predict ephemeris."
               print,"  SPK = trj_orb_240821-331231_dsf2.0_prm_4.4ms_240820.bsp"
               ttitle = "trj_orb_240821-331231_dsf2.0_prm_4.4ms_240820.bsp"
             end
       3   : begin
               mname = 'maven_spacecraft_mso_230322-320101_dsf2.5-arm-prm-inc-17.5ms_230320.sav'
               gname = 'maven_spacecraft_geo_230322-320101_dsf2.5-arm-prm-inc-17.5ms_230320.sav'
               ename = 'maven_spacecraft_eph_230322-320101_dsf2.5-arm-prm-inc-17.5ms_230320.sav'
               timespan, ['2023-03-22','2032-01-01']
               treset = 1
               print,"Using extended predict ephemeris."
               print,"  SPK = trj_orb_230322-320101_dsf2.5-arm-prm-inc-17.5ms_230320.bsp"
               ttitle = "trj_orb_230322-320101_dsf2.5-arm-prm-inc-17.5ms_230320.bsp"
             end
       4   : begin
               mname = 'maven_spacecraft_mso_230322-320101_dsf1.5-prm-3.5ms_230320.sav'
               gname = 'maven_spacecraft_geo_230322-320101_dsf1.5-prm-3.5ms_230320.sav'
               ename = 'maven_spacecraft_eph_230322-320101_dsf1.5-prm-3.5ms_230320.sav'
               timespan, ['2023-03-22','2032-01-01']
               treset = 1
               print,"Using extended predict ephemeris."
               print,"  SPK = trj_orb_230322-320101_dsf1.5-prm-3.5ms_230320.bsp"
               ttitle = "trj_orb_230322-320101_dsf1.5-prm-3.5ms_230320.bsp"
             end
       5   : begin
               mname = 'maven_spacecraft_mso_2022-2032_dsf2.5_arm_prm_19.2ms_220802.sav'
               gname = 'maven_spacecraft_geo_2022-2032_dsf2.5_arm_prm_19.2ms_220802.sav'
               ename = 'maven_spacecraft_eph_2022-2032_dsf2.5_arm_prm_19.2ms_220802.sav'
               timespan, ['2022-08-10','2032-01-01']
               treset = 1
               print,"Using extended predict ephemeris."
               print,"  SPK = trj_orb_220810-320101_dsf2.5_arm_prm_19.2ms_220802.bsp"
               ttitle = "trj_orb_220810-320101_dsf2.5_arm_prm_19.2ms_220802.bsp"
             end
       6   : begin
               mname = 'maven_spacecraft_mso_2022-2032_dsf2.5_arms_18ms_210930.sav'
               gname = 'maven_spacecraft_geo_2022-2032_dsf2.5_arms_18ms_210930.sav'
               ename = 'maven_spacecraft_eph_2022-2032_dsf2.5_arms_18ms_210930.sav'
               timespan, ['2022-01-01','2032-01-01']
               treset = 1
               print,"Using extended predict ephemeris."
               print,"  SPK = trj_orb_220101-270101_dsf2.5_arms_18ms_210930.bsp"
               ttitle = "trj_orb_220101-320101_dsf2.5_arms_18ms_210930.bsp"
             end
       7   : begin
               mname = 'maven_spacecraft_mso_2022-2032_dsf2.5_arm_prm_13.5ms_210908.sav'
               gname = 'maven_spacecraft_geo_2022-2032_dsf2.5_arm_prm_13.5ms_210908.sav'
               ename = 'maven_spacecraft_eph_2022-2032_dsf2.5_arm_prm_13.5ms_210908.sav'
               timespan, ['2022-01-01','2032-01-01']
               treset = 1
               print,"Using extended predict ephemeris."
               print,"  SPK = trj_orb_220101-270101_dsf2.5_arm_prm_13.5ms_210908.bsp"
               ttitle = "trj_orb_220101-320101_dsf2.5_arm_prm_13.5ms_210908.bsp"
             end
       8   : begin
               mname = 'maven_spacecraft_mso_2021-2030_dsf2.5_210330.sav'
               gname = 'maven_spacecraft_geo_2021-2030_dsf2.5_210330.sav'
               ename = 'maven_spacecraft_eph_2021-2030_dsf2.5_210330.sav'
               timespan, ['2021-03-26','2030-12-30']
               treset = 1
               print,"Using extended predict ephemeris."
               print,"  SPK = trj_orb_210326-260101_dsf2.5-otm0.4-arms-prm-13.9ms_210330.bsp"
               ttitle = "trj_orb_210326-301230_dsf2.5-otm0.4-arms-prm-13.9ms_210330.bsp"
             end
      else : begin
               print,"Extended predict ephemeris options are: "
               print,"  0 : Do not use an extended predict ephemeris (default)."
               print,"  1 : trj_orb_250407-350702_dsf2.0_prm_4.4ms_250402.bsp"
               print,"  2 : trj_orb_240821-331231_dsf2.0_prm_4.4ms_240820.bsp"
               print,"  3 : trj_orb_230322-320101_dsf2.5-arm-prm-inc-17.5ms_230320.bsp"
               print,"  4 : trj_orb_230322-320101_dsf1.5-prm-3.5ms_230320.bsp"
               print,"  5 : trj_orb_220810-320101_dsf2.5_arm_prm_19.2ms_220802.bsp"
               print,"  6 : trj_orb_220101-320101_dsf2.5_arms_18ms_210930.bsp"
               print,"  7 : trj_orb_220101-320101_dsf2.5_arm_prm_13.5ms_210908.bsp"
               print,"  8 : trj_orb_210326-301230_dsf2.5-otm0.4-arms-prm-13.9ms_210330.bsp"
               print,""
               return
             end
    endcase
  endif else extended = 0

; Set the color scheme for the altitude panel (assumes line color scheme 5):
;   colors 1-6 = [magenta, blue, cyan, green, orange, red]

  lcol = (n_elements(lcol) gt 0) ? fix(lcol[0]) : 5

              ; wind is shown in the foreground color (!p.color)
  blue = 2    ; shadow
  green = 4   ; sheath
  orange = 5  ; pileup
  case n_elements(colors) of
    0 : rcols = [green, orange, blue]
    1 : rcols = [round(colors), orange, blue]
    2 : rcols = [round(colors), blue]
    3 : rcols = round(colors)
    else : rcols = round(colors[0:2])
  endcase
  if keyword_set(now) then donow = 1 else donow = 0

; Restore the MSO state vectors

  file = mvn_pfp_file_retrieve(rootdir+mname,last_version=0,source=ssrc,verbose=verbose)
  nfiles = n_elements(file)

  if (extended eq 0) then begin
    year = strmid(file,9,4,/rev)
    month = strmid(file,5,2,/rev)

    date = replicate(time_struct(0D), nfiles)
    date.year = year
    date.month = month
    date.date = 1
    maxdate = date[n_elements(date)-1]
    maxdate.month += 1
    maxdate = time_double(maxdate)
    date = time_double(date)

    if (tspan[0] gt maxdate) then begin
      print,"No ephemeris coverage after ",time_string(maxdate)
      return
    endif
    if (tspan[1] lt date[0]) then begin
      print,"No ephemeris coverage before ",time_string(date[0])
      return
    endif

    i = max(where(date lt tspan[0], icnt))
    if (icnt eq 0) then i = 0
    j = min(where(date gt tspan[1], jcnt))
    if (jcnt eq 0) then j = nfiles - 1
    file = file[i:j]
    nfiles = n_elements(file)
  endif

  state = [{t:0D, x:0D, y:0D, z:0D, vx:0D, vy:0D, vz:0D}]
  for i=0,(nfiles-1) do begin
    finfo = file_info(file[i])
    if (finfo.exists) then begin
      print, "Loading: ", file_basename(file[i])
      restore, file[i]
      state = [temporary(state), maven_mso]
    endif else print, "File not found: ", file[i]
  endfor
  maven = temporary(state[1:*])

  time = maven.t
  dt = median(time - shift(time,1))

  mso_x = fltarr(n_elements(maven.x),3)
  mso_x[*,0] = maven.x
  mso_x[*,1] = maven.y
  mso_x[*,2] = maven.z

  mso_v = mso_x
  mso_v[*,0] = maven.vx
  mso_v[*,1] = maven.vy
  mso_v[*,2] = maven.vz

  maven = 0
  
; Restore the GEO state vectors

  file = mvn_pfp_file_retrieve(rootdir+gname,last_version=0,source=ssrc,verbose=verbose)
  nfiles = n_elements(file)

  if (extended eq 0) then begin
    year = strmid(file,9,4,/rev)
    month = strmid(file,5,2,/rev)

    date = replicate(time_struct(0D), nfiles)
    date.year = year
    date.month = month
    date.date = 1
    maxdate = date[n_elements(date)-1]
    maxdate.month += 1
    maxdate = time_double(maxdate)
    date = time_double(date)

    if (tspan[0] gt maxdate) then begin
      print,"No ephemeris coverage after ",time_string(maxdate)
      return
    endif
    if (tspan[1] lt date[0]) then begin
      print,"No ephemeris coverage before ",time_string(date[0])
      return
    endif

    i = max(where(date lt tspan[0], icnt))
    if (icnt eq 0) then i = 0
    j = min(where(date gt tspan[1], jcnt))
    if (jcnt eq 0) then j = nfiles - 1
    file = file[i:j]
    nfiles = n_elements(file)
  endif

  state = [{t:0D, x:0D, y:0D, z:0D, vx:0D, vy:0D, vz:0D}]
  for i=0,(nfiles-1) do begin
    finfo = file_info(file[i])
    if (finfo.exists) then begin
      print, "Loading: ", file_basename(file[i])
      restore, file[i]
      state = [temporary(state), maven_geo]
    endif else print, "File not found: ", file[i]
  endfor
  maven_g = temporary(state[1:*])

  geo_x = fltarr(n_elements(maven_g.x),3)
  geo_x[*,0] = maven_g.x
  geo_x[*,1] = maven_g.y
  geo_x[*,2] = maven_g.z

  geo_v = geo_x
  geo_v[*,0] = maven_g.vx
  geo_v[*,1] = maven_g.vy
  geo_v[*,2] = maven_g.vz

  maven_g = 0

; Trim ephemeris to the requested time range

  if (extended eq 0) then begin
    indx = where((time ge tspan[0]) and (time le tspan[1]), npts)

    if (npts gt 0L) then begin
      time = temporary(time[indx])
      mso_x = temporary(mso_x[indx,*])
      mso_v = temporary(mso_v[indx,*])
      geo_x = temporary(geo_x[indx,*])
      geo_v = temporary(geo_v[indx,*])
    endif else begin
      print,"No ephemeris data within requested range: ",time_string(tspan)
      print,"Retaining all ephemeris data."
    endelse
  endif

; Combined state vector for MSO and GEO frames --> common block

  npts = n_elements(time)
  state = {time:time, mso_x:mso_x, mso_v:mso_v, geo_x:geo_x, geo_v:geo_v}

; Calculate additional parameters derived from state vectors

  x = state.mso_x[*,0]/R_m
  y = state.mso_x[*,1]/R_m
  z = state.mso_x[*,2]/R_m
  vx = state.mso_x[*,0]
  vy = state.mso_x[*,1]
  vz = state.mso_x[*,2]

  r = sqrt(x*x + y*y + z*z)
  s = sqrt(y*y + z*z)
  sza = atan(s,x)

  case (sflg) of
      0  : begin
             print,"Using optical shadow"
             shadow = 1D
             stype = 'OPT'
           end
      1  : begin
             print,"Using EUV shadow"
             shadow = 1D + (150D/R_m)
             stype = 'EUV'
           end
      2  : begin
             print,"Using electron footpoint shadow"
             shadow = 1D + (170D/R_m)
             stype = 'EFP'
           end
    else : begin
             print,"Shadow option not recognized: ",sflg
             print,"Using default EUV shadow"
             shadow = 1D + (150D/R_m)
             stype = 'EUV'
           end
  endcase

; Calculate altitude, longitude, latitude, local time, and sub-solar point
; (or restore pre-calculated values for MISSION or EXTENDED).  All of these
; parameters are stored in the common block.

  if (~keyword_set(mission) and ~keyword_set(extended)) then begin
    print,"Reference surface for calculating altitude: ",strlowcase(datum)
    mvn_altitude, cart=transpose(state.geo_x), datum=datum, result=dat
    hgt = dat.alt
    lon = dat.lon
    lat = dat.lat

    mvn_spice_stat, summary=sinfo, /silent
    if ~sinfo.planets_exist then mvn_swe_spice_init, /baseonly
    print,"Calculating local time and sub-solar point."
    mvn_mars_localtime, time, lon, result=dat
    lst = dat.lst
    slon = dat.slon
    slat = dat.slat

    eph = maven_orbit_eph()
    undefine, dat
  endif else begin
    hgt = dblarr(n_elements(time))
    lon = hgt
    lat = hgt
    lst = hgt
    slon = hgt
    slat = hgt

    file = mvn_pfp_file_retrieve(rootdir+ename,last_version=0,source=ssrc,verbose=verbose,/valid)
    i = where(file ne '', nfiles)
    if (nfiles eq 1) then begin
      file = file[0]
      print, "Loading: ", file_basename(file)
      restore, file

      i = nn2(eph.time, time, maxdt=10D, /valid, vindex=j)
      if (n_elements(j) gt 0L) then begin
        hgt[j] = eph.alt[i]
        lon[j] = eph.lon[i]
        lat[j] = eph.lat[i]
        lst[j] = eph.lst[i]
        slon[j] = eph.slon[i]
        slat[j] = eph.slat[i]
      endif else print, "Ephemeris does not match state vector."
      undefine, eph
    endif else begin
      print,"Reference surface for calculating altitude: ",strlowcase(datum)
      mvn_altitude, cart=transpose(state.geo_x), datum=datum, result=dat
      hgt = dat.alt
      lon = dat.lon
      lat = dat.lat

      print,"Calculating local time and sub-solar point."
      mvn_mars_localtime, time, lon, result=dat
      lst = dat.lst
      slon = dat.slon
      slat = dat.slat

      undefine, dat
    endelse
  endelse

; Package the ephemeris (MSO state vector + calculated values)

  eph = maven_orbit_eph()

  result = {t     : time  , $   ; time (UTC)
            x     : x     , $   ; MSO X (R_m)
            y     : y     , $   ; MSO Y (R_m)
            z     : z     , $   ; MSO Z (R_m)
            vx    : vx    , $   ; MSO Vx (km/s)
            vy    : vy    , $   ; MSO Vy (km/s)
            vz    : vz    , $   ; MSO Vz (km/s)
            r     : r     , $   ; sqrt(x*x + y*y + z*z)
            s     : s     , $   ; sqrt(y*y + z*z)
            sza   : sza   , $   ; atan(s,x)
            hgt   : hgt   , $   ; altitude (km)
            lon   : lon   , $   ; GEO longitude of spacecraft (deg)
            lat   : lat   , $   ; GEO latitude of spacecraft  (deg)
            R_m   : R_m   , $   ; Mean radius of Mars (km)
            datum : datum , $   ; reference surface
            lst   : lst   , $   ; local solar time (Mars hours)
            slon  : slon  , $   ; GEO longitude of sub-solar point (deg)
            slat  : slat     }  ; GEO latitude of sub-solar point (deg)

; Determine the plasma regions sampled by the spacecraft along its orbit

; Shock conic (Trotignon)

  x0  = 0.600
  ecc = 1.026
  L   = 2.081

  phm = 160.*!dtor

  phi   = atan(s,(x - x0))
  rho_s = sqrt((x - x0)^2. + s*s)
  shock = L/(1. + ecc*cos(phi < phm))

; MPB conic (2-conic model of Trotignon)

  rho_p = x
  MPB   = x

; First conic (x > 0)

  indx = where(x ge 0)

  x0  = 0.640
  ecc = 0.770
  L   = 1.080

  phi = atan(s,(x - x0))

  rho_p[indx] = sqrt((x[indx] - x0)^2. + s[indx]*s[indx])
  MPB[indx] = L/(1. + ecc*cos(phi[indx]))

; Second conic (x < 0)

  indx = where(x lt 0)

  x0  = 1.600
  ecc = 1.009
  L   = 0.528

  phm = 160.*!dtor

  phi = atan(s,(x - x0))

  rho_p[indx] = sqrt((x[indx] - x0)^2. + s[indx]*s[indx])
  MPB[indx] = L/(1. + ecc*cos(phi[indx] < phm))

; Define the nominal plasma regions (based on the above conics)

  ss = dblarr(npts, 5)
  ss[*,0] = x
  ss[*,1] = y
  ss[*,2] = z
  ss[*,3] = r
  ss[*,4] = hgt

  indx = where(rho_s ge shock, count)
  sheath = ss
  if (count gt 0L) then begin
    sheath[indx,0] = !values.f_nan
    sheath[indx,1] = !values.f_nan
    sheath[indx,2] = !values.f_nan
    sheath[indx,3] = !values.f_nan
    sheath[indx,4] = !values.f_nan
  endif

  indx = where(rho_p ge MPB, count)
  pileup = ss
  if (count gt 0L) then begin
    pileup[indx,0] = !values.f_nan
    pileup[indx,1] = !values.f_nan
    pileup[indx,2] = !values.f_nan
    pileup[indx,3] = !values.f_nan
    pileup[indx,4] = !values.f_nan
  endif

  indx = where((x gt 0D) or (s gt shadow), count)
  wake = ss
  if (count gt 0L) then begin
    wake[indx,0] = !values.f_nan
    wake[indx,1] = !values.f_nan
    wake[indx,2] = !values.f_nan
    wake[indx,3] = !values.f_nan
    wake[indx,4] = !values.f_nan
  endif

  indx = where(finite(sheath[*,0]) eq 1, count)
  wind = ss
  if (count gt 0L) then begin
    wind[indx,0] = !values.f_nan
    wind[indx,1] = !values.f_nan
    wind[indx,2] = !values.f_nan
    wind[indx,3] = !values.f_nan
    wind[indx,4] = !values.f_nan
  endif
  
  indx = where(finite(pileup[*,0]) eq 1, count)
  if (count gt 0L) then begin
    sheath[indx,0] = !values.f_nan
    sheath[indx,1] = !values.f_nan
    sheath[indx,2] = !values.f_nan
    sheath[indx,3] = !values.f_nan
    sheath[indx,4] = !values.f_nan
  endif
  
  indx = where(finite(wake[*,0]) eq 1, count)
  if (count gt 0L) then begin
    sheath[indx,0] = !values.f_nan
    sheath[indx,1] = !values.f_nan
    sheath[indx,2] = !values.f_nan
    sheath[indx,3] = !values.f_nan
    sheath[indx,4] = !values.f_nan

    pileup[indx,0] = !values.f_nan
    pileup[indx,1] = !values.f_nan
    pileup[indx,2] = !values.f_nan
    pileup[indx,3] = !values.f_nan
    pileup[indx,4] = !values.f_nan
  endif

  tmin = min(time, max=tmax)

; Make the time series plot

  store_data,'alt',data={x:time, y:hgt}

  store_data,'sza',data={x:time, y:sza*!radeg}
  ylim,'sza',0,180,0
  options,'sza','yticks',6
  options,'sza','yminor',3
  options,'sza','panel_size',0.5
  options,'sza','ytitle','Solar Zenith Angle'

  store_data,'sheath',data={x:time, y:sheath[*,4]}
  options,'sheath','color',rcols[0]

  store_data,'pileup',data={x:time, y:pileup[*,4]}
  options,'pileup','color',rcols[1]

  store_data,'wake',data={x:time, y:wake[*,4], shadow:stype}
  options,'wake','color',rcols[2]

  store_data,'wind',data={x:time, y:wind[*,4]}

  store_data,'iono',data={x:[tmin,tmax], y:[ialt,ialt]}
  options,'iono','color',6  ; hard-coded to red in line color scheme 5
  options,'iono','linestyle',2
  options,'iono','thick',2

  store_data,'alt_lab',data={x:minmax(time), y:replicate(-1.,2,4), v:indgen(4)}
  options,'alt_lab','labels',[stype+' SHD','PILEUP','SHEATH','WIND']
  options,'alt_lab','colors',[reverse(rcols),!p.color]
  options,'alt_lab','labflag',1

  store_data,'alt2',data=['alt_lab','alt','sheath','pileup','wake','wind','iono']
  ylim, 'alt2', 0, 1000*ceil(max(hgt)/1000.), 0
  options,'alt2','line_colors',lcol
  options,'alt2','ytitle','Altitude (km)!c' + strlowcase(datum)

; 6200-km apoapsis: options,'alt2','constant',[500,1200,4970,5270]
; 4500-km apoapsis: options,'alt2','constant',[500,1050,3460,3850]

  if keyword_set(segments) then options,'alt2','constant',[500,1050,3460,3850] $
                           else options,'alt2','constant',-1

  if keyword_set(pds) then begin
    nmon = 100  ; extends to 2039-08-15
    pds_rel = replicate(time_struct('2014-11-15'),nmon)
    pds_rel.month += 3*indgen(nmon)
    pds_rel = time_double(pds_rel)
    pflg = 1
  endif else pflg = 0

  mvn_sun_bar

; Calculate statistics (orbit by orbit)

  alt = ss[*,4]
  aalt = max(alt)
  palt = min(alt)
  gndx = where(alt lt 500.)
  di = gndx - shift(gndx,1)
  di[0L] = 2L
  gap = where(di gt 1L, norb)

  if (norb gt 3) then begin
    torb = dblarr(norb-3L)
    twind = torb
    tsheath = torb
    tpileup = torb
    twake = torb
    period = torb
    atime = torb
    aalt = torb
    ptime = torb
    palt = torb
    plon = torb
    plonx = torb
    plony = torb
    plat = torb
    psza = torb
    sma = dblarr(norb-3L,3)

    d2sza = spl_init(time, sza)
    d2lat = spl_init(time, lat)
    lonx = cos(lon*!dtor)
    lony = sin(lon*!dtor)
    d2lonx = spl_init(time, lonx)
    d2lony = spl_init(time, lony)

    hwind = twind
    hsheath = tsheath
    hpileup = tpileup
    hwake = twake

    for i=1L,(norb-3L) do begin

      p1 = min(alt[gndx[gap[i]:(gap[i+1L]-1L)]],j)
      j1 = gndx[j+gap[i]]
      jndx = [-1L, 0L, 1L] + j1
      parabola_vertex, time[jndx], alt[jndx], t1, p1

      p2 = min(alt[gndx[gap[i+1L]:(gap[i+2L]-1L)]],j)
      j2 = gndx[j+gap[i+1L]]
      jndx = [-1L, 0L, 1L] + j2
      parabola_vertex, time[jndx], alt[jndx], t2, p2

      a1 = max(alt[j1:j2],j)
      j3 = j1 + j
      jndx = [-1L, 0L, 1L] + j3
      parabola_vertex, time[jndx], alt[jndx], t3, a1

      dj = double(j2 - j1 + 1L)

      k = i - 1L

      torb[k] = (t1 + t2)/2D
      period[k] = (t2 - t1)/3600D

      ptime[k] = t1
      palt[k] = p1         ; minimum altitude, not geometric periapsis
      atime[k] = t3
      aalt[k] = a1
      plonx[k] = spl_interp(time, lonx, d2lonx, t1)
      plony[k] = spl_interp(time, lony, d2lony, t1)
      plat[k] = spl_interp(time, lat, d2lat, t1)
      psza[k] = spl_interp(time, sza, d2sza, t1)

      indx = where(finite(wind[j1:j2,0]), count)
      twind[k] = double(count)/dj
      hwind[k] = double(count)*(dt/3600D)

      indx = where(finite(sheath[j1:j2,0]), count)
      tsheath[k] = double(count)/dj
      hsheath[k] = double(count)*(dt/3600D)

      indx = where(finite(pileup[j1:j2,0]), count)
      tpileup[k] = double(count)/dj
      hpileup[k] = double(count)*(dt/3600D)

      indx = where(finite(wake[j1:j2,0]), count)
      twake[k] = double(count)/dj
      hwake[k] = double(count)*(dt/3600D)

;   Determine semi-minor axis direction for each orbit -- start at periapsis
;   and look for the point in the orbit outbound where [S(periapsis) dot S] 
;   changes sign.  This will be a line perpendicular to the semi-major axis 
;   and therefore parallel to the semi-minor axis.  Note: this is all done
;   in MSO coordinates.

      s1 = ss[j1:j2,0:2]
      pdots = (s1[*,0]*s1[0,0]) + (s1[*,1]*s1[0,1]) + (s1[*,2]*s1[0,2])
      indx = where((pdots*shift(pdots,1)) lt 0.)
      sma[k,0:2] = ss[indx[0]+j1,0:2]/ss[indx[0]+j1,3]

    endfor

    plon = atan(plony, plonx)*!radeg
    indx = where(plon lt 0., count)
    if (count gt 0L) then plon[indx] += 360.
  endif

  if keyword_set(swia) then begin
    if (norb gt 15) then sma = smooth(sma,[11,1],/edge_truncate) ; unit vector --> semi-minor axis
    fov = sma                      ; unit vector --> perpendicular to SWIA FOV center plane
    fov[*,0] = 0D                  ; cross product --> X x SMA
    fov[*,1] = -sma[*,2]
    fov[*,2] = sma[*,1]
    for i=0L,n_elements(fov[*,0])-1L do begin
       amp = sqrt(fov[i,1]*fov[i,1] + fov[i,2]*fov[i,2])
       fov[i,*] = fov[i,*]/amp
    endfor

; The vector fov changes smoothly over the mission lifetime.  I want to calulate the 
; angle between fov and nadir throughout all the orbits.

    nx = -x/r   ; unit vector --> nadir
    ny = -y/r
    nz = -z/r

    fx = replicate(0D, n_elements(time))
    fy = spline(torb, fov[*,1], time)
    fz = spline(torb, fov[*,2], time)
    
    sdotf = dblarr(n_elements(time))
    for i=0L, n_elements(time)-1L do sdotf[i] = (ny[i]*fy[i]) + (nz[i]*fz[i])
  
    phi = 90D - (!radeg*acos(sdotf))

; phi is the elevation angle of nadir in SWIA's FOV.  The optimal FOV has phi = 0, 
; that is, nadir is in the center plane of the FOV.
; SWIA's blind spots are at |phi| > 45 degrees.

; Clip off the periapsis and apoapsis parts of the orbit -- focus on the sides only.
  
    alt = (ss[*,3] - 1D)*R_m
    indx = where((alt lt 500D) or (alt gt 5665D))
    phi[indx] = !values.f_nan
  
    swia = {time    : time    , $   ; time (UTC)
            fx      : fx      , $   ; FOV unit vector (x component)
            fy      : fy      , $   ; FOV unit vector (y component)
            fz      : fz      , $   ; FOV unit vector (z component)
            phi     : phi        }  ; elev of nadir in SWIA FOV

  endif

; Package the results - statistics are on an orbit-by-orbit basis
; check for valid results, torb, etc... may not be defined, jmm,
; 2018-12-17

  if n_elements(torb) Gt 0 then begin
     stat = {time    : torb    , $  ; time (UTC)
             twind   : twind   , $  ; fraction of time in solar wind
             tsheath : tsheath , $  ; fraction of time in sheath
             tpileup : tpileup , $  ; fraction of time in MPR
             twake   : twake   , $  ; fraction of time in wake
             hwind   : hwind   , $  ; hours in solar wind
             hsheath : hsheath , $  ; hours in sheath
             hpileup : hpileup , $  ; hours in MPR
             hwake   : hwake   , $  ; hours in wake
             period  : period  , $  ; orbit period
             atime   : atime   , $  ; apoapsis time
             aalt    : aalt    , $  ; apoapsis altitude
             ptime   : ptime   , $  ; periapsis time
             palt    : palt    , $  ; periapsis altitude
             plon    : plon    , $  ; periapsis longitude
             plat    : plat    , $  ; periapsis latitude
             psza    : psza    , $  ; periapsis solar zenith angle
             datum   : datum      } ; reference surface

     orbstat = stat                 ; update the common block

; Stack up times for plotting in one panel

     tpileup = tpileup + twake
     tsheath = tsheath + tpileup
     twind = twind + tsheath

; Store the data in TPLOT

     store_data, 'twind'  , data = {x:torb, y:twind}
     store_data, 'tsheath', data = {x:torb, y:tsheath}
     store_data, 'tpileup', data = {x:torb, y:tpileup}
     store_data, 'twake'  , data = {x:torb, y:twake, shadow:stype}

     options, 'tsheath', 'color', rcols[0]
     options, 'tpileup', 'color', rcols[1]
     options, 'twake', 'color', rcols[2]

     store_data, 'stat', data = ['twind','tsheath','tpileup','twake']
     ylim, 'stat', 0, 1
     options, 'stat', 'panel_size', 0.75
     options, 'stat', 'ytitle', 'Orbit Fraction'

     store_data, 'period', data = {x:torb, y:period}
     options,'period','ytitle','Period'
     options,'period','panel_size',0.5
     options,'period','ynozero',1

     store_data, 'aalt', data = {x:atime, y:aalt}
     options,'aalt','ytitle','Apoapsis (km)!c' + strlowcase(datum)
     options,'aalt','ynozero',1

     store_data, 'palt', data = {x:ptime, y:palt}
     options,'palt','ytitle','Periapsis (km)!c' + strlowcase(datum)
     options,'palt','ynozero',1

     store_data, 'plon', data = {x:ptime, y:plon}
     ylim,'plon',0,360,0
     options,'plon','yticks',4
     options,'plon','yminor',3
     options,'plon','ytitle','Periapsis Lon (deg)'
  
     store_data, 'plat', data = {x:ptime, y:plat}
     ylim,'plat',-90,90,0
     options,'plat','yticks',2
     options,'plat','yminor',3
     options,'plat','ytitle','Periapsis Lat (deg)'

     store_data, 'psza', data = {x:ptime, y:psza*!radeg}
     ylim,'psza',0,180,0
     options,'psza','yticks',2
     options,'psza','yminor',3
     options,'psza','constant',[98,108] ; EUV shadow at [150,300] km
     options,'psza','ytitle','Periapsis SZA (deg)'
  
     store_data, 'lon', data = {x:time, y:lon}
     ylim,'lon',-180,180,0
     options,'lon','yticks',4
     options,'lon','yminor',3
  
     store_data, 'lat', data = {x:time, y:lat}
     ylim,'lat',-90,90,0
     options,'lat','yticks',2
     options,'lat','yminor',3
     options,'lat','panel_size',0.5

; Determine orbit number

     print, 'Getting orbit numbers ... ', format='(a,$)'
     dprint,' ', getdebug=bug, dlevel=4
       dprint,' ', setdebug=verbose, dlevel=4
       orbnum = mvn_orbit_num(time=time)
     dprint,' ', setdebug=bug, dlevel=4
     print,'done'

     store_data,'orbnum',data={x:time, y:orbnum}
     tplot_options,'var_label','orbnum'

; Put up the plot

     vars = ['alt2','stat','sza','period','palt','lon','lat']
     
     if not keyword_set(loadonly) then begin
        avars = vars[0:2]
        nvars = n_elements(avars)

        str_element, topt, 'varnames', tvars, success=ok
        if (not ok) then tvars = avars
        for i=(nvars-1),0,-1 do if (~max(strcmp(avars[i],tvars))) then tvars = [avars[i],tvars]

        if (treset) then timespan,[tmin,tmax],/sec
        tplot,tvars,title=ttitle
        if (donow) then timebar,systime(/utc,/sec),line=1
        if (pflg) then timebar,pds_rel,line=2
     endif
  endif

  success = 1

  return

end
