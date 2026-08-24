;+
;2025-12-01: CMF: note, the original generate.pro has had small edits to improve it, and so this _nobkg4 is
;slightly out of date. I need to update it at some point.
;
;Small edits to original program. When running for nobk4, for some reason some of the STATIC tplot variables have one extra timestamp, causing
;this to crash. This routine removes the extra timestamp. Rest of routine should be the same, as of 2022-03-09.
;
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
;
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_generate_science_files.pro  ;for testing only
;-
;

pro mvn_sta_l3_generate_science_files_nobkg4, dfile_version=dfile_version, tfile_version=tfile_version, testfile=testfile, success=success, nodelete=nodelete

;If versions not set, don't process them:
if size(dfile_version,/type) eq 0 then den=0 else den=1
if size(tfile_version,/type) eq 0 then temp=0 else temp=1

success=0

basedir = '/disks/data/maven/data/sci/sta/l3/'
dendir = basedir+'density/'
tempdir = basedir+'temperature/'

;########
;DENSITY:
;Find files to work on:
if den eq 1 then begin
    dfiletmp = 'mvn_sta_l3_den_????????_full_v'+dfile_version+'.tplot'
    files_den = file_search(dendir, dfiletmp, count=nfiles_den)  ;search recursively through year and month subfolders.
    
    ;THRESHOLDS:
    min_cnts = 5.  ;must have this many counts
    ramang = 10.  ;angle between APP i and sc ram direction must be less than this (in degrees). Accounts for rover comm orbits and off pointing.
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
            get_data, 'mvn_sta_l3_density_heavy_method', data=dd2
            get_data, 'mvn_sta_den_uncert', data=dd3, dlimit=dl3, limit=ll3 
            get_data, 'mvn_sta_den_uncert_perc', data=dd4, dlimit=dl4, limit=ll4
            get_data, 'mvn_sta_c6_mode', data=ddstamode
            get_data, 'mvn_sta_c6_cb_scpot', data=ddscpot
            
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
            
            itmp = where((ramangle_interp gt ramang and ddatt.y[iKP1] ge 2 and ddalt.y lt ramalt) or $
                            (ddmode.y[iKP1] eq 6), nitmp)  ;find times when mechanical attenuator in, and ram angle off nominal
            
            ramflag = fltarr(neleT)
            if nitmp gt 0 then ramflag[itmp] = 1  ;keep flag for overall flag
            
            dd1.y[itmp,*] = 0.  ;set densities and uncertainty to zero.
            dd3.y[itmp,*] = 0.
            dd4.y[itmp,*] = 0.
            
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
                      
            ;==================
            ;Derive final flag:
            ;==================
            ;First need to check that all variables are the same length - sometimes there is an extra timestamp at the end - not sure why
            ;this is - to do with selecting a timerange for nobkg4.
            neleT1 = n_elements(hcntflag1)
            if neleT1 ne neleT then begin
              if abs(neleT1 - neleT) gt 1 then stop  ;this shouldn't happen
              
              ;cntflag1 and cntflag2 are missing the final timestamp. Assuming this is not of interest, add these as zeros:
              hcntflag1 = [hcntflag1, 0.]
              hecntflag1 = [hecntflag1, 0.]
              ocntflag1 = [ocntflag1, 0.]
              o2cntflag1 = [o2cntflag1, 0.]
              co2cntflag1 = [co2cntflag1, 0.]
              
              hcntflag2 = [hcntflag2, 0.]
              hecntflag2 = [hecntflag2, 0.]
              ocntflag2 = [ocntflag2, 0.]
              o2cntflag2 = [o2cntflag2, 0.]
              co2cntflag2 = [co2cntflag2, 0.]           
            endif
            
            ;Do for each ion species, as count flag is species dependent.
            final_flag = fltarr(neleT, 5)  ;flag array for each ion species
            final_flag[*,0] = hcntflag1 + hcntflag2 + ramflag + attflag + scpotflag  ;there must be a min number of counts, that must be stat significant compared to bkg
            final_flag[*,1] = hecntflag1 + hecntflag2 + ramflag + attflag + scpotflag
            final_flag[*,2] = ocntflag1 + ocntflag2 + ramflag + attflag + scpotflag
            final_flag[*,3] = o2cntflag1 + o2cntflag2 + ramflag + attflag + scpotflag
            final_flag[*,4] = co2cntflag1 + co2cntflag2 + ramflag + bco2_flag + attflag + scpotflag
            
            final_flag2 = final_flag < 1. ;make largest flag = 1
            
            ;===============
            ;TPLOT VARIABLES:
            ;===============
            ;Store attenuator and mode as a single double line array:
            tname = 'mvn_sta_c6_att_mode'
            get_data, 'mvn_sta_c6_mode', data=ddc6mode
            get_data, 'mvn_sta_c6_att', data=ddc6att
            store_data, tname, data={x: ddc6mode.x, y: [[ddc6mode.y], [ddc6att.y]]}
              options, tname, labels=['Mode', 'Att']
              options, tname, labflag=-1
              options, tname, colors=[0, 1]  ;note, default hard coded colors here- will fix in the l3 load routine
              ylim, tname, -1, 9
                        
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
              ddpos.y = ddpos.y * 3376.  ;mvn_sta_anc_ephemeris uses 1RMars = 3376 km.
            store_data, 'mvn_sta_l3_density_mvn_pos_mso', data=ddpos, limit=llpos, dlimit=dlpos           
              options, 'mvn_sta_l3_density_mvn_pos_mso', ytitle='MVN pos!C[km]'
            
            ;Rename variables:           
            options, 'mvn_sta_anc_mvn_sza', ytitle='MVN SZA!C[degrees]'          
            get_data, 'mvn_sta_anc_mvn_sza', data=ddsza, dlimit=dlsza, limit=llsza
            store_data, 'mvn_sta_l3_density_mvn_sza', data=ddsza, dlimit=dlsza, limit=llsza
            
            get_data, 'mvn_sta_anc_mvn_alt_iau', data=ddalt, dlimit=dlalt, limit=llalt
            store_data, 'mvn_sta_l3_density_mvn_alt_iau', data=ddalt, dlimit=dlalt, limit=llalt
                       
            
            ;Save in a flag file:
            flagstore=['mvn_sta_l3_ramflag', 'mvn_sta_l3_att_flag', 'mvn_sta_l3_scpot_flag', 'mvn_sta_l3_min_cnts_flag_h', 'mvn_sta_l3_min_cnts_flag_he', $
                        'mvn_sta_l3_min_cnts_flag_o', 'mvn_sta_l3_min_cnts_flag_o2', 'mvn_sta_l3_min_cnts_flag_co2', 'mvn_sta_l3_sig_cnts_flag_h', $
                          'mvn_sta_l3_sig_cnts_flag_he', 'mvn_sta_l3_sig_cnts_flag_o', 'mvn_sta_l3_sig_cnts_flag_o2', 'mvn_sta_l3_sig_cnts_flag_co2']
            
            ;Save as the main science file:
            tstore = ['mvn_sta_l3_density', 'mvn_sta_l3_density_abs_uncertainty', 'mvn_sta_l3_density_perc_uncertainty', $
                       'mvn_sta_l3_density_quality_flag', 'mvn_sta_l3_density_light_method', 'mvn_sta_l3_density_heavy_method', $
                        'mvn_sta_c6_att_mode', 'mvn_sta_l3_density_mvn_pos_mso', 'mvn_sta_l3_density_mvn_sza', 'mvn_sta_l3_density_mvn_alt_iau']
                    
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
      options, 'mvn_sta_l3_temperature_mvn_pos_mso', ytitle='MVN pos!C[km]'
      
      get_data, 'mvn_sta_anc_mvn_pos_geo', data=ddpos, limit=llpos, dlimit=dlpos
      store_data, 'mvn_sta_l3_temperature_mvn_pos_geo', data=ddpos, limit=llpos, dlimit=dlpos
      options, 'mvn_sta_l3_temperature_mvn_pos_geo', ytitle='MVN pos!C[km]'
      
      get_data, 'mvn_sta_anc_mvn_sza', data=ddsza, dlimit=dlsza, limit=llsza
      store_data, 'mvn_sta_l3_temperature_mvn_sza', data=ddsza, dlimit=dlsza, limit=llsza
      options, 'mvn_sta_l3_temperature_mvn_sza', ytitle='MVN SZA!C[degrees]'
    
      get_data, 'mvn_sta_anc_mvn_lst', data=ddlst, dlimit=dllst, limit=lllst
      store_data, 'mvn_sta_l3_temperature_mvn_lst', data=ddlst, dlimit=dllst, limit=lllst
      options, 'mvn_sta_l3_temperature_mvn_lst', ytitle='MVN LST!C'

      get_data, 'mvn_sta_anc_mvn_alt_iau', data=ddalt, dlimit=dlalt, limit=llalt
      store_data, 'mvn_sta_l3_temperature_mvn_alt_iau', data=ddalt, dlimit=dlalt, limit=llalt
      
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
      store_data, 'mvn_sta_l3_sta_att_mode', data={x:tt,y: [ [modedat], [attdat] ] }
      options,'mvn_sta_l3_sta_att_mode',colors=[247,255],ytitle='Mode/Att'
      ylim,'mvn_sta_l3_sta_att_mode',-1,9


      tstore = ['mvn_sta_l3_temperature_o2+', 'mvn_sta_l3_temperature_abs_uncertainty', 'mvn_sta_l3_temperature_product',$;'mvn_sta_l3_density_perc_uncertainty', $
        'mvn_sta_l3_temperature_quality_flag', 'mvn_sta_l3_temperature_mvn_pos_mso', 'mvn_sta_l3_temperature_mvn_sza', $
        'mvn_sta_l3_temperature_mvn_alt_iau', 'mvn_sta_l3_temperature_mvn_pos_geo', 'mvn_sta_l3_temperature_mvn_lst', 'mvn_sta_l3_sta_att_mode']

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


