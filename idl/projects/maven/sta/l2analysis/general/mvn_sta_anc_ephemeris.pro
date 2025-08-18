;+
;Routine based on CMF mvn_sta_anc_spacecraft.pro, to obtain MAVEN sc ephemeris info. This routine is lighter than the LPW version - it
;only calculates a handful of parameters, which can be specified as keywords. This makes the routine quicker. The routine also uses kernels 
;loaded in by mvn_spice_kerneles(/load), rather than mvn_sta_anc_get_spice_kernels.pro. This reduces some complexities.
;
;For checking kernel coverage, this routine requires the full directories to the SPICE kernels loaded. These can be input as a keyword,
;or are loaded automatically within the routine. Timespan must be set for this to happen.
;
;The routine will check whether the SPICE kernels cover each of the requested timestamps, and should gracefully use NaNs if coverage is
;not present. There are two tplot flag variables produced for checking SPICE coverage (see below).
;
;
;INPUTS:
;
;unix_in: double precision UNIX timestamps. Ephemeris data are calculated at these values.
;
;
;KEYWORDS / OUTPUTS:
;spicekernels: if you have already loaded SPICE using kk=mvn_spice_kernels(/load), set spicekernels=kk. If you haven't run SPICE,
;              don't set this keyword, and this routine will run it for you.
;
;Set /qc to use qualcolors (M. Chaffins colorbar software). If not set, routine assumes IDL color table 39. Tplot colors can be changed
;       later by the user as well.
;
;
;The following flag variables are produced showing which timestamps are covered by SPICE (there can sometimes be gaps in the SPICE kernels):
;
;mvn_sta_anc_ck_flag: 0 means MAVEN pointing information is available, 1 means it is not.
;
;mvn_st_anc_spk_flag: 0 means MAVEN position information is available, 1 means it is not.
;
;
;The following keywords produce tplot variable outputs for the requested parameters, at the time steps sent in under "unix_in":
;
;Set /mvn_pos to generate MAVENs position in the MSO frame. The output variable has size [N,4], where N is the same length as unix_in,
;   and the four rows are: X, Y, Z, total. Units of Mars radii.
;   
;Set /mvn_vel to generate MAVENs velocity in the MSO frame. The output variable has size [N,4], where N is the same length as unix_in,
;   and the four rows are: X, Y, Z, total. Note that mvn_pos and mvn_vel are generated from the same SPICE call, so requesting one will also
;   generate the other. Units of km/s.
;   
;Set /mvn_alt to generate MAVENs altitude in the IAU frame. This represents Mars as the flattened ellipsoid. Units of km.
;
;Set /mvn_lonlat to generate MAVENs altitude in east longitude planetary frame. Size is [N,2], where the top row is longitude (0 => 360) and
;   bottom row is latitude (90 (north) => -90 (south)). Units of degrees. This parameter requires pos_mso and vel_mso to also be generated.
;
;Set /mvn_sza to generate MAVEN SZA values, based on its MSO position at Mars. If set, /mvn_pos is also set, to obtain the required data.
;   Calculated SZA are all positive. If you wish to split up dawn versus dusk, use the position tplot variable to find times where Ymso is 
;   negative (dawn) versus positive (dusk).
;   
;Set /mars_ls to generate Mars' Ls value about the Sun. Units of degrees.
;
;
;NOTES:
;1 Mars radius = 3376.km in all conversion carried out here.
;This routine will not clear SPICE kernels from IDL memory after it runs, regardless of whether you set the spicekernels keyword or not.
;
;
;EGS:
;## Generate MAVEN position, without loading in SPICE prior to call:
;timespan, '2017-01-01', 1.
;get_data, 'mvn_sta_c6_E', data=dd   ;get STATIC timestamps
;mvn_sta_anc_ephemeris, dd.x, /mvn_pos   ;generate ephemeris data (routine calls SPICE internally).
;
;## Generate MAVEN position after calling SPICE prior to call:
;timespan, '2017-01-01', 1.
;kk = mvn_spice_kernels(/load)
;get_data, 'mvn_sta_c6_E', data=dd
;mvn_sta_anc_ephemeris, dd.x, spicekernels=kk, /mvn_pos
;
;
;Author: CM Fowler (cmfowler@berkeley.edu). First written 2019-11-08.
;
;-
;

pro mvn_sta_anc_ephemeris, unix_in, spicekernels=spicekernels, success=success, mvn_pos=mvn_pos, mvn_vel=mvn_vel, mvn_alt=mvn_alt, $
                            mvn_lonlat=mvn_lonlat, mars_ls=mars_ls, mvn_sza=mvn_sza, qc=qc

if keyword_set(qc) then begin
  @'qualcolors'
  col_black = qualcolors.black
  col_red = qualcolors.red
  col_green = qualcolors.green
  col_blue = qualcolors.blue
endif else begin  ;assume ct39
  col_black = 0.
  col_red = 254.
  col_green = 150.  ;best guesses
  col_blue = 100.

endelse

if keyword_set(mvn_alt) then mvn_lonlat=1  ;this is required to get alt info
if keyword_set(mvn_lonlat) then mvn_pos=1  ;this is required to get latlon info
if keyword_set(mvn_sza) then mvn_pos=1  ;required for SZA

rname = 'mvn_sta_anc_ephemeris'
sl = path_sep()  ;/ for unix, \ for Windows

;Has SPICE been loaded:
if not keyword_set(spicekernels) then begin
    
    kernels = mvn_sta_anc_determine_spice_kernels()  ;are SPICE kernels loaded?
    
    if kernels.nTOT gt 0 then spicekernels = kernels.kernels else begin
    
        ;if no kernels set, load them:
        ;Check timespan is set - this is needed for getting SPICE.
        get_timespan, tsp
        if size(tsp,/type) eq 0 then begin
            print, ""
            print, rname+": you must set timespan, or set the keyword spicekernels."
            success=0
            return
        endif
        
        spicekernels=mvn_spice_kernels(/load)
    
    endelse
    
endif

;Check whether the times fall within kernel coverage for the SPK files: First find SPK files loaded:
iFI = where(strmatch(spicekernels, '*'+sl+'spk'+sl+'*'), niFI)

if niFI eq 0 then begin
  print, rname+" : I couldn't find any SPICE spk files loaded. Have you set timespan and run spicekernels=mvn_spice_kernels(/load)?"
  success=0
  return
endif

spicekernels2check = spicekernels[iFI]

spkcov = mvn_lpw_anc_covtest(unix_in, spicekernels2check, -202)  
if min(spkcov) eq 1 then spk_coverage = 'all' else begin
  spk_coverage = 'some'
  tmp = where(spkcov eq 0, nTMP)
  if nTMP gt 0. then print, rname+" ### WARNING ###: Position (spk) information not available for ", nTMP, " data point(s)."
endelse
;spkcov is an array nele long. 1 means timestep is covered, 0 means timestep is outside of coverage.
;There is a ck check later on, it requires encoded time so is below:

;=============================
;---- Convert UNIX to UTC ----
;=============================
;Davin's routines all require UTC as input, use Berkeley routines here to convert from UNIX to UTC:
et_time = time_ephemeris(unix_in, /ut2et)  ;convert unix to et

cspice_et2utc, et_time, 'ISOC', 6, utc_time  ;convert et to utc time  ### LSK file needed here ###

;Convert ET times to encoded sclk for use with cspice_ckgp later
cspice_sce2c, -202, et_time, enc_time

;CK check:
nele_in = n_elements(unix_in)
ck_check = fltarr(nele_in)
for aa = 0, nele_in-1 do begin
  cspice_ckgp, -202000, enc_time[aa], 0.0, 'MAVEN_SPACECRAFT', mat1, clk, found
  ck_check[aa] = found  ;0 if coverage exists, 1 if not
endfor
if min(ck_check) eq 1 then ck_coverage = 'all' else begin
  ck_coverage = 'some'
  tmp = where(ck_check eq 0., nTMP)
  if nTMP gt 0. then print, rname+" ### WARNING ###: Pointing information (ck) not available for ", nTMP, " data point(s)."
endelse

;Coverage checks: 0 if covered by SPICE, 1 if there's a flag (ie not covered).
ck_flag = ck_check ne 1
spk_flag  = spkcov ne 1
store_data, 'mvn_sta_anc_ck_flag', data={x:unix_in, y:ck_flag} ;, dlimit=dl_ck
  ylim, 'mvn_sta_anc_ck_flag', -1, 2
  options, 'mvn_sta_anc_ck_flag', ytitle='CK flag'
store_data, 'mvn_sta_anc_spk_flag', data={x:unix_in, y:spk_flag} ;, dlimit=dl_spk
  ylim, 'mvn_sta_anc_spk_flag', -1 , 2
  options, 'mvn_sta_anc_spk_flag', ytitle='SPK flag'


;==========
;VARIABLES:
;==========
;MAVEN position and velocity in MSO frames: these come from the same SPICE call:
if keyword_set(mvn_pos) or keyword_set(mvn_vel) then begin
    ;General info:
    frame    = 'MAVEN_MSO'
    frame2   = 'IAU_MARS'
    abcorr   = 'LT+S'
    observer = 'Mars'
    target = 'MAVEN'
    
    ;if (spk_coverage eq 'all') and (ck_coverage eq 'all') then stateezr = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin  ;DAVINS ROUTINE
    if (spk_coverage eq 'all') then begin  ;and (ck_coverage eq 'all') then begin
      cspice_spkezr, target, et_time, frame, abcorr, observer, stateezr, ltime ;state contains R and V [0:5], USE FOR NOW UNTIL DAVIN ADDS VEL TO HIS ABOVE
      cspice_spkezr, target, et_time, frame2, abcorr, observer, stateezr2, ltime  ;contains R and V in the IAU_MARS frame
    endif else begin
      stateezr = dblarr(6,nele_in)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
      stateezr2 = dblarr(6,nele_in)
      for aa = 0, nele_in-1 do begin  ;do each time point individually
        ;if (spkcov[aa] eq 1) and (ck_check[aa] eq 1) then state_temp = spice_body_pos(target, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr) else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]  ;DAVINS
        if (spkcov[aa] eq 1) then cspice_spkezr, target, et_time[aa], frame, abcorr, observer, state_temp, ltime else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]  ;USE THIS FOR NOW UNTIL DAVINS HAS VEL
        if (spkcov[aa] eq 1) then cspice_spkezr, target, et_time[aa], frame2, abcorr, observer, state_temp2, ltime else state_temp2=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]  ;USE THIS FOR NOW UNTIL DAVINS HAS VEL

        ;if we don't have coverage, use nans instead
        stateezr[0,aa] = state_temp[0]  ;add time step to overall array
        stateezr[1,aa] = state_temp[1]
        stateezr[2,aa] = state_temp[2]
        stateezr[3,aa] = state_temp[3]  ;vel
        stateezr[4,aa] = state_temp[4]
        stateezr[5,aa] = state_temp[5]
        
        stateezr2[0,aa] = state_temp2[0]  ;iau
        stateezr2[1,aa] = state_temp2[1]
        stateezr2[2,aa] = state_temp2[2]
        stateezr2[3,aa] = state_temp2[3]  ;vel
        stateezr2[4,aa] = state_temp2[4]
        stateezr2[5,aa] = state_temp2[5]
    
      endfor
    endelse
    
    mvn_pos_mso = dblarr(nele_in,4)  ;x,y,z,total (4 rows)
    mvn_vel_mso = dblarr(nele_in,4)
    mvn_pos_iau = dblarr(nele_in,4)  ;x,y,z,total (4 rows)
    mvn_vel_iau = dblarr(nele_in,4)
    
    Rmars = 3376.0d ;Mars radius, km
    
    mvn_pos_mso[*,0] = stateezr[0,*]/Rmars  ;positions in Rmars
    mvn_pos_mso[*,1] = stateezr[1,*]/Rmars  ;positions in Rmars
    mvn_pos_mso[*,2] = stateezr[2,*]/Rmars  ;positions in Rmars
    mvn_pos_mso[*,3] = sqrt(mvn_pos_mso[*,0]^2 + mvn_pos_mso[*,1]^2 + mvn_pos_mso[*,2]^2)  ;total radius
    mvn_vel_mso[*,0] = stateezr[3,*]  ;velocities in km/s
    mvn_vel_mso[*,1] = stateezr[4,*]  ;velocities in km/s
    mvn_vel_mso[*,2] = stateezr[5,*]  ;velocities in km/s
    mvn_vel_mso[*,3] = sqrt(mvn_vel_mso[*,0]^2 + mvn_vel_mso[*,1]^2 + mvn_vel_mso[*,2]^2)  ;total vel, km/s
    
    mvn_pos_iau[*,0] = stateezr2[0,*]/Rmars  ;positions in Rmars
    mvn_pos_iau[*,1] = stateezr2[1,*]/Rmars  ;positions in Rmars
    mvn_pos_iau[*,2] = stateezr2[2,*]/Rmars  ;positions in Rmars
    mvn_pos_iau[*,3] = sqrt(mvn_pos_iau[*,0]^2 + mvn_pos_iau[*,1]^2 + mvn_pos_iau[*,2]^2)  ;total radius
    mvn_vel_iau[*,0] = stateezr2[3,*]  ;velocities in km/s
    mvn_vel_iau[*,1] = stateezr2[4,*]  ;velocities in km/s
    mvn_vel_iau[*,2] = stateezr2[5,*]  ;velocities in km/s
    mvn_vel_iau[*,3] = sqrt(mvn_vel_iau[*,0]^2 + mvn_vel_iau[*,1]^2 + mvn_vel_iau[*,2]^2)  ;total vel, km/s
    mvn_pos_iau_cp = stateezr2[0:2,*]  ;copy for getting lon+lat, later on

    ;STORE:  
    store_data, 'mvn_sta_anc_mvn_pos_mso', data={x:unix_in, y:mvn_pos_mso}
      options, 'mvn_sta_anc_mvn_pos_mso', 'Rmars2km', 3376.
      options, 'mvn_sta_anc_mvn_pos_mso', colors=[col_blue, col_green, col_red, col_black]
      options, 'mvn_sta_anc_mvn_pos_mso', labflag=1
      options, 'mvn_sta_anc_mvn_pos_mso', labels=['X', 'Y [MSO]', 'Z', 'TOT']
      options, 'mvn_sta_anc_mvn_pos_mso', ytitle='MVN pos'
      
    store_data, 'mvn_sta_anc_mvn_vel_mso', data={x:unix_in, y:mvn_vel_mso}
      options, 'mvn_sta_anc_mvn_vel_mso', colors=[col_blue, col_green, col_red, col_black]
      options, 'mvn_sta_anc_mvn_vel_mso', labflag=1
      options, 'mvn_sta_anc_mvn_vel_mso', labels=['X', 'Y [MSO]', 'Z', 'TOT']
      options, 'mvn_sta_anc_mvn_vel_mso', ytitle='MVN vel'
    
    if keyword_set(mvn_sza) then begin
     
        rad = sqrt(mvn_pos_mso[*,1]^2 + mvn_pos_mso[*,2]^2)

        sza1 = atan(rad, mvn_pos_mso[*,0]) * 180./!pi
  
        store_data, 'mvn_sta_anc_mvn_sza', data={x: unix_in, y: sza1}
          options, 'mvn_sta_anc_mvn_sza', ytitle='MVN SZA'
          ylim, 'mvn_sta_anc_mvn_sza', 0, 180

    endif
   
endif   

;==================
;Ls value for Mars:
;==================
if keyword_set(mars_ls) then begin
    LsMars = fltarr(nele_in)
    
    for aa = 0, nele_in-1 do begin  ;do each time point individually
      if (spkcov[aa] eq 1) then LsMars[aa] = CSPICE_LSPCN('MARS',et_time[aa],'NONE') else LsMars[aa] = !values.f_nan
    endfor
    ;endelse
    
    LsMars = LsMars * 180./!pi  ;convert to degrees
    store_data, 'mvn_sta_anc_mars_ls', data={x:unix_in, y:LsMars}
      options, 'mvn_sta_anc_mars_ls', ytitle='Mars L!Ds!N'
endif


;========================================================
;Longitude, Latitude, Altitude, based on geodetic coords:
;========================================================
if keyword_set(mvn_lonlat) then begin
    ;Mars is not a sphere therefore the altitudes calculated above are off by upto ~20 km.
    ;Check we have radius information about Mars:
    found = cspice_bodfnd( 499, "RADII" )
    
    if (found) then begin
      cspice_bodvrd, 'MARS', "RADII", 499, radii
      flat = (RADII[0] - RADII[2])/RADII[0]  ;flattening coefficient between polar and equatorial radii.
    
      cspice_recgeo, mvn_pos_iau_cp, radii[0], flat, lon, lat, alt   ;mvn_pos_iau is 3XN matrix of position. THIS GIVES CORRECT ALTITUDE BUT NOT EAST LON-LAT!!
    
      alt_iau = alt
    
      ;Calculate east lon-lat correctly! Convert MSO cartesian to IAU_Mars frame using cspice_pxform, then get long lat (from spherical).
      cspice_pxform, 'MAVEN_MSO', 'IAU_MARS', et_time, rotate  ;rotate contains the rotation matrix to go from MAVEN_MSO to IAU_MARS.
      ;rotate is 3x3xN, where N is number of time steps
    
      pos_IAU = fltarr(3, nele_in)  ;store position in IAUmars frame
      get_data, 'mvn_sta_anc_mvn_pos_mso', data=ddMSO
    
      for tp = 0., nele_in-1. do begin
        cspice_mxv, rotate[*,*,tp], transpose(ddMSO.y[tp,0:2]), iauTMP   ;rotate into new frame
        pos_IAU[*,tp] = iauTMP  ;store rotated position
      endfor
    
      ;Convert cartesian to spherical (lon-lat):
      rIAU = sqrt(pos_IAU[0,*]^2 + pos_IAU[1,*]^2 + pos_IAU[2,*]^2)
      phi = acos(pos_IAU[2,*]/rIAU) * (180./!pi)  ;0 is in +Z direction, adjust:
      phi2=90.-phi   ;this is now latitude +90 => -90
    
      theta = atan(pos_IAU[1,*], pos_IAU[0,*]) * (180./!pi)  ;this should also be east longitude, NOTE: whenr you give atan() two arguments it does the sectors correctly.
      iTMP = where(theta lt 0., niTMP)  ;range is -180=>180, negative values go to 180-360
      if niTMP gt 0. then theta[iTMP] = 360. + theta[iTMP]  ;negative means values subtract
    
      longlat = [[transpose(theta)], [transpose(phi2)]]
    
      ;Store data:
      store_data, 'mvn_sta_anc_mvn_longlat_iau', data={x:unix_in, y:longlat}
        options, 'mvn_sta_anc_mvn_longlat_iau', labels=['LON', 'LAT']
        options, 'mvn_sta_anc_mvn_longlat_iau', labflag=1
        options, 'mvn_sta_anc_mvn_longlat_iau', colors=[col_black, col_blue]
        options, 'mvn_sta_anc_mvn_longlat_iau', ytitle='MVN lon-lat'
        options, 'mvn_sta_anc_mvn_longlat_iau', ysubtitle='[degrees]'
        
      store_data, 'mvn_sta_anc_mvn_alt_iau', data={x:unix_in, y:alt_iau}
        options, 'mvn_sta_anc_mvn_alt_iau', ytitle='MVN alt'
        options, 'mvn_sta_anc_mvn_alt_iau', ysubtitle='[km, IAU]'

    endif
endif


end


