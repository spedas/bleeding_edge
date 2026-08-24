;+
;STATIC L3 processing software. Routine loads in the tplot save file output from mvn_sta_l3_den.pro. Using the various tplot
;flags, this routine will create a final y/n flag for each data point. This routine saves the following variables into a 
;"L3 science file":
; - mvn_sta_l3_density (density for the 5 main species)
; - mvn_sta_l3_density_uncertainty (statistical uncertainty of 5 main species - units of absolute density)
; - mvn_sta_l3_flag (flags for the 5 main species)
;
;This routine will create the following save files in the same directories as the input tplot save files:
; mvn_sta_l3_den_yyyymmdd_v##.tplot
; 
;Where v## is the same version number as the input save file.
;
;
;INPUTS:
;dfile_version, tfile_version: string: eg "01", "02". The version number of files that should be processed by this routine. Can be 
;                              different for density (dfile) and temperature (tfile).
;                              If these are not set, then that variable will not be processed.
;
;KEYWORDS:
;testfile: string: full directory and filename to load instead of the default location. This is used primarily for testing.
;
;nodelete: by default this routine will delete all tplot variables, and then load in the specified file, before processing. Set /nodelete to not 
;   delete all tplot files.
;
;NOTES:
;Several criteria are already applied in the derivation software. This routine takes into account the following thresholds and 
;criteria when producing the final quality flag:
; - (counts - bkg) > min threshold.
; 
;In addition, densities are removed for specific conditions when derived values are known to be incorrect:
; - At periapsis when attenuator state >=2 (ie the mechanical attenuator is in) and when STATIC does not point
;   nominally (APP i vector lies in the spacecraft ram direction). This happens during high densities, so always on the dayside, and
;   at times on the nightside. This is because the calibration for high density cases (to account for ion suppression, etc) only works
;   when STATIC points in the correct orientation.
;   
; - Currently (07/27/2021) CO2+ densities derived using n_4d() are removed. This happens outside of the dense ionosphere (typically
;   pick CO2+ at higher altitudes). This is because the O2+ tail can swamp the CO2+ mass peak, and this has not been corrected for at 
;   higher altitudes (a specific energy table makes this feasible at high densities; this may be correctable in the future).
;
; - As of 2021-11-03, tplot_restore will crash if you try to append tplot save files that have common variable names (eg loading multiple
;   days of data). To fix this, a second routine will be added to the processing cron job that will load in the data files affected, 
;   split the variable 'mvn_sta_c6_att_mode' apart into its components mvn_sta_c6_att and mvn_sta_c6_mode, and remove the joint variable from
;   the data file.
;
;PLOTTING NOTES:
; - Some ytitle labels for tplot variables can extend outside of the plot window. To adjust this, use the tplot_options command:
;     e.g.
;     tplot_options, 'xmargin', [16,8] (16 is for the spacing on the left; 8 on the right)
;     tplot_options, 'ymargin', [4,2] (4 is spacing on the bottom; 2 at the top)
;
;EDITS:
;2024-11-15: CMF added code to get ion suppression constants, so that they can be used to generate a quality flag here.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_generate_science_files.pro  ;for testing only
;-
;

pro mvn_sta_l3_generate_science_files, dfile_version=dfile_version, tfile_version=tfile_version, testfile=testfile, success=success, nodelete=nodelete

proname = 'mvn_sta_l3_generate_science_files'

;If versions not set, don't process them:
if size(dfile_version,/type) eq 0 then den=0 else den=1
if size(tfile_version,/type) eq 0 then temp=0 else temp=1

success=0

basedir = '/disks/data/maven/data/sci/sta/l3/'
dendir = basedir+'density/'
tempdir = basedir+'temperature/'

common mvn_sta_kk3_anode,kk3_anode

;########
;DENSITY:
;Find files to work on:
if den eq 1 then begin
    dfiletmp = 'mvn_sta_l3_den_????????_full_v'+dfile_version+'.tplot'
    files_den = file_search(dendir, dfiletmp, count=nfiles_den)  ;search recursively through year and month subfolders.
    
    ;THRESHOLDS:
    min_cnts = 5.  ;must have this many counts
    ramang = 10.  ;angle between APP i and sc ram direction must be less than this (in degrees). Accounts for rover comm orbits and off pointing.
    ramang = 20.  ;new test value - this should allow densities to be derived during NGIMS wind scans still. Off pointing by this much will still
                  ;within the main ram anodes (+-1 either side) and within the deflectors (+-45 degrees at low energies). 
    bco2 = 1  ;beam co2: if =1, only use CO2+ densities obtained in beam mode. If =0, use CO2+ densities from beam and n_4d. This is currently
              ;set to 1, because only RAM anode has been calibrated for now (07/27/2021). This could be fixed at some point...
    ramalt = 500.  ;km, only care about whether STATIC is pointing ram below this altitude. On a few rare occasions (eg 2017-10-25) the
                   ;attenuator was left in at high altitudes, but we still want to use n_4d() here, even though we don't point ram.
    
    if keyword_set(testfile) then begin
        files_den = testfile
        nfiles_den=1
    endif
    
    if nfiles_den gt 0 then begin
        
        ;Go over each file:
        for ff = 0l, nfiles_den-1l do begin 
            if not keyword_set(nodelete) then store_data, '*', /delete
            
            fullvars = tnames() ;get a list of tplot variables loaded from the full variable
            
            tplot_restore, filename=files_den[ff]
            
            ;Keep all of these variables  - do not overwrite them:
            get_data, 'mvn_sta_density_prelim_2', data=dd1, dlimit=dl1, limit=ll1 
            get_data, 'mvn_sta_l3_density_heavy_method', data=dd2, dlimit=dl2, limit=ll2 
            get_data, 'mvn_sta_den_uncert', data=dd3, dlimit=dl3, limit=ll3 
            get_data, 'mvn_sta_den_uncert_perc', data=dd4, dlimit=dl4, limit=ll4
            get_data, 'mvn_sta_l3_density_light_method', data=dd5, dlimit=dl5, limit=ll5 
            get_data, 'mvn_sta_c6_mode', data=ddstamode
            get_data, 'mvn_sta_c6_cb_scpot', data=ddscpot
            
              ;Get spiceloaded and parent_files, which will be added to all output tplot variables, under the limits structure:
              spiceloaded = ll1.spiceloaded
              parent_files = ll1.parent_files
              
              if size(spiceloaded,/type) eq 8 then begin
                  print, proname, ": spiceloaded is empty!"
                  spiceloaded = ''
              endif
              if size(parent_files,/type) eq 8 then begin
                  print, proname, ": parent_files is empty!"
                  parent_files = ''
              endif
                        
            neleT = n_elements(dd1.x)  ;number of data points in this file.
            
            ;Flags to work:
            ;counts - bkg > min threshold
            ;at periapsis, spacecraft pointed at ram  
    
            ;Do we want to include:
            ;When nadir direction is within STA fov?
            ;When sc is likely in sw?
                        
            ;For any flag, a value of 0 means ok, a value of 1 means bad:        
            ;=======================
            ;---Counts threshold---:
            ;=======================
            ;Two criteria must be met: (1) counts > min threshold; (2) (counts - bkg) must be statistically significant.
            ;There are two types of tplot variable: "_all" is for the full energy range, while those without that are for the nbc beam
            ;method, energies [0,11] eV. H+ and He++ are always _all, while O+, O2+ and CO2+ transition between the two. Use the 
            ;heavy_method tplot variable to determine which type to use at each timestep.
            ;all:
            get_data, 'mvn_sta_h+_c6_all_cnts', data=ddhcnts_all  ;these are all the same length (c6), and the same length as the L3 tplot variables above
            get_data, 'mvn_sta_h+_c6_all_bkg', data=ddhbkg_all
            get_data, 'mvn_sta_he++_c6_all_cnts', data=ddhecnts_all
            get_data, 'mvn_sta_he++_c6_all_bkg', data=ddhebkg_all
            get_data, 'mvn_sta_o+_c6_all_cnts', data=ddocnts_all
            get_data, 'mvn_sta_o+_c6_all_bkg', data=ddobkg_all
            get_data, 'mvn_sta_o2+_c6_all_cnts', data=ddo2cnts_all
            get_data, 'mvn_sta_o2+_c6_all_bkg', data=ddo2bkg_all
            
            ;nbc:
            get_data, 'mvn_sta_o+_c6_cnts', data=ddocnts    ;O and O2 are the same length as those above, but CO2 can be different length - fix below
            get_data, 'mvn_sta_o+_c6_bkg', data=ddobkg
            get_data, 'mvn_sta_o2+_c6_cnts', data=ddo2cnts
            get_data, 'mvn_sta_o2+_c6_bkg', data=ddo2bkg                     
            get_data, 'mvn_sta_co2+_c6_cnts', data=ddco2cnts, dlimit=dlcnts, limit=llcnts
            get_data, 'mvn_sta_co2+_c6_bkg', data=ddco2bkg, dlimit=dlbkg, limit=llbkg
            
            ;The CO2+ array is not always the same size as the other mass arrays (due to how CO2+ cnts are obtained).
            ;Map the CO2+ array onto the other time arrays:
            nele1 = n_elements(ddhcnts_all.x) ;same for H+, He+, O+, O2+
            nele2 = n_elements(ddco2cnts.x)  ;beam method 
            if nele1 ne nele2 then begin
                cntsnew = fltarr(nele1)  ;new arrays for CO2+
                bkgnew = fltarr(nele1)
                for tt = 0l, nele1-1l do begin
                  diff = abs(ddhcnts_all.x[tt] - ddco2cnts.x)
                  m1 = min(diff, imin, /nan)
                  if m1 lt 1. then begin
                      cntsnew[tt] = ddco2cnts.y[imin]  ;add cnts and bkg to new array if times match
                      bkgnew[tt] = ddco2bkg.y[imin]
                  endif             
                endfor
                
                ;Re-save this tplot variable:
                store_data, 'mvn_sta_co2+_c6_cnts', data={x: ddhcnts_all.x, y: cntsnew}, dlimit=dlcnts, limit=llcnts
                store_data, 'mvn_sta_co2+_c6_bkg', data={x: ddhcnts_all.x, y: bkgnew}, dlimit=dlbkg, limit=llbkg
                
                get_data, 'mvn_sta_co2+_c6_cnts', data=ddco2cnts ;grab updated arrays
                get_data, 'mvn_sta_co2+_c6_bkg', data=ddco2bkg
            endif
            
            ;For heavies, when calculating count thresholds, take into account whether high altitude (method=0) or beam (method>0) were used:
            ;(1) counts-bkg > min_cnts      
            hcntflag1 = ((ddhcnts_all.y - ddhbkg_all.y) lt min_cnts)  ;0=ok (counts >= min_cnts), 1=bad (counts < min_cnts)
            hecntflag1 = ((ddhecnts_all.y - ddhebkg_all.y) lt min_cnts) ;note the lt to get the logic correct
            ;Take into account whether high altitude or beam method used for heavies. Note, heavy method variable contains only O+, O2+, CO2+
            ocntflag1 = (((ddocnts.y - ddobkg.y) lt min_cnts) * (dd2.y[*,0] gt 0)) + (((ddocnts_all.y - ddobkg_all.y) lt min_cnts) * (dd2.y[*,0] eq 0))
            o2cntflag1 = (((ddo2cnts.y - ddo2bkg.y) lt min_cnts) * (dd2.y[*,1] gt 0)) + (((ddo2cnts_all.y - ddo2bkg_all.y) lt min_cnts) * (dd2.y[*,1] eq 0)) 
            co2cntflag1 = (((ddco2cnts.y - ddco2bkg.y) lt min_cnts) * (dd2.y[*,2] gt 0)) ;high alt method not valid for CO2 yet; + (((ddco2cnts_all.y - ddco2bkg_all.y) lt min_cnts) * (dd2.y[*,2] eq 0))       
            
            ;(2) (counts-bkg) statisitcally significant: err = sqrt(cnts), cnts-bkg > err
            hcntflag2 = ((ddhcnts_all.y - ddhbkg_all.y) lt sqrt(ddhcnts_all.y))
            hecntflag2 = ((ddhecnts_all.y - ddhebkg_all.y) lt sqrt(ddhecnts_all.y))
            ;beam method:
            ocntflag2 = (((ddocnts.y - ddobkg.y) lt sqrt(ddocnts.y)) * (dd2.y[*,0] gt 0)) + (((ddocnts_all.y - ddobkg_all.y) lt sqrt(ddocnts_all.y)) * (dd2.y[*,0] eq 0))
            o2cntflag2 = (((ddo2cnts.y - ddo2bkg.y) lt sqrt(ddo2cnts.y)) * (dd2.y[*,1] gt 0)) + (((ddo2cnts_all.y - ddo2bkg_all.y) lt sqrt(ddo2cnts_all.y)) * (dd2.y[*,1] eq 0))
            co2cntflag2 = (((ddco2cnts.y - ddco2bkg.y) lt sqrt(ddco2cnts.y)) * (dd2.y[*,2] gt 0)) ;high alt method not valid for CO2 yet; + (((ddco2cnts_all.y - ddco2bkg_all.y) lt sqrt(ddco2cnts_all.y)) * (dd2.y[*,2] eq 0))

            ;==========================================
            ;Remove at periapsis for off ram direction:
            ;==========================================
            ;2025-07-15: updates to code; the stitch code will now only use ram if the peak energy is below a threshold,
            ;most of the energy flux lies within the 3 anode bins centered on the peak anode, and either (a) attenuator =<1
            ;or (b) att >=2 and the peak eflux lies in anode 6, 7 or 8. This should remove the dependence on ramalt (which did 
            ;not always work).
            ;-> So now, still keep ramflag, which flags when the ram angle is >10 degrees, but the code should no
            ;longer have tried to use beam mode during these times. Below, now only remove data when in mode 6 (protect).
            ;
            ;Do this when attenuator state >=2. Ramangle is at 10 s cadence, so interpolate to required timestamps.
            get_data, 'mvn_sta_ramdir_angle', data=ddramangle
            get_data, 'mvn_sta_c6_att', data=ddatt ;for every timestamp on this day
            get_data, 'mvn_sta_anc_mvn_alt_iau', data=ddalt  ;just for times requested on this day (if tramge set)
            get_data, 'mvn_sta_c6_mode', data=ddmode  ;during comm passes, mode=6, don't use these times either (no low energy)
            ;Att variable is for the whole day by default, so check this in case trange keyword was used to create file:
            iKP1 = where(ddatt.x ge dd1.x[0] and ddatt.x le dd1.x[neleT-1l], niKP1)   
            if niKP1 eq 0 then return ;this should never happen
            
            ramangle_interp = interpol(ddramangle.y, ddramangle.x, dd1.x)
            
            tname = 'mvn_sta_l3_ram_angle_interp'
            store_data, tname, data={x: dd1.x, y: ramangle_interp}
              options, tname, ytitle='ram angle!Cinterp'
            
            ;Old way, didn't always work (2025-07-15)
            ;itmp = where((ramangle_interp gt ramang and ddatt.y[iKP1] ge 2 and ddalt.y lt ramalt) or $
            ;                (ddmode.y[iKP1] eq 6), nitmp)  ;find times when mechanical attenuator in, and ram angle off nominal
            
            iramflag = where(ramangle_interp gt ramang, niramflag) ;when ram angle >10, throughout whole orbit
            imode6 = where((ddmode.y[iKP1] eq 6), nimode6)  ;find times when in protect mode

            ramflag = fltarr(neleT)
            if niramflag gt 0 then ramflag[iramflag] = 1  ;keep flag for overall flag
            
            if nimode6 gt 0 then begin
              dd1.y[imode6,*] = 0.  ;set densities and uncertainty to zero.
              dd3.y[imode6,*] = 0.
              dd4.y[imode6,*] = 0.
            endif
            
            ;============================================
            ;Remove at periapsis for poor sc orientation:
            ;============================================
            ;MAVENs orientation through periapsis determines how severe spacecraft charging is. Most of the time MAVEN flies optimially
            ;and this isn't a problem. Sometimes the spacecraft must fly in an off-optimum orientation, which can lead to severe
            ;spacecraft charging (<-8 V). When this happens, and STATIC is in mode 7, STATICs highest energy (10ev) cannot observe the ionospheric
            ;ions which have been accelerated by the spacecraft potential to >10 eV. Remove data from these times.
            ;Use the variable mvn_att_bar, which contains numbers describing MAVENs pointing: 
            ;Sun point (8), Earth point (3), Fly +/-Y (4.85), Fly -Z (10.), Fly +Z (1.4).
            ;Sun and Earth point are not typically used during periapsis, but if so, could result in severe spacecraft charging, depending on 
            ;where the Sun and Earth are with respect to MAVENs ram direction.
            ;Fly +Z is always very bad for spacecraft charging.
            ;Fly +-Y and -Z are good for spacecraft charging. 
            ;
            ;Criteria: if attitude =/= (Fly +-Y or Fly -Z), and STATIC mode = 7, do not use these points.
            get_data, 'mvn_att_bar', data=ddbar
            attflag = fltarr(neleT)
            ;Interpolate attitude info to STATIC timestamps. Attitude is at 1s cadence, starting at 00:00:00. There are NaNs in between segments
            ;when MAVEN is presumably slewing. The intrpolate seems to work fine.
            attitude_interp = interpol(ddbar.y[*,0], ddbar.x, dd1.x)
            ;Find times to flag as bad. First, find STATIC modes, which are returned for the full day and are not limited by trange (shouldn't
            ;usually be a problem, just when testing on limited time ranges):
            tmin = min(dd1.x,/nan)
            tmax = max(dd1.x,/nan)
            iSTA = where(ddstamode.x ge tmin and ddstamode.x le tmax, niSTA)
                   
            iATT = where((attitude_interp ne 4.85 and attitude_interp ne 10) and (ddstamode.y[iSTA] eq 7), niATT)
            if niATT gt 0 then attflag[iATT] = 1
            
            ;====================
            ;Remove large sc pot:
            ;====================
            ;Based on looking at eg 2020-02-17, when the sc potential goes below -5V, STATIC density drops and doesn't appear accurate. 
            scpotflag = fltarr(neleT)
            iscp = where(ddscpot.y lt -5., niscp)
            if niscp gt 0 then scpotflag[iscp] = 1
                       
            ;=======================
            ;Remove CO2 from n_4d():
            ;=======================
            bco2_flag = fltarr(neleT)
            if bco2 eq 1 then begin    ;Only use beam values:
                  itmp = where(dd2.y[*,2] eq 0, nitmp)  ;find the locations where CO2 was obtained by n_4d()
                  if nitmp gt 0 then begin  ;Set density and uncertainty to zero:
                      dd1.y[itmp,4] = 0. 
                      dd3.y[itmp,4] = 0.
                      dd4.y[itmp,4] = 0.  
                      
                      bco2_flag[itmp] = 1 ;record where this happened                   
                  endif
            endif
            
            ;=====================
            ;Ion suppression flag:
            ;=====================
            ;Get these for the date range:
            trange = [min(dd1.x), max(dd1.x)]
            timespan, trange  ;needed for get-kk3 below: it is checked in get-kk3, but I don't think it actually does anything           
            kk3_anode=1
            kk3=mvn_sta_get_kk3((trange[0]+trange[1])/2.) ;needed to get ion suppression values
           
            ;kk3_string = strmid(string(round(kk3[0]*10.)/10.),6,3)+'-'+strmid(string(round(kk3[1]*10.)/10.),6,3)+'-'+strmid(string(round(kk3[2]*10.)/10.),6,3)+'-'+strmid(string(round(kk3[3]*10.)/10.),6,3)
            ;kk=kk3_string ;not sure which element to compare with

            ;Assume sc velocity of 4.2 km/s, calculate (ram velocity + scpot) for O2+, and this is energy. Then, corr = exp((kk4/energy)^2). In nbc_4d, 
            ;corr_max =< 30 in nbc_4d, but Jim and Gwen suggest using 10 here. So, when this value = 10 here, set the flag to 1 to denote bad ion suppression (large correction factor needed).            
            IonSuppressionFlag = fltarr(neleT,5) ;For each ion.
            ;IonSuppressionValue = fltarr(neleT) ;made below, the ion suppression value at each timestamp, for that specific attenuator state
            
            get_data, 'mvn_sta_c6_att', data=ddatt
            
            ;If using trange, timestamps are less than full attenuator variable:
            tKP = where(ddatt.x ge min(dd1.x) and ddatt.x le max(dd1.x), ntKP)           
            if ntKP ne neleT then stop ;this should never happen - CMF needs to write a catch if it ever does...
            
            IonSuppressionConstant = kk3[ddatt.y[tKP]]  ;the att state (0-3) determines which kk3 value at each timestamp
            
            ;Energy of O2+ (ram + scpot), assuming ram vel = 4.2 km/s. 
            scvel = 4.2*1E3  ;m/s
            mp = 1.67E-27 ;proton mass, kg
            qq = 1.6E-19  ;e charge
            get_data, 'mvn_sta_c6_cb_scpot', data=ddscpot  ;same size as dd1
            
            ;ram+Scp energy for the 5 ion amu/q:
            hp_energy = ((0.5*1*mp*scvel*scvel)/qq)   +   ((-1.)*ddscpot.y)  ;multiply scp by -1, this is so when scp <0 (acelerates ions to sc), the measured energy is larger
            he2p_energy = ((0.5*2*mp*scvel*scvel)/qq)   +   ((-1.)*ddscpot.y)  ;multiply scp by -1, this is so when scp <0 (acelerates ions to sc), the measured energy is larger
            op_energy = ((0.5*16*mp*scvel*scvel)/qq)   +   ((-1.)*ddscpot.y)  ;multiply scp by -1, this is so when scp <0 (acelerates ions to sc), the measured energy is larger
            o2p_energy = ((0.5*32*mp*scvel*scvel)/qq)   +   ((-1.)*ddscpot.y)  
            co2p_energy = ((0.5*44*mp*scvel*scvel)/qq)   +   ((-1.)*ddscpot.y)

            corr_1 = exp((IonSuppressionConstant/hp_energy)^2)  ;corresponding correction factor for each ion amu/q
            corr_2 = exp((IonSuppressionConstant/he2p_energy)^2)
            corr_16 = exp((IonSuppressionConstant/op_energy)^2)
            corr_32 = exp((IonSuppressionConstant/o2p_energy)^2)
            corr_44 = exp((IonSuppressionConstant/co2p_energy)^2)
            
            ;Ion suppression only affects low energy ions. But, we can't use peak energy of c6, for example, because if suppression is large,
            ;STATIC won't see the ions, so there won't be a peak..! I think, we set the flag when altitude<500. This will mean that if
            ;ion suppression is bad at periapsis, we will likely end up ignoring the full pass, and that's probably the safest thing to do.
            get_data, 'mvn_sta_anc_mvn_alt_iau', data=ddalt  ;this is at same time cadence as dd1.x
            
            ;*** MAKE THE ION SUPPRESSION FLAG***
            corr_max = 10.  ;max value allowed, above this, corrections are deemed too large
            corr_max_alt = 500.  ;km, only apply ion suppression flag below this altitude
            ;Find flag times for each ion species amu/q. By default, H+ set to zero, as can enter from all directions and not suppressed as much
            
            ;H+
            ;is_flag_1 = where(corr_1 ge corr_max and ddalt.y lt corr_max_alt, nis_flag_1) 
            ;if nis_flag_1 gt 1 then IonSuppressionFlag[is_flag_1,0] = 1.  ;flag when corr is large and altitude < 500 km.
            
            ;He++ (amu/q=2)
            ;is_flag_2 = where(corr_2 ge corr_max and ddalt.y lt corr_max_alt, nis_flag_2)  
            ;if nis_flag_2 gt 1 then IonSuppressionFlag[is_flag_2,1] = 1.
            
            ;O+ 
            is_flag_16 = where(corr_16 ge corr_max and ddalt.y lt corr_max_alt, nis_flag_16)  
            if nis_flag_16 gt 1 then IonSuppressionFlag[is_flag_16,2] = 1.
            
            ;O2+
            is_flag_32 = where(corr_32 ge corr_max and ddalt.y lt corr_max_alt, nis_flag_32)
            if nis_flag_32 gt 1 then IonSuppressionFlag[is_flag_32,3] = 1.
            
            ;CO2+
            is_flag_44 = where(corr_44 ge corr_max and ddalt.y lt corr_max_alt, nis_flag_44)
            if nis_flag_44 gt 1 then IonSuppressionFlag[is_flag_44,4] = 1.
     
            ;==================
            ;Derive final flag:
            ;==================
            ;Do for each ion species, as count flag is species dependent.
            ;Sometimes, hcntflag1 and flag2 can be one timestamp less than the ram and att flags. Not sure why - I think this
            ;only happens when using the trange keyword.
            ;Check if this is the case. Quick dirty fix - we are using dd1 as the "main" variable here (the preliminary density). This 
            ;is at the same cadence as ram and att flags, so we will assume that these are correct. When the cnt arrays are off by 1,
            ;add an extra point to the start or end of the arrays to make them the same length. This shouldn't make a difference as this
            ;error only occurs sometimes when using trange, and people should not be using data at the edge of the time selected.
            ;Make the added flag values 1 (don't use), to be safe.
            neleCT = n_elements(hcntflag1)
            if neleCT ne neleT then begin
                ;dd1.x are the timestamps for ram and att flags; ddhcnts_all.x are the timestamps for the cnt flags.
                ;This should just be the case that there's an extra timestamp added on at the start or end of one of the arrays,
                ;so search for this and remove:
                ;Add an element to cnt flags:
                if neleCT lt neleT then begin
                    ;Add an element to cnt arrays:
                    if (dd1.x[0] - ddhcnts_All.x[0]) le -1.d then begin
                        ;add an element to the start of flag arrays:
                        hcntflag1 = [1., hcntflag1]
                        hcntflag2 = [1., hcntflag2]
                        hecntflag1 = [1., hecntflag1]
                        hecntflag2 = [1., hecntflag2]
                        ocntflag1 = [1., ocntflag1]
                        ocntflag2 = [1., ocntflag2]
                        o2cntflag1 = [1., o2cntflag1]
                        o2cntflag2 = [1., o2cntflag2]
                        co2cntflag1 = [1., co2cntflag1]
                        co2cntflag2 = [1., co2cntflag2]
                    endif
                    
                    if (dd1.x[neleT-1l] - ddhcnts_All.x[neleCT-1l]) gt 1.d then begin
                        ;add an element to the end of the flag arrays:
                        hcntflag1 = [hcntflag1, 1.]
                        hcntflag2 = [hcntflag2, 1.]
                        hecntflag1 = [hecntflag1, 1.]
                        hecntflag2 = [hecntflag2, 1.]
                        ocntflag1 = [ocntflag1, 1.]
                        ocntflag2 = [ocntflag2, 1.]
                        o2cntflag1 = [o2cntflag1, 1.]
                        o2cntflag2 = [o2cntflag2, 1.]
                        co2cntflag1 = [co2cntflag1, 1.]
                        co2cntflag2 = [co2cntflag2, 1.]
                    endif
                 
                ;Remove an element from cnt flags: 
                endif else begin
                    ;Hasn't been encountered yet so tbw.
                  
                endelse
                
                
              
            endif
            
            ;2025-07-15: ramflag no longer included in the final_flag, as that is taken care of in the stitch routine.
            ;Also, there are times when the moment method could be used instead of beam, if STATIC is not ram pointed, so the
            ;ramflag isn't useful as a one off y/n here.
            final_flag = fltarr(neleT, 5)  ;flag array for each ion species
            final_flag[*,0] = hcntflag1 + hcntflag2 + attflag + scpotflag + IonSuppressionFlag[*,0]  ;there must be a min number of counts, that must be stat significant compared to bkg
            final_flag[*,1] = hecntflag1 + hecntflag2 + attflag + scpotflag + IonSuppressionFlag[*,1]
            final_flag[*,2] = ocntflag1 + ocntflag2 + attflag + scpotflag + IonSuppressionFlag[*,2] 
            final_flag[*,3] = o2cntflag1 + o2cntflag2 + attflag + scpotflag + IonSuppressionFlag[*,3]
            final_flag[*,4] = co2cntflag1 + co2cntflag2 + bco2_flag + attflag + scpotflag + IonSuppressionFlag[*,4]
            
            final_flag2 = fix(final_flag < 1) ;make largest flag = 1  ;make integer
            
            ;===============
            ;TPLOT VARIABLES:
            ;===============
            ;Store attenuator and mode as a single double line array: this has the entire day and needs to be cut down in time to match
            ;the time range of the other variables:
            get_data, 'mvn_sta_c6_mode', data=ddc6mode
            get_data, 'mvn_sta_c6_att', data=ddc6att
            
            iKPattmode = where(ddc6mode.x ge min(dd1.x) and ddc6mode.x le max(dd1.x), niKPattmode)
              if niKPattmode ne n_elements(dd1.x) then stop  ;this shouldn't happen - but currently does not exit gracefully.....
            tname = 'mvn_sta_c6_att_mode'
            
            store_data, tname, data={x: ddc6mode.x[iKPattmode], y: [[ddc6mode.y[iKPattmode]], [ddc6att.y[iKPattmode]]]}
              options, tname, labels=['Mode', 'Att']
              options, tname, labflag=-1
              options, tname, colors=[0, 1]  ;note, default hard coded colors here- will fix in the l3 load routine
              ylim, tname, -1, 9
              options, tname, ytitle='STA!CMode!CAtt'
                        
            ;Flag variables:
            tname = 'mvn_sta_l3_ramflag'
            store_data, tname, data={x: dd1.x, y: ramflag}
              options, tname, ytitle='ramflag'
              ylim, tname, -1, 2
            
            tname = 'mvn_sta_l3_att_flag'
            store_data, tname, data={x: dd1.x, y: attflag}
              options, tname, ytitle='Attitude!Cflag'
              ylim, tname, -1, 2
            
            tname = 'mvn_sta_l3_scpot_flag'
            store_data, tname, data={x: dd1.x, y: scpotflag}
              options, tname, ytitle='sc pot!cflag'
              ylim, tname, -1, 2
              
            tname = 'mvn_sta_l3_min_cnts_flag_h'
            store_data, tname, data={x: dd1.x, y: hcntflag1}
              options, tname, ytitle='min cnts!Cflag H+'
              ylim, tname, -1, 2
              
            tname = 'mvn_sta_l3_min_cnts_flag_he'
            store_data, tname, data={x: dd1.x, y: hecntflag1}
              options, tname, ytitle='min cnts!Cflag He+'
              ylim, tname, -1, 2
              
            tname = 'mvn_sta_l3_min_cnts_flag_o'
            store_data, tname, data={x: dd1.x, y: ocntflag1}
              options, tname, ytitle='min cnts!Cflag O+'
              ylim, tname, -1, 2
            
            tname = 'mvn_sta_l3_min_cnts_flag_o2'
            store_data, tname, data={x: dd1.x, y: o2cntflag1}
              options, tname, ytitle='min cnts!Cflag O2+'
              ylim, tname, -1, 2
            
            tname = 'mvn_sta_l3_min_cnts_flag_co2'
            store_data, tname, data={x: dd1.x, y: co2cntflag1}
              options, tname, ytitle='min cnts!Cflag CO2+'
              ylim, tname, -1, 2
            
            tname = 'mvn_sta_l3_sig_cnts_flag_h'
            store_data, tname, data={x: dd1.x, y: hcntflag2}
              options, tname, ytitle='sig cnts!Cflag H+'
              ylim, tname, -1, 2

            tname = 'mvn_sta_l3_sig_cnts_flag_he'
            store_data, tname, data={x: dd1.x, y: hecntflag2}
              options, tname, ytitle='sig cnts!Cflag He+'
              ylim, tname, -1, 2

            tname = 'mvn_sta_l3_sig_cnts_flag_o'
            store_data, tname, data={x: dd1.x, y: ocntflag2}
              options, tname, ytitle='sig cnts!Cflag O+'
              ylim, tname, -1, 2

            tname = 'mvn_sta_l3_sig_cnts_flag_o2'
            store_data, tname, data={x: dd1.x, y: o2cntflag2}
              options, tname, ytitle='sig cnts!Cflag O2+'
              ylim, tname, -1, 2

            tname = 'mvn_sta_l3_sig_cnts_flag_co2'
            store_data, tname, data={x: dd1.x, y: co2cntflag2}
              options, tname, ytitle='sig cnts!Cflag CO2+'
              ylim, tname, -1, 2
              
            tname = 'mvn_sta_l3_ion_suppression_correction'
            store_data, tname, data={x: dd1.x, y: [[corr_1], [corr_2], [corr_16], [corr_32], [corr_44]]}
              options, tname, ytitle='Ion!Csupp.!Ccorr.!C(ram+scp)'
              options, tname, colors=ll1.colors
              options, tname, labels=ll1.labels
              options, tname, labflag=-1
              options, tname, ylog=1
            
            tname = 'mvn_sta_l3_ion_suppression_flag'
              store_data, tname, data={x: dd1.x, y: IonSuppressionFlag}
              options, tname, ytitle='Ion!Csupp.!Cflag'
              ylim, tname, -1, 2
              options, tname, colors=ll1.colors
              options, tname, labels=ll1.labels
              options, tname, labflag=-1
              
            tname = 'mvn_sta_l3_ion_suppression_constants'
            store_data, tname, data={x: dd1.x[floor(neleT/2.)], y: transpose(kk3)} ;plot in middle of time range
              options, tname, ytitle='Ion!Csupp.!Cconstants'
              ylim, tname, 0, 10
              options, tname, psym=1
              options, tname, colors=[0,1,2,3]
              options, tname, labels=['0', '1', '2', '3']
              options, tname, labflag=-1
                      
            ;Rename density tplot file:           
            tname1 = 'mvn_sta_l3_density'
            dd1b = dd1
            dd1b.y[*,3] *= 1.2  ;account for O2+ straggler tail that is lost
            store_data, tname1, data=dd1b, dlimit=dl1, limit=ll1  ;density values
              ylim, tname1, 0.1, 5E5
              options, tname1, ytitle='Ion density!C[cm!U-3!N]'
            
            tname2 = 'mvn_sta_l3_density_abs_uncertainty'
            store_data, tname2, data=dd3, dlimit=dl3, limit=ll3
              options, tname2, ytitle='Uncertainty!Cin ion!Cdensity!C[cm!U-3!N]'
              ylim, tname2, 1E-2, 1E3
              options, tname2, colors=ll1.colors  ;use same settings as density variable
              
            tname3 = 'mvn_sta_l3_density_perc_uncertainty'
            store_data, tname3, data=dd4, dlimit=dl4, limit=ll4
              options, tname3, ytitle='Uncertainty!Cin ion!Cdensity!C[%]'
              ylim, tname3, 0.1, 1E3
              options, tname3, colors=ll1.colors  ;use same settings as density variable
           
            tname4 = 'mvn_sta_l3_density_quality_flag'
            store_data, tname4, data={x: dd1.x, y: final_flag2}
              ylim, tname4, -1, 2
              options, tname4, ytitle='Ion density!Cquality flag!C0=Good!C1=Caution
              options, tname4, colors=ll1.colors  ;use same settings as density variable
              options, tname4, labels=ll1.labels
              options, tname4, labflag=ll1.labflag
            
            ;Convert position in km to be consistent with Ti:
            get_data, 'mvn_sta_anc_mvn_pos_mso', data=ddpos, limit=llpos, dlimit=dlpos
              ddpos.y = ddpos.y * 3376.  ;mvn_sta_anc_ephemeris uses 1RMars = 3376 km, convert to float (not double)
              ddpos2 = create_struct('X'   ,     ddpos.x   ,   $
                                     'X_IND' ,   ddpos.x_ind , $
                                     'Y'   ,     float(ddpos.y)  , $
                                     'Y_IND' ,   ddpos.y_ind)
            
            store_data, 'mvn_sta_l3_density_mvn_pos_mso', data=ddpos2, limit=llpos, dlimit=dlpos           
              options, 'mvn_sta_l3_density_mvn_pos_mso', ytitle='MVN pos!C[km]'
           
            ;Rename variables:           
            options, 'mvn_sta_anc_mvn_sza', ytitle='MVN SZA!C[degrees]'          
            get_data, 'mvn_sta_anc_mvn_sza', data=ddsza, dlimit=dlsza, limit=llsza
            store_data, 'mvn_sta_l3_density_mvn_sza', data=ddsza, dlimit=dlsza, limit=llsza
            
            get_data, 'mvn_sta_anc_mvn_alt_iau', data=ddalt, dlimit=dlalt, limit=llalt
            store_data, 'mvn_sta_l3_density_mvn_alt_iau', data=ddalt, dlimit=dlalt, limit=llalt
            
            get_data, 'mvn_sta_c6_att_mode', data=ddam, dlimit=dlam, limit=llam
            store_data, 'mvn_sta_l3_density_att_mode', data=ddam, dlimit=dlam, limit=llam
            
            ;====================================================
            ;---Combine density methods into a single variable---
            ;====================================================
            ;dd2 is heavy ion, dd5 is light. H+ and He++ are the same values, so only one entry in light variable.
            tname5 = 'mvn_sta_l3_density_method'
            dd2b=dd2
            ich = where(dd2b.y gt 1, nich)
            if nich gt 0 then dd2b.y[ich] = 1  ;convert any values >1 to 1, to keep simple
            store_data, tname5, data={x: dd5.x, y: fix([[dd5.y<1], [dd5.y<1], [dd2.y[*,0]<1], [dd2.y[*,1]<1], [dd2.y[*,2]<1]])}
              options, tname5, colors=ll1.colors  ;copy settings from density
              options, tname5, labels=ll1.labels
              options, tname5, labflag=ll1.labflag
              options, tname5, ytitle='Density!Cmethod!C0=high altitude!C1=periapsis'
              ylim, tname5, -1, 2
            
            ;Save in a flag file:
            flagstore=['mvn_sta_l3_ramflag', 'mvn_sta_l3_att_flag', 'mvn_sta_l3_scpot_flag', 'mvn_sta_l3_min_cnts_flag_h', 'mvn_sta_l3_min_cnts_flag_he', $
                        'mvn_sta_l3_min_cnts_flag_o', 'mvn_sta_l3_min_cnts_flag_o2', 'mvn_sta_l3_min_cnts_flag_co2', 'mvn_sta_l3_sig_cnts_flag_h', $
                          'mvn_sta_l3_sig_cnts_flag_he', 'mvn_sta_l3_sig_cnts_flag_o', 'mvn_sta_l3_sig_cnts_flag_o2', 'mvn_sta_l3_sig_cnts_flag_co2', $
                           'mvn_sta_l3_ion_suppression_correction', 'mvn_sta_l3_ion_suppression_flag', 'mvn_sta_l3_ion_suppression_constants']
            
            ;Save as the main science file:
            tstore = ['mvn_sta_l3_density', 'mvn_sta_l3_density_abs_uncertainty', 'mvn_sta_l3_density_perc_uncertainty', $
                       'mvn_sta_l3_density_quality_flag', 'mvn_sta_l3_density_method', $
                        'mvn_sta_l3_density_att_mode', 'mvn_sta_l3_density_mvn_pos_mso', 'mvn_sta_l3_density_mvn_sza', 'mvn_sta_l3_density_mvn_alt_iau']
                    ;'mvn_sta_l3_density_light_method', 'mvn_sta_l3_density_heavy_method' ;these used to be included, but are combined in density_method
            
            ;Cycle through all variables and add spiceloaded and parent_files to the limit structure:
            ntv1 = n_elements(flagstore)
            ntv2 = n_elements(tstore)
            for ftv = 0l, ntv1-1l do begin
                options, flagstore[ftv], 'spiceloaded', spiceloaded
                options, flagstore[ftv], 'parent_files', parent_files
            endfor
            for ftv = 0l, ntv2-1l do begin
              options, tstore[ftv], 'spiceloaded', spiceloaded
              options, tstore[ftv], 'parent_files', parent_files
            endfor
            
            ;================
            ;SAVE TPLOT FILE:
            ;================
            ;For now, save within the same folder, with additional file extension.
            ;Input file format: mvn_sta_l3_den_????????_v??.tplot
            savedir = file_dirname(files_den[ff])+'/'  ;same directory as file is loaded from
            nameTMP = file_basename(files_den[ff])  ;filename loaded
            dateTMP = strmid(nameTMP, 15, 8)  ;extract yyyymmdd date
            savename = 'mvn_sta_l3_den_'+dateTMP+'_v'+dfile_version  ;use same version number; adds '.tplot' on end automatically
            
            tplot_save, tstore, filename=savedir+savename
            mvn_sta_checkfilesave, savedir+savename+'.tplot'
            
            ;Save flag file as well:
            savename2 = 'mvn_sta_l3_den_'+dateTMP+'_flags_v'+dfile_version  ;use same version number; adds '.tplot' on end automatically
            tplot_save, flagstore, filename=savedir+savename2
            mvn_sta_checkfilesave, savedir+savename2+'.tplot'
           
        endfor  ;ff
      
    endif

success=1
endif  ;den=1

;############
;TEMPERATURE:
if temp eq 1 then begin
  tfiletmp = 'mvn_sta_l3_temp_????????_full_v'+tfile_version+'.tplot'
  files_temp = file_search(tempdir, tfiletmp, count=nfiles_temp)  ;search recursively through year and month subfolders.

  if keyword_set(testfile) then begin
    files_temp = testfile
    nfiles_temp=1
  endif

  if nfiles_temp gt 0 then begin

    ;Go over each file:
    for ff = 0l, nfiles_temp-1l do begin
      if not keyword_set(nodelete) then store_data, '*', /delete

      tplot_restore, filename=files_temp[ff]
      
      ;Keep all of these variables  - do not overwrite them:
      get_data, 'mvn_sta_o2+_temp', data=dd1, dlimit=dl1, limit=ll1
      get_data, 'mvn_sta_temp_product', data=dd2
      get_data, 'mvn_sta_o2+_temp_unc', data=dd3, dlimit=dl3, limit=ll3
      get_data, 'mvn_sta_o2+_temp_flag', data=dd4, dlimit=dl4, limit=ll4
      
      ;At this point you could recreate the temp_flag variable if you want. 
      ;There are tplot variables in the full file named corrflag, cntflag, scpotflag 
      ;that are created by mvn_sta_temp_stitch 
      ; if they need to be updated, tweak that program 
     
      ;===============
      ;TPLOT VARIABLES:
      ;===============
      ;Rename temperature tplot variables
      tname1 = 'mvn_sta_l3_temperature_o2+'
      store_data, tname1, data=dd1, dlimit=dl1, limit=ll1  ;temperature values
      ylim, tname1, 0.01, 10,1
      options, tname1, ytitle='O!D2!U+!N Temperature!C[eV]'

      tname2 = 'mvn_sta_l3_temperature_abs_uncertainty'
      store_data, tname2, data=dd3, dlimit=dl3, limit=ll3
      options, tname2, ytitle='Uncertainty!Cin O!D2!U+!N!Ctemp!C[eV]'
      ylim, tname2, 1E-3,10,1

;      tname3 = 'mvn_sta_l3_temperature_perc_uncertainty'
;      store_data, tname3, data=dd4, dlimit=dl4, limit=ll4
;      options, tname3, ytitle='Uncertainty!Cin ion!Ctemperature!C[%]'
;      ylim, tname3, 0.1, 1E3

      tname4 = 'mvn_sta_l3_temperature_quality_flag'
      store_data, tname4, data=dd4, dlimit=dl4, limit=ll4
      ylim, tname4, -1, 2
      options, tname4, ytitle='O!D2!U+!N temp!Cquality flag!C0=Good!C1=Caution
      
      ;Rename variables:
      get_data, 'mvn_sta_anc_mvn_pos_mso', data=ddpos, limit=llpos, dlimit=dlpos
      store_data, 'mvn_sta_l3_temperature_mvn_pos_mso', data=ddpos, limit=llpos, dlimit=dlpos
      if n_elements(ddpos.x) ne n_elements(dd1.x) then begin
        match_inds=nn2(ddpos.x,dd1.x)
        store_data,'mvn_sta_l3_temperature_mvn_pos_mso', data={x:dd1.x, y:ddpos.y[match_inds,*]},limit=llpos,dlimit=dlpos
      endif
      options, 'mvn_sta_l3_temperature_mvn_pos_mso', ytitle='MVN pos!C[km]'
      
      get_data, 'mvn_sta_anc_mvn_pos_geo', data=ddpos, limit=llpos, dlimit=dlpos
      store_data, 'mvn_sta_l3_temperature_mvn_pos_geo', data=ddpos, limit=llpos, dlimit=dlpos
      if n_elements(ddpos.x) ne n_elements(dd1.x) then begin
        match_inds=nn2(ddpos.x,dd1.x)
        store_data,'mvn_sta_l3_temperature_mvn_pos_geo', data={x:dd1.x, y:ddpos.y[match_inds,*]},limit=llpos,dlimit=dlpos
      endif
      options, 'mvn_sta_l3_temperature_mvn_pos_geo', ytitle='MVN pos!C[km]'
      
      get_data, 'mvn_sta_anc_mvn_sza', data=ddsza, dlimit=dlsza, limit=llsza
      store_data, 'mvn_sta_l3_temperature_mvn_sza', data=ddsza, dlimit=dlsza, limit=llsza
      if n_elements(ddsza.x) ne n_elements(dd1.x) then begin
        match_inds=nn2(ddsza.x,dd1.x)
        store_data,'mvn_sta_l3_temperature_mvn_sza', data={x:dd1.x, y:ddsza.y[match_inds]},limit=llsza,dlimit=dlsza
      endif
      options, 'mvn_sta_l3_temperature_mvn_sza', ytitle='MVN SZA!C[degrees]'
    
      get_data, 'mvn_sta_anc_mvn_lst', data=ddlst, dlimit=dllst, limit=lllst
      store_data, 'mvn_sta_l3_temperature_mvn_lst', data=ddlst, dlimit=dllst, limit=lllst
      if n_elements(ddlst.x) ne n_elements(dd1.x) then begin
        match_inds=nn2(ddlst.x,dd1.x)
        store_data,'mvn_sta_l3_temperature_mvn_lst', data={x:dd1.x, y:ddlst.y[match_inds]},limit=lllst,dlimit=dllst
      endif
      options, 'mvn_sta_l3_temperature_mvn_lst', ytitle='MVN LST!C'

      get_data, 'mvn_sta_anc_mvn_alt_iau', data=ddalt, dlimit=dlalt, limit=llalt
      store_data, 'mvn_sta_l3_temperature_mvn_alt_iau', data=ddalt, dlimit=dlalt, limit=llalt
      if n_elements(ddalt.x) ne n_elements(dd1.x) then begin
        match_inds=nn2(ddalt.x,dd1.x)
        store_data,'mvn_sta_l3_temperature_mvn_alt_iau', data={x:dd1.x, y:ddalt.y[match_inds]},limit=llalt,dlimit=dlalt
      endif
      
      get_data, 'mvn_sta_temp_product', data=dd4, dlimit=dl4, limit=ll4

	;;; there was a bug in v01 of processing that didn't set the product if not in ram/co2 mode
	;;; but it will always be c6 so set it here. 
	tmp=where( finite(dd1.y) and ~finite(dd4.y) )
	prod=dd4.y
	prod[tmp] = 0. 
	dd4.y = prod 
      store_data, 'mvn_sta_l3_temperature_product', data=dd4, dlimit=dl4, limit=ll4
      options, 'mvn_sta_l3_temperature_product',ytitle='O!D2!U+!N  temp !Cproduct!C0=c6!C1=c8' 
      ylim,'mvn_sta_l3_temperature_product',-1,2

      get_data,'mvn_sta_c6_mode',tt,modedat
      get_data,'mvn_sta_c6_att',tt,attdat 
      store_data, 'mvn_sta_l3_temperature_att_mode', data={x:tt,y: [ [modedat], [attdat] ] }
      options,'mvn_sta_l3_temperature_att_mode',colors=[247,255],ytitle='Mode/Att'
      ylim,'mvn_sta_l3_temperature_att_mode',-1,9


      tstore = ['mvn_sta_l3_temperature_o2+', 'mvn_sta_l3_temperature_abs_uncertainty', 'mvn_sta_l3_temperature_product',$;'mvn_sta_l3_density_perc_uncertainty', $
        'mvn_sta_l3_temperature_quality_flag', 'mvn_sta_l3_temperature_mvn_pos_mso', 'mvn_sta_l3_temperature_mvn_sza', $
        'mvn_sta_l3_temperature_mvn_alt_iau', 'mvn_sta_l3_temperature_mvn_pos_geo', 'mvn_sta_l3_temperature_mvn_lst', 'mvn_sta_l3_temperature_att_mode']

      tplot_options, 'xmargin', [16,12]

      ;================
      ;SAVE TPLOT FILE:
      ;================
      ;For now, save within the same folder, with additional file extension.
      ;Input file format: mvn_sta_l3_temp_????????_v??.tplot
      savedir = file_dirname(files_temp[ff])+'/'  ;same directory as file is loaded from
      nameTMP = file_basename(files_temp[ff])  ;filename loaded
      dateTMP = strmid(nameTMP, 16, 8)  ;extract yyyymmdd date
      savename = 'mvn_sta_l3_temp_'+dateTMP+'_v'+tfile_version  ;use same version number; adds '.tplot' on end automatically

      tplot_save, tstore, filename=savedir+savename
      mvn_sta_checkfilesave, savedir+savename+'.tplot'

    endfor  ;ff

  endif ;nfiles>0

  success=1




endif ;temp=1



end


