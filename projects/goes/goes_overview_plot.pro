;+
; Procedure:
;         goes_overview_plot
;         
; Purpose:
;         Generates daily overview plots for GOES data
;              
; Keywords:
;         date: start date for the overview plot
;         duration: duration of the overview plot, in days; defaults to 1-day
;         directory: local directory to save the overview plots to (should end with '/' or '\')
;         device: change the plot device for cron plotting (for cron use device = 'z')
;         geopack_lshell: calculate L-shell by tracing field lines 
;             to the equator instead of using the dipole assumption
;         skip_ae_idx: set this keyword to skip downloading/plotting AE data
;         error: 1 indicates an error, 0 for no error
;
;    * Keywords specific to creating overview plots in the GUI:
;         gui_overplot: overview plot was created in the GUI
;         oplot_calls: pointer to an int for tracking calls to overview plots - for 
;             avoiding overwriting tplot data already loaded during this session
;          import_only: Used to make this routine import the data into the gui, but not plot it.
;         
; Notes:
;     For GOES 13-15:
;       Panel 1: Kyoto AE, THEMIS AE
;       Panel 2: B components in SM coordinates (colored), B magnitude (black)
;       Panel 3: delta B components, (B components subtracted from the IGRF)
;       Panel 4: MAGPD, line plot of protons by energy channel (omni directional)
;       Panel 5: EPEAD, line plot of e- by energy channel (omni directional)
;       Panel 6: MAGED, line plot of e- by energy channel (omni directional)
;       Panel 7: EPEAD high energy protons by energy channel (omni directional)
;       Panel 8: X-ray, short wavelength and long wavelength
;       
;     For GOES 8-12:
;       Panel 1: Kyoto AE, THEMIS AE
;       Panel 2: B components in SM coordinates (colored), B magnitude (black)
;       Panel 3: delta B components, (B components subtracted from the IGRF)
;       Panel 4: EPS, line plot of protons measured by the telescope detector by energy channel 
;       Panel 5: EPS, line plot of integral electron flux by energy channel
;       Panel 6: EPS, line plot of protons measured by the dome detector by energy channel 
;       Panel 7: X-ray, short wavelength and long wavelength
;       
;       
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2015-12-10 11:16:11 -0800 (Thu, 10 Dec 2015) $
; $LastChangedRevision: 19568 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/goes_overview_plot.pro $
;-

pro goes_overview_plot, date = date, probe = probe_in, directory = directory, device = device, $
                    geopack_lshell = geopack_lshell, duration = duration, gui_overplot = gui_overplot, $
                    oplot_calls = oplot_calls, error = error, skip_ae_idx = skip_ae_idx, import_only=import_only, $
                    _extra=_extra
                    
                       
    compile_opt idl2
    error = 0
    
    ; Catch errors and return
    catch, errstats
    if errstats ne 0 then begin
        error = 1
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return 
    endif
    
    ; compile the routines in our GOES library
    goes_lib
    
    ; delete any tplot variables sitting around
    ;store_data, '*', /delete
    
    ; sample GOES overview plot
    if undefined(probe_in) then probe = '13' else probe=probe_in[0]
    if undefined(date) then overviewdate = '2013-12-05' else overviewdate = time_string(date)
    if undefined(duration) then duration = 1 ; days
    if undefined(oplot_calls) then suffix = '' else suffix = strcompress('_op'+string(oplot_calls[0]), /rem)
    
    timespan, overviewdate, duration, /day
    time = time_struct(overviewdate)
    prefix = 'g'+probe
    earth_radius = 6371.
      
    window_xsize = 750
    window_ysize = 800
    if undefined(directory) then dir = path_sep() + 'g'+probe+path_sep() else dir = directory; +path_sep();+'g'+probe+path_sep()
    if ~undefined(device) then begin 
        set_plot, device
        device, set_resolution = [window_xsize, window_ysize]
    endif
if undefined(skip_ae_idx) then begin
;;=============================================================================
;; Panel 1: Kyoto and THEMIS AE
    kyoto_load_ae, datatype = 'ae'
    thm_make_AE
    
    get_data, 'thmAE', data=thm_ae_data, dlimits=thm_ae_dlimits
    get_data, 'kyoto_ae', data=kyoto_ae_data, dlimits=kyoto_ae_dlimits
    
    if is_struct(kyoto_ae_data) && is_struct(thm_ae_data) then begin
        combined_ae = fltarr(n_elements(kyoto_ae_data.X), 2)
    
        ; combine them into a single AE tplot variable
        for i=0l, n_elements(kyoto_ae_data.X)-1 do begin
            ae_nearest_neighbor = find_nearest_neighbor(thm_ae_data.X, kyoto_ae_data.X[i])
            if ae_nearest_neighbor ne -1 then begin
                combined_ae[i,0] = thm_ae_data.Y[where(thm_ae_data.X eq ae_nearest_neighbor)]
                combined_ae[i,1] = kyoto_ae_data.Y[i]
            endif else begin
                combined_ae[i,0] = !values.f_nan
                combined_ae[i,1] = !values.f_nan
            endelse
        endfor
        str_element, thm_ae_dlimits, 'labels', ['THEMIS AE', 'Kyoto AE'], /add
        str_element, thm_ae_dlimits, 'colors', [2,0], /add
        str_element, thm_ae_dlimits, 'ytitle', 'AE index', /add
        str_element, thm_ae_dlimits, 'ysubtitle', '[nT]', /add
        str_element, thm_ae_dlimits, 'labflag', 1, /add
        store_data, 'kyoto_thm_combined_ae'+suffix, data={x: kyoto_ae_data.X, y: combined_ae}, dlimits=thm_ae_dlimits
    endif else if is_struct(thm_ae_data) then begin
        ; only THEMIS AE available
        copy_data, 'thmAE', 'kyoto_thm_combined_ae'+suffix
        options, 'kyoto_thm_combined_ae'+suffix, 'ytitle', 'AE index'
        options, 'kyoto_thm_combined_ae'+suffix, 'labels', 'THEMIS AE'
        options, 'kyoto_thm_combined_ae'+suffix, 'labflag', 1
        options, 'kyoto_thm_combined_ae'+suffix, 'ysubtitle', '[nT]'
    endif else if is_struct(kyoto_ae_data) then begin
        ; only Kyoto AE available
        copy_data, 'kyoto_ae', 'kyoto_thm_combined_ae'+suffix
        options, 'kyoto_thm_combined_ae'+suffix, 'ytitle', 'AE index'
        options, 'kyoto_thm_combined_ae'+suffix, 'labels', 'Kyoto AE'
        options, 'kyoto_thm_combined_ae'+suffix, 'labflag', 1
        options, 'kyoto_thm_combined_ae'+suffix, 'ysubtitle', '[nT]'
    endif

endif
;;=============================================================================
; Panel 2: magnetic field components in SM coordinates
    goes_load_data, datatype='fgm', probes = probe, /avg_1m, suffix = suffix

    total_field = (uint(probe) ge 13) ? 'g'+probe+'_HT_1'+suffix : 'g'+probe+'_ht'+suffix
    enp_tvar_name = (uint(probe) ge 13) ? 'g'+probe+'_H_enp_1'+suffix : 'g'+probe+'_H_enp'+suffix
    
    ; make sure ephemeris data was loaded. 
    if tnames('g'+probe+'_pos_gei'+suffix) ne '' then begin
    
        ; make our transformation matrix for transforming to GEI coordinates
        enp_matrix_make, 'g'+probe+'_pos_gei'+suffix

        ; make sure the tvariable is loaded
        if tnames(enp_tvar_name) ne '' then begin
            ; rotate the field data into GEI coordinates
            tvector_rotate, 'g'+probe+'_pos_gei'+suffix+'_enp_mat', enp_tvar_name, /invert

            ; we really want the data in SM coordinates, so we go GEI->GSE->GSM->SM
            cotrans, enp_tvar_name+'_rot', 'g'+probe+'_H_gse'+suffix, /GEI2GSE
            cotrans, 'g'+probe+'_H_gse'+suffix, 'g'+probe+'_H_gsm'+suffix, /GSE2GSM
            cotrans, 'g'+probe+'_H_gsm'+suffix, 'g'+probe+'_H_sm'+suffix, /GSM2SM
            
            ; need to update the dlimits structure for the B-field vector in SM coordinates
            get_data, 'g'+probe+'_H_sm'+suffix, dlimits = b_sm_dlimits, data=b_sm_data
            get_data, total_field, data=b_total_data
            str_element, b_sm_dlimits, 'labels', ['Bx','By','Bz', 'Bmag'], /add
            str_element, b_sm_dlimits, 'colors', [2,4,6,0], /add
            str_element, b_sm_dlimits, 'labflag', -1, /add
            str_element, b_sm_dlimits, 'ytitle', 'B (SM)', /add
            str_element, b_sm_dlimits, 'ysubtitle', '[nT]', /add

            bvec_with_mag = [[b_sm_data.Y], [b_total_data.Y]]
            
            store_data, 'g'+probe+'_H_sm'+suffix, dlimits = b_sm_dlimits, data={x: b_sm_data.X, y: bvec_with_mag}
        endif
        b_field_tvarname = '_H_sm'+suffix
    endif else begin
        ; no ephemeris data was loaded, can't do the ENP->SM transformation
        ; plot the field data in ENP coordinates
        b_field_tvarname = '_H_enp'+suffix
        
        
        get_data, enp_tvar_name, dlimits = b_enp_dlimits, data=b_enp_data
        get_data, total_field, data=b_total_data
        str_element, b_enp_dlimits, 'labels', ['E','N','P', 'Bmag'], /add
        str_element, b_enp_dlimits, 'colors', [2,4,6,0], /add
        str_element, b_enp_dlimits, 'labflag', 1, /add
        str_element, b_enp_dlimits, 'ytitle', 'B (ENP)', /add
        str_element, b_enp_dlimits, 'ysubtitle', '[nT]', /add
        
        if is_struct(b_enp_data) && is_struct(b_enp_dlimits) then begin
            bvec_with_mag = [[b_enp_data.Y], [b_total_data.Y]]
        
            store_data, 'g'+probe+b_field_tvarname, dlimits = b_enp_dlimits, data = {x: b_enp_data.X, y: bvec_with_mag}
        endif 
    endelse

;;=============================================================================
; Panel 3: magnetic field components subtracted from IGRF

    ; make sure we have the B field loaded in SM coordinates and the IDL Geopack 
    ; DLM is installed before trying to calculate the IGRF
    if tnames('g'+probe+'_H_sm'+suffix) ne '' && igp_test() eq 1 then begin
        cotrans, 'g'+probe+'_pos_gei'+suffix, 'g'+probe+'_pos_gse'+suffix, /GEI2GSE
        cotrans, 'g'+probe+'_pos_gse'+suffix, 'g'+probe+'_pos_gsm'+suffix, /GSE2GSM
        
        get_data, 'g'+probe+'_pos_gsm'+suffix, data=pos_data
        
        igrf_bx = fltarr(n_elements(pos_data.y[*,0]))
        igrf_by = fltarr(n_elements(pos_data.y[*,1]))
        igrf_bz = fltarr(n_elements(pos_data.y[*,2]))
        
        ; find the IGRF in GSM for each point
        for i=0, n_elements(pos_data.X)-1 do begin
            timestr = time_struct(pos_data.X[i])
            geopack_recalc, timestr.year, timestr.doy, timestr.hour, timestr.min, timestr.sec, tilt=tilt
            ; input position units should be in Re
            geopack_igrf_gsm, pos_data.Y[i,0]/earth_radius, pos_data.Y[i,1]/earth_radius, pos_data.Y[i,2]/earth_radius, dummy_bx, dummy_by, dummy_bz
            igrf_bx[i] = dummy_bx
            igrf_by[i] = dummy_by
            igrf_bz[i] = dummy_bz
        endfor
        
        igrf_b_gsm = fltarr(n_elements(pos_data.Y[*,2]),3)
        igrf_b_gsm[*,0] = igrf_bx
        igrf_b_gsm[*,1] = igrf_by
        igrf_b_gsm[*,2] = igrf_bz
        store_data, 'igrf_b_gsm'+suffix, data={x: pos_data.X, y: igrf_b_gsm}
        
        ; transform the IGRF to SM coordinates
        cotrans, 'igrf_b_gsm'+suffix, prefix+'igrf_b_sm'+suffix, /GSM2SM
        
        get_data, prefix+'igrf_b_sm'+suffix, data=igrf_b_sm
        get_data, 'g'+probe+'_H_sm'+suffix, data=goes_h_sm
        
        deltaB = fltarr(n_elements(goes_h_sm.X), 3)
        for i=0l, n_elements(goes_h_sm.X)-1 do begin
            igrf_nearest_neighbor = find_nearest_neighbor(igrf_b_sm.X, goes_h_sm.X[i])
            if igrf_nearest_neighbor ne -1 then begin
                deltaB[i,0] = goes_h_sm.Y[i,0]-igrf_b_sm.Y[where(igrf_b_sm.X eq igrf_nearest_neighbor),0]
                deltaB[i,1] = goes_h_sm.Y[i,1]-igrf_b_sm.Y[where(igrf_b_sm.X eq igrf_nearest_neighbor),1]
                deltaB[i,2] = goes_h_sm.Y[i,2]-igrf_b_sm.Y[where(igrf_b_sm.X eq igrf_nearest_neighbor),2]
            endif else begin
                deltaB[i,0] = !values.f_nan
                deltaB[i,1] = !values.f_nan
                deltaB[i,2] = !values.f_nan
            endelse
            
        endfor
        
        store_data, prefix+'_delta_b_sm'+suffix, data={x: goes_h_sm.X, y: deltaB}, dlimits=b_sm_dlimits
        
        ; update the dlimits 
        options, prefix+'_delta_b_sm'+suffix, 'labels', ['Bx','By','Bz']
        options, prefix+'_delta_b_sm'+suffix, 'labflag', -1
        options, prefix+'_delta_b_sm'+suffix, 'ytitle', 'B (SM)-IGRF (SM)'
        options, prefix+'_delta_b_sm'+suffix, 'ysubtitle', '[nT]'
        
    endif 
    
    ; now load the particle data
    if uint(probe) ge 13 then begin
;;=============================================================================
; Panel 4: MAGPD, omni-directional protons, by energy
        goes_load_data, datatype = 'magpd', probes = probe, /avg_1m, suffix = suffix, tplotnames = tplotnames, /noephem
    
        goes_magpd_omni_flux, prefix, suffix

;;=============================================================================
; Panel 5: EPEAD, high energy electrons by energy
; this call to the load routine loads both electrons and proton data from EPEAD
        goes_load_data, datatype = 'epead', probes = probe, /avg_1m, suffix = suffix, tplotnames = tplotnames, /noephem

        ; the following averages the east and west components for each energy and 
        ; creates a single tplot variable with the 3 EPEAD electron energy channels
        goes_epead_comb_electron_flux, prefix, suffix


;;=============================================================================
; Panel 6: MAGED, omni-directional electrons, by energy
        goes_load_data, datatype = 'maged', probes = probe, /avg_1m, suffix = suffix, tplotnames = tplotnames, /noephem
    
        goes_maged_omni_flux, prefix, suffix

;;=============================================================================
; Panel 7: EPEAD high energy protons by energy
; the following averages the east and west components for each energy and 
; creates a single tplot variable with the 7 EPEAD proton energy channels
        goes_epead_comb_proton_flux, prefix, suffix

    endif else begin
        goes_load_data, datatype = 'eps', probes = probe, /avg_1m, suffix = suffix, tplotnames=tplotnames, /noephem
        goes_eps_comb_proton_flux, prefix, suffix
        goes_eps_comb_electron_flux, prefix, suffix
    endelse
;;=============================================================================
; Panel 8: XRS
    goes_load_data, datatype = 'xrs', probes = probe, /avg_1m, suffix = suffix, tplotnames = tplotnames, /noephem


;;=============================================================================
; Labels across the bottom: UT, MLT, L-shell
    if tnames('g'+probe+'_pos_gei'+suffix) ne '' then begin
        ; first, we need to use the position to calculate MLT
        cotrans, 'g'+probe+'_pos_gei'+suffix, 'g'+probe+'_pos_gse'+suffix, /GEI2GSE
        cotrans, 'g'+probe+'_pos_gse'+suffix, 'g'+probe+'_pos_gsm'+suffix, /GSE2GSM
        cotrans, 'g'+probe+'_pos_gsm'+suffix, 'g'+probe+'_pos_sm'+suffix, /GSM2SM
        get_data, 'g'+probe+'_pos_sm'+suffix, data=goes_pos_sm
        
        cart_to_sphere,goes_pos_sm.Y[*,0],goes_pos_sm.Y[*,1],goes_pos_sm.Y[*,2],goes_pos_r,goes_pos_theta,goes_pos_phi,/PH_0_360
        
        ; now we calculate MLT from phi
        mlt_values = fltarr(n_elements(goes_pos_phi))
    
        mlt_uncor = 12.0 + (goes_pos_phi*!dtor)*24./(2.*!PI)
    
        wheregt24 = where(mlt_uncor gt 24., gt24count, complement=wherelt24)
        mlt_values[wheregt24] = mlt_uncor[wheregt24]-24.
        mlt_values[wherelt24] = mlt_uncor[wherelt24]
    
        store_data, 'g'+probe+'_pos_mlt'+suffix, data={x: goes_pos_sm.X, y: mlt_values}
        options, 'g'+probe+'_pos_mlt'+suffix,ytitle='MLT'
        
        if undefined(geopack_lshell) then begin
            ; calculate L-shell, assuming a dipole field
            goes_L_values = (goes_pos_r/earth_radius)/cos(goes_pos_theta*!dtor)^2
        endif else begin
            ; calculate L-shell by tracing IGRF to the equator
            get_data, 'g'+probe+'_pos_gsm'+suffix, data=goes_pos_gsm
            goes_L_values = calculate_lshell(transpose([[goes_pos_gsm.X],[goes_pos_gsm.Y/earth_radius]]))
        endelse
        
        store_data, 'g'+probe+'_L_shell'+suffix, data={x: goes_pos_sm.X, y: goes_L_values}
        options, 'g'+probe+'_L_shell'+suffix,ytitle='L-shell'
    endif
    ; no errors up to this point
    error = 0
;;=============================================================================
; Make the figure
    !p.background=255.
    !p.color=0.
    time_stamp,/off
    loadct2,43
    !p.charsize=0.8
    
    if uint(probe) ge 13 then begin
        part_plots = ['_magpd_dtc_cor_omni_flux',$ ; MAGPD, line for each energy channel
                      '_elec_uncor_comb_flux', $ ; EPEAD electrons, line for each energy channel
                      '_maged_dtc_cor_omni_flux', $ ; MAGED, line for each energy channel
                      '_prot_uncor_comb_flux'] ; EPEAD high energy protons, line for each energy channel]
        empty_title = ['B comp', 'B comp', 'MAGPD', 'EPEAD', 'MAGED', 'EPEAD', 'X-ray'] ; titles for empty panels
    endif else begin
        part_plots = ['_eps_tele_protons', $ ; EPS, lower energy protons
                      '_eps_dome_electrons',$ ; EPS, integral electron flux
                      '_eps_dome_protons'] ; EPS, higher energy protons
        empty_title = ['B comp', 'B comp', 'EPS', 'EPS', 'EPS', 'X-ray'] ; titles for empty panels             
    endelse
    
    full_goes_plot = [prefix+[b_field_tvarname, $ ; B-field in SM coordnates
                   '_delta_b_sm'+suffix, $ ; delta B components
                   part_plots+suffix,$
                   '_xrs_avg'+suffix]]
    
    
    ; count the valid tplot variables in the GOES plot list
    num_valid_plots = 0
    for plot_idx = 0l, n_elements(full_goes_plot)-1 do $
        if tnames(full_goes_plot[plot_idx]) ne '' then num_valid_plots++
    
    ; Only make figures when we have at least one GOES tplot variable
    if num_valid_plots ge 1 then begin
        ; Create empty panels if needed, so that
        ; we always have 8 panels for GOES13-15, and 7 panels for GOES10-12
        for plot_idx = 0, n_elements(full_goes_plot)-1 do begin
            if tnames(full_goes_plot[plot_idx]) eq '' then begin
                store_data, full_goes_plot[plot_idx], data = {x: 0, y: 0}
                options, full_goes_plot[plot_idx], ytitle = empty_title[plot_idx]
                options, full_goes_plot[plot_idx], labels = 'No data'
                options, full_goes_plot[plot_idx], labflag = 1
            endif
        endfor
    endif else begin
        dprint, dlevel = 1, 'No valid GOES plots for this interval.'
    endelse
         
    if undefined(gui_overplot) then begin
              
            if ~undefined(device) then begin
                tplot_options,'title','GOES-'+probe+' Overview ('+overviewdate+')' 
                tplot, ['kyoto_thm_combined_ae', $ ; AE plot
                    [full_goes_plot]] 
                tplot, var_label=['g'+probe+'_pos_mlt', 'g'+probe+'_L_shell']+suffix
            endif else begin
                window, 1, xsize=window_xsize, ysize=window_ysize
                tplot_options,'title','GOES-'+probe+' Overview ('+overviewdate+')', window=1
                tplot, ['kyoto_thm_combined_ae', $ ; AE plot
                  [full_goes_plot]], window=1
                tplot, var_label=['g'+probe+'_pos_mlt', 'g'+probe+'_L_shell']+suffix, window=1 
            endelse
               
            ;thm_gen_multipngplot, 'g'+probe+'_overview', overviewdate, directory = dir, /mkdir
            thm_gen_multipngplot, 'goes_goes'+probe, overviewdate, directory = dir, /mkdir

    endif else begin
        tplot_gui, /no_verify, /add_panel, import_only=import_only, ['kyoto_thm_combined_ae'+suffix, $ ; AE plot
                    [full_goes_plot]], var_label=['g'+probe+'_pos_mlt', 'g'+probe+'_L_shell']+suffix
                    
    endelse
end