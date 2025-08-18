;+
;Crib to get STATIC flow information. Working progress. Routine produces flow vectors in MSO frame. 
;
;This routine will check that SPICE kernels exist such that STATIC pointing information can be rotated to the MSO frame
;at each timestep, using mvn_sta_ck_check. If not loaded, the routine will load them using mvn_spice_kernels(/load), based on the set values
;of timespan.
;
;This routine uses j_4d, which corrects for sc potential if it is present in the STATIC common blocks. By default, the L2 STATIC data contain the 
;sc potential (as estimated from STATIC). This tends to work well through periapsis in the ionosphere, but STATIC cannot determine the sc potential
;when it is positive (ie at high altitudes in sunlight). In such cases, there is currently no correction applied.
;
;
;INPUTS:
;Load in STATIC ce, cf, d0 or d1 data into tplot and IDL. Use mvn_sta_l2_load, sta_apid=sta_apid.
;             
;sta_apid: the STATIC data product to use, as a string. Choose from 'ce', 'cf', 'd0', 'd1'.   
;
; 
;             
;OUTPUTS:
;tplot variables: containing the MSO x, y, z fluxes for various ion species. Units are #/cm^2/s. Each tplot variable has the
;                 AMU mass number appended to it. Note that there are only 8 mass bins within the d0/d1 data products, so mass
;                 resolution is coarse.      
;                 
;                 "correction_factor": the size of the sc velocity correction factor, which can be compared to the ion flux and/or velocity.
;                 
;                 "correction_flag": flags when the sc velocity correction is a significant fraction of the derived ion flux / velocity, and may
;                 result in large errors. 0 = no flag, 1 = sc velocity correction is significant, defined as flux (or velocity)/correction factor < sc_cor_flag
;                 sc_cor_flag is a keyword, with a default value of 2.
;                 
;KEYWORDS:                   
;
;trange: two element double array with start and stop times. If not set, routine will go over the entire loaded data, but this
;         may take a while.
;
;Set /clearspice to clear the loaded SPICE kernels in IDL memory. 
;     Default is to LEAVE the loaded SPICE kernels in IDL memory.
;
;Set /kms to calculate flow in units of km/s.
;
;Set /flux to calculate flow in units of #/cm^2/s.
;
; If neither /kms nor /flux are set, the default is to set /kms.
; 
;species: there are several ions with pre-set mass parameters; enter the following strings (case independent):
;         'H', 'He', 'O', 'O2' or 'CO2'. If set, you don't need to set mrange or m_int - these are set for you. The species input overwrites
;         the mrange and m_int keywords.
;
;mrange: [a,b]: use this keyword to specify the mass range for which flow velocities are calculated for. 
;       Each mass range will have its own tplot variable created. If not set, all masses are used.
;       
;       Some additional notes:
;       STATIC d0 and d1 data have 8 mass bins centered on the following AMU values. The following options are allowed for the 
;       mass keyword:
;       mass  = 1.09 AMU
;             = 2.23 AMU
;             = 4.67 AMU
;             = 9.42 AMU
;             = 17.14 AMU
;             = 30.57 AMU
;             = 42.42 AMU
;             = 62.53 AMU
;     
;       STATIC ce and cf data have 16 mass bins (more mass resolution), but are only available in ~2015. After ~2015, at least d0
;       data should be available all of time (and d1 data should be available most of the time).
;
;m_int: assumed AMU value to calculate flow. If not set, mean of mrange is used.
;
;erange: [a,b]: energy range to look at in eV. If not set, full energy range is used. 
; 
;Set /sc_vel to correct for spaccraft velocity relative to Mars (ie, move from spacecraft frame to Mars frame). When set, the routine
;    will use SPICE to obtain the spacecraft velocity (in the MSO corrdinate system). For ion velocity, the spacecraft velocity is subtracted
;    from the ion velocity in the spacecraft frame. For particle flux, j' = j - n*sc_vel; ie, flux in the Mars frame is equal to flux in the
;    spacecraft frame minus (density * spacecraft velocity). 
;    
;    ### IMPORTANT ### as of 2019-11-07, the code uses n_4d to calculate density when correcting the number flux for sc velocity. This may not be
;    correct at lower altitudes when the ion distribution becomes a beam. CMF needs to adjust code to use L3 densities, once these are 
;    available. 
; 
;BINS: bytarr(ne,na),  optional, energy/angle bins to be included in the array for integration
;      0,1=exclude,include    
;      Default is to include all bins if not set.
;      ne = dat.energy (number of energy bins)
;      nb = dat.nbins (number of anode-deflector bins)
;      When set, data=dat.dat * bins. Zero elements do not contribute to the flux calculation.
; 
;sc_cor_flag: the value used to determine whether corrections for sc velocity are significant compared to derived ion fluxes or velocities. A flag is 
;             set when flux (or velocity)/correction factor < sc_cor_flag.
;             The default value of sc_cor_flag is 2, if not set.
;
;qc: set /qc if you have Mike Chaffins qualcolors installed. If not, leave, and the routine will use the current color table.
;
;NOTES:
;d0 and d1 data are large - don't try to load too many days at once, unless you have lots of RAM (lots means >= 16 Gb).
;
;This routine will load in SPICE kernels for co-ordinate rotation, using mvn-spice-kernels. It will then remove them from IDL 
;memory once run. Use the above keywords to change whether these actions occur. The routine assumes that timespan has been set by the user.
;
;The 8 mass bins in d0/d1 are centered on:
;1.09088, 2.22833, 4.67166, 9.41619, 17.1449, 30.5701, 42.4226, 62.5310
;
;EGS:
;timespan, '2019-02-03', 1.
;mvn_sta_l2_load, sta_apid=['d1'], /tplot_vars_create
;kk = mvn_spice_kernels(/load)   ;load SPICE kernels based on timespan
;mvn_sta_flow, /flux, species='O', sta_apid='d1', spicekernels=kk  ;calculate O+ flow vectors for all available timestamps. SPICE is loaded before hand.
;
;
;timespan, '2019-02-03', 1.
;mvn_sta_l2_load, sta_apid=['d1'], /tplot_vars_create
;ctime, tt   ;for now, this routine requires a time range input as flow calculations take a long time on an entire day.
;mvn_sta_flow, /flux, species='O2', sta_apid='d1', trange=tt  ;calculate O2+ vectors for selected time range only. SPICE is loaded within the routine.
;
;
;UPDATES:
;2024-03-26: CMF: STATIC apid is now adde to the tplot variable names produced, so that the flow vector can be derived from multiple apids in
; the same session.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Flow_routines/mvn_sta_flow.pro
;-
;

pro mvn_sta_flow, trange=trange, clearspice=clearspice, kms=kms, flux=flux, mrange=mrange, success=success, $
                    sta_apid=sta_apid, erange=erange, m_int=m_int, sc_vel=sc_vel, species=species, bins=bins, sc_cor_flag=sc_cor_flag, qc=qc

proname = 'mvn_sta_flow'

if keyword_set(qc) then begin
  @'qualcolors'
  topc = qualcolors.top_c
  bottomc = qualcolors.bottom_c
  col_white = qualcolors.white
  col_blue = qualcolors.blue
  col_green = qualcolors.green
  col_red = qualcolors.red
endif else begin
  ;There is probably a better way to code colors for default tables. Figure this out.
  topc = 254l
  bottomc = 0l
  col_white=0l
  col_blue = 125l ;guesses for now
  col_green = 175l
  col_red = 254
endelse

;Deal with trange keyword below, once common blocks have been dealt with
if size(sc_cor_flag, /type) eq 0 then sc_cor_flag=2
if size(sta_apid,/type) eq 0 then begin
    print, proname, ": you must define sta_apid as eg 'ce', 'cf', 'd0' or 'd1'. Returning."
    success=0
    return
endif

;CHECK STATIC COMMON BLOACKS ARE LOADED:
;res = execute("common mvn_"+sta_apid+", get_ind_"+sta_apid+", all_dat_"+sta_apid)

common mvn_ce, get_ind_ce, all_dat_ce
common mvn_cf, get_ind_cf, all_dat_cf
common mvn_d0, get_ind_d0, all_dat_d0
common mvn_d1, get_ind_d1, all_dat_d1

;Select data structure based on dSTR:
case strupcase(sta_apid) of
  'CE' : all_dat = all_dat_ce
  'CF' : all_dat = all_dat_cf
  'D0' : all_dat = all_dat_d0
  'D1' : all_dat = all_dat_d1
  else : begin
    print, ""
    print, "sta_apid must be set to either ce, cf, d0 or d1."
    success=0
    return
  end
endcase

strapid = strlowcase(sta_apid)  ;for putting into tplot variable names below

;If keyword species set, go with this:
if size(species, /type) eq 7 then begin
  mranges = mvn_sta_get_mrange()

  species=strupcase(species)
  case species of
    'H' : begin
            mrange = mranges.H
            m_int=1.
          end
    'HE' : begin
             mrange = mranges.He
             m_int=2.
           end
    'O' : begin
            mrange = mranges.O
            m_int=16.
          end
    'O2' : begin
            mrange = mranges.O2
            m_int=32.
          end
    'CO2' : begin
            mrange = mranges.CO2
            m_int=44.
          end
    else :
  endcase
endif

if size(kms,/type) eq 0 and size(flux,/type) eq 0 then kms=1  ;default setting 
if keyword_set(flux) then flux=1 else flux=0
if keyword_set(kms) then kms=1 else kms=0
if keyword_set(sc_vel) then sc_vel=1 else sc_vel=0
if not keyword_set(mrange) then mrange=[0., 100.]
if not keyword_set(erange) then erange=[0., 1e6]  ;use all energies
if not keyword_set(m_int) then m_int = mean(mrange,/nan)

massSTR = strtrim(string(mrange[0], format='(f12.1)'),2)+'-'+strtrim(string(mrange[1], format='(f12.1)'),2)
estr = strtrim(string(erange[0], format='(f12.1)'),2)+'-'+strtrim(string(erange[1], format='(f12.1)'),2)
               
;One final check incase default data is not loaded:
if size(all_dat,/type) eq 0 then begin
  print, ""
  print, "Load requested STATIC data using, e.g., mvn_sta_l2_load, sta_apid=['d0']"
  success=0
  return
endif

;###########
;TIME RANGE: if not set, use full time range instead
if size(trange,/type) eq 0 then trange = [min(all_dat.time,/nan), max(all_dat.end_time,/nan)]

;Routine assumes timespan has already been set appropriately
tr = trange  ;change variable for below

;get_4dt returns a tplot variable N steps long, with 24 lines at each time step. Each set of 3 is a mass bin, X,Y,Z in the STATIC
;FOV. For eg, [N,0:2] are the H+ flow vectors in STATIC; [N,3:5] are the second mass bin flow vectors, and so on.

print, "Getting STATIC data structures..."

;FLOW IN FLUX UNITS: needed for flux
if flux eq 1 then begin
    tname = 'mvn_sta_flow_flux_m'+massSTR+'_er'+estr
    get_4dt, t1=tr[0], t2=tr[1], 'j_4d','mvn_sta_get_'+sta_apid,mass=mrange, name=tname,energy=erange,m_int=m_int, bins=bins
    
    ;Get density if sc_vel correction requested, need density (j' = j - n*sc_vel). For now use n_4d, but use L3 save files once they are available
    if sc_vel eq 1 then begin
      print, ""
      print, "#### mvn_sta_flow #### : CMF should edit code to include STATIC L3 densities, rather than n_4d!!!"
      print, ""
      
      tname_den = 'mvn_sta_flow_dentmp'+massSTR+'_er'+estr
      get_4dt, t1=tr[0], t2=tr[1], 'n_4d', 'mvn_sta_get_'+sta_apid, mass=mrange, name=tname_den, energy=erange, m_int=m_int, bins=bins
    endif
endif

;FLOW IN VEL: needed for units of km/s
if kms eq 1 then begin
     tname = 'mvn_sta_flow_kms_m'+massSTR+'_er'+estr
     get_4dt, t1=tr[0], t2=tr[1], 'v_4d', 'mvn_sta_get_'+sta_apid, mass=mrange, name=tname, energy=erange, m_int=m_int, bins=bins
     
     ;If sc velocity correction requested, just subtract sc velocity in MSO frame, which is done below.
endif

;GETTING SPICE: check whether it's loaded or not. It's needed for any of the rotations requested.
kernels = mvn_sta_anc_determine_spice_kernels()
if kernels.nTOT eq 0 then spicekernels = mvn_spice_kernels(/load)

print, "Performing SPICE rotation..."

;FLUX:
if flux eq 1 then begin
    tname = 'mvn_sta_flow_flux_m'+massSTR+'_er'+estr  ;get correct tplot variable
    
    get_data, tname, data=dd2
    
    vect = transpose(dd2.y[*, 0:2])  ;needs to be 3xN for rotate
    times = dd2.x
    
    ;Check when we have SPICE coverage for STATIC rotations:
    mvn_sta_ck_check, times, success=sc  ;SPICE already loaded
    
    if sc eq 1 then begin
        get_data, 'mvn_sta_ck_check', data=ddch

        neleROT = n_elements(ddch.x)  ;number of rotations needed
        rotateARR_full = fltarr(neleROT,3)+!values.f_nan

        for rr = 0l, neleROT-1l do begin
            if ddch.y[rr] eq 0 then begin
                rotateTMP = spice_vector_rotate(vect[*,rr],times[rr],'MAVEN_STATIC','MAVEN_MSO')
                rotateARR_full[rr,*] = transpose(rotateTMP)
            endif
        endfor        
        
        fname_flux = 'mvn_sta_flow_flux_'+strapid+'_m'+massSTR+'_er'+estr+'_MSO'
        store_data, fname_flux, data={x: times, y: rotateARR_full}
          options, fname_flux, labels=['X', 'Y [MSO]', 'Z']
          options, fname_flux, colors=[col_blue, col_green, col_red]
          options, fname_flux, labflag=1
          options, fname_flux, ytitle='STA flow!Cm:'+massSTR+'!Cer:'+estr+'!C[#/cm2/s]'
        
        success=1          
    endif else success=0 ;sc=1
    
endif

;VEL:
if kms eq 1 then begin
    tname = 'mvn_sta_flow_kms_m'+massSTR+'_er'+estr  ;get correct tplot variable
    get_data, tname, data=dd2
    
    vect = transpose(dd2.y[*, 0:2])  ;needs to be 3xN for rotate
    times = dd2.x

    ;Check when we have SPICE coverage for STATIC rotations:
    mvn_sta_ck_check, times, success=sc  ;SPICE already loaded
   
    if sc eq 1 then begin
        get_data, 'mvn_sta_ck_check', data=ddch
        
        neleROT = n_elements(ddch.x)  ;number of rotations needed
        rotateARR_full = fltarr(neleROT,3)+!values.f_nan
        
        for rr = 0l, neleROT-1l do begin
            if ddch.y[rr] eq 0 then begin
                rotateTMP = spice_vector_rotate(vect[*,rr],times[rr],'MAVEN_STATIC','MAVEN_MSO')
                rotateARR_full[rr,*] = transpose(rotateTMP)
            endif               
        endfor
        
        fname_kms = 'mvn_sta_flow_kms_'+strapid+'_m'+massSTR+'_er'+estr+'_MSO'               
        store_data, fname_kms, data={x: times, y: rotateARR_full}  ;can't do log as can have -ve values. Leave as log for now.
          options, fname_kms, labels=['X', 'Y [MSO]', 'Z']
          options, fname_kms, colors=[col_blue, col_green, col_red]
          options, fname_kms, labflag=1
          options, fname_kms, ytitle='STA flow!C'+massSTR+'!Cer:'+estr+'!C[km/s]'
        
        success=1
    endif else success=0 ;sc=1 
    
endif

;Correct for sc velocity if requested:
corr_flag_val = sc_cor_flag  ;threshold for flagging when correction factor is same size as actual data. If data/correction factor < corr_flag_val,
                             ;then flag as large error likely.
if sc_vel eq 1 then begin
    ;Get spacecraft velocity in kms in MSO for either or both cases - not sure if kms or flux can vary in length, so calculate for
    ;each explicitly in each if statement below.   
    
    if kms eq 1 then begin
        ;If output is in kms, just subtract spacecraft velocity from calculated flow vectors:
        get_data, fname_kms, data=ddTMP, dlimit=dlTMP, limit=llTMP
        ddTMP2 = ddTMP  ;make a copy, to contain sc vel corrected values.
        
        if size(spicekernels,/type) ne 0 then mvn_sta_anc_ephemeris, ddTMP.x, /mvn_vel, spicekernels=spicekernels else begin
                spicekernels = mvn_spice_kernels(/load)
                mvn_sta_anc_ephemeris, ddTMP.x, /mvn_vel, spicekernels=spicekernels
        endelse
        
        get_data, 'mvn_sta_anc_mvn_vel_mso', data=ddVEL
        
        ;units: flow in km/s => keep ddVEL in units of km/s
        ddTMP2.y[*,0] = ddTMP.y[*,0] + ddVEL.y[*,0]   ;TW suggested + here => CMF agrees.
        ddTMP2.y[*,1] = ddTMP.y[*,1] + ddVEL.y[*,1]
        ddTMP2.y[*,2] = ddTMP.y[*,2] + ddVEL.y[*,2]  ;ddTMP only has x,y,z, no tot.       
        
        ;When there is no d0/d1 etc flux (due to mode change, for example), the derived velocity in instrument frame is 0 in all 3 componenets.
        ;Find these times and remove from the corrected variable:
        iFI = where(ddTMP.y[*,0] eq 0. and ddTMP.y[*,1] eq 0. and ddTMP.y[*,2] eq 0., niFI)
        if niFI gt 0. then ddTMP2.y[iFI,*] = !values.f_nan
        
        fname_kms2 = fname_kms+'_sc-corr'
        store_data, fname_kms2, data=ddTMP2, dlimit=dlTMP, limit=llTMP
          options, fname_kms2, ytitle='STA flow!C'+massSTR+'!Cer:'+estr+'!Csc-corr!C[km/s]'
          
        ;Store correction factor for checks:
        fname_kms3 = fname_kms+'_sc_correction_factor'
        store_data, fname_kms3, data=ddVEL, dlimit=dlTMP, limit=llTMP
          options, fname_kms3, ytitle='STA flow!C'+massSTR+'!Cer:'+estr+'!Ccorr factor!C[km/s]'
          
        ;Make a correction flag for when sc velocity corrections become within x2 of the measured values. This occurs at 
        ;periapsis when ion energies are low. ALso flag timestamps when data are NaNs.
        mag1 = sqrt(ddTMP.y[*,0]^2 + ddTMP.y[*,1]^2 + ddTMP.y[*,2]^2)  ;measured (includes sc vel)
        mag2 = sqrt(ddVEL.y[*,0]^2 + ddVEL.y[*,1]^2 + ddVEL.y[*,2]^2)  ;correction factor
        diff = abs(mag1/mag2)
        
        corr_flag1 = fltarr(n_elements(diff))  ;0=no flag, 1=flag
        iFL = where(diff lt corr_flag_val, niFL)
        if niFL gt 0 then corr_flag1[iFL] = 1
        iFL2 = where(finite(ddTMP2.y[*,0]) eq 0, niFL2)
        if niFL2 gt 0 then corr_flag1[iFL2] = 1
        
        fname_kms4 = fname_kms+'_sc_correction_flag'
        store_data, fname_kms4, data={x: ddVEL.x, y: corr_flag1}
          options, fname_kms4, ytitle='sc corr!Cflag'
          ylim, fname_kms4, -1, 2
        
    endif
    
    if flux eq 1 then begin 
        ;j'=j - n*sc_vel  ;do subtraction in MSO frame (+- depends on definition of vectors; use + below)
        get_data, tname_den, data=ddDEN
        get_data, fname_flux, data=ddFLUX, dlimit=dlTMP, limit=llTMP
        
        if size(spicekernels,/type) ne 0 then mvn_sta_anc_ephemeris, ddFLUX.x, /mvn_vel, spicekernels=spicekernels else begin
                spicekernels = mvn_spice_kernels(/load)
                mvn_sta_anc_ephemeris, ddFLUX.x, /mvn_vel, spicekernels=spicekernels  
        endelse
        
        get_data, 'mvn_sta_anc_mvn_vel_mso', data=ddVEL ;sc vel
        
        ;Units:
        ;Flux is #/cm^2/s => keep density in /cc and vel from km/s to cm/s
        flux_new_x = ddFLUX.y[*,0] + (ddDEN.y * ddVEL.y[*,0] * 1E5)   ;TW suggested + here => CMF agrees.
        flux_new_y = ddFLUX.y[*,1] + (ddDEN.y * ddVEL.y[*,1] * 1E5)
        flux_new_z = ddFLUX.y[*,2] + (ddDEN.y * ddVEL.y[*,2] * 1E5)
        
        corr_factor = ddFLUX  ;make a copy
        corr_factor.y[*,0] = (ddDEN.y * ddVEL.y[*,0] * 1E5)  ;correction factor
        corr_factor.y[*,1] = (ddDEN.y * ddVEL.y[*,1] * 1E5)
        corr_factor.y[*,2] = (ddDEN.y * ddVEL.y[*,2] * 1E5)
        
        ddFLUX2 = ddFLUX  ;make a copy
        ddFLUX2.y[*,0] = flux_new_x
        ddFLUX2.y[*,1] = flux_new_y
        ddFLUX2.y[*,2] = flux_new_z
        
        ;Find times when flux is zero in all 3 components (can occur at times due to instrument operation).
        iFI = where(ddFLUX.y[*,0] eq 0. and ddFLUX.y[*,1] eq 0. and ddFLUX.y[*,2] eq 0., niFI)
        if niFI gt 0. then ddFLUX2.y[iFI,*] = !values.f_nan
        
        fname_flux2 = fname_flux+'_sc-corr'
        store_data, fname_flux2, data=ddFLUX2, dlimit=dlTMP, limit=llTMP
          options, fname_flux2, ytitle='STA flow!C'+massSTR+'!Cer:'+estr+'!Csc-corr!C[#/cm2/s]'
        
        fname_flux3 = fname_flux+'_sc_correction_factor'
        store_data, fname_flux3, data=corr_factor, dlimit=dlTMP, limit=llTMP
          options, fname_flux3, ytitle='STA flow!C'+massSTR+'!Cer:'+estr+'!Csc corr factor!C[#/cm2/s]'
          
        ;Make a correction flag for when sc velocity corrections become within x2 of the measured values. This occurs at
        ;periapsis when ion energies are low. Also flag when data are NaNs.
        mag1 = sqrt(ddFLUX.y[*,0]^2 + ddFLUX.y[*,1]^2 + ddFLUX.y[*,2]^2)  ;measured (includes sc vel)
        mag2 = sqrt(corr_factor.y[*,0]^2 + corr_factor.y[*,1]^2 + corr_factor.y[*,2]^2)  ;correction factor
        diff = abs(mag1/mag2)

        corr_flag2 = fltarr(n_elements(diff))  ;0=no flag, 1=flag
        iFL = where(diff lt corr_flag_val, niFL)
        if niFL gt 0 then corr_flag2[iFL] = 1
        iFL2 = where(finite(ddFLUX2.y[*,0]) eq 0, niFL2)
        if niFL2 gt 0 then corr_flag2[iFL2] = 1

        fname_flux4 = fname_flux+'_sc_correction_flag'
        store_data, fname_flux4, data={x: ddVEL.x, y: corr_flag2}
          options, fname_flux4, ytitle='sc corr!Cflag'
          ylim, fname_flux4, -1, 2
        
    endif
    
endif
   
if keyword_set(clearspice) then mvn_lpw_anc_clear_spice_kernels  ;clear spice kernels
  
end


