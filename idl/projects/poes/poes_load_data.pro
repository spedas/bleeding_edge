;+
; Procedure: poes_load_data
; 
; Keywords: 
;             trange:       time range of interest
;             datatype:     type of POES data to be loaded. Valid data types are:
;                    ---- Total Energy Detector (TED) ----
;                      ted_ele_flux: TED differential electron flux, both telescopes, energies: 189 eV, 844 eV, 2595 eV, 7980 eV
;                      ted_pro_flux: TED differential proton flux, both telescopes, energies: 189 eV, 844 eV, 2595 eV, 7980 eV
;                      ted_ele_eflux: TED electron integral energy flux, both telescopes, low (50-1000 eV) and high energy (1-20 keV)
;                      ted_pro_eflux: TED proton integral energy flux, both telescopes, low (50-1000 eV) and high energy (1-20 keV)
;                      ted_ele_eflux_atmo: TED electron atmospheric integral energy flux, low and high energies (50-1000 eV, 1-20 keV), at 120 km
;                      ted_pro_eflux_atmo: TED proton atmospheric integral energy flux, low and high energies (50-1000 eV, 1-20 keV), at 120 km
;                      ted_total_eflux_atmo: TED electron and proton total atmospheric integral energy flux at 120 km
;                      ted_ele_energy: TED electron characteristic energy channel, both telescopes
;                      ted_pro_energy: TED proton characteristic energy channel, both telescopes
;                      ted_ele_max_flux: TED electron maximum differential flux, both telescopes
;                      ted_pro_max_flux: TED proton maximum differential flux, both telescopes
;                      ted_ele_eflux_bg: TED electron background integral energy flux, both telescopes, low (50-1000 eV) and high energy (1-20 keV)
;                      ted_pro_eflux_bg: TED proton background integral energy flux, both telescopes, low (50-1000 eV) and high energy (1-20 keV)
;                      ted_pitch_angles: TED pitch angles (at satellite and foot of field line)
;                      ted_ifc_flag: TED IFC flag (0=off, 1=on)
;
;                    ---- Medium Energy Proton and Electron Detector ----
;                      mep_ele_flux: MEPED electron integral flux, in energy for each telescope
;                      mep_pro_flux: MEPED proton differential flux, in energy for each telescope
;                      mep_pro_flux_p6: MEPED proton integral flux,  >6174 keV, for each telescope
;                      mep_omni_flux: MEPED omni-directional proton differential flux
;                      mep_pitch_angles: MEPED pitch angles (satellite and foot print)
;                      mep_ifc_flag: IFC flag for MEPED, (0=off, 1=on)
;            
;             suffix:        String to append to the end of the loaded tplot variables
;             probes:        Name of the POES spacecraft, i.e., probes=['noaa18','noaa19','metop2']
;             varnames:      Name(s) of variables to load, defaults to all (*)
;             ncei_server:   When set, use NOAA NCEI server instead of SPDF. Some older data is only available on the NOAA server.
;             /downloadonly: Download the file but don't read it  
; 
; $LastChangedBy: nikos $
; $LastChangedDate: 2024-09-05 08:04:54 -0700 (Thu, 05 Sep 2024) $
; $LastChangedRevision: 32807 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_load_data.pro $
;-
 
; split tplot variable containing data for two telescopes into 
; two tplot variables - one for each telescope
pro poes_split_telescope_data, name, telescope_angles, tplotnames = tplotnames
    get_data, name, data=the_data, dlimits=the_dlimits
    if is_struct(the_data) && is_struct(the_dlimits) then begin
        store_data, name+'_tel'+telescope_angles[0], data={x: the_data.X, y: reform(the_data.Y[*,0,*])}, dlimits=the_dlimits
        store_data, name+'_tel'+telescope_angles[1], data={x: the_data.X, y: reform(the_data.Y[*,1,*])}, dlimits=the_dlimits
    
        del_data, name
        ; add the new tplot variables to tplotnames, so we can time clip them.
        append_array, tplotnames, name+'_tel'+telescope_angles[0]
        append_array, tplotnames, name+'_tel'+telescope_angles[1]
    endif else begin
        dprint, dlevel=0, 'Error splitting the telescope data for '+name+'. Invalid tplot variable?'
    endelse
end

; we need to "fix" every TED flux tplot variable. By "fix", I mean:
;   1) replace all -1s in the data with NaNs
;   2) change the fillval in the metadata to NaN
;   3) set the y-axis to plot as log by default
pro poes_fix_ted_flux_vars, ted_fluxes
    ; loop through the TED flux tplot variables
    for ted_flux_idx = 0, n_elements(ted_fluxes)-1 do begin
        get_data, ted_fluxes[ted_flux_idx], data=poes_data_to_fix, dlimits=poes_dlimits_to_fix
        
        if is_struct(poes_data_to_fix) && is_struct(poes_dlimits_to_fix) then begin
            poes_dlimits_to_fix.cdf.vatt.fillval = !values.F_NAN
            str_element, poes_dlimits_to_fix, 'ylog', 1, /add_replace
            poes_fixed_data = poes_data_to_fix
            
            ; change -1s to NaNs
            for j = 0, n_elements(poes_data_to_fix.Y[0,*])-1 do begin
                poes_fixed_data.Y[where(poes_data_to_fix.Y[*,j] eq -1),j] = !values.f_nan
            endfor
            
            store_data, ted_fluxes[ted_flux_idx]+'_fixed', data=poes_fixed_data, dlimits=poes_dlimits_to_fix
            
            tdeflag, ted_fluxes[ted_flux_idx]+'_fixed', 'linear', /overwrite
            
            ; remove the old tplot variable
            del_data, ted_fluxes[ted_flux_idx]
        endif
    endfor
end

pro poes_fix_metadata, tplotnames, prefix = prefix
    if undefined(prefix) then prefix = ''
    
    ; loop through each tplot name, set the metadata for variables based on their name
    for name_idx = 0, n_elements(tplotnames)-1 do begin
        tplot_name = tplotnames[name_idx]
        case tplot_name of
            ; TED differential electron flux
            prefix + '_' + 'ted_ele_flux_tel0': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'ytitle', 'TED!CElectron Flux!C0deg telescope'
                options, /def, tplot_name, 'labels', ['189 eV', '844 eV', '2595 eV', '7980 eV']
            end
            prefix + '_' + 'ted_ele_flux_tel30': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'ytitle', 'TED!CElectron Flux!C30deg telescope'
                options, /def, tplot_name, 'labels', ['189 eV', '844 eV', '2595 eV', '7980 eV']
            end
            prefix + '_' + 'ted_pro_flux_tel0': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'ytitle', 'TED!CProton Flux!C0deg telescope'
                options, /def, tplot_name, 'labels', ['189 eV', '844 eV', '2595 eV', '7980 eV']
            end
            prefix + '_' + 'ted_pro_flux_tel30': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'ytitle', 'TED!CProton Flux!C30deg telescope'
                options, /def, tplot_name, 'labels', ['189 eV', '844 eV', '2595 eV', '7980 eV']
            end
            prefix + '_' + 'ted_ele_tel0_low_eflux': begin ; 0 deg telescope, low e- eflux
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'colors', [2,4]
                options, /def, tplot_name, 'lazy_ytitle', 0
                options, /def, tplot_name, 'ytitle', 'Electron Integral!CEnergy Flux!C0deg telescope'
                options, /def, tplot_name, 'labels', '50-1000 eV'
                options, /def, tplot_name, 'ysubtitle', '[mW/m!U2!N-str]'
            end
            prefix + '_' + 'ted_ele_tel30_low_eflux': begin ; 30 deg telescope, low e- eflux
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'colors', [2,4]
                options, /def, tplot_name, 'lazy_ytitle', 0
                options, /def, tplot_name, 'ytitle', 'Electron Integral!CEnergy Flux!C30deg telescope'
                options, /def, tplot_name, 'labels', '50-1000 eV'
                options, /def, tplot_name, 'ysubtitle', '[mW/m!U2!N-str]'
            end
            prefix + '_' + 'ted_ele_tel0_hi_eflux': begin ; 0 deg telescope, high e- eflux
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'colors', [2,4]
                options, /def, tplot_name, 'lazy_ytitle', 0
                options, /def, tplot_name, 'ytitle', 'Electron Integral!CEnergy Flux!C0deg telescope'
                options, /def, tplot_name, 'labels', '1-20 keV'
                options, /def, tplot_name, 'ysubtitle', '[mW/m!U2!N-str]'
            end
            prefix + '_' + 'ted_ele_tel30_hi_eflux': begin ; 30 deg telescope, high e- eflux
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'colors', [2,4]
                options, /def, tplot_name, 'lazy_ytitle', 0
                options, /def, tplot_name, 'ytitle', 'Electron Integral!CEnergy Flux!C30deg telescope'
                options, /def, tplot_name, 'labels', '1-20 keV'
                options, /def, tplot_name, 'ysubtitle', '[mW/m!U2!N-str]'
            end
            prefix + '_' + 'ted_pro_tel0_low_eflux': begin ; 0 deg telescope, low p+ eflux
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'ytitle', 'Proton Integral!CEnergy Flux!C0deg telescope'
                options, /def, tplot_name, 'labels', '50-1000 eV'
                options, /def, tplot_name, 'ysubtitle', '[mW/m!U2!N-str]'
            end
            prefix + '_' + 'ted_pro_tel30_low_eflux': begin ; 30 deg telescope, low p+ eflux
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'ytitle', 'Proton Integral!CEnergy Flux!C30deg telescope'
                options, /def, tplot_name, 'labels', '50-1000 eV'
                options, /def, tplot_name, 'ysubtitle', '[mW/m!U2!N-str]'
            end
            prefix + '_' + 'ted_pro_tel0_hi_eflux': begin ; 0 deg telescope, high p+ eflux
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'ytitle', 'Proton Integral!CEnerg Flux!C0deg telescope'
                options, /def, tplot_name, 'labels', '1-20 keV'
                options, /def, tplot_name, 'ysubtitle', '[mW/m!U2!N-str]'
            end
            prefix + '_' + 'ted_pro_tel30_hi_eflux': begin ; 30 deg telescope, high p+ eflux
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'ytitle', 'Proton Integral!CEnergy Flux!C30deg telescope'
                options, /def, tplot_name, 'labels', '1-20 keV'
                options, /def, tplot_name, 'ysubtitle', '[mW/m!U2!N-str]'
            end
            prefix + '_' + 'ted_alpha_0_sat': begin ; pitch angle at 0 deg telescope, at the satellite
                options, /def, tplot_name, 'ytitle', 'TED_pitch angle_satellite'
                options, /def, tplot_name, 'ysubtitle', '[degrees]'
            end
            prefix + '_' + 'ted_alpha_30_sat': begin ; pitch angle at 30 deg telescope, at the satellite
                options, /def, tplot_name, 'ytitle', 'TED_pitch angle_satellite'
                options, /def, tplot_name, 'ysubtitle', '[degrees]'
            end
            prefix + '_' + 'ted_alpha_0_foot': begin ; pitch angle at 0 deg telescope, mapped to foot of field line
                options, /def, tplot_name, 'ytitle', 'TED_pitch angle_footprint'
                options, /def, tplot_name, 'ysubtitle', '[degrees]'
            end
            prefix + '_' + 'ted_alpha_30_foot': begin ; pitch angle at the 30 deg telescope, mapped to foot of field line
                options, /def, tplot_name, 'ytitle', 'TED_pitch angle_footprint'
                options, /def, tplot_name, 'ysubtitle', '[degrees]'
            end
            prefix + '_' + 'ted_ele_max_flux_tel0': begin ; maximum differential e- flux, 0 deg telescope
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'ytitle', 'Max_Electron_Differential_Flux'
                options, /def, tplot_name, 'labels', '0 deg_telescope'
                options, /def, tplot_name, 'ysubtitle', '[#/cm!U2!N-s-str-eV]'
            end
            prefix + '_' + 'ted_ele_max_flux_tel30': begin ; maximum differential e- flux, 30 deg telescope
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'ytitle', 'Max_Electron_Differential_Flux'
                options, /def, tplot_name, 'labels', '30 deg_telescope'
                options, /def, tplot_name, 'ysubtitle', '[#/cm!U2!N-s-str-eV]'
            end
            prefix + '_' + 'ted_pro_max_flux_tel0': begin ; max differential p+ flux, 0 deg telescope
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'ytitle', 'Max_Proton_Differential_Flux'
                options, /def, tplot_name, 'labels', '0 deg_telescope'
                options, /def, tplot_name, 'ysubtitle', '[#/cm!U2!N-s-str-eV]'
            end
            prefix + '_' + 'ted_pro_max_flux_tel30': begin ; max differential p+ flux, 30 deg telescope
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'ytitle', 'Max_Proton_Differential_Flux'
                options, /def, tplot_name, 'labels', '30 deg_telescope'
                options, /def, tplot_name, 'ysubtitle', '[#/cm!U2!N-s-str-eV]'
            end 
            prefix + '_' + 'mep_pro_flux_p6': begin ; p+ integral flux, >6174 keV, contaminated by electrons
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'ytitle', 'Proton_Integral_Flux'
                options, /def, tplot_name, 'labels', '>6174 keV'
                options, /def, tplot_name, 'ysubtitle', '[#/cm!U2!N-s-str]'
            end
            prefix + '_' + 'mep_omni_flux': begin ; omni-directional p+ flux (MeV)
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'colors', [2,4,6]
                options, /def, tplot_name, 'ytitle', 'Omni-directional_Proton_Flux'
                options, /def, tplot_name, 'labels', ['25 MeV', '50 MeV', '100 MeV']
                options, /def, tplot_name, 'ysubtitle', '[#/cm!U2!N-s-str-MeV]'
            end
            prefix + '_' + 'mep_ele_flux_tel0': begin
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'labels', ['40 keV', '130 keV', '287 keV', '612 keV']
                options, /def, tplot_name, 'ytitle', 'MEPED!CElectron Flux!C0deg telescope'
            end
            prefix + '_' + 'mep_ele_flux_tel90': begin
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'labels', ['40 keV', '130 keV', '287 keV', '612 keV']
                options, /def, tplot_name, 'ytitle', 'MEPED!CElectron Flux!C90deg telescope'
            
            end
            prefix + '_' + 'mep_pro_flux_tel0': begin
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6,8,1]
                options, /def, tplot_name, 'labels', ['30-80 keV', '80-240 keV', '240-800 keV', '2500-6900 keV', '> 6900 keV']
                options, /def, tplot_name, 'ytitle', 'MEPED!CProton Flux!C0deg telescope'
            
            end
            prefix + '_' + 'mep_pro_flux_tel90': begin
                options, /def, tplot_name, 'ylog', 1
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6,8,1]
                options, /def, tplot_name, 'labels', ['30-80 keV', '80-240 keV', '240-800 keV', '2500-6900 keV', '> 6900 keV']
                options, /def, tplot_name, 'ytitle', 'MEPED!CProton Flux!C90deg telescope'
            
            end
            prefix + '_' + 'meped_alpha_0_sat': begin ; pitch angles at the satellite, 0 deg detector
                options, /def, tplot_name, 'ytitle', 'MEPED_pitch angle_satellite'
                options, /def, tplot_name, 'ysubtitle', '[degrees]'
            end
            prefix + '_' + 'meped_alpha_90_sat': begin ; pitch angles at the satellite, 90 deg detector
                options, /def, tplot_name, 'ytitle', 'MEPED_pitch angle_satellite'
                options, /def, tplot_name, 'ysubtitle', '[degrees]'
            end
            prefix + '_' + 'meped_alpha_0_foot': begin ; pitch angles at the field foot print, 0 deg detector
                options, /def, tplot_name, 'ytitle', 'MEPED_pitch angle_footprint'
                options, /def, tplot_name, 'ysubtitle', '[degrees]'
            end
            prefix + '_' + 'meped_alpha_90_foot': begin ; pitch angles at teh field foot print, 90 deg detector
                options, /def, tplot_name, 'ytitle', 'MEPED_pitch angle_footprint'
                options, /def, tplot_name, 'ysubtitle', '[degrees]'
            end
        else: ; don't complain if this isn't a POES variable that needs its metadata fixed
        endcase
    endfor
end

pro poes_load_data, trange = trange, datatype = datatype, probes = probes, suffix = suffix, $
                    downloadonly = downloadonly, verbose = verbose, noephem = noephem, ncei_server=ncei_server
    compile_opt idl2

    poes_init
    if undefined(suffix) then suffix = ''
    if undefined(prefix) then prefix = ''
    if undefined(ncei_server) then ncei_server=0 else ncei_server=1
    
    ; handle possible server errors
    catch, errstats
    if errstats ne 0 then begin
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return
    endif

    if not keyword_set(datatype) then datatype = '*'
    if not keyword_set(probes) then probes = ['noaa19'] 
    if not keyword_set(source) then source = !poes
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    tn_list_before = tnames('*')
    
    pathformat = strarr(n_elements(probes))
    ; let's have the prefix include the probe name, so we can load
    ; data from multiple spacecraft without naming conflicts
    prefix_array = strarr(n_elements(probes))
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        dprint, dlevel = 2, verbose=source.verbose, 'Loading ', strupcase(probes[probe_idx]), ' data'

        pathformat[probe_idx] = '/noaa/'+probes[probe_idx]+'/sem2_fluxes-2sec/YYYY/'+probes[probe_idx]+'_poes-sem2_fluxes-2sec_YYYYMMDD_v01.cdf'
        prefix_array[probe_idx] = prefix + probes[probe_idx]
        
        nmlen = strlen(probes[probe_idx])
        if ncei_server eq 1 && nmlen gt 1 then begin
          num = strmid(probes[probe_idx], nmlen-2, 2)
          pathformat[probe_idx] = "YYYY/" + probes[probe_idx] + "/poes_n" + num + "_YYYYMMDD.cdf"
        endif
    endfor
    
    for j = 0, n_elements(datatype)-1 do begin
        if datatype[j] eq '*' then varformat = '*' else begin
            case datatype[j] of 
                ; TED differential electron flux
                'ted_ele_flux': append_array, varformat, 'ted_ele_flux'
                ; TED differential proton flux
                'ted_pro_flux': append_array, varformat, 'ted_pro_flux'
                ; TED electron integral energy flux
                'ted_ele_eflux': append_array, varformat, 'ted_ele_*_eflux'
                ; TED proton integral energy flux
                'ted_pro_eflux': append_array, varformat, 'ted_pro_*_eflux'
                ; TED electron atmospheric integral energy flux at 120 km
                'ted_ele_eflux_atmo': append_array, varformat, 'ted_ele_eflux_atmo_*'
                ; TED proton atmospheric integral energy flux at 120 km
                'ted_pro_eflux_atmo': append_array, varformat, 'ted_pro_eflux_atmo_*'
                ; TED electron and proton total atmospheric integral energy flux at 120 km
                'ted_total_eflux_atmo': append_array, varformat, 'ted_total_eflux_atmo'
                ; TED electron characteristic energy channel
                'ted_ele_energy': append_array, varformat, 'ted_ele_energy*'
                ; TED proton characteristic energy channel
                'ted_pro_energy': append_array, varformat, 'ted_pro_energy*'
                ; TED electron maximum differential flux
                'ted_ele_max_flux': append_array, varformat, 'ted_ele_max_flux_*'
                ; TED proton maximum differential flux
                'ted_pro_max_flux': append_array, varformat, 'ted_pro_max_flux_*'
                ; TED electron background integral energy flux
                'ted_ele_eflux_bg': append_array, varformat, 'ted_ele_eflux_bg*'
                ; TED proton background integral energy flux
                'ted_pro_eflux_bg': append_array, varformat, 'ted_pro_eflux_bg*'
                ; TED pitch angles (at satellite and foot of field line)
                'ted_pitch_angles': append_array, varformat, 'ted_alpha_*'
                ; TED IFC flag
                'ted_ifc_flag': append_array, varformat, 'ted_ifc_on'
                ; MEPED electron integral flux, in energy for each telescope
                'mep_ele_flux': append_array, varformat, 'mep_ele_flux*'
                ; MEPED proton differential flux, in energy for each telescope
                'mep_pro_flux': append_array, varformat, 'mep_pro_flux*'
                ; MEPED proton integral flux,  >6174 keV, for each telescope
                'mep_pro_flux_p6': append_array, varformat, 'mep_pro_flux_p6*'
                ; MEPED omni-directional proton differential flux
                'mep_omni_flux': append_array, varformat, 'mep_omni_flux*'
                ; MEPED pitch angles (satellite and foot print)
                'mep_pitch_angles': append_array, varformat, 'meped_alpha_*'
                ; IFC flag for MEPED, (0=off, 1=on)
                'mep_ifc_flag': append_array, varformat, 'mep_ifc_on'
                else: dprint, dlevel = 0, 'Unknown data type!'

            endcase
        endelse
    endfor
    
    ; load ephemeris data
    if undefined(noephem) then begin
        append_array, varformat, 'mag_lat_sat'
        append_array, varformat, 'mag_lon_sat'
        append_array, varformat, 'l_igrf'
        append_array, varformat, 'mlt'
    endif
    
    ; MEPED electron flux energies????
    append_array, varformat, 'mep_*_energies'
    
    for j = 0, n_elements(pathformat)-1 do begin
        relpathnames = file_dailynames(file_format=pathformat[j], trange=tr, /unique)

        ;files = file_retrieve(relpathnames, _extra=source, /last_version)
        if ncei_server eq 1 then begin
          remote_server = 'https://www.ncei.noaa.gov/data/poes-metop-space-environment-monitor/access/l2/v01r00/cdf/'
        endif else begin
          remote_server = source.remote_data_dir
        endelse
        files = spd_download(remote_file=relpathnames, remote_path=remote_server, $
          local_path = source.local_data_dir, ssl_verify_peer=0, ssl_verify_host=0)
        
        if keyword_set(downloadonly) then continue
        ; warning: using /get_support_data with cdf2tplot will cause cdf2tplot to ignore the varformat keyword
        poes_cdf2tplot, files, prefix = prefix_array[j]+'_', suffix = suffix, verbose = verbose, $
            tplotnames=tplotnames, varformat = varformat, /load_labels
        
        ; check for data types with data for multiple telescopes in a single tplot variable. 
        mep_telescopes = ['0', '90']
        mep_ele_flux = where(tplotnames eq prefix_array[j]+'_mep_ele_flux', ele_count)
        if ele_count ne 0 then begin
            poes_split_telescope_data, prefix_array[j]+'_mep_ele_flux', mep_telescopes, tplotnames = tplotnames
            poes_split_telescope_data, prefix_array[j]+'_mep_ele_flux_err', mep_telescopes, tplotnames = tplotnames
        endif

        mep_pro_flux = where(tplotnames eq prefix_array[j]+'_mep_pro_flux', pro_count)
        if pro_count ne 0 then begin
            poes_split_telescope_data, prefix_array[j]+'_mep_pro_flux', mep_telescopes, tplotnames = tplotnames
            poes_split_telescope_data, prefix_array[j]+'_mep_pro_flux_err', mep_telescopes, tplotnames = tplotnames
        endif
        
        ted_telescopes = ['0', '30']
        ted_ele_flux = where(tplotnames eq prefix_array[j]+'_ted_ele_flux', ele_count)
        if ele_count ne 0 then begin
            poes_split_telescope_data, prefix_array[j]+'_ted_ele_flux', ted_telescopes, tplotnames = tplotnames
            poes_split_telescope_data, prefix_array[j]+'_ted_ele_flux_err', ted_telescopes, tplotnames = tplotnames
        endif

        ted_pro_flux = where(tplotnames eq prefix_array[j]+'_ted_pro_flux', pro_count)
        if pro_count ne 0 then begin
            poes_split_telescope_data, prefix_array[j]+'_ted_pro_flux', ted_telescopes, tplotnames = tplotnames
            poes_split_telescope_data, prefix_array[j]+'_ted_pro_flux_err', ted_telescopes, tplotnames = tplotnames
        endif
        
        
        ; fix the metadata for the newly loaded tplot variables (labels, etc) 
        poes_fix_metadata, tplotnames, prefix = prefix_array[j]

        ted_fluxes = prefix_array[j]+['_ted_ele_flux_tel0', '_ted_ele_flux_tel30', $
                '_ted_pro_flux_tel0', '_ted_pro_flux_tel30']
                
        poes_fix_ted_flux_vars, ted_fluxes
    endfor

    ; make sure some tplot variables were loaded
    tn_list_after = tnames('*')
    new_tnames = ssl_set_complement([tn_list_before], [tn_list_after])
    
    ; check that some data was loaded
    if n_elements(new_tnames) eq 1 && is_num(new_tnames) then begin
        dprint, dlevel = 1, 'No new data was loaded.'
        return
    endif

    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
        
end
