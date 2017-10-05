;+
; Procedure:    goes_combine_tdata
;
; Purpose:
;     The procedures in this library combine multi-dimensional GOES tplot variables 
;     and ensure the combined tplot variables contain the standard data attributes structure
;     required for TDAS/SPEDAS data processing and analysis
;     
;     For instance, GOES magnetometer data can be loaded as 'he', 'hn', 'hp', 
;     goes_combine_mag_data will find and combine these into a single 'g[8-15]_h_enp' variable, with
;     the coordinates set to 'ENP' and units set to 'nT' in the data attributes structure
;     
;     
; Notes:
;     If the get_support_data keyword isn't set, these routines will delete the tplot variables
;     corresponding to the support data (i.e., variables ending in *_NUM_PTS and *_QUAL_FLAG).
;     
;     If the user loads support data for one type of particle data (i.e., electrons) and then 
;     loads a different type of data without support data, the initial support data may be removed
;     by these routines (due to the globbing). 
;     
;     For the instruments with multiple detectors:
;         EPEAD: E, W detectors are combined into a single tplot variable with the E-component 
;            in the first column of the Y component [*,0] and the W-component in the second
;            column of the Y component [*,1]
;         MAG(E/P)D: The 9-telescopes are combined into a single tplot variable with each detector 
;            in the (detector-1) column of the Y-component; note that this is also in order of 
;            increasing energy
;     
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-29 07:58:21 -0700 (Fri, 29 Apr 2016) $
; $LastChangedRevision: 20969 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/goes_combine_tdata.pro $
;-

pro goes_set_ephem_data_att, ephem_tvar, prefix, tplotnames = tplotnames
    compile_opt idl2, hidden
    if undefined(prefix) then prefix = ''
    if undefined(ephem_tvar) then begin
        dprint, dlevel=0, 'Error setting the data attributes structure for an ephemeris tvariable; no variable defined'
        return
    endif
    if tnames(ephem_tvar) eq '' then begin
        dprint, dlevel=0, 'Error setting the data attributes structure for an ephemeris tvariable; invalid tplot variable'
        return
    endif
    ; get the dlimits structure
    get_data, ephem_tvar, dlimits=dlim
    
    ; get the units from the dlimits structure
    str_element, dlim, 'cdf.vatt.units', dlunits, success=units_success
    if units_success eq 0 then dlunits = 'none'
    
    ; get the coordinate system from the dlimits structure
    str_element, dlim, 'cdf.vatt.coordinate_system', coord_sys, success=coordsys_success
    if coordsys_success eq 0 then coord_sys = 'none'
    
    data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'ephem', units: dlunits, coord_sys: coord_sys, st_type: 'none'}
    options, ephem_tvar, 'data_att', data_att, /add, /def
    tplotnames = keyword_set(tplotnames) ? [tplotnames,ephem_tvar] : ephem_tvar
end
pro goes_combine_eps_data, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
    compile_opt idl2, hidden
    ; the EPS instruments are the particle detectors onboard the GOES 8-12 spacecraft
    ; data is loaded for 7 proton channels, 3 electron channels and 6 alpha channels (sometimes)
    ; data can be corrected, uncorrected, flux and/or integral flux
    if undefined(prefix) then prefix = '' ; just in case the prefix wasn't set
    if undefined(suffix) then suffix = ''
    
    ; alpha flux
    eps_alpha_flux = tnames('*_a?_flux')
    ; electron integral flux, without corrections applied
    eps_elec_iflux = tnames('*_e?_flux_i'+suffix)
    ; electron integral flux, with corrections applied
    eps_elec_iflux_corr = tnames('*_e?_flux_ic'+suffix)
    ; proton channels, without corrections applied
    eps_prot_flux = tnames('*_p?_flux'+suffix)
    ; proton channels, with corrections applied
    eps_prot_flux_corr = tnames('*_p?_flux_c'+suffix)
    ; proton integral flux, with corrections applied
    eps_prot_iflux_corr = tnames('*_p?_flux_ic'+suffix)
    
    tvars = ['eps_elec_iflux', 'eps_elec_iflux_corr', 'eps_prot_flux', 'eps_prot_flux_corr', 'eps_prot_iflux_corr', 'eps_alpha_flux']

    ; electron energy channels
    eps_elec_en = ['0.6','2.0','4.0'] ; MeV
    ; proton energy channels
    eps_prot_en = ['2.4','6.5','12','27.5','60','122.5','332.5'] ; MeV
    ; alpha particle energy channels
    eps_alph_en = ['7', '15.5', '40.5', '105', '200', '400'] ; MeV
    
    eps_energies = ['eps_elec_en', 'eps_prot_en', 'eps_alph_en']

    ; instead of having individual loops for each potential data type from the EPS
    ; instrument, we have a single loop that loops through the potential types 
    ; using scope_varfetch
    for tvarname_idx = 0, n_elements(tvars)-1 do begin
        ; get the tvariable names
        tvarnames = scope_varfetch(tvars[tvarname_idx])

        ; proton_check is 1 if the first tvariable name has the format of proton data, 
        ; i.e., 'g12_p1_flux_ic'
        proton_check = stregex(tvarnames[0], '.+[_p][0-9]{1}[_].+', /bool)
        electron_check = stregex(tvarnames[0], '.+[_e][0-9]{1}[_].+',/bool)
        alpha_check = stregex(tvarnames[0], '.+[_a][0-9]{1}[_].+', /bool)
        
        if electron_check eq 1 then begin
            center_energies = scope_varfetch(eps_energies[0])
            energy_array = eps_energies[0]
        endif 
        if proton_check eq 1 then begin
            center_energies = scope_varfetch(eps_energies[1])
            energy_array = eps_energies[1]
        endif
        if alpha_check eq 1 then begin
            center_energies = scope_varfetch(eps_energies[2])
            energy_array = eps_energies[2]
        endif

        for tvar_idx = 0, n_elements(tvarnames)-1 do begin
            if tvarnames[tvar_idx] ne '' then begin
                get_data, tvarnames[tvar_idx], data=eps_data, dlimits=eps_dlimits
                if is_struct(eps_data) then begin
                    ; get species type using regex
                    speciestype = stregex(energy_array, '.+[_](.{4})[_].+', /subexp, /extr)
                    
                    ; check if this variable contains flux or integral flux (for appropriate naming)
                    integralflux = stregex(tvarnames[tvar_idx], '.+[_]?[i].*')
                    if integralflux eq -1 then iflux = '' else iflux = 'i'
                    
                    ; store the data attributes in a structure
                    data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'eps', units: eps_dlimits.cdf.vatt.units, coord_sys: 'none', st_type: 'none'}
                    
                    labels = center_energies[tvar_idx]+'MeV'
                    str_element, eps_dlimits, 'data_att', data_att, /add
                    str_element, eps_dlimits, 'labels', labels, /add
                    str_element, eps_dlimits, 'labflag', 2, /add

                    newtvar = prefix + speciestype[1] + '_' + center_energies[tvar_idx] + 'MeV_'+iflux+'flux'+suffix
                    ; update the vname in the CDF structure
                    eps_dlimits.cdf.vname = newtvar
                    store_data, newtvar, data = {x:eps_data.X, y:eps_data.Y}, dlimits = eps_dlimits
                    tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
                    del_data, tvarnames[tvar_idx]
                endif
            endif
        endfor
    endfor
end
pro goes_combine_epead_data, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
    compile_opt idl2, hidden
    if undefined(prefix) then prefix = '' ; so the code doesn't die without a prefix set
    if undefined(suffix) then suffix = '' ; ^^
    
    ; EPEAD telescope detector information:
    ; - 3 proton channels: P1 (0.74-4.2 MeV), P2 (4.2-8.7 MeV), P3 (8.7-14.5 MeV)
    ; - 3 alpha channels: A1 (3.8-9.9 MeV), A2 (9.9-20.5 MeV), A3 (20.5-61 MeV)
    ; 
    ; EPEAD dome detector information:
    ; - 4 proton channels: P4 (15-40 MeV), P5 (38-82 MeV), P6 (84-200 MeV), P7 (110-900 MeV)
    ; - 3 alpha channels: A4 (60-160 MeV), A5 (160-260 MeV), A6 (330-500 MeV)
    ; - 3 electron channels: E1 (> 0.6 MeV), E2 (> 2 MeV), E3 (> 4 MeV)

    wp_detectors_uncor = tnames('*_P'+strcompress(string(indgen(8)), /rem)+'W_UNCOR_FLUX'+suffix)
    ep_detectors_uncor = tnames('*_P'+strcompress(string(indgen(8)), /rem)+'E_UNCOR_FLUX'+suffix)
    wp_detectors_cor = tnames('*_P'+strcompress(string(indgen(8)), /rem)+'W_COR_FLUX'+suffix)
    ep_detectors_cor = tnames('*_P'+strcompress(string(indgen(8)), /rem)+'E_COR_FLUX'+suffix)
    wa_detectors = tnames('*_A'+strcompress(string(indgen(7)), /rem)+'W_FLUX'+suffix)
    ea_detectors = tnames('*_A'+strcompress(string(indgen(7)), /rem)+'E_FLUX'+suffix)
    we_detectors_uncor = tnames('*_E'+strcompress(string(indgen(4)), /rem)+'W_UNCOR_FLUX'+suffix)
    ee_detectors_uncor = tnames('*_E'+strcompress(string(indgen(4)), /rem)+'E_UNCOR_FLUX'+suffix)
    we_detectors_cor = tnames('*_E'+strcompress(string(indgen(4)), /rem)+'W_COR_FLUX'+suffix)
    ee_detectors_cor = tnames('*_E'+strcompress(string(indgen(4)), /rem)+'E_COR_FLUX'+suffix)
    ; in the data file, the center energies for proton data are labeled as:
    ;    P1 = 2.5 MeV, P2 = 6.5 MeV, P3 = 11.6 MeV
    ;    P4 = 30.6 MeV, P5 = 63.1 MeV, P6 = 165 MeV, P7 = 433 MeV
    proton_en = ['2.5', '6.5', '11.6', '30.6', '63.1', '165', '433']   
  
    ; Start with the proton detectors 
    ; (note actual pointing direction depends on S/C orientation)
    for pidx = 0, n_elements(wp_detectors_uncor)-1 do begin
        if (n_elements(wp_detectors_uncor) gt pidx) && (n_elements(ep_detectors_uncor) gt pidx) then begin
            if tnames(ep_detectors_uncor[pidx]) ne '' && tnames(wp_detectors_uncor[pidx]) ne '' then begin
              newtvar = prefix+'prot_'+proton_en[(pidx)]+'MeV_uncor_flux'+suffix
              store_data, newtvar[0], data=[ep_detectors_uncor[pidx], wp_detectors_uncor[pidx]]
              options, newtvar[0], labels = ['E', 'W'], labflag = 2, colors=[2, 4]
              tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
            endif
        endif

        ; try to grab the data and dlimits structures for data corrected for electron contamination
        if (n_elements(wp_detectors_cor) gt pidx) && (n_elements(ep_detectors_cor) gt pidx) then begin ; make sure these variables exist before trying to access them
            if tnames(ep_detectors_cor[pidx]) ne '' && tnames(wp_detectors_cor[pidx]) ne '' then begin
              newtvar = prefix+'prot_'+proton_en[pidx]+'MeV_cor_flux'+suffix
              store_data, newtvar[0], data=[ep_detectors_cor[pidx], wp_detectors_cor[pidx]]
              options, newtvar[0], labels = ['E', 'W'], labflag = 2, colors=[2, 4]
              tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
            endif
        endif
    endfor

    ; now, for the electron detectors
    electron_en = ['0.6', '2', '4']
    for eidx = 0, n_elements(we_detectors_uncor)-1 do begin
        if (n_elements(we_detectors_uncor) gt eidx) && (n_elements(ee_detectors_uncor) gt eidx) then begin
            if tnames(ee_detectors_uncor[eidx]) ne '' && tnames(we_detectors_uncor[eidx]) ne '' then begin
              newtvar = prefix+'elec_'+electron_en[eidx]+'MeV_uncor_flux'+suffix
              store_data, newtvar[0], data=[ee_detectors_uncor[eidx], we_detectors_uncor[eidx]]
              options, newtvar[0], labels = ['E', 'W'], labflag = 2, colors=[2, 4]
              tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
            endif
        endif
        
        ; now for the corrected electron data
        if (n_elements(we_detectors_cor) gt eidx) && (n_elements(ee_detectors_cor) gt eidx) then begin
            if tnames(ee_detectors_cor[eidx]) ne '' && tnames(we_detectors_cor[eidx]) ne '' then begin
              newtvar = prefix+'elec_'+electron_en[eidx]+'MeV_cor_flux'+suffix
              store_data, newtvar[0], data=[ee_detectors_cor[eidx], we_detectors_cor[eidx]]
              options, newtvar[0], labels = ['E', 'W'], labflag = 2, colors=[2, 4]
              tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
            endif
        endif
    endfor
    
    ; finally, the alpha particles
    alpha_en = ['6.8', '15.2', '40.7', '110', '210', '415']
    for aidx = 0, n_elements(wa_detectors)-1 do begin
        if (n_elements(wa_detectors) gt aidx) && (n_elements(ea_detectors) gt aidx) then begin
            if tnames(ea_detectors[aidx]) ne '' && tnames(wa_detectors[aidx]) ne '' then begin
              newtvar = prefix+'alpha_'+alpha_en[aidx]+'MeV_flux'+suffix
              store_data, newtvar[0], data=[ea_detectors[aidx], wa_detectors[aidx]]
              options, newtvar[0], labels = ['E', 'W'], labflag = 2, colors=[2, 4]
              tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
            endif
        endif
    endfor
 
    ; delete the support data if the user didn't specifically request it
    if undefined(get_support_data) then begin
        ; note: the globbing here should be as specific as possible, 
        ; so as to not delete support data loaded for other instruments
        epead_proton_num_pts = tnames('*_P*_NUM_PTS'+suffix)
        epead_elec_num_pts = tnames('*_E*_NUM_PTS'+suffix)
        epead_alpha_num_pts = tnames('*_A*_NUM_PTS'+suffix)
        epead_proton_qual_flag = tnames('*_P*_QUAL_FLAG'+suffix)
        epead_elec_qual_flag = tnames('*_E*_QUAL_FLAG'+suffix)
        epead_alpha_qual_flag = tnames('*_A*_QUAL_FLAG'+suffix)
        del_data, [epead_proton_num_pts, epead_elec_num_pts, epead_alpha_num_pts]
        del_data, [epead_proton_qual_flag, epead_elec_qual_flag, epead_alpha_qual_flag]
    endif else begin
        ; the user requested support data
        support_types = ['QUAL_FLAG','NUM_PTS']+suffix
        for support_type = 0, n_elements(support_types)-1 do begin
            ; proton support data
            eproton_support = prefix + 'P'+strcompress(string((indgen(7)+1)), /rem)+'E_'+support_types[support_type]
            wproton_support = prefix + 'P'+strcompress(string((indgen(7)+1)), /rem)+'W_'+support_types[support_type]
            
            ; loop through the proton support variables
            for psupport_idx = 0, n_elements(eproton_support)-1 do begin
                newtvarname = prefix + 'prot_'+proton_en[psupport_idx]+'MeV_'+strlowcase(support_types[support_type])
                join_vec, [eproton_support[psupport_idx], wproton_support[psupport_idx]], newtvarname
                tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvarname] : newtvarname
                del_data, [eproton_support[psupport_idx], wproton_support[psupport_idx]]
            endfor
            
            ; electron support data
            eelectron_support = prefix + 'E'+strcompress(string((indgen(3)+1)), /rem)+'E_'+support_types[support_type]
            welectron_support = prefix + 'E'+strcompress(string((indgen(3)+1)), /rem)+'W_'+support_types[support_type]
            
            ; loop through the electron support variables
            for esupport_idx = 0, n_elements(eelectron_support)-1 do begin
                newtvarname = prefix + 'elec_'+electron_en[esupport_idx]+'MeV_'+strlowcase(support_types[support_type])
                join_vec, [eelectron_support[esupport_idx],welectron_support[esupport_idx]], newtvarname
                tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvarname] : newtvarname
                del_data, [eelectron_support[esupport_idx],welectron_support[esupport_idx]]
            endfor

            ; alpha support data
            ealpha_support = prefix + 'A'+strcompress(string((indgen(6)+1)), /rem)+'E_'+support_types[support_type]
            walpha_support = prefix + 'A'+strcompress(string((indgen(6)+1)), /rem)+'W_'+support_types[support_type]
            
            ; loop through alpha support variables
            for asupport_idx = 0, n_elements(ealpha_support)-1 do begin
                newtvarname = prefix + 'alpha_'+alpha_en[asupport_idx]+'MeV_'+strlowcase(support_types[support_type])
                join_vec, [ealpha_support[asupport_idx], walpha_support[asupport_idx]], newtvarname
                tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvarname] : newtvarname
                del_data, [ealpha_support[asupport_idx], walpha_support[asupport_idx]]
            endfor
        endfor
    endelse
end
pro goes_combine_hepad_data, type, probe, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
    compile_opt idl2, hidden
    ; HEPAD detector information:
    ; - 2 alpha channels: A7 (2560-3400 MeV) and A8 (>3400 MeV)
    ; - 4 proton channels: P8 (330–420 MeV), P9 (420–510 MeV), P10 (510–700 MeV), P11 (> 700 MeV)
    ; HEPAD support data:
    ; - channels: S1, S2, S3, S4, S5
    proton_flux_channels = tnames('*_P*_FLUX'+suffix)
    alpha_flux_channels = tnames('*_A*_FLUX'+suffix)
    
    ; count rates
    proton_count_rates = tnames('*_P*_COUNT_RATE'+suffix)
    alpha_count_rates = tnames('*_A*_COUNT_RATE'+suffix)
    support_count_rates = tnames('*_S*_COUNT_RATE'+suffix)
    
    ; for HEPAD, each energy bin has only one channel, so all we need to do is 
    ; change the name of the tplot variable to our standard format and make sure
    ; the data attributes are set correctly
    hepad_proton_center_en = ['375', '465', '605', '700']
    for p_index = 0, n_elements(proton_flux_channels)-1 do begin
        get_data, proton_flux_channels[p_index], data = protondata, dlimits = protondlimits
        
        ; check the returned structures
        if (is_struct(protondata) && is_struct(protondlimits)) then begin
            ; store the data attributes in a structure
            data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'hepad', units: protondlimits.cdf.vatt.units, coord_sys: 'none', st_type: 'none'}
            
            ; label the energies
            labels = [hepad_proton_center_en[p_index]+'MeV']
            str_element, protondlimits, 'data_att', data_att, /add
            str_element, protondlimits, 'labels', labels, /add
            str_element, protondlimits, 'labflag', 2, /add
            
            newtvar = prefix+'hepadp_'+hepad_proton_center_en[p_index]+'MeV_flux'+suffix
            ; update the vname in the CDF structure
            protondlimits.cdf.vname = newtvar
            
            store_data, newtvar[0], data=protondata, dlimits=protondlimits
            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
            del_data, proton_flux_channels[p_index]
        endif else begin
            dprint, dlevel = 0, 'Invalid structure; data might be missing.'
        endelse
    endfor
    
    ; now loop over proton count rate variables
    for pcr_index = 0, n_elements(proton_count_rates)-1 do begin
        get_data, proton_count_rates[pcr_index], data = protondata, dlimits = protondlimits
        
        ; check the returned structures
        if (is_struct(protondata) && is_struct(protondlimits)) then begin
            ; store the data attributes in a structure
            data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'hepad', units: protondlimits.cdf.vatt.units, coord_sys: 'none', st_type: 'none'}
            
            ; label the energies
            labels = [hepad_proton_center_en[pcr_index]+'MeV']
            str_element, protondlimits, 'data_att', data_att, /add
            str_element, protondlimits, 'labels', labels, /add
            str_element, protondlimits, 'labflag', 2, /add
            
            newtvar = prefix+'hepadp_'+hepad_proton_center_en[pcr_index]+'MeV_CR'+suffix
            ; update the vname in the CDF structure
            protondlimits.cdf.vname = newtvar
            
            store_data, newtvar[0], data=protondata, dlimits=protondlimits
            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
            del_data, proton_count_rates[pcr_index]
        endif else begin
            dprint, dlevel = 0, 'Invalid structure; data might be missing.'
        endelse
    endfor
    
    ; again, the alpha SSDs have a single channel for each energy bin
    ; so we just need to set the data attributes
    hepad_alpha_center_en = ['2980','3400']
    for a_index = 0, n_elements(alpha_flux_channels)-1 do begin
        get_data, alpha_flux_channels[a_index], data = alphadata, dlimits = alphadlimits
        
        ; check the returned structures
        if (is_struct(alphadata) && is_struct(alphadlimits)) then begin
            ; store the data attributes in a structure
            data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'hepad', units: alphadlimits.cdf.vatt.units, coord_sys: 'none', st_type: 'none'}
            
            ; label the energies
            labels = [hepad_alpha_center_en[a_index]+'MeV']
            str_element, alphadlimits, 'data_att', data_att, /add
            str_element, alphadlimits, 'labels', labels, /add
            str_element, alphadlimits, 'labflag', 2, /add
    
            newtvar = prefix+'hepada_'+hepad_alpha_center_en[a_index]+'MeV_flux'+suffix
            ; update the vname in the CDF structure
            alphadlimits.cdf.vname = newtvar
            
            store_data, newtvar[0], data=alphadata, dlimits=alphadlimits
            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
            del_data, alpha_flux_channels[a_index]
        endif else begin
            dprint, dlevel = 0, 'Invalid structure; data might be missing.'
        endelse
    endfor
    
    ; and now, loop over alpha count rate variables
    for acr_index = 0, n_elements(alpha_count_rates)-1 do begin
        get_data, alpha_count_rates[acr_index], data = alphadata, dlimits = alphadlimits
        
        ; check the returned structures
        if (is_struct(alphadata) && is_struct(alphadlimits)) then begin
            ; store the data attributes in a structure
            data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'hepad', units: alphadlimits.cdf.vatt.units, coord_sys: 'none', st_type: 'none'}
            
            ; label the energies
            labels = [hepad_alpha_center_en[acr_index]+'MeV']
            str_element, alphadlimits, 'data_att', data_att, /add
            str_element, alphadlimits, 'labels', labels, /add
            str_element, alphadlimits, 'labflag', 2, /add
    
            newtvar = prefix+'hepada_'+hepad_alpha_center_en[acr_index]+'MeV_CR'+suffix
            ; update the vname in the CDF structure
            alphadlimits.cdf.vname = newtvar
            
            store_data, newtvar[0], data=alphadata, dlimits=alphadlimits
            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
            del_data, alpha_count_rates[acr_index]
        endif else begin
            dprint, dlevel = 0, 'Invalid structure; data might be missing.'
        endelse
    endfor
    
    ; 5 tplot variables are created for HEPAD housekeeping
    ; here, we combine them and make sure the attributes are set
    ;  (only keep these if get_support_data is set)
    if undefined(get_support_data) then begin
        ; if the user didn't request support data, let's remove it. 
        del_data, [tnames('*_P*_QUAL_FLAG'+suffix), tnames('*_P*_NUM_PTS'+suffix)]
        del_data, [tnames('*_A*_QUAL_FLAG'+suffix), tnames('*_A*_NUM_PTS'+suffix)]
        del_data, [tnames('*_S*_COUNT_RATE'+suffix), tnames('*_S*_QUAL_FLAG'+suffix), tnames('*_S*_NUM_PTS'+suffix)]
    endif else begin
        ; the user requested the support data, let's combine it for them
        ; start with the S* count rates
        hepad_s_cr = prefix + 'S'+strcompress(string(indgen(5)+1),/rem)+'_COUNT_RATE'+suffix
        newtvarname = prefix + 'S_count_rate'+suffix
        join_vec, hepad_s_cr, newtvarname
        tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvarname] : newtvarname
        
        support_types = ['NUM_PTS', 'QUAL_FLAG']+suffix
        for support_type = 0, n_elements(support_types)-1 do begin
            ; first the S* quality flags and number of points
            hepad_s_support = prefix + 'S'+strcompress(string(indgen(5)+1),/rem)+'_'+support_types[support_type]
            newtvarname = prefix + 'S_'+strlowcase(support_types[support_type])
            join_vec, hepad_s_support, newtvarname
            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvarname] : newtvarname
            
            ; now the support data for protons
            hepad_alpha_support = prefix + 'A'+['7','8']+'_'+support_types[support_type]
            for asupport_idx = 0, n_elements(hepad_alpha_support)-1 do begin
                get_data, hepad_alpha_support[asupport_idx], data=asupportdata, dlimits=asupportdlimits
                if (is_struct(asupportdata) && is_struct(asupportdlimits)) then begin
                    newtvarname = prefix + 'hepada_'+hepad_alpha_center_en[asupport_idx]+'MeV_'+strlowcase(support_types[support_type])
                    store_data, newtvarname, data={x:asupportdata.X, y: asupportdata.Y}, dlimits=asupportdlimits
                    tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvarname] : newtvarname
                endif else begin
                    dprint, dlevel=0, 'Invalid structure; support data might be missing.'
                endelse
            endfor
            
            ; and finally the support data for alpha particles
            hepad_prot_support = prefix + 'P'+['8','9','10','11']+'_'+support_types[support_type]
            for psupport_idx = 0, n_elements(hepad_prot_support)-1 do begin
                get_data, hepad_prot_support[psupport_idx], data=psupportdata, dlimits=psupportdlimits
                if (is_struct(psupportdata) && is_struct(psupportdlimits)) then begin
                    newtvarname = prefix + 'hepadp_'+hepad_proton_center_en[psupport_idx]+'MeV_'+strlowcase(support_types[support_type])
                    store_data, newtvarname, data={x:psupportdata.X, y:psupportdata.Y}, dlimits=psupportdlimits
                    tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvarname] : newtvarname
                endif else begin
                    dprint, dlevel=0, 'Invalid structure; support data might be missing.'
                endelse
            endfor
        endfor
        del_data, [tnames('*_P*_QUAL_FLAG'+suffix), tnames('*_P*_NUM_PTS'+suffix)]
        del_data, [tnames('*_A*_QUAL_FLAG'+suffix), tnames('*_A*_NUM_PTS'+suffix)]
        del_data, [tnames('*_S*_COUNT_RATE'+suffix), tnames('*_S*_QUAL_FLAG'+suffix), tnames('*_S*_NUM_PTS'+suffix)]
    endelse
end
pro goes_combine_xrs_data, probe, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
    compile_opt idl2, hidden
    ; The XRS tplot variables are different depending on which GOES spacecraft we're interested in
    ; for GOES 8-12, the tplot names for XRS are 'xs' (short wavelength) 
    ;    and 'xl' (long wavelength) with no quality/number of points support data. 
    ; for GOES 13-15, the tplot names for XRS are 'A_AVG' (short wavelength) 
    ;    and 'B_AVG' (long wavelength) with support data in *_QUAL_FLAG and *_NUM_PTS
    if undefined(probe) then begin
        dprint, dlevel=1, 'Error, probe argument required in calls to goes_combine_xrs_data'
        return
    endif else if size(probe, /type) ne 7 then probe=strcompress(string(probe),/rem)
    
    if (uint(probe) le 12) and (uint(probe) ge 8) then begin
        xrays = 'g'+probe+'_'+['xs', 'xl']+suffix
    endif else if (uint(probe) le 15) and (uint(probe) ge 13) then begin
        ; check for averaged data first
        if tnames('*_A_AVG'+suffix) ne '' then begin
            xrays = 'g'+probe+'_'+['A_AVG', 'B_AVG']+suffix
        endif else if tnames('*_A_FLUX'+suffix) ne '' then begin
            ; if we don't find any averaged data, let's look for unaveraged data
            xrays = 'g'+probe+'_'+['A_FLUX', 'B_FLUX']+suffix
        endif
    endif else begin
        dprint, dlevel = 1, 'Invalid GOES probe # -- valid probes are 08 - 15'
        return
    endelse

    ; loop through the XRS tplot variables
    for xray_index = 0, n_elements(xrays)-1 do begin
        ; grab the data and dlimits structures for this tplot variable
        get_data, xrays[xray_index], data = xrsdata, dlimits = xrsdlimits
        
        ; check that valid structures were returned
        if ~is_struct(xrsdata) || ~is_struct(xrsdlimits) then begin
            dprint, dlevel = 0, 'Error getting data from tplot variable. Possibly an invalid tname?'
            return
        endif 
        
        ; XRS data should be plotted with logarithmic scaling in the y-component
        str_element, xrsdlimits, 'log', xrs_log_value, success=s
        if s ne 0 then str_element, xrsdlimits, 'ylog', 1, /add
        
        if xray_index eq 0 then begin
            ; first tplot variable, need to create an array of floats to store xray data
            xray_avg = fltarr(n_elements(xrsdata.Y),2)
            xray_avg[*, xray_index] = xrsdata.Y[*]
            xray_times = xrsdata.X[*]
        endif else begin
            xray_avg[*, xray_index] = xrsdata.Y[*]
            
            ; store the data attributes in a structure
            data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'xrs', units: xrsdlimits.cdf.vatt.units, coord_sys: 'none', st_type: 'none'}
            
            ; update the dlimits structure for the xrays tplot variable
            ; the upper limit on the short wavelength band for GOES 08-12 is 0.3 nm
            ; and 0.4 nm for GOES 13-15
            labels = (uint(probe) le 12) ? ['0.05-0.3 nm','0.1-0.8 nm'] : ['0.05-0.4 nm','0.1-0.8 nm']
            str_element, xrsdlimits, 'data_att', data_att, /add
            str_element, xrsdlimits, 'labels', labels, /add
            str_element, xrsdlimits, 'labflag', 1, /add
            str_element, xrsdlimits, 'colors', [2,6], /add
            str_element, xrsdlimits, 'ytitle', 'Xray Flux!C [W/m!U2!N]', /add
            str_element, xrsdlimits, 'ysubtitle', '', /add
            ; store the tplot variable
            newtvar = 'g'+probe+'_xrs_avg'+suffix
            ; update the vname in the CDF structure
            xrsdlimits.cdf.vname = newtvar
            
            store_data, newtvar[0], data={x:xray_times, y:xray_avg, v:xray_avg}, dlimits=xrsdlimits
            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar[0]] : newtvar[0]
        endelse
    endfor
    ; now that we've stored the combined data, delete the old tplot variables
    del_data, xrays
    if undefined(get_support_data) then begin
        del_data, [tnames('*_A_QUAL_FLAG'+suffix), tnames('*_B_QUAL_FLAG'+suffix)]
        del_data, [tnames('*_A_NUM_PTS'+suffix), tnames('*_B_NUM_PTS'+suffix)]
    endif else begin
        ; the user requested support data
        if tnames('*_A_QUAL_FLAG'+suffix) ne '' then begin
            ; note that only GOES spacecraft > 12 have support data (quality flags and number of points) included
            join_vec, [tnames('*_A_NUM_PTS'+suffix), tnames('*_B_NUM_PTS'+suffix)], prefix + 'xrs_num_pts'+suffix
            join_vec, [tnames('*_A_QUAL_FLAG'+suffix), tnames('*_B_QUAL_FLAG'+suffix)], prefix + 'xrs_qual_flag'+suffix
            tplotnames = keyword_set(tplotnames) ? [tplotnames,prefix+['xrs_num_pts','xrs_qual_flag']+suffix] : prefix+['xrs_num_pts','xrs_qual_flag']+suffix
            
            ; now that we've combined the support data, delete the old tvars
            del_data, [tnames('*_A_QUAL_FLAG'+suffix), tnames('*_B_QUAL_FLAG'+suffix)]
            del_data, [tnames('*_A_NUM_PTS'+suffix), tnames('*_B_NUM_PTS'+suffix)]
        endif
    endelse
end

pro goes_combine_mag_data, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
    compile_opt idl2, hidden
    ; ensure a prefix/suffix has been set
    if undefined(prefix) then prefix = ''
    if undefined(suffix) then suffix = ''
    
    ; Usually, GOES magnetometer data is loaded using 3 different coordinate systems: 
    ;  1) ENP coordinates
    ;  2) Spacecraft coordinates
    ;  3) Sensor coordinates

    ; Start with FGM ENP coordinates
    if tnames('*HE_1'+suffix) eq '' then begin
        oldgoes = 1 ; oldgoes is set to 1 for GOES 8-12 
        tojoin = prefix + 'h'+['e', 'n', 'p'] + suffix
        get_data, tojoin[0], dlimits=tojoindlimits
    endif else begin
        oldgoes = 0 ; oldgoes is set to 0 for GOES 13-15
        tojoin_1 = prefix + 'H'+['E', 'N', 'P']+'_1' + suffix
        tojoin_2 = prefix + 'H'+['E', 'N', 'P']+'_2' + suffix
        get_data, tojoin_1[0], dlimits=tojoindlimits
    endelse
    
    ; check that a valid dlimits structure was returned
    if ~is_struct(tojoindlimits) then begin
    	dprint, dlevel = 1, 'Couldn''t find FGM data in ENP coordinates'
        return
    endif 
    
    ; miscellaneous data attributes
    data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'fgm', units: tojoindlimits.cdf.vatt.units, coord_sys: 'enp', st_type: 'none'}
    
    ; label the field components
    labels = ['E','N','P']
    str_element, tojoindlimits, 'data_att', data_att, /add
    str_element, tojoindlimits, 'labels', labels, /add
    str_element, tojoindlimits, 'labflag', 2, /add
    str_element, tojoindlimits, 'colors', [2,4,6], /add
    
    if oldgoes eq 0 then begin
        newtvar = prefix + 'H_enp_' + ['1','2']+suffix

        for tojoin_idx = 0, n_elements(tojoin_1)-1 do begin
            store_data, tojoin_1[tojoin_idx], dlimits = tojoindlimits
            store_data, tojoin_2[tojoin_idx], dlimits = tojoindlimits
        endfor

        ; join the ENP tvariables
        join_vec, tojoin_1, newtvar[0]
        join_vec, tojoin_2, newtvar[1]
        tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar] : newtvar
    
        ; delete the old ENP tvariables
        for idx_enp = 0, n_elements(tojoin_1)-1 do begin
            del_data, [tojoin_1[idx_enp], tojoin_2[idx_enp]]
        endfor
    endif else begin
        for tojoin_idx = 0, n_elements(tojoin)-1 do begin
            store_data, tojoin[tojoin_idx], dlimits = tojoindlimits
        endfor
        
        ; join the ENP variables
        join_vec, tojoin, prefix + 'H_enp'+suffix
        tplotnames = keyword_set(tplotnames) ? [tplotnames, prefix + 'H_enp'+suffix] : prefix + 'H_enp'+suffix
        for idx_enp = 0, n_elements(tojoin)-1 do begin
            del_data, tojoin[idx_enp]
        endfor
    endelse

    ; FGM in spacecraft coordinates
    tojoin_1 = prefix+['BXSC', 'BYSC', 'BZSC']+'_1'
    tojoin_2 = prefix+['BXSC', 'BYSC', 'BZSC']+'_2'
    
    ; store the data attributes in a structure
    data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'fgm', units: tojoindlimits.cdf.vatt.units, coord_sys: 'spacecraft', st_type: 'none'}
    
    ; label the field components
    labels = ['Bxsc','Bysc','Bzsc']
    str_element, tojoindlimits, 'data_att', data_att, /add
    str_element, tojoindlimits, 'labels', labels, /add
    str_element, tojoindlimits, 'labflag', 2, /add
    str_element, tojoindlimits, 'colors', [2,4,6], /add
    
    for tojoin_idx = 0, n_elements(tojoin_1)-1 do begin
        store_data, tojoin_1[tojoin_idx], dlimits = tojoindlimits
        store_data, tojoin_2[tojoin_idx], dlimits = tojoindlimits
    endfor
    
    ; join the tvars in spacecraft coordinates
    newtvar = prefix + 'Bsc_'+['1','2']+suffix
    join_vec, tojoin_1, newtvar[0]
    join_vec, tojoin_2, newtvar[1]
    tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar] : newtvar
    
    ; delete the old tvariables in spacecraft coordinates
    for idx_sc = 0, n_elements(tojoin_1)-1 do begin
        del_data, [tojoin_1[idx_sc], tojoin_2[idx_sc]]
    endfor

    ; FGM in sensor coordinates
    tojoin_1 = prefix + 'B'+['X','Y','Z']+'_1'
    tojoin_2 = prefix + 'B'+['X','Y','Z']+'_2'
    
    ; update the data attributes structure
    data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], instrument: 'fgm', units: tojoindlimits.cdf.vatt.units, coord_sys: 'sensor', st_type: 'none'}
    
    ; label the field components
    labels = ['Bxsens','Bysens','Bzsens']
    str_element, tojoindlimits, 'data_att', data_att, /add
    str_element, tojoindlimits, 'labels', labels, /add
    str_element, tojoindlimits, 'labflag', 2, /add
    str_element, tojoindlimits, 'colors', [2,4,6], /add
    
    for tojoin_idx = 0, n_elements(tojoin_1)-1 do begin
        store_data, tojoin_1[tojoin_idx], dlimits = tojoindlimits
        store_data, tojoin_2[tojoin_idx], dlimits = tojoindlimits
    endfor
    
    ; join the tvars in sensor coordinates
    newtvar = prefix + 'Bsens_'+['1', '2']+suffix
    join_vec, tojoin_1, newtvar[0]
    join_vec, tojoin_2, newtvar[1]
    tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar] : newtvar
    
    ; delete the old tvars in sensor coordinates
    for idx_sensor = 0, n_elements(tojoin_1)-1 do begin
        del_data, [tojoin_1[idx_sensor], tojoin_2[idx_sensor]]
    endfor
    
    ; need to add the new total tplot variables to the list of tplot names
    if oldgoes eq 0 then begin
        newtvar = prefix + 'HT_'+['1', '2']+suffix
        new_btsc = prefix + 'BTSC_'+['1', '2']+suffix
    endif else begin
        newtvar = prefix + 'ht'+suffix
        new_btsc = prefix + 'btsc'+suffix
    endelse
    tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar] : newtvar
    tplotnames = keyword_set(tplotnames) ? [tplotnames,new_btsc] : new_btsc
    
    ; if the user didn't request support data, delete it
    if undefined(get_support_data) then begin
        del_data, [tnames(prefix + 'B?_?_NUM_PTS'+suffix), tnames(prefix + 'B?_?_QUAL_FLAG'+suffix)]
        del_data, [tnames(prefix + 'B?SC_?_NUM_PTS'+suffix), tnames(prefix + 'B?SC_?_QUAL_FLAG'+suffix)]
        del_data, [tnames(prefix + 'H?_?_NUM_PTS'+suffix), tnames(prefix + 'H?_?_QUAL_FLAG'+suffix)]
    endif else begin
        ; the user requested the support data, so we'll combine it for them
        support_types = ['NUM_PTS', 'QUAL_FLAG']+suffix
        for support_type = 0, n_elements(support_types)-1 do begin
            ; join support data for ENP coordinates
            support_enp_join_1 = prefix + 'H'+['E', 'N', 'P']+'_1_'+support_types[support_type]
            support_enp_join_2 = prefix + 'H'+['E', 'N', 'P']+'_2_'+support_types[support_type]
            newtvar = prefix + ['H_enp_1_'+strlowcase(support_types[support_type]), 'H_enp_2_'+strlowcase(support_types[support_type])]
            join_vec, support_enp_join_1, newtvar[0]
            join_vec, support_enp_join_2, newtvar[1]
            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar] : newtvar
            
            ; join support data for spacecraft coordinates
            support_sc_join_1 = prefix + ['BXSC', 'BYSC', 'BZSC']+'_1_'+support_types[support_type]
            support_sc_join_2 = prefix + ['BXSC', 'BYSC', 'BZSC']+'_2_'+support_types[support_type]
            newtvar = [prefix+'Bsc_1_'+strlowcase(support_types[support_type]), prefix+'Bsc_2_'+strlowcase(support_types[support_type])]
            join_vec, support_sc_join_1, newtvar[0]
            join_vec, support_sc_join_2, newtvar[1]
            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar] : newtvar
            
            ; join support data for sensor coordinates
            support_sens_join_1 = prefix + 'B'+['X','Y','Z']+'_1_'+support_types[support_type]
            support_sens_join_2 = prefix + 'B'+['X','Y','Z']+'_2_'+support_types[support_type]
            newtvar = [prefix+'Bsens_1_'+strlowcase(support_types[support_type]), prefix+'Bsens_2_'+strlowcase(support_types[support_type])]
            join_vec, support_sens_join_1, newtvar[0]
            join_vec, support_sens_join_2, newtvar[1]
            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtvar] : newtvar
            
            ; now for the field totals
            tplot_rename, prefix + 'BTSC_1_' + support_types[support_type], prefix + 'BTsc_1_' + strlowcase(support_types[support_type])
            tplot_rename, prefix + 'BTSC_2_' + support_types[support_type], prefix + 'BTsc_2_' + strlowcase(support_types[support_type])
            tplot_rename, prefix + 'HT_1_' + support_types[support_type], prefix + 'HT_1_' + strlowcase(support_types[support_type])
            tplot_rename, prefix + 'HT_2_' + support_types[support_type], prefix + 'HT_2_' + strlowcase(support_types[support_type])
            
        endfor
        ; delete the support variables that we just joined
        del_data, [tnames(prefix + 'B?_?_NUM_PTS'+suffix), tnames(prefix + 'B?_?_QUAL_FLAG'+suffix)]
        del_data, [tnames(prefix + 'B?SC_?_NUM_PTS'+suffix), tnames(prefix + 'B?SC_?_QUAL_FLAG'+suffix)]
        del_data, [tnames(prefix + 'H?_?_NUM_PTS'+suffix), tnames(prefix + 'H?_?_QUAL_FLAG'+suffix)]
    endelse

end
; type is particle species type, should be either E for electrons or P for protons
; probe should be the numeric identifier for the spacecraft, i.e., 13, 14, 15
pro goes_combine_magpart_data, type, probe, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
    compile_opt idl2, hidden
    if undefined(type) or undefined(probe) then begin
        dprint, dlevel=0, 'Error: goes_combine_particle_data requires 2 inputs: type and probe.'
        return
    endif 
    ; we need the species type to be capitalized so that we can use it to find the tplot variables
    type = strupcase(type)
    ; sc is the typical GOES prefix, i.e., g15
    ;sc = 'g'+strcompress(string(probe),/remove_all)
    sc = strsplit(prefix, '_', /extract)

    ; the energies here are from the GOES-N databook
    ; note that these are only the center energies for the 
    ; instrument's energy bands
    energies = intarr(5,2)
    ; electron energies
    energies[*,0] = [40, 75, 150, 275, 475]
    ; proton energies
    energies[*,1] = [95, 140, 210, 300, 575]
    
    ; first work on the MAGE/PD tplot variables that are corrected for both dead times and contamination (COR)
    ; and then work on the tplot variables that are corrected for dead times but not other sources of contamination (UNCOR)
    ; this could be sped up significantly by vectorizing the for loops
    dtype = ['FLUX', 'CR']
    dtc_type = ['DTC', 'UDTC']
    contam_type = ['COR', 'UNCOR']
    for dtc_idx = 0, n_elements(dtc_type)-1 do begin
        for dtype_index = 0, n_elements(dtype)-1 do begin
            for contam_index = 0, n_elements(contam_type)-1 do begin
                ; find all the tplot variables for this spacecraft, particle species and contamination type
                tdtcflux = tnames(sc+'_M*M'+type+'*_'+dtc_type[dtc_idx]+'_'+contam_type[contam_index]+'_'+dtype[dtype_index]+suffix)
                ;tudtcflux = tnames(sc+'_M*M'+type+'*_UDTC_'+contam_type[contam_index]+'_*')
                ; loop through the tplot variables
                for tvar_index = 0, n_elements(tdtcflux)-1 do begin
                    ; use regex to identify the telescope and energy for this tplot varible
                    cortemp = stregex(tdtcflux[tvar_index], '^'+sc+'_M_(.+)M'+type+'(.)_'+dtc_type[dtc_idx]+'_'+contam_type[contam_index]+'_'+dtype[dtype_index], $
                    /extract, /subexp)
                    ; cortemp should always contain 3 elements here, the first being the full regex match
                    ; the second is the # corresponding to the telescope (or look direction)
                    ; the third is the # corresponding to the energy band
                    if (n_elements(cortemp) eq 3) && (cortemp[0] ne '') then begin
                        telescope = cortemp[1]
                        energy = cortemp[2]
                        get_data, tdtcflux[tvar_index], data=tcordata, dlimits=tcordlimits
                        ; if this is the first telescope, we need to create the array that we'll use to 
                        ; store the data from all telescopes for this energy band
                        if telescope eq 1 then begin
                            newmagedvar = fltarr(n_elements(tcordata.Y),9) ; 9 telescopes total
                            newmagedvar[*,0] = tcordata.Y[*]
                            ; we also need to store the time data. note that we assume here that the time data for the first 
                            ; telescope matches the time data for the rest of the telescopes exactly
                            maged_timedata = tcordata.X[*]
                        endif else if telescope eq 9 then begin
                            ; this is the last telescope, store the new tplot variable
                            newmagedvar[*,8] = tcordata.Y[*]
                            newtname = strcompress(sc+'_mag'+strlowcase(type)+'d_'+string(energies[energy-1, (type eq 'P')])+'keV_'+strlowcase(dtc_type[dtc_idx])+'_'+strlowcase(contam_type[contam_index])+'_'+strlowcase(dtype[dtype_index])+suffix, /remove_all)
                            
                            ; miscellaneous data attributes
                            data_att = {project: 'GOES', observatory: sc[0], instrument: 'mag'+strlowcase(type)+'d', units: tcordlimits.cdf.vatt.units, coord_sys: tcordlimits.cdf.vatt.coordinate_system, st_type: 'none'}
                            ; label the 9 telescopes
                            labels = strcompress(string(indgen(9)+1))
                            str_element, tcordlimits, 'data_att', data_att, /add
                            str_element, tcordlimits, 'labels', labels, /add
                            str_element, tcordlimits, 'labflag', 1, /add

                            ; update the vname in the CDF structure
                            tcordlimits.cdf.vname = newtname[0]
        
                            store_data, newtname[0], data={x:maged_timedata, y:newmagedvar, v:newmagedvar}, dlimits=tcordlimits
                            tplotnames = keyword_set(tplotnames) ? [tplotnames,newtname[0]] : newtname[0]
                        endif else begin
                            ; save the data for telescopes 2-8
                            newmagedvar[*,telescope-1] = tcordata.Y[*]
                        endelse
                        ; we assume the data was stored for this variable, go ahead and delete it
                        del_data, tdtcflux[tvar_index]
                    endif else begin
                        ; cortemp wasn't a 3 element array. this means the regex wasn't able to 
                        ; find the telescope/energy band information from the tplot variable name
                        dprint, dlevel = 1, 'No ' +contam_type[contam_index] + ' MAG'+type+'D data to load.'
                    endelse
                endfor
            endfor
        endfor
    endfor

    ; combine support data, if the user requested it; delete the tplot variables if not
    if undefined(get_support_data) then begin
        ; MAG*D support data include number of points and quality flags for each energy/telescope
        del_data, [tnames(sc+'_M*M'+type+'*_NUM_PTS'+suffix), tnames(sc+'_M*M'+type+'*_QUAL_FLAG'+suffix)]
    endif else begin
        ; 9 telescopes at five different energies
        for en_idx = 0, 4 do begin
            ; NUM_PTS variables
            num_pts_tvars = prefix+'M_'+strcompress(string((indgen(9)+1)), /rem)+'M'+type+strcompress(string(en_idx+1), /rem)+'_NUM_PTS'+suffix
            ; QUAL_FLAG variables
            qual_flag_tvars = prefix+'M_'+strcompress(string((indgen(9)+1)), /rem)+'M'+type+strcompress(string(en_idx+1), /rem)+'_QUAL_FLAG'+suffix
            new_num_pts_tvar = prefix+'mag'+strlowcase(type)+'d_'+strcompress(string(energies[en_idx, (type eq 'P')]), /rem)+'keV_num_pts'+suffix
            new_qual_flag_tvar = prefix+'mag'+strlowcase(type)+'d_'+strcompress(string(energies[en_idx, (type eq 'P')]), /rem)+'keV_qual_flag'+suffix
            join_vec, num_pts_tvars, new_num_pts_tvar
            join_vec, qual_flag_tvars, new_qual_flag_tvar
            tplotnames = keyword_set(tplotnames) ? [tplotnames,[new_num_pts_tvar, new_qual_flag_tvar]] : [new_num_pts_tvar, new_qual_flag_tvar]
            del_data, [num_pts_tvars, qual_flag_tvars]
        endfor
    endelse
end
; interface to the routines that combine different tdata loaded
; by the GOES netCDF load routines
pro goes_combine_tdata, datatype = datatype, probe = probe, prefix = prefix, suffix = suffix, $
                        get_support_data = get_support_data, tplotnames = tplotnames, noephem = noephem
    compile_opt idl2, hidden
    if undefined(prefix) then prefix = ''
    if undefined(suffix) then suffix = ''
    
    ; called from goes_load_data, after generating tplot variables
    if undefined(datatype) || undefined(probe) then begin
        dprint, dlevel = 0, 'Error, can''t combine data without datatype and probe in goes_combine_tdata'
        return
    endif 
    case datatype of
        'fgm': goes_combine_mag_data, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
        'eps': goes_combine_eps_data, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
        'epead': goes_combine_epead_data, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
        'maged': goes_combine_magpart_data, 'E', probe, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
        'magpd': goes_combine_magpart_data, 'P', probe, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
        'hepad': goes_combine_hepad_data, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
        'xrs': goes_combine_xrs_data, probe, prefix = prefix, suffix = suffix, get_support_data = get_support_data, tplotnames = tplotnames
    endcase

    ; delete ephemeris data loaded by the GOES load routines
    if ~undefined(noephem) then begin
        del_data, prefix + ['time_tag_orbit', 'inclination', 'west_longitude', 'time_tag'] + suffix
    endif else begin
        ; keep the ephemeris - let's make sure the data attributes are set correctly
        ; time_tag_orbit contains time values for orbit data (west_longitude, inclination)
        ; first, let's check that the standard ephemeris tvariables are loaded
        goes_set_ephem_data_att, prefix+'time_tag_orbit'+suffix, prefix, tplotnames = tplotnames
        goes_set_ephem_data_att, prefix+'inclination'+suffix, prefix, tplotnames = tplotnames
        goes_set_ephem_data_att, prefix+'west_longitude'+suffix, prefix, tplotnames = tplotnames
        goes_set_ephem_data_att, prefix+'time_tag'+suffix, prefix, tplotnames = tplotnames
    endelse
end
