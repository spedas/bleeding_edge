;+
;Refined code for STATIC L3 density processing.
;
;Steps:
;1. Calculate full set of densities from mac_den.
;2. Stitch together n_4d and nbc products - how to do this - when energy of beam gets above X?
;3. Smooth data over mode / att changes.
;4. Deal with "bad" data that definitely cannot be included: eg large sc pot, zero fluxes.
;5. Field of field flag
;6. Any other flags - pointing at Mars, pointing at SW.
;7. Overall quality - should you use this - y or n.
;8. What is output to L3 file generator - IDL save file, and/or CDF files?
;
;Include sc pot in L3 files?
;
;For testing:
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_den_stitch.pro
;
;-
;

;==================
;===SUB ROUTINES===
;==================


;+
;Calculate the predicted RAM direction in STATICS fov. Send in timestamps, calculate MAVEN velocity in MSO, convert from MAVEN_MSO to MAVEN_STATIC.
;
;Routines assumes that timespan has already been set.
;Routine will use get_data to grab timestamps from the produced tplot variables from the density routine.
;
;
;INPUTS:
;Routine requires STATIC ca, c8 and c6 data products in tplot.
;
;mvn_sta_l3_den_stitch_ram -> mvn_sta_l3_den_stitch_ram
;-

pro mvn_sta_l3_den_stitch_ram, success=success, spicekernels=spicekernels, trange=trange

;Find colors:
if size(qualcolors,/type) ne 0 then begin
  colred = qualcolors.red
  colblack=qualcolors.black
  colblue=qualcolors.blue
  colgreen=qualcolors.green
  
endif else begin
  cols=get_colors()
  colred =cols.red
  colblack=cols.black
  colblue=cols.blue
  colgreen=cols.green
  
endelse

;Get timestamp:
get_data, 'mvn_sta_ca_A', data=ddca, dlimit=dlca, limit=llca  ;get anode info
;get_data, 'mvn_sta_ca_A', data=ddc8, dlimit=dlc8, limit=llc8

;Pick all times if trange not set:
if keyword_set(trange) then iTIME = where(ddca.x ge trange[0] and ddca.x le trange[1], niTIME) else begin
                            niTIME = n_elements(ddca.x)
                            iTIME = findgen(niTIME)
                       endelse

;Calculate MAVEN velocity:
mvn_sta_anc_ephemeris, ddca.x[iTIME], /mvn_pos, /mvn_vel, spicekernels=spicekernels   ;load SPICE within this routine   ;$%$%$%$% UNCOMMENT ME AFTER TESTING!!!

get_data, 'mvn_sta_anc_mvn_vel_mso', data=ddmvnvel  ;MAVEN velocity in km/s in MSO coordinates

;Check when we have SPICE coverage for STATIC rotations:
mvn_sta_ck_check, ddca.x, success=sc  ;SPICE already loaded

if sc eq 1 then begin
    get_data, 'mvn_sta_ck_check', data=ddch
  
    neleROT = niTIME  ;number of rotations needed
    rotateARR_full = fltarr(neleROT,3)+!values.f_nan
  
    for rr = 0l, neleROT-1l do begin
        if ddch.y[rr] eq 0 then begin
            vecTMP = transpose(ddmvnvel.y[rr,0:2])
            rotateTMP = spice_vector_rotate(vecTMP, ddca.x[iTIME[rr]],'MAVEN_MSO', 'MAVEN_STATIC')  ;vec in is 3xN, send in one timestamp at a time
            rotateARR_full[rr,*] = transpose(rotateTMP)
        endif
    endfor
    
    ;Normalize to unit vector:
    vmag = sqrt(ddmvnvel.y[*,0]^2 + ddmvnvel.y[*,1]^2 + ddmvnvel.y[*,2]^2)
    rotateARR_full2 = rotateARR_full
      rotateARR_full2[*,0] = rotateARR_full[*,0]/vmag
      rotateARR_full2[*,1] = rotateARR_full[*,1]/vmag
      rotateARR_full2[*,2] = rotateARR_full[*,2]/vmag
    
    tname = 'mvn_sta_ram_vector'
    store_data, tname, data={x: ddca.x[iTIME], y: rotateARR_full2}
      options, tname, labels=['i', 'j [STA]', 'k']
      options, tname, colors=[colblue, colgreen, colred]
      options, tname, labflag=1
      options, tname, ytitle='RAM flow vector!Cin STA'
      ylim, tname, -1.1, 1.1
    
    success=1
endif else success=0 ;sc=1

;UPTO HERE - convert STATIC look direction STATIC angles - overplot on anode data to check the conversion is correct.
;For testing: 
;x = [1., -1., -1., 1.]
;y = [1., 1., -1., -1.]
;test_theta = atan(y, x)*180./!pi

;Note STATIC uses phi for 0-360 and theta for -45 to 45
phi = (atan(rotateARR_full2[*,1], (-1.)*rotateARR_full2[*,0]) * 180./!pi) * (-1.)  ;the (-1) factors are added to get angles right wrt STATIC products
store_data, 'ramphi', data={x: ddca.x[iTIME], y: phi}
store_data, 'mvn_sta_ca_A_ram', data=['mvn_sta_ca_A', 'ramphi'] ;, dlimit=dlca, limit=llca
  ylim, 'mvn_sta_ca_A_ram', -180, 180

theta = acos(rotateARR_full2[*,2])*180./!pi  ;r=1 (unit vector)
theta2 = (90.-theta)*(-1.) ;get +45 : 0 : -45 range, CMF added the *(-1) to match the STATIC data.
store_data, 'ramtheta', data={x: ddca.x[iTIME], y: theta2}
store_data, 'mvn_sta_c8_D_ram', data=['mvn_sta_c8_D', 'ramtheta'] ;, dlimit=dlc8, limit=llc8. Overplot RAM vector on c8 D
  ylim, 'mvn_sta_c8_D_ram', -45, 45

end

;###########
;###########

;+
;At STATIC attenuator or mode changes, average densities from either side
;
;sta_apid: string: STATIC apid to use. Default is 'c6' if not set.
;denname: string: tplot variable name containing STATIC density. Can be multi-row array containing multiple species. Default
;         if not set is 'mvn_sta_density_prelim'
;
;Based on by-eye analysis, CMF has determined the following:
; - When attenuator goes 1->2 or 2->1, get a small drop in O+ counts. The density code seems to leave O2+ density blank. Leave all blank.
; - When mode goes to 7, get a drop in O2+ counts. Average between the two neighboring points.
; - When attenuator = 3 (mechanical and electrostatic), we lose O+ (due to attenuation and possibly ion suppresion). This can't be corrected
;                        for using STATIC data (but NGIMS O+ measurements may be used in the future - TBD).
; - When attenuator goes 0->1 and 1-> we get a drop in O+ (probably due to ion suppresion and changes in which surfaces are mostly exposed
;                        when the attenuator state changes). Leave this point blank for O+.
;
;NOTES:
;This routine is quick and does not currently have a trange keyword. This routine creates a new tplot variable, so changes can be tracked
;easily through this.
;
;mvn_sta_l3_den_stitch_att_mode_changes -> mvn_sta_l3_den_stitch_att_mode_changes
;-

pro mvn_sta_l3_den_stitch_att_mode_changes, sta_apid=sta_apid, denname=denname, success=success, trange=trange

proname = 'mvn_sta_l3_den_stitch_att_mode_changes'

if not keyword_set(sta_apid) then sta_apid = 'c6'
if not keyword_set(denname) then denname = 'mvn_sta_density_prelim'

get_data, 'mvn_sta_'+sta_apid+'_mode', data=ddmode
get_data, 'mvn_sta_'+sta_apid+'_att', data=ddatt
get_data, denname, data=ddNi, dlimit=dlden, limit=llden  ;derived density. Should be same length as ddatt and ddmode

if keyword_set(trange) then begin
    iTIME = where(ddmode.x ge trange[0] and ddmode.x le trange[1], neleT1)
endif else begin
    neleT1 = n_elements(ddmode.x)
    iTIME = findgen(neleT1)
endelse

neleT2 = n_elements(ddNi.x)  ;this has already accounted for trange

if neleT1 ne neleT2 then begin
    success=0
    print, proname, ": attenuator data and density data have a different number of time steps. Bailing."
    return
endif else begin
    ;Extract attenuator and mode info for trange:
    attx = ddatt.x[iTIME]
    atty = ddatt.y[iTIME]
    ;modex = ddmode.x[iTIME]  ;same as attx
    modey = ddmode.y[iTIME]
    
    ;Find times when attenuator state goes from 0->1 or 1->0. Leave these times blank for O+:
    iFI1 = where((atty[0:*] eq 0 and atty[1:*] eq 1.) or (atty[0:*] eq 1 and atty[1:*] eq 0.), niFI1)  
    if niFI1 gt 0 then ddNi.y[iFI1+1l,2] = !values.f_nan  ;make the O+ point after the mode change NaN.
    
    ;Find times when attenuator state goes from 1->2 or 2->1. Density code already sets density to 0 for all of these
    ;times, but set them to nans here.
    iFI1b = where((atty[0:*] eq 1 and atty[1:*] eq 2.) or (atty[0:*] eq 2 and atty[1:*] eq 1.), niFI1b)  
    if niFI1b gt 0 then ddNi.y[iFI1b,*] = !values.f_nan  ;make density point during the mode change NaN. CMF checked no +1l here
      
    ;Find times when mode goes to 7:
    mode2 = modey eq 7
    iFI2 = where((mode2[0:*] eq 0 and mode2[1:*] eq 1) or (mode2[0:*] eq 1 and mode2[1:*] eq 0), niFI2)
    if niFI2 gt 0 then begin
        ;Average over the two neighboring O2+ values:
        for pp = 0l, niFI2-1l do begin
            midI = iFI2[pp]+1l  ;mid point is the point that will be the average
            I1 = (midI-1l)>0l  ;> and < are cludges to avoid code breaking if mdoe change occurs on first and last point of file.
            I2 = (midI+1l)<(neleT1-1l)
            aveTMP = mean([ddNi.y[I1,3], ddNi.y[I2,3]],/nan)  ;do for just O2+
            
            ddNi.y[midI,3] = aveTMP         
        endfor  ;pp     
    endif
    
    ;Restore corrected variable:
    store_data, denname+'_2', data=ddNi, dlimit=dlden, limit=llden
      options, denname+'_2', ytitle='Ion density!Cprelim [cm!U-3!N]'   ;CMF: 2021-08-18 - this used to be "Final", but it's not
    
    success=1
  
endelse

end

;###########
;###########

;+
;
;mvn_sta_l3_den_stitch_scpot_flag - > mvn_sta_l3_den_stitch_scpot_flag
;-

pro mvn_sta_l3_den_stitch_scpot_flag, success=success, trange=trange

get_data, 'mvn_sta_c6_scpot', data=ddscpot_sta
get_data, 'mvn_sta_c6_energypeak', data=ddenpeak

if size(ddscpot_sta,/type) eq 8 and size(ddenpeak,/type) eq 8 then begin
    if keyword_set(trange) then begin
        iTIME = where(ddscpot_sta.x ge trange[0] and ddscpot_sta.x le trange[1], neleT)
    endif else begin
        neleT = n_elements(ddscpot_sta.x)
        iTIME = findgen(neleT)
    endelse
    
    ;Large values of sc potential are only problematic when ion energies are low. Conditions:
    ;[peakenergy > 20 eV], flag=0 (ok)
    ;sc pot > -8 eV, flag = 0 (ok)
    ;peakenergy < 20 eV and sc pot < -8 V, flag=1 (may be problematic).
    ;These conditions should take into account high altitude cases when STATIC can't determine sc pot, but peakenergy is large.
    flag_arr = fltarr(neleT) +1. ;default=1, ie not ok
    enthreshold = 20.  ;eV
    scthreshold = -8.  ;V
    
    i1 = where(ddenpeak.y[iTIME] ge enthreshold, ni1)
    if ni1 gt 0 then flag_arr[i1] = 0.  ;ok
    i2 = where(ddscpot_sta.y[iTIME] gt scthreshold, ni2)
    if ni2 gt 0 then flag_arr[i2] = 0.  ;ok
    i3 = where(ddenpeak.y[iTIME] lt enthreshold and ddscpot_sta.y[iTIME] lt scthreshold, ni3)
    if ni3 gt 0 then flag_arr[i3] = 1.  ;bad
    
    tname = 'mvn_sta_scpot_flag'
    store_data, tname, data={x: ddenpeak.x[iTIME], y: flag_arr}
      ylim, tname, -1, 2
      options, tname, ztitle='0 = ok!C1 = caution'
    
    success=1
endif else success=0

end


;###########
;###########

;+
;Determine quality flags for each timestep, and put in to a structure which is returned.
;
;Flags returned are:
; - Field of view rating, from mvn_sta_fov_snap. 0 = beam in FOV, 1 or 2 = beam probably in FOV, 3 = plasma probably not beam like, and not in FOV.
; - Min number of counts threshold.
; - Large sc pot (<-8 V).
; - Within one step (4s) of a mode or attenuator change.
; - Is STATIC pointing towards planet?
;
;Add in flow vectors as well:
; - Peak energy of beam vs sc pot
; - SC velocity correction
; - Flag / remove data when getting into ion-neutral wind territory
;
;
;
;mvn_sta_l3_den_stitch_flags - > mvn_sta_l3_den_stitch_flags
;-

function mvn_sta_l3_den_stitch_flags, spicekernels=spicekernels, trange=trange

get_data, 'mvn_sta_density_prelim', data=ddSTAden  ;[timex5] H+, He+, O+, O2+, CO2+

timearr = ddSTAden.x

tr = [min(timearr,/nan), max(timearr,/nan)]

neleT = n_elements(timearr)

;==========
;---FOV---:
;==========
;Leave this out for now - takes long time, and requires specific knowledge of energy ranges being considered. Also need to know whether d0 or d1 are used.
mranges = mvn_sta_get_mrange()
;mvn_sta_fov_snap, trange=trange, sta_apid=sta_apid, mrange=mranges.H, success=success_fov_1  ;from mac_den
;mvn_sta_fov_snap, trange=trange, sta_apid=sta_apid, mrange=mranges.He, success=success_fov_2
;mvn_sta_fov_snap, trange=trange, sta_apid=sta_apid, mrange=mranges.O, success=success_fov_16
;mvn_sta_fov_snap, trange=trange, sta_apid=sta_apid, mrange=mranges.O2, success=success_fov_32   ;Because O2+ tail tends to contaminate CO2+, use O2+ flag for CO2+ for now.

;=============
;---SC pot---:
;=============
mvn_sta_l3_den_stitch_scpot_flag, success=success_scpot

;=====================
;---NADIR POINTING---:
;=====================
;get_data, 'mvn_sta_c6_energypeak', data=ddenpeak
get_data, 'mvn_sta_c6_peak_counts_energy_O2p', data=ddenpeak ;2026-05: nadir pointing is to determine if nbc_4d can be used,
                  ;whih will be when O2+ dominates (in ionosphere)
if keyword_set(trange) then begin
  iTIME = where(ddenpeak.x ge trange[0] and ddenpeak.x le trange[1], neleTOT)
endif else begin
  neleTOT = n_elements(ddenpeak.x)
  iTIME = findgen(neleTOT)
endelse
;The nadir routine will re-run mvn_sta_anc_ephemeris, because the current variables are for ca timestamps. we need c6, which can have slightly
;different numbers of elements.
mvn_sta_mom_nadirpoint, ddenpeak.x[iTIME], spicekernels=spicekernels, success=success_nadir  ;see routine for names of tplot variables returned

;==============
;---SW FLAG---: flag when sc is in sw
;==============
;mvn_sta_mom_swregion, sta_apid='c6', success=success_swregion, trange=trange  ;produces mvn_sta_sw_region
success_swregion=1

;==================================
;---Counts ~< background counts---:
;==================================
;*** 01-31-22: CMF: this section removed for H+ and He++ as well - grab count rates in mac_den_v2, using get_4dt, where all other bits are gathered.
;*** 01-28-22: CMF: this section removed for heavy ions - it was not getting correct counts for CO2+. Instead use the outputs from 
;mvn_sta_l3_mac_den_v2.pro
;Flag times when counts are ~< background counts, for each mass species.
;*** keep this to calculate counts and bkg counts (need new CO2+ code from Jim first). 
;A later routine will then flag this (keep the flagging here for now).
;mvn_sta_cnt_bkg_flag, [mranges.h[0], mranges.h[1]], 'c6', trange=trange, success=success_cnts_flag_1, tplotname='mvn_sta_h+_c6'  ;creates tplot variable mvn_sta_h+_c6_cnts, mvn_sta_h+_c6_bkg
;mvn_sta_cnt_bkg_flag, [mranges.he[0], mranges.he[1]], 'c6', trange=trange, success=success_cnts_flag_2, tplotname='mvn_sta_he+_c6'
;mvn_sta_cnt_bkg_flag, [mranges.o[0], mranges.o[1]], 'c6', trange=trange, success=success_cnts_flag_3, tplotname='mvn_sta_c6_o'
;mvn_sta_cnt_bkg_flag, [mranges.o2[0], mranges.o2[1]], 'c6', trange=trange, success=success_cnts_flag_4, tplotname='mvn_sta_c6_o2'
;mvn_sta_cnt_bkg_flag, [mranges.co2[0], mranges.co2[1]], 'c6', trange=trange, success=success_cnts_flag_5, tplotname='mvn_sta_c6_co2'

;=======================
;---Counts threshold---:
;=======================
;Flag when counts < min value required, for each mass, using the outputs from mvn_sta_cnt_bkg_flag.
;*** This is now moved to a later routine as it's flaggin based on a threshold

;=========================
;---Att / mode changes---:
;=========================
;Average points either side of these.
mvn_sta_l3_den_stitch_att_mode_changes, sta_apid='c6', success=success_attmode, trange=trange


;stop
end

;###########
;###########

;+
;Routine that decides whether to use nbc or n_4d density values.
;Routine also calculate uncertainty for each density value, once nbc or n_4d() has been picked.
;
;2021-08-03: CMF modified, if altitude>600 km, use d0/d1 instead of nbc for heavy ions. This is based upon cold ion outflow
;            in tail (at 2000-3000 km) where nbc was being selected at times, but could not provide a density. n_4d() should
;            be fine, as spacecraft velocity is ~half compared to periapsis.
;
;mvn_sta_l3_den_stitch_pickmethod -> mvn_sta_l3_den_stitch_pickmethod
;-

pro mvn_sta_l3_den_stitch_pickmethod, yesd0, yesd1, trange=trange

common mvn_c6, get_ind_c6, all_dat_c6
@'qualcolors'
if size(qualcolors,/type) eq 0 then begin
  cols=get_colors()
  colblack = cols.black
  colblue = cols.blue
  colgreen = cols.green
  colred = cols.red
  colpurple = cols.purple
endif else begin
  colblack = qualcolors.black
  colblue = qualcolors.blue
  colgreen = qualcolors.green
  colred = qualcolors.red
  colpurple = qualcolors.purple
endelse

;Get position data from common block, and subtract 3390 km. Used for getting altitude above which we always use n_4d() for heavy ions.
;This isn't IAU, but should be fine for these high altitudes.
pos_magnitude1 = sqrt(all_dat_c6.pos_sc_mso[*,0]^2 + all_dat_c6.pos_sc_mso[*,1]^2 + all_dat_c6.pos_sc_mso[*,2]^2)
pos_magnitude2 = pos_magnitude1 - 3390.

;Get nbc data:
get_data, 'mvn_sta_o+_c6_density2', data=ddO_nbc
get_data, 'mvn_sta_o2+_c6_density2', data=ddO2_nbc
get_data, 'mvn_sta_c6_den_co2', data=ddCO2_nbc

;If nbc data don't exist, create temp arrays with false timestamps. When the code tries to match nbc and moment values to specific
;timestamps below, it won't match the temp nbc values (which is done based on timestamps). This saves a lot of error checking:
if size(ddO_nbc,/type) ne 8 then ddO_nbc = {x: -999.d, y: -999.}
if size(ddO2_nbc,/type) ne 8 then ddO2_nbc = {x: -999.d, y: -999.}
if size(ddCO2_nbc,/type) ne 8 then ddCO2_nbc = {x: -999.d, y: -999.}

;Get n_4d data:
get_data, 'mvn_sta_c6_den_p', data=ddp_c6_n4d  ;H+ and He+ agree very well between c6 and d1 when no attenuators in. This is most of the time.
get_data, 'mvn_sta_c6_den_a', data=dda_c6_n4d  ;With attenuators, they may disagree, but I haven't found evidence to conclude either way yet.
if yesd0 eq 1 then begin
    get_data, 'mvn_sta_d0_den_p', data=ddp_d0_n4d  
    get_data, 'mvn_sta_d0_den_a', data=dda_d0_n4d  
    get_data, 'mvn_sta_o+_d0_density_n_4d', data=ddO_d0_n4d
    get_data, 'mvn_sta_o2+_d0_density_n_4d', data=ddO2_d0_n4d
    get_data, 'mvn_sta_co2+_d0_density_n_4d', data=ddCO2_d0_n4d
    neleTd0 = n_elements(ddO2_d0_n4d.x)
endif
if yesd1 eq 1 then begin
    get_data, 'mvn_sta_d1_den_p', data=ddp_d1_n4d  
    get_data, 'mvn_sta_d1_den_a', data=dda_d1_n4d  
    get_data, 'mvn_sta_o+_d1_density_n_4d', data=ddO_d1_n4d
    get_data, 'mvn_sta_o2+_d1_density_n_4d', data=ddO2_d1_n4d
    get_data, 'mvn_sta_co2+_d1_density_n_4d', data=ddCO2_d1_n4d   
    neleTd1 = n_elements(ddO2_d1_n4d.x) 
endif

get_data, 'mvn_sta_o+_c6_density_all', data=ddO_c6_n4d ;n_4d on c6 data. Used to fill in when we don't have d1 data (only d0), and can use n_4d.
get_data, 'mvn_sta_o2+_c6_density_all', data=ddO2_c6_n4d

;Get sc pot data:
get_data, 'mvn_sta_c6_cb_scpot', data=ddscpot  ;this has the same times and length as the c6 data product (it's based on it) - it has accounted for trange (but seems to have one extra time stamp...?)

;Get %energy peak and peak energy data: CMF: 2026-05: these are no longer used - use the c6 parameters below instead.
get_data, 'mvn_sta_ca_anode_perc_all', data=ddcaperc     ;these two do not always have same number of timesteps, because they are based on ca and c6 respectively.
get_data, 'mvn_sta_ca_panode_index_all', data=ddpanode ;index of anode peak eflux is in
;get_data, 'mvn_sta_c6_energypeak', data=ddpeaken ;old - eflux, no longer used - we use counts now

;2026:05: use energy width in c6 to determine if beam like (not ca). Use energy of bin with peak counts for the energy check.
;These changes make these checks the same as those in nbc_4d. These are now as a function of species:
get_data, 'mvn_sta_c6_peak_counts_perc_Op', data=ddc6perc_op ;% of counts in peak+-4 energy bins (same as nbc_4d) NOTE: top row = just the peak, second = peak+-4, use this one***
get_data, 'mvn_sta_c6_peak_counts_energy_Op', data=ddc6peakenergy_op ;peak energy in eV, that has peak counts
get_data, 'mvn_sta_c6_peak_counts_perc_O2p', data=ddc6perc_o2p ;% of counts in peak+-4 energy bins (same as nbc_4d)
get_data, 'mvn_sta_c6_peak_counts_energy_O2p', data=ddc6peakenergy_o2p
get_data, 'mvn_sta_c6_peak_counts_perc_CO2p', data=ddc6perc_co2p ;% of counts in peak+-4 energy bins (same as nbc_4d)
get_data, 'mvn_sta_c6_peak_counts_energy_CO2p', data=ddc6peakenergy_co2p

get_data, 'mvn_sta_c6_att', data=ddatt   ;has NOT accounted for trange
get_data, 'mvn_sta_c6_mode', data=ddmode

;Combine mode and att variables:
tnametmp = 'mvn_sta_c6_att_mode'
store_data, tnametmp, data=['mvn_sta_c6_mode', 'mvn_sta_c6_att']
  options, tnametmp, colors=[colblack, colred]
  options, tnametmp, labels=['mode', 'att']
  options, tnametmp, labflag=1

;Mark a transition point: base it on total eflux (ie min threshold) and energy of peak. Include sc_pot in energy threshold - adjust by this amount.
;Some preliminary guesses for when to use nbc (over n_4d):
;% energypeak>85%
;peak energy - sc_pot < 20. eV (if STATIC can't find sc pot, then use n_4d by default)

;Because nbc are shorter in length than c6 (and n_4d), loop through each time stamp; find if there's a matching nbc time. If not, use n_4d. If so,
;check to see which one to use.

if keyword_set(trange) then begin
    ;I originally used ddatt as the guide for how many c6 timestamps there are, but this is sometimes slightly off compared to eg ddO_c6_n4d.x. This caused some crashes.
    ;So now I used ddO_c6_n4d here. Edit - this way also broke, because I need the scp and att states, which are the same as c6 timestamps. So back
    ;to the old way, and a check to avoid the crash later
    iTIME = where(ddatt.x ge trange[0] and ddatt.x le trange[1], neleTOT)  ;ddatt is the full day, while ddscpot has already been filtered for trange
    ;iTIME = where(ddO_c6_n4d.x ge trange[0] and ddO_c6_n4d.x le trange[1], neleTOT)  ;ddatt is the full day, while ddscpot has already been filtered for trange

endif else begin
    neleTOT = n_elements(ddatt.x)
    iTIME = findgen(neleTOT)  ;neleTOT based on c6 data. Note, ddatt can sometimes have one more timestamp than eg ddO_c6_n4d. I'm not sure why,
                              ;but it seems that the last timestamp is the extra one, and I have checks below to avoid illegal subscripts.
endelse

;ARRAYS:
attstate = ddatt.y[iTIME]  ;attenuator state at c6 cadence, accounted for trange
nelec6 = n_elements(ddO_c6_n4d.x)  ;number of c6 data points (should be the same as neleTOT)
;neleD0D1 = n_elements(ddO_n4d.x)  ;the number of elements in the d0/d1 arrays
den_array = fltarr(neleTOT, 5) +!values.f_nan ;H+, He+, O+, O2+, CO2+
den_method = fltarr(neleTOT,3) +!values.f_nan  ;0 = n_4d, 1 = nbc for O+; 2= nbc for O2+; 3 = nbc for CO2+ 
light_den_method = fltarr(neleTOT)+!values.f_nan  ;H+ and He++. 0 = c6, 1 = d0, 2 = d1. Code always uses n_4d() for these.
c6time_array = ddp_c6_n4d.x  ;copy time array

;NOTES: H+ and He+ always use n_4d, as lighter mass means nbc not required. Confirmed by comparison to nbc. Use d1 when attenuators are in, otherwise
;use c6. 

;threshold_perc is for anode - not energy, which is what nbc_4d requires. Need to add that in here as well, otherwise
;can get times where it passes here but then fails in nbc_4d.
c6threshold_perc = 75.  ;%, same as nbc_4d - this many counts must lie in peak energy bin, to be beam
cathreshold_perc = 75.  ;% this many counts must lie in the three neighboring ram anodes, to be a beam (and the peak must lie in the ram anode)
threshold_en = 20.  ;eV: the eflux peak must be below this value, after correction for sc pot, to be considered a cold beam

maxtime = 4.d  ;if d0 data are used, data can be 64s+ from c6 data. So, in order to not duplicate d0 data for most of the c6 array,
               ;only include data within 4s of c6 (which is at 4s cadence). 

altlim = 5000. ;650. ;km, altitude above which always use n_4d() over nbc, regardless of other parameters.

;Arrays for pairing d0 and d1 data to each c6 data point.
d0d1pair = fltarr(neleTOT,2)+!values.f_nan ;top row = d0, bottom = d1. The numbers are the indices in the d0 and d1 arrays, that pair to that element
                                           ;in the c6 array. If a d1 data point pairs, the code won't check for d0.
apidmethod = fltarr(neleTOT,5)+!values.f_nan ;store the apid used to derive density for each timestamp. Rows top to bottom are H+, He++, O+, O2+, CO2+.
                                             ;Codes are: 1 = c6, 2 = d0, 3 = d1.

;Determine if d0 or d1 data point should be paired to this c6 time.
;First, go through and pair all d0 data to c6 timestamps. Because d0 are averaged over 4s+, d0 data can be duplicated, based on the
;dt between d0 data, giving a "chunky" density profile.
;Second, go through and pair d1 data to c6 timestamps. These will overwrite any d0 data present, giving higher time resolution.
;Third, when attenuator state = 0, c6 data can be used if d0 or d1 data are not available (or to turn d0 to higher time cadence).
if yesd0 eq 1 then begin
     for ttd0 = 0l, neleTd0-1l do begin
          d0time = ddO2_d0_n4d.x[ttd0]  ;current d0 timestamp
          diff = abs(c6time_array - d0time)  ;find c6 time that this d0 time pairs to
          m1 = min(diff, c6iTMP, /nan)  ;c6iTMP is the c6 indice that this ttd0 pairs to
          
          if m1 lt 4. then begin ;I think this has to be 4s, which is the dt of c6 data
              ;The dt to the previous timestep; but if this is the first value, assume it's the same as dt to the next timestep:
              if ttd0 eq 0 then d0_dt1 = ddO2_d0_n4d.x[ttd0+1l] - ddO2_d0_n4d.x[ttd0] else d0_dt1 = ddO2_d0_n4d.x[ttd0] - ddO2_d0_n4d.x[ttd0-1l]
              ;The dt to the next timestep; but if this is the last value, assume it's the same as dt from the previous timestep:
              if ttd0 eq neleTd0-1l then d0_dt2 = ddO2_d0_n4d.x[ttd0] - ddO2_d0_n4d.x[ttd0-1l] else d0_dt2 = ddO2_d0_n4d.x[ttd0+1l] - ddO2_d0_n4d.x[ttd0]
      
              ;Find c6 times/indices that lie within this d0/d1 range:
              d0_t1 = d0time - (d0_dt1/2d)
              d0_t2 = d0time + (d0_dt2/2d)
              ic6TMP = where(c6time_array ge d0_t1 and c6time_array lt d0_t2, nic6TMP) ;these are the indices in den_array that d0 data occupy
              
              if nic6TMP gt 0 then begin
                  ;Check all indices lie within d0d1pair array length:
                  ikptmp = where(ic6TMP lt neleTOT, nikptmp)
                  ;Save if there are 1+ points; leave as NaN if not
                  if nikptmp gt 0 then d0d1pair[ic6TMP[ikptmp],0] = ttd0  ;d0 time ttd0 pairs to these c6 indices, ic6TMP, in the c6 array.
              endif            
          endif 
     endfor
endif

;Now loop through d1 data (if present), and pair these to c6 data points:
if yesd1 eq 1 then begin
    for ttd1 = 0l, neleTd1-1l do begin
        d1time = ddO2_d1_n4d.x[ttd1]  ;current d1 timestamp
        diff = abs(c6time_array - d1time)
        m1 = min(diff, c6iTMP, /nan)
        
        ;Only add this if the indice is within the array length, if not leave as NaN. This happens sometimes, because the att product is a few 
        ;timestamps less than the actual c6 data. Not sure how to fix this - it's something deeper in the STATIC tplot code I think.
        if m1 lt 1. and c6iTMP lt neleTOT then d0d1pair[c6iTMP,1] = ttd1  ;d1 time ttd1 pairs to this c6 indice, in the c6 array  
        
    endfor 
endif

;Go over all c6 timestamps and create density array:
for tt = 0l, neleTOT-1l do begin
    timeTMP = ddscpot.x[tt]  ;time of this timestamp - has accounted for trange
    attTMP = ddatt.y[iTIME[tt]]  ;attenuator state - iTIME[] needed to account for trange
    altTMP = pos_magnitude2[iTIME[tt]]  ;magnitude of position in MSO frame 
    
    ;*** in nbc_4d, the code requires 75% of counts lie in the peak ENERGY bin (from c6). That is different to below which
    ;currently uses anodes -> 2026-05: CMF: this is now fixed and the same criteria are used.
    
    ;Find % of counts in c6 peak count bins: this is a function of mass for heavy ions, which all share the same timestamps
    diffTMP = abs(ddc6perc_op.x - timeTMP) ;same for O+, O2+, CO2+
    min1 = min(diffTMP, imin, /nan)
    diffTMP2 = abs(ddpanode.x - timeTMP) ;anode different timestamps to c6 sometimes
    min2 = min(diffTMP2, imin2, /nan)
    ;For some reason ddca8perc.x and ddscpot.x are off by ~0.0001s, so use min() method instead to pair in time. They can also be different lengths.
    if min1 lt 1. then begin
        countperc = [ddc6perc_op.y[imin,1], ddc6perc_o2p.y[imin,1], ddc6perc_co2p.y[imin,1]]   ;-999 if no value, O+, O2+, CO2+
        char_energy = [ddc6peakenergy_op.y[imin], ddc6peakenergy_o2p.y[imin], ddc6peakenergy_co2p.y[imin]]
        ca_count_perc = ddcaperc.y[imin2,1] ;imin2 for pairing to ca data; use if 75% counts in peak+- one anode
    endif else begin
        countperc = [-999., -999., -999.]
        char_energy = [-999., -999., -999.]
        ca_count_perc = -999.
    endelse
    
    if min2 lt 5. then begin ;panode not always same timesteps as c6, make this more flexible (5s vs 1s above)
      panode = ddpanode.y[imin2] 
    endif else  begin
      panode = -999.
    endelse
    
    case panode of
        6: ramanode=0
        7: ramanode=1  ;used to be 6-8, but ion suppression only calibrated for 7
        8: ramanode=0
        else: ramanode=0
    endcase
    
    ;If d1 data are used, they will have the same time stamp as c6. But if d0 data are being used, they will not. Use the d0d1pair array
    ;from above for pairings.
    d0pair = -999.  ;start by assuming there are no pairings for d0 or d1, for this c6 timestamp
    d1pair = -999.
    if finite(d0d1pair[tt,0]) eq 1 then d0pair = d0d1pair[tt,0] ;record the indice if we have pairings for d0 or d1
    if finite(d0d1pair[tt,1]) eq 1 then d1pair = d0d1pair[tt,1] 
    if d0pair ge 0 or d1pair ge 0 then niFId = 1. else niFId = 0.  ;niFId is used throughout the code to mark when d0 or d1 data are paired, so keep here
    
   
    ;===========
    ;H+ and He+:
    light_den_method_tmp = -999.
    if attTMP eq 0 then begin
        iFI = where(ddp_c6_n4d.x eq timeTMP, niFI)  ;use c6 if attenuator is not in
        if niFI eq 1 then begin
            den_array[tt,0] = ddp_c6_n4d.y[iFI[0]]  ;H+
            den_array[tt,1] = dda_c6_n4d.y[iFI[0]]  ;He+
            light_den_method_tmp = 0.  ;c6
            
            apidmethod[tt,0:1] = 1.  ;c6 apid
        endif
    endif else begin
        ;If attenuator is in, use d0 or d1. Record d0 first, and update with higher cadence d1 if present:
        if d0pair ge 0 then begin
            den_array[tt,0] = ddp_d0_n4d.y[d0pair]  ;H+
            den_array[tt,1] = dda_d0_n4d.y[d0pair]  ;He++
            light_den_method_tmp = 1
            
            apidmethod[tt,0:1] = 2. ;d0
        endif
        if d1pair ge 0 then begin
            den_array[tt,0] = ddp_d1_n4d.y[d1pair]
            den_array[tt,1] = dda_d1_n4d.y[d1pair]
            light_den_method_tmp = 2.
            
            apidmethod[tt,0:1] = 3. ;d1
        endif
    endelse
    light_den_method[tt] = light_den_method_tmp
     ; if light_den_method_tmp lt 0 then stop
    ;ddscpot and ddpeaken have accounted for trange
  ;CMF: 2026-05: replaced peakenergyTMP with char_energy[]
  ;  if finite(ddscpot.y[tt]) eq 1 then peakenergyTMP = ddpeaken.y[tt] + ddscpot.y[tt] else $   ;when sc pot is negative, observed ion energy is increased. Decrease by sc pot.
  ;                                                        peakenergyTMP = ddpeaken.y[tt] - 5.  ;default is to assume sc pot is -5 V if STATIC can't derive it. This is typical at periapsis. At higher 
  ;                                                                                 ;altitudes, peakenergyTMP will be 100s-1000s eV, and this assumption won't matter.
    
    ;===
    ;O+:
    methodTMP = 0.
    iFIb = where(ddO_nbc.x eq timeTMP, niFIb)
    ;iFId = where(ddO_n4d.x eq timeTMP, niFId)  ;use above value
    ;Only n4d available, only use if peakenergy is larger than thershold_en (ie high energy), or altitude>altlim (650?) km. 
    ;Plasma can still be a beam (eg solar wind).
    if (niFIb eq 0 and niFId eq 1 and char_energy[0] ge threshold_en) then begin
          ;Find d0 and/or d1 pairings:
          if d0pair ge 0 then begin
              den_array[tt,2] = ddO_d0_n4d.y[d0pair]
              apidmethod[tt,2] = 2. ;n4d, d0
          endif
          if d1pair ge 0 then begin
              den_array[tt,2] = ddO_d1_n4d.y[d1pair]
              apidmethod[tt,2] = 3. ;update with d1 if available
          endif
    endif
    
    ;Only nbc available, still require low energy, beam like, and either (att=<1) or (att >=2 and panode = 6,7,8):
    if niFId eq 0 and niFIb eq 1 then begin
        if char_energy[0] lt threshold_en and countperc[0] ge c6threshold_perc and ramanode eq 1 and ca_count_perc ge cathreshold_perc then begin  ;and ((attTMP le 1) or (attTMP ge 2 and ramanode eq 1)) then begin 
            den_array[tt,2] = ddO_nbc.y[iFIb[0]]
            apidmethod[tt,2] = 1.  ;nbc, c6
            methodTMP = 1
        endif
    endif
    
    ;Both available, decide which:
    if niFIb eq 1 and niFId eq 1 then begin
          ;To use beam, require low energy, beam like, and either (att=<1) or (att >=2 and panode = 6,7,8): (this used to include ramalt, but this sometimes failed)
          if char_energy[0] lt threshold_en and countperc[0] ge c6threshold_perc and ramanode eq 1 and ca_count_perc ge cathreshold_perc then begin  ;and ((attTMP le 1) or (attTMP ge 2 and ramanode eq 1)) then begin  
              den_array[tt,2] = ddO_nbc.y[iFIb[0]]
              apidmethod[tt,2] = 1.  ;c6, nbc
              methodTMP = 1
          endif else begin
                ;Find d0 and/or d1 pairings, if beam criteria not met:
                if d0pair ge 0 then begin
                      den_array[tt,2] = ddO_d0_n4d.y[d0pair]
                      apidmethod[tt,2] = 2.  ;n4d, d0
                endif
                if d1pair ge 0 then begin
                    den_array[tt,2] = ddO_d1_n4d.y[d1pair]
                    apidmethod[tt,2] = 3.  ;update with d1 if available
                endif
                
                
                ;2026-06-05: I don't think this ever kicks in - have never seen a method=0.5. But also, I don't think it
                ;should be here: if att=0, and code has decided to use d0 already, then we should stick with that, as c6 not
                ;appropriate.
                ;if using d0 (d1 not available), and attenuator state is 0, switch in c6 n_4d data:
              ;  if (d0pair ge 0) and (d1pair lt 0) and (attTMP eq 0) and (tt le (neleC6-1l)) then begin
              ;      den_array[tt,2] = ddO_c6_n4d.y[tt]
              ;      apidmethod[tt,2] = 1.  ;c6
              ;      methodTMP = 0.5
              ;   endif
          endelse
    endif
    den_method[tt,0] = methodTMP
    
    ;====
    ;O2+:
    methodTMP = 0.
    iFIb = where(ddO2_nbc.x eq timeTMP, niFIb)
    ;iFId = where(ddO2_n4d.x eq timeTMP, niFId)  ;use above value
    ;Only n4d available, only use if peakenergy is larger than thershold_en (ie high energy). Plasma can still be a beam (eg solar wind).
    if (niFIb eq 0 and niFId eq 1 and char_energy[1] ge threshold_en) then begin
        ;Find d0 and/or d1 pairings:
        if d0pair ge 0 then begin
              den_array[tt,3] = ddO2_d0_n4d.y[d0pair]
              apidmethod[tt,3] = 2.  ;n4d, d0
        endif
        if d1pair ge 0 then begin
              den_array[tt,3] = ddO2_d1_n4d.y[d1pair]
              apidmethod[tt,3] = 3.  ;update with d1 if available
        endif
    endif
    
    ;Only nbc available: still require low energy and beam like:
    if niFId eq 0 and niFIb eq 1 then begin
        if char_energy[1] lt threshold_en and countperc[1] ge c6threshold_perc and ramanode eq 1 and ca_count_perc ge cathreshold_perc then begin ;((attTMP le 1) or (attTMP ge 2 and ramanode eq 1)) then begin  
            den_array[tt,3] = ddO2_nbc.y[iFIb[0]]
            apidmethod[tt,3] = 1. ;c6, nbc
            methodTMP = 2
        endif
    endif
    
    ;Both available, decide which:
    ;There are rare cases where there are significant energetic ions while at periapsis (eg ion acceleration events). In these cases,
    ;Ni returned by nbc is NaN, but is a finite number from n_4d. I don't yet have a solution for this, as one can't just use n_4d
    ;at periapsis if nbc is not available. Probably, will have to look at these on a case by case basis.
    if niFIb eq 1 and niFId eq 1 then begin
            ;Beam criteria met:
            if char_energy[1] lt threshold_en and countperc[1] ge c6threshold_perc and ramanode eq 1 and ca_count_perc ge cathreshold_perc then begin  ;((attTMP le 1) or (attTMP ge 2 and ramanode eq 1)) then begin                              
                den_array[tt,3] = ddO2_nbc.y[iFIb[0]]
                apidmethod[tt,3] = 1.  ;c6
                methodTMP = 2
            endif else begin
                  ;Find d0 and/or d1 pairings, if beam criteria not met:
                  if d0pair ge 0 then begin
                        den_array[tt,3] = ddO2_d0_n4d.y[d0pair]
                        apidmethod[tt,3] = 2.  ;n4d, d0
                  endif
                  if d1pair ge 0 then begin
                      den_array[tt,3] = ddO2_d1_n4d.y[d1pair]
                      apidmethod[tt,3] = 3.  ;update with d1 if available
                  endif
                  
                  ;2026-06-05: I don't think this ever kicks in - have never seen a method=0.5. But also, I don't think it 
                  ;should be here: if att=0, and code has decided to use d0 already, then we should stick with that, as c6 not
                  ;appropriate.
                  ;if using d0 (d1 not available), and attenuator state is 0, switch in c6 n_4d data:
                 ; if (d0pair ge 0) and (d1pair lt 0) and (attTMP eq 0) and (tt le (neleC6-1l)) then begin
                 ;   den_array[tt,3] = ddO2_c6_n4d.y[tt]
                 ;   apidmethod[tt,3] = 1.  ;c6 
                 ;   methodTMP = 0.5
                 ; endif
            endelse            
    endif
    den_method[tt,1] = methodTMP

    ;=====
    ;CO2+:
    methodTMP = 0.
    iFIb = where(ddCO2_nbc.x eq timeTMP, niFIb)
    ;iFId = where(ddCO2_n4d.x eq timeTMP, niFId)  ;use above value
    ;Only n4d available: peakenergy must be >threshold_en - can only use n4d for pick up CO2+. But actually we remove this later anyway as not fully calibrated - only keep nbc for CO2+
    if (niFIb eq 0 and niFId eq 1 and char_energy[2] gt threshold_en) then begin
          ;Find d0 and/or d1 pairings:
          if d0pair ge 0 then begin
                den_array[tt,4] = ddCO2_d0_n4d.y[d0pair]
                apidmethod[tt,4] = 2.   ;n4d, d0
          endif
          if d1pair ge 0 then begin
                den_array[tt,4] = ddCO2_d1_n4d.y[d1pair]
                apidmethod[tt,4] = 3.   ;update with d1 if available
          endif
    endif
    
    ;Only nbc available: still require low energy and beam like conditions:
    if niFId eq 0 and niFIb eq 1 then begin
        if char_energy[2] lt threshold_en and countperc[2] ge c6threshold_perc and ramanode eq 1 and ca_count_perc ge cathreshold_perc then begin  ;((attTMP le 1) or (attTMP ge 2 and ramanode eq 1)) then begin 
          den_array[tt,4] = ddCO2_nbc.y[iFIb[0]]
          apidmethod[tt,4] = 1. ;c6, nbc
          methodTMP = 3
        endif
    endif
    
    ;Both available, decide which:
    if niFIb eq 1 and niFId eq 1 then begin
          if char_energy[2] lt threshold_en and countperc[2] ge c6threshold_perc and ramanode eq 1 then begin ;((attTMP le 1) or (attTMP ge 2 and ramanode eq 1)) then begin  
              den_array[tt,4] = ddCO2_nbc.y[iFIb[0]]
              apidmethod[tt,4] = 1.  ;c6
              methodTMP = 3
          endif else begin
              ;Find d0 and/or d1 pairings, if beam criteria not met:
              if d0pair ge 0 then begin
                    den_array[tt,4] = ddCO2_d0_n4d.y[d0pair]
                    apidmethod[tt,4] = 2.  ;n4d, d0
              endif
              if d1pair ge 0 then begin
                    den_array[tt,4] = ddCO2_d1_n4d.y[d1pair]
                    apidmethod[tt,4] = 3.  ;update with d1 if available
              endif

              ;if using d0 (d1 not available), and attenuator state is 0, switch in c6 n_4d data:
              ;***There is no c6 density entry for CO2+ -> this isn't available at the moment.***
             ; if (d0pair ge 0) and (d1pair lt 0) and (attstate[tt] eq 0) and (tt le (neleC6-1l)) then begin
             ;   den_array[tt,4] = ddCO2_c6_n4d.y[tt]
             ;   methodTMP = 0.5
             ; endif
          endelse  
    endif
    den_method[tt,2] = methodTMP
endfor


;STORE INTO TPLOT:
tname = 'mvn_sta_d0d1pair'
store_data, tname, data={x: ddscpot.x, y: d0d1pair}
  options, tname, colors=[colblack, colpurple, colblue, colred, colgreen]
  options, tname, labels=['H+', 'He++', 'O+', 'O2+', 'CO2+']
  options, tname, labflag=1
  ylim, tname, 0., 4.
  options, tname, ytitle='STA d0, d1!Cpair indices'

tname = 'mvn_sta_apid_method'
store_data, tname, data={x: ddscpot.x, y: apidmethod}
  options, tname, colors=[colblack, colpurple, colblue, colred, colgreen]
  options, tname, labels=['H+', 'He++', 'O+', 'O2+', 'CO2+']
  options, tname, labflag=1
  ylim, tname, 0., 4.
  options, tname, ytitle='STA apid!Cmethod!C1=c6, 2=d0!C3=d1'

tname = 'mvn_sta_den_method'
store_data, tname, data={x: ddscpot.x, y: den_method}
  options, tname, colors=[colblue, colred, colgreen]
  options, tname, labels=['O+', 'O2+', 'CO2+']
  options, tname, labflag=1
  ylim, tname, -1, 4
  options, tname, ytitle='Ion density!Cmethod'
  
tname = 'mvn_sta_light_den_method'
  store_data, tname, data={x: ddscpot.x, y: light_den_method}
  options, tname, colors=[colblack]
  options, tname, labels=['H+, He++']
  options, tname, labflag=1
  ylim, tname, -1, 3
  options, tname, ytitle='H+ and He++ ion!Cdensity method'  

tname = 'mvn_sta_density_prelim'
store_data, tname, data={x: ddscpot.x, y: den_array}
  options, tname, colors=[colblack, colpurple, colblue, colred, colgreen]
  options, tname, labels=['H+', 'He++', 'O+', 'O2+', 'CO2+']
  options, tname, labflag=1
  options, tname, ylog=1
  ylim, tname, 0.1, 1E4
  options, tname, ytitle='Ion density!C[cm!U-3!N]'

end

;==================
;===MAIN ROUTINE===
;==================
;+
;Currently, mac_den must be run first, and the results are used as inputs here. CMF needs to edit code so that mac_den is run here.
;
;
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_den_stitch.pro
;-

pro mvn_sta_l3_den_stitch, spicekernels=spicekernels, trange=trange, colorindices=colorindices

;Check if d1 data are loaded. Use d1 where available, and fill in with d0 where not. d0 can be replaced with c6 with attenuator state = 0.
get_data, 'mvn_sta_o+_d0_density_n_4d', data=ddd0
get_data, 'mvn_sta_o+_d1_density_n_4d', data=ddd1
;Defaults:
yesd0 = 0
yesd1 = 0

if size(ddd0, /type) eq 8 then yesd0 = 1
if size(ddd1, /type) eq 8 then yesd1 = 1


;Check for SPICE kernels; if not set, load them here:
if not keyword_set(spicekernels) then begin
  kernels = mvn_sta_anc_determine_spice_kernels()
  if kernels.nTOT eq 0 then spicekernels=mvn_spice_kernels(/load)  ;load SPICE if not loaded
endif

;This overplots the RAM direction in the STATIC ca and c8 tplot products. Useful for checking, but not required for creating density
;variables.
;mvn_sta_l3_den_stitch_ram, success=success1, spicekernels=spicekernels, trange=trange

mvn_sta_l3_den_stitch_pickmethod, yesd0, yesd1, trange=trange

;Determine quality flags. This code also averages across attenuator state changes, to produce mvn_sta_density_prelim_2:
flag_str = mvn_sta_l3_den_stitch_flags(trange=trange, spicekernels=spicekernels)  ;how deal with 'cf' ?



end




