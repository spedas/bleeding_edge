;+
; Procedure:
;         poes_overview_plot
;         
; Purpose:
;         Generates overview plots for POES data
;              
; Keywords:
;         probe: POES probe to create an overview plot for (noaa18, noaa19, etc.)
;         
;         date: Start date for the overview plot
;         duration: Duration of the overview plot
;         error: error state, 0 for no error, 1 for an error
;         makepng: generate png files
;         gui_overplot: flag, 0 if the overview plot isn't being made in the GUI, 1 if it is
;         oplot_calls: pointer to an int for tracking calls to overview plots - for 
;             avoiding overwriting tplot data already loaded during this session
;         
; Notes:
;       
;       
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2022-03-18 12:52:44 -0700 (Fri, 18 Mar 2022) $
; $LastChangedRevision: 30691 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_overview_plot.pro $
;-

pro poes_overview_plot, date = date, probe = probe_in, duration = duration, error = error, makepng = makepng,$
                        gui_overplot = gui_overplot, oplot_calls = oplot_calls, directory = directory, $
                        device = device, import_only=import_only, _extra = _extra
    compile_opt idl2
    
    ; Catch errors and return
    catch, errstats
    if errstats ne 0 then begin
        error = 1
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return 
    endif

    thm_init
    poes_init
    
    window_xsize = 750
    window_ysize = 800
    
    if undefined(date) then date = '2013-03-17/00:00:00'
    if undefined(probe_in) then probe_in = 'noaa19'
    if is_numeric(probe_in) then probe_in = 'noaa' + probe_in
;    if undefined(duration) then duration = 0.08333 ; days
    if undefined(duration) then duration = 1 ; days
    
    if undefined(directory) then dir = path_sep() + probe_in+path_sep() else dir = directory
    if ~undefined(device) then begin 
        set_plot, device
        device, set_resolution = [window_xsize, window_ysize]
    endif
    
    timespan, date, duration, /day
    
    poes_load_data, probes = probe_in

    poes_plots = probe_in+['_ted_ele_flux_tel0_fixed', '_ted_ele_flux_tel30_fixed', $
        '_ted_pro_flux_tel0_fixed', '_ted_pro_flux_tel30_fixed', $
        '_mep_ele_flux_tel?', '_mep_ele_flux_tel??', $
        '_mep_pro_flux_tel?', '_mep_pro_flux_tel??']

    ; make sure the data was loaded
    poes_data_loaded = tnames(poes_plots)

    if n_elements(poes_data_loaded) gt 1 then begin
        if undefined(gui_overplot) then begin
            ; setup the plot
            ;window, 1, xsize=window_xsize, ysize=window_ysize
            time_stamp,/off
            loadct2,43
            !p.charsize=0.7
            
            !p.background=255.
            !p.color=0.
            
            tplot_options, 'title', strupcase(probe_in)
            
            tplot, poes_plots
        
            ; add the ephem labels
            options, /def, probe_in+'_mlt', 'ytitle', 'MLT'
            options, /def, probe_in+'_mag_lat_sat', 'ytitle', 'Lat'
            
            tplot, var_label=[probe_in+'_mlt', probe_in+'_mag_lat_sat']
            if keyword_set(makepng) then begin
              thm_gen_multipngplot, probe_in, date, directory = dir, /mkdir
            endif
        endif else begin
          
            options, /add, probe_in+'_mlt', 'ytitle', 'MLT'
            options, /add, probe_in+'_mag_lat_sat', 'ytitle', 'Lat'
            tplot_gui, /no_verify, /add_panel, poes_plots, var_label=[probe_in+'_mag_lat_sat', probe_in+'_mlt'], import_only=import_only
        
        endelse
        error = 0
    endif else begin
        dprint, dlevel = 0, 'Error creating POES overview plot - no data loaded for ' + time_string(date)
        error = 1
    endelse
end
