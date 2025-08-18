;+
; Procedure: goes_load_data
; 
; Keywords: 
;             trange:       time range of interest
;             datatype:     type of GOES data to be loaded. Valid data types are:
;                             'fgm': Fluxgate magnetometer
;                             'epead': Electron, Proton, Alpha Detector
;                             'maged': Magnetospheric Electron Detector
;                             'magpd': Magnetospheric Proton Detector
;                             'hepad': High energy Proton and Alpha Detector
;                             'xrs': X-ray Sensor
;            
;             suffix:        String to append to the end of the loaded tplot variables
;             probes:        Number(s) of the GOES spacecraft, i.e., probes=['13','14','15']
;             varnames:      Name(s) of variables to load, defaults to all (*)
;             /downloadonly: Download the file but don't read it
;             /avg_1m:       Use 1-minute averaged GOES data
;             /avg_5m:       Use 5-minute averaged GOES data
;             /no_time_clip: Don't clip the tplot variables
;             /get_support_data: keep the support data
;             /noephem:     Don't keep the ephemeris data
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2022-03-04 13:49:56 -0800 (Fri, 04 Mar 2022) $
; $LastChangedRevision: 30652 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/goes_load_data.pro $
;-
pro goes_load_data, trange = trange, datatype = datatype, probes = probes, suffix = suffix, $
      downloadonly = downloadonly, avg_1m = avg_1m, avg_5m = avg_5m, no_time_clip = no_time_clip, $
      tplotnames = tplotnames, varformat = varformat, get_support_data = get_support_data, noephem = noephem
    compile_opt idl2
    
    goes_init
    if undefined(suffix) then suffix = ''
    
    ; handle possible server errors
    catch, errstats
    if errstats ne 0 then begin
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return
    endif
    
    ; set the default datatype to FGM data
    if not keyword_set(datatype) then datatype = 'fgm'
    if not keyword_set(probes) then probes = ['13', '14', '15']
    if not keyword_set(source) then source = !goes
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    tn_list_before = tnames('*')
      
    for idx_probes=0,n_elements(probes)-1 do begin ; loop through the probes
      
        prb = strcompress(string(probes[idx_probes]), /rem)
        if array_contains(['16', '17'], prb) then begin
            dprint, dlevel=0, 'This routine is only valid for GOES-N data; GOES-R (probes 16, 17) data can be accessed with goesr_load_data'
            continue
        endif
        
        sc = 'g'+string(probes[idx_probes], format='(I02)')
        prefix = sc + '_'

        dprint,dlevel=2,verbose=source.verbose,'Loading GOES-',string(probes[idx_probes], format='(I02)'),' ',strupcase(datatype),' data'
        
        fullavgpath = ['full', 'avg']
        goes_path_dir = fullavgpath[~undefined(avg_1m) or ~undefined(avg_5m)]
        remote_path = goes_path_dir + '/YYYY/MM/goes' + string(probes[idx_probes], format='(I02)') + '/netcdf/'

        case datatype of
            ; flux-gate magnetometer -- valid for GOES 08-15
            'fgm': begin 
                if undefined(avg_1m) && undefined(avg_5m) then begin ; full, unaveraged data
                    pathformat = remote_path + sc + '_magneto_512ms_YYYYMMDD_YYYYMMDD.nc'
                endif else if ~undefined(avg_1m) then begin ; 1 minute averages
                    pathformat = remote_path + sc + '_magneto_1m_YYYYMM01_YYYYMM??.nc'
                endif else if ~undefined(avg_5m) then begin ; 5 minute averages
                    pathformat = remote_path + sc + '_magneto_5m_YYYYMM01_YYYYMM??.nc'
                endif
            end
            ; energetic particle sensor -- only valid for GOES-08 through GOES-12, only averaged data available
            'eps': begin 
                if ~undefined(avg_1m) then begin 
                    pathformat = remote_path + sc + '_eps_1m_YYYYMM01_YYYYMM??.nc'
                endif else if ~undefined(avg_5m) then begin
                    pathformat = remote_path + sc + '_eps_5m_YYYYMM01_YYYYMM??.nc'
                endif
            end
            ; electron, proton, alpha detector -- only valid on GOES-13, 14, 15
            'epead': begin 
                if undefined(avg_1m) && undefined(avg_5m) then begin
                     pathformat = strarr(8)
                     pathformat[0] = remote_path + sc + '_epead_e1ew_4s_YYYYMMDD_YYYYMMDD.nc'
                     pathformat[1] = remote_path + sc + '_epead_e2ew_16s_YYYYMMDD_YYYYMMDD.nc'
                     pathformat[2] = remote_path + sc + '_epead_e3ew_16s_YYYYMMDD_YYYYMMDD.nc'
                     pathformat[3] = remote_path + sc + '_epead_p1ew_8s_YYYYMMDD_YYYYMMDD.nc'
                     pathformat[4] = remote_path + sc + '_epead_p27e_32s_YYYYMMDD_YYYYMMDD.nc'
                     pathformat[5] = remote_path + sc + '_epead_p27w_32s_YYYYMMDD_YYYYMMDD.nc'
                     pathformat[6] = remote_path + sc + '_epead_a16e_32s_YYYYMMDD_YYYYMMDD.nc'
                     pathformat[7] = remote_path + sc + '_epead_a16w_32s_YYYYMMDD_YYYYMMDD.nc'
                endif else if ~undefined(avg_1m) then begin ; 1 minute averages
                    pathformat = strarr(3) ; electrons, protons, alpha
                    pathformat[0] = remote_path + sc + '_epead_e13ew_1m_YYYYMM01_YYYYMM??.nc'
                    pathformat[1] = remote_path + sc + '_epead_p17ew_1m_YYYYMM01_YYYYMM??.nc'
                    pathformat[2] = remote_path + sc + '_epead_a16ew_1m_YYYYMM01_YYYYMM??.nc'
                endif else if ~undefined(avg_5m) then begin ; 5 minute averages
                    pathformat = strarr(3) ; electrons, protons, alpha
                    pathformat[0] = remote_path + sc + '_epead_e13ew_5m_YYYYMM01_YYYYMM??.nc'
                    pathformat[1] = remote_path + sc + '_epead_p17ew_5m_YYYYMM01_YYYYMM??.nc'
                    pathformat[2] = remote_path + sc + '_epead_a16ew_5m_YYYYMM01_YYYYMM??.nc'
                endif
            end
            ; magnetospheric electron detector -- only valid on GOES 13, 14, 15
            'maged': begin 
                if undefined(avg_1m) && undefined(avg_5m) then begin ; unaveraged maged data
                    pathformat = strarr(5)
                    channels = ['me1','me2','me3','me4','me5']
                    resolution = ['2','2','4','16','32'] ; seconds
                    for i = 0, n_elements(channels)-1 do pathformat[i] = $
                      remote_path + sc + '_maged_19'+channels[i]+'_'+resolution[i]+'s_YYYYMMDD_YYYYMMDD.nc'
                endif else if ~undefined(avg_1m) then begin ; 1 minute averages
                    pathformat = remote_path + sc + '_maged_19me15_1m_YYYYMM01_YYYYMM??.nc'
                endif else if ~undefined(avg_5m) then begin ; 5 minute averages
                    pathformat = remote_path + sc + '_maged_19me15_5m_YYYYMM01_YYYYMM??.nc'
                endif
            end
            ; magnetospheric proton detector -- only valid on GOES 13, 14, 15
            'magpd': begin 
                if undefined(avg_1m) && undefined(avg_5m) then begin ; unaveraged magpd data
                    pathformat = strarr(5)
                    channels = ['mp1','mp2','mp3','mp4','mp5']
                    resolution = ['16','16','16','32','32'] ; seconds
                    for i = 0, n_elements(channels)-1 do pathformat[i] = $
                      remote_path + sc + '_magpd_19'+channels[i]+'_'+resolution[i]+'s_YYYYMMDD_YYYYMMDD.nc'
                endif else if ~undefined(avg_1m) then begin
                    pathformat = remote_path + sc + '_magpd_19mp15_1m_YYYYMM01_YYYYMM??.nc'
                endif else if ~undefined(avg_5m) then begin
                    pathformat = remote_path + sc + '_magpd_19mp15_5m_YYYYMM01_YYYYMM??.nc'
                endif
            end
            ; high energy proton and alpha detector -- valid for GOES 08-15
            'hepad': begin 
                if undefined(avg_1m) && undefined(avg_5m) then begin
                    pathformat = strarr(2)
                    pathformat[0] = remote_path + sc + '_hepad_ap_32s_YYYYMMDD_YYYYMMDD.nc'
                    pathformat[1] = remote_path + sc + '_hepad_s15_4s_YYYYMMDD_YYYYMMDD.nc'
                endif else if ~undefined(avg_1m) then begin
                    pathformat = strarr(2)
                    pathformat[0] = remote_path + sc + '_hepad_ap_1m_YYYYMM01_YYYYMM??.nc'
                    pathformat[1] = remote_path + sc + '_hepad_s15_1m_YYYYMM01_YYYYMM??.nc'
                endif else if ~undefined(avg_5m) then begin
                    pathformat = strarr(2)
                    pathformat[0] = remote_path + sc + '_hepad_ap_5m_YYYYMM01_YYYYMM??.nc'
                    pathformat[1] = remote_path + sc + '_hepad_s15_5m_YYYYMM01_YYYYMM??.nc'
                endif 
            end
            ; x-ray sensor -- valid for GOES 08-15
            'xrs': begin 
                if undefined(avg_1m) && undefined(avg_5m) then begin
                    pathformat = remote_path + sc + '_xrs_2s_YYYYMMDD_YYYYMMDD.nc'
                endif else if ~undefined(avg_1m) then begin
                    pathformat = remote_path + sc + '_xrs_1m_YYYYMM01_YYYYMM??.nc'
                endif else if ~undefined(avg_5m) then begin
                    pathformat = remote_path + sc + '_xrs_5m_YYYYMM01_YYYYMM??.nc'
                endif 
            end
            else:  pathformat = ''
        endcase
        
        if not keyword_set(pathformat) then begin
            dprint,'No data found. Try a different probe.'
            return
        endif
        
        for j = 0, n_elements(pathformat)-1 do begin
            relpathnames = file_dailynames(file_format=pathformat[j],trange=tr,addmaster=addmaster, /unique)

            files = spd_download(remote_file=relpathnames, remote_path=!goes.remote_data_dir, $
              local_path = !goes.local_data_dir)

            if keyword_set(downloadonly) then continue

            ; netcdf2tplot, files, varformat = varformat, prefix = prefix, suffix = suffix
            netcdf2tplot, files, prefix = prefix, suffix = suffix
        endfor
        
        ; make sure some tplot variables were loaded
        tn_list_after = tnames('*')
        new_tnames = ssl_set_complement([tn_list_before], [tn_list_after])

        ; load the ephemeris data in GEI coordinates
        if undefined(noephem) && is_string(new_tnames) then begin
            ephem = goes_load_pos(trange = time_string(tr), probe = probes[idx_probes])
            if is_struct(ephem) then begin
                ; store the data attributes structure 
                data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], $
                            instrument: 'ephem', units: 'km', coord_sys: 'gei', st_type: 'pos'}
                dlimits = {data_att: data_att, colors: [2,4,6], labels: ['x','y','z']+'_gei', ysubtitle: '[km]'}
                store_data, prefix + 'pos_gei' + suffix, data={x: ephem.time, y: ephem.pos_values}, dlimits=dlimits
            endif else begin
                dprint, dlevel=1, 'Error loading ephemeris data. No data returned from goes_load_pos()'
            endelse
        endif
        
        if is_string(new_tnames) then begin
            ; now that we've loaded the variables from the netCDF file into tplot, we can combine 
            ; data for the different telescopes/detectors to TDAS-ify the tvariables
            goes_combine_tdata, datatype = datatype, probe = probes[idx_probes], prefix = prefix, suffix = suffix, $
                               get_support_data = get_support_data, tplotnames = tplotnames, noephem = noephem
        endif
    endfor

    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
    ;print, 'TPLOT variables: '
    ;tplot_names
end
