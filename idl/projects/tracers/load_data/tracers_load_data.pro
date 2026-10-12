function get_tracers_opts, level_in=level_in, instrument_in=instrument_in, $
    probes=probes, levels=levels, instruments=instruments, datatypes=datatypes

    probes_opts = ['1','2']
    levels_opts = ['1a','1b','2','3']
    instruments_opts = ['ace','aci','efi','mag','magic','msc']

    if keyword_set(probes) then return,probes_opts
    if keyword_set(levels) then return,levels_opts
    if keyword_set(instruments) then return,instruments_opts
    if keyword_set(datatypes) && ~undefined(level_in) && ~undefined(instrument_in) then begin
        ;if ~in_set(level_in,['l1a','l1b','l2','l3']) then level_in='l'+level_in
        case instrument_in of
            'ace': begin
                    if in_set(level_in,['l1a','l1b','l2']) then datatypes_opts = ['def']
                    if in_set(level_in,['l3']) then datatypes_opts = ['pitch-angle-dist']
                end
            'aci': begin
                    if in_set(level_in,['l1a','l1b','l2']) then datatypes_opts = ['ipd']
                end
            'efi': begin
                    if in_set(level_in,['l1a','l1b','l2']) then datatypes_opts = ['eac','ehf','hsk','vdc']
                end
            'mag': begin
                    if in_set(level_in,['l1a','l1b','l2']) then datatypes_opts = ['bdc-16sps']
                end
            'magic': begin
                    if in_set(level_in,['l1a','l1b','l2']) then datatypes_opts = ['bdc-16sps']
                end
            'msc': begin
                    if in_set(level_in,['l1a','l1b','l2']) then datatypes_opts = ['bac']
                end
        endcase
        return, datatypes_opts
    endif else begin
        dprint,"Insufficient information given"
        return,["**"]
    endelse

end

;+
;NAME:
;       tracers_load_data
;DESCRIPTION:
;       Download L1A, L1B, L2, or L3 TRACERS data from the public portal, team data archive, or SPDF
;PARAMETERS:
;       trange (in, optional, STRING | Array[STRING]): 
;           Time range of interest [starttime, endtime]. 
;           Expects format: 'YYYY-MM-DD' or 'YYYY-MM-DD/hh:mm:ss'. 
;           If not set, prompts user to input start datetime and duration (number of days to load).
;       probes (in, optional, STRING | Array[STRING]):
;           Spacecraft to load. 
;           Options are: '1', '2', 'ts1', 'ts2', '*', or 'all'. 
;           Inputs of '*' or 'all' load both TS1 and TS2 data.
;           If not set, defaults to '2'. 
;       levels (in, optional, STRING):
;           Data processing level. 
;           Options are: 'l1a', 'l1b', 'l2' and 'l3'. Public data portal only contains 'l2' and 'l3' data.
;           If not set, defaults to 'l2'. 
;       instrument (in, optional, STRING):
;           Instrument to load. 
;           Options are: 'ace', 'aci', 'efi', 'mag', 'magic', 'msc'. 
;           If not set, defaults to 'ace'.
;       datatypes_in (in, optional, STRING | Array[STRING])
;           Instrument data product to load.
;           Setting wildcard '*' will load all data products for given instrument.
;           The data products for each processing level and instrument are as follows (first listed is default):
;               * L2:
;                   * ACE: 'def'
;                   * ACI: 'ipd'
;                   * EFI: 'eac', 'ehf', 'hsk', 'vdc'
;                   * MAG: 'bdc-16sps'
;               * L3:
;                   * ACE: 'pitch-angle-dist'
;       cdf_version:
;           specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;       data_rates
;           Instrument data rates
;       local_data_dir
;       source
;       login_info
;       tplotnames: 
;           returns a list of the names of the tplot variables loaded by the load routine
;       varformat: 
;           should be a string (wildcards accepted) that will match the CDF variables that should be loaded into 
;           tplot variables
;       suffix: 
;           appends a suffix to the end of the tplot variable name. this is useful for preserving original tplot 
;           variable.
;       cdf_records: 
;           specify the # of records to load from the CDF files; this is useful for grabbing one record from a CDF
;           file
;KEYWORDS:
;       spdf: 
;           grab the data from the SPDF instead of TRACERS server - ***NOTE: only state and epdef data are at SPDF
;           available
;       pred: 
;           set this flag for 'predicted' state data. default state data is 'definitive'.
;       get_support_data: 
;           load support data (defined by VAR_TYPE="support_data" in the CDF)
;       no_time_sort: 
;           set this flag to not order by time and remove duplicates
;       no_color_setup: 
;           don't setup graphics configuration; use this keyword when you're using this load routine from a 
;           terminal without an X server running
;       no_time_clip: 
;           don't clip the data to the requested time range; note that if you do use this keyword you may load a 
;           longer time range than requested.
;       no_update: (NOT YET IMPLEMENTED) 
;           set this flag to preserve the original data. if not set and newer data is found the existing data will 
;           be overwritten
;       no_download:
;       tt2000: 
;           flag for preserving TT2000 timestamps found in CDF files (note that many routines in SPEDAS 
;           (e.g., tplot.pro) do not currently support these timestamps)
;       public_data: 
;           set this flag to retrieve data from the public area (default is private dir)
;       versions:
;           this keyword returns the version #s of the CDF files used when loading the data
;       cdf_filenames:
;           this keyword returns the names of the CDF files used when loading the data
;USAGE:
;       tracers_load_data,probe='2'
;AUTHOR:
;       Adapted from the TRACERS Mission package, written by S. Shaver, S. Henderson, C. Piker, with 
;       contributions from the TRACERS Science Operations and Instrument Teams.
;       Written by D. Carpenter and J. Lewis, 2026
;NOTES:
;       is trange bidirectional?
;       data_rates for future dev?
;       default datatype for each instrument?
;       versions vs CDF version? versions is bidirectional to contain loaded versions, cdf_version is input to constrain file version
;       ;    case instrument of
;        'ace':dtype_opts=['def']
;        'aci':dtype_opts=['ipd']
;        'efi':dtype_opts=['eac','ehf','hsk','vdc']
;        'mag':dtype_opts=['bdc-16sps']
;        'magic':dtype_opts=['bdc-16sps']
;        'msc':dtype_opts=['bac']
;        else:dtype_opts=['**']
;    endcase

;--------------------------------------------------------------------------------------
pro tracers_load_data, trange = trange, probes = probes, datatypes = datatypes, $
    level = level, instruments = instruments, data_rates = data_rates, spdf = spdf, teams = teams, $
    local_data_dir = local_data_dir, source = source, pred = pred, versions = versions, $
    get_support_data = get_support_data, login_info = login_info, no_time_sort=no_time_sort, $
    tplotnames = tplotnames, varformat = varformat, no_color_setup = no_color_setup, $
    suffix = suffix, no_time_clip = no_time_clip, no_update = no_update, no_download=no_download, $
    cdf_filenames = cdf_filenames, cdf_version = cdf_version, cdf_records = cdf_records, $
    tt2000 = tt2000 
    
    ;temporary variables to track elapsed times
    t0 = systime(/sec)
    dt_query = 0d
    dt_download = 0d
    dt_load = 0d
    public = 1

    ; initializes remote data directory, local directory, and no color setup
    tracers_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, no_color_setup = no_color_setup
    if undefined(source) then source = !tracers
    
    probes_opts = ['1','2']
    levels_opts = ['1a','1b','2','3']
    instruments_opts = ['ace','aci','efi','mag','magic','msc']
    
    ; Handle input arguments
    ; Probes:
    probes_opts = get_tracers_opts(/probes)
    if undefined(probes) then probes = ['2']
    if ~is_array(probes) then probes = strsplit(probes,' ',/extract)
    if in_set('all',probes) or in_set('*',probes) then probes = probes_opts
    probes = strcompress(string(probes), /rem) ; probes should be strings
    probes = strlowcase(probes)
    ; Levels
    levels_opts = get_tracers_opts(/levels)
    if undefined(level) then level='2'
    level = 'l' + strlowcase(level)
    ; Instruments:
    instruments_opts = get_tracers_opts(/instruments)
    if undefined(instruments) then instruments = ['all']
    if ~is_array(instruments) then instruments = strsplit(instruments,' ',/extract)
    if in_set('all',instruments) or in_set('*',instruments) then instruments = instruments_opts
    instruments = strlowcase(instruments)
    ; Datatypes:
    if undefined(datatypes) then datatypes=['all']
    if is_string(datatypes) && ~is_array(datatypes) then datatypes = strsplit(datatypes,' ',/extract)
    if in_set('all',datatypes) or in_set('*',datatypes) then datatypes = ['**']
    datatypes = strlowcase(datatypes)
    ; CDF Version:
    ; default to latest version of CDF unless version specifically requested
    ; TODO: handle CDF versions as arrays? probably not...
    if undefined(cdf_version) then cdf_version='**'
    if cdf_version eq 'latest' then cdf_version='**'
    ; Data Rates:
    if undefined(data_rates) then data_rates = ['']
    if is_string(data_rates) && ~is_array(data_rates) then data_rates = strsplit(data_rates,' ',/extract)
    data_rates = strlowcase(data_rates)
    
    ; Remote Source
    remote_source = 'public'
    if keyword_set(teams) then remote_source = 'teams'
    if keyword_set(spdf) then remote_source = 'spdf'
    ; if level 1, set remote_source to teams:
    if in_set(level,['l1a','l1b']) then begin
        dprint,'L1A and L1B data are only available in the team portal; changing remote source to "teams"...'
        remote_source = 'teams'
    endif
    if ~undefined(login_info) then begin
        remote_source = 'teams'
        if ~is_array(login_info) then begin
            dprint,'login_info must be array of strings, where the first element contains the username and the second element contains the password.'
            return
        endif else begin
            if n_elements(login_info) lt 2 then begin
                dprint,'login_info must be array of strings, where the first element contains the username and the second element contains the password.'
                return
            endif
        endelse
    endif else begin
        if remote_source eq 'teams' then begin
            dprint,'login_info required for teams data access.'
            return
        endif
    endelse
        
    if remote_source eq 'teams' and undefined(remote_data_dir) then source.remote_data_dir = 'https://tracers-portal.physics.uiowa.edu/teams/flight/'
    if remote_source eq 'spdf' and undefined(remote_data_dir) then source.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/tracers/'
    if undefined(local_data_dir) then local_data_dir = source.local_data_dir    
    ; handle shortcut characters in the user's local data directory
    spawn, 'echo ' + local_data_dir, local_data_dir
    if is_array(local_data_dir) then local_data_dir = local_data_dir[0]
    
    ; TODO: pred is for predicted vs definitive. Determine if this is still needed. For support data? Predicted vs definitive SPICE kernel?
    if undefined(pred) then pred = 0 else pred = 1
    
    ; varformat and get_support_data are conflicting; warn the user
    ; if they're both set, and default to varformat
    if ~undefined(varformat) && ~undefined(get_support_data) then begin
        dprint, dlevel = 1, 'Conflicting keywords set (varformat and get_support_data). Using varformat'
        get_support_data = 0
    endif
    ; time range arguments
    if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
        dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
        return
    endif
    if ~undefined(trange) && n_elements(trange) eq 2 then tr = timerange(trange) else tr = timerange()
    ; TODO: is response_code still needed?
    ;response_code = spd_check_internet_connection()
    response_code = 200
    ;combine these flags for now, if we're not downloading files then there is
    ;no reason to contact the server unless mms_get_local_files is unreliable
    if ~undefined(no_download) then no_download=1 else $
        no_download = source.no_download or source.no_server or (response_code ne 200) or ~undefined(no_update); or keyword_set(spdf)
    ;clear so new names are not appended to existing array
    undefine, tplotnames
    ; clear CDF filenames, so we're not appending to an existing array
    undefine, cdf_filenames
    ; Retrieve data:
    for probes_idx = 0, n_elements(probes)-1 do begin
        probe = 'ts' + probes[probes_idx]
        for instruments_idx = 0, n_elements(instruments)-1 do begin
            instrument = instruments[instruments_idx]
            datatypes_opts = []
            case instrument of
                'ace': begin
                    if in_set(level,['l1a','l1b','l2']) then datatypes_opts = ['def']
                    if in_set(level,['l3']) then datatypes_opts = ['pitch-angle-dist']
                end
                'aci': begin
                    if in_set(level,['l1a','l1b','l2']) then datatypes_opts = ['ipd']
                end
                'efi': begin
                    if in_set(level,['l1a','l1b','l2']) then datatypes_opts = ['eac','ehf','hsk','vdc']
                end
                'mag': begin
                    if in_set(level,['l1a','l1b','l2']) then datatypes_opts = ['bdc-16sps']
                end
                'magic': begin
                    if in_set(level,['l1a','l1b','l2']) then datatypes_opts = ['bdc-16sps']
                end
                'msc': begin
                    if in_set(level,['l1a','l1b','l2']) then datatypes_opts = ['bac']
                end
            endcase
            if n_elements(datatypes_opts) gt 0 then begin
                if (n_elements(datatypes) eq 1) || (datatypes[0] eq '**') then begin
                    instr_datatypes = datatypes_opts
                endif else begin
                    instr_datatypes = datatypes
                endelse
                for datatypes_idx = 0, n_elements(instr_datatypes)-1 do begin
                    datatype = instr_datatypes[datatypes_idx]
                    if in_set(datatype,datatypes_opts) then begin
                        for data_rates_idx = 0, n_elements(data_rates)-1 do begin
                            data_rate = data_rates[data_rates_idx]
                            ; construct file names
                            daily_names = file_dailynames(trange=tr, /unique, times=times)
                            fn_remote_list = make_array(n_elements(daily_names), /string)
                            fn_local_list = make_array(n_elements(daily_names), /string)
                            for dn=0, n_elements(daily_names)-1 do fn_remote_list[dn] = probe + '_' + level + '_' + instrument + '_' + datatype + '_' + daily_names[dn] + '_v'+cdf_version+'.cdf'
                            ;clear so new names are not appended to existing array
                            undefine, tplotnames
                            ; clear CDF filenames so we're not appending to an existing array
                            undefine, cdf_filenames
                            ; set up the path names
                            local_path = filepath('', ROOT_DIR=source.local_data_dir, $
                                SUBDIRECTORY=[probe, level, instrument])
                            local_path = spd_addslash(local_path)
                            for file_idx = 0, n_elements(fn_remote_list)-1 do begin
                                file_remote_path = ''
                                file_local_path = ''
                                case remote_source of
                                    'spdf': begin
                                        datatype_dir = datatype
                                        case instrument of
                                            'ace': begin
                                                instrument_dir = instrument + '_cusp-electrons'
                                                if datatype eq 'def' then datatype_dir = 'def_diff-en-flux'
                                                if datatype eq 'pitch-angle-dist' then datatype_dir = 'def_pitch-angle-dist'
                                            end
                                            'aci': begin
                                                instrument_dir = instrument + '_cusp-ions'
                                                if datatype eq 'ipd' then datatype_dir = 'ipd_ion-dist'
                                            end
                                            'efi': begin
                                                if datatype eq 'ehf' then datatype_dir = 'highfrequency'
                                            end
                                            'msc': instrument_dir = instrument + '_searchcoil'
                                            else: instrument_dir = instrument
                                        endcase
                                        file_remote_path = 'tracers' + probes[probes_idx] + '/' + instrument_dir + '/' + level + '/' + datatype_dir + '/' + strmid(daily_names[file_idx],0,4) + '/'
                                    end
                                    'teams': begin
                                        case instrument of
                                            'aci': file_remote_path = strupcase(instrument) + '/' + probe + '/' + level + '/' + instrument + '/' + strmid(daily_names[file_idx],0,4) + '/' + strmid(daily_names[file_idx],4,2) + '/'
                                            'efi': file_remote_path = strupcase(instrument) + '/' + probe + '/' + level + '/' + strmid(daily_names[file_idx],0,4) + '/' + strmid(daily_names[file_idx],4,2) + '/' + strmid(daily_names[file_idx],6,2) + '/'
                                            'mag': file_remote_path = strupcase(instrument) + '/' + 'publish' + '/'
                                            'magic': file_remote_path = strupcase(instrument) + '/' + 'publish' + '/' + strupcase(probe) + '/' + strupcase(level) + '/' + strmid(daily_names[file_idx],0,4) + '/' + strmid(daily_names[file_idx],4,2) + '/' + strmid(daily_names[file_idx],6,2) + '/'
                                            else: file_remote_path = strupcase(instrument) + '/' + probe + '/' + level + '/' + strmid(daily_names[file_idx],0,4) + '/' + strmid(daily_names[file_idx],4,2) + '/'
                                        endcase
                                    end
                                    'public': begin
                                        case instrument of
                                            'magic': file_remote_path = strupcase(instrument) + '/' + strupcase(probe) + '/' + strupcase(level) + '/' + strmid(daily_names[file_idx],0,4) + '/' + strmid(daily_names[file_idx],4,2) + '/'
                                            else: file_remote_path = strupcase(level) + '/' + strupcase(probe) + '/' + strmid(daily_names[file_idx],0,4) + '/' + strmid(daily_names[file_idx],4,2) + '/' + strmid(daily_names[file_idx],6,2) + '/' ; public
                                        endcase
                                    end
                                endcase
                                file_remote_path = source.remote_data_dir + file_remote_path
                                file_local_path = spd_addslash(local_path + strmid(daily_names[file_idx],0,4) + '/' + strmid(daily_names[file_idx],4,2) + '/' + strmid(daily_names[file_idx],6,2) + '/')
                                ; Download the data unless told otherwise:
                                if ~keyword_set(no_download) then begin
                                    if file_test(file_local_path,/dir) eq 0 then file_mkdir2, file_local_path
                                    dprint, dlevel=1, 'Downloading ' + fn_remote_list[file_idx] + ' to ' + file_local_path
                                    if ~undefined(login_info) then begin
                                        paths = spd_download(remote_file=fn_remote_list[file_idx], remote_path=file_remote_path, $
                                            local_file=local_fn, local_path=file_local_path, $
                                            last_version=1, $
                                            ssl_verify_peer=0, ssl_verify_host=0, $
                                            url_username=login_info[0], url_password=login_info[1])
                                    endif else begin
                                        paths = spd_download(remote_file=fn_remote_list[file_idx], remote_path=file_remote_path, $
                                            local_file=local_fn, local_path=file_local_path, $
                                            last_version=1, $
                                            ssl_verify_peer=0, ssl_verify_host=0)
                                    endelse
                                    ;url_username=user, url_password=pw, ssl_verify_peer=1, $
                                    ;ssl_verify_host=1)
                                    fn_local_list[file_idx]=local_fn
                                    ; Extract Version:
                                    ; use local file name to extract version, and append that to version list
                                    ; Assumes argument is file basename (no path)
                                    cdf_data_version = STRJOIN(STRSPLIT((STRSPLIT(local_fn,'_v',/EXTRACT))[-1],'.cdf',/EXTRACT),'.')
                                    append_array, versions, cdf_data_version
                                    ; Record file to load:
                                    if undefined(paths) or paths eq '' then begin
                                        dprint, 'Unable to download ' + fn_remote_list[file_idx]
                                    endif else begin
                                        append_array, files, file_local_path+fn_local_list[file_idx]
                                    endelse
                                endif ; download sequence

                                ; if remote file not found or no_download set then look for local copy
                                if paths eq '' or keyword_set(no_download)then begin
                                    ; get all files from the beginning of the first day
                                    day_string=strmid(daily_names[file_idx],0,4)+'-'+strmid(daily_names[file_idx],4,2)+'-'+strmid(daily_names[file_idx],6,2)
                                    end_string=time_string(time_double(day_string)+86399.)
                                    local_files_result = tracers_get_local_files(probe=probe, instrument=instrument, $
                                        data_rate=data_rate, datatype=datatype, level=level, $
                                        trange=time_double([day_string, end_string]), cdf_version=cdf_version, $
                                        min_version=min_version, latest_version=latest_version, pred=pred)
                                    if is_string(local_files_result) then begin
                                        ; prepare the file list as a list of structs, (required input to mms_files_in_interval)
                                        local_file_info = replicate({filename: '', timetag: ''}, n_elements(local_files_result))
                                        for local_file_idx = 0, n_elements(local_files_result)-1 do begin
                                            local_file_info[local_file_idx].filename = local_files_result[local_file_idx]
                                        endfor
                                        ; filter to the requested time range
                                        local_files_filtered = tracers_files_in_interval(local_file_info, tr)
                                        local_files_result = local_files_filtered.filename
                                        append_array, files, local_files_result
                                    endif
                                endif ; local check sequence

                                ; Load CDF files into tplot variables:
                                if ~undefined(files) then begin
                                    unique_files = files[uniq(files, sort(files))]
                                    if ~undefined(cdf_data_version) then begin
                                        if n_elements(unique_files) GT 1 then begin
                                            sidx = strpos(unique_files, cdf_data_version)
                                            fidx = where(sidx NE -1, ncnt)
                                            if ncnt GT 0 then unique_files = unique_files[fidx]
                                        endif
                                    endif
                                    spd_cdf2tplot, unique_files, tplotnames = loaded_tnames, varformat=varformat, $
                                        suffix = suffix, get_support_data = get_support_data, /load_labels, $
                                        min_version=min_version,version=cdf_data_version,latest_version=latest_version, $
                                        number_records=cdf_records, center_measurement=center_measurement, $
                                        loaded_versions = the_loaded_versions, major_version=major_version, $
                                        tt2000=tt2000
                                endif
                                ; add cdf files to file list
                                append_array, cdf_filenames, files
                                ; if the local files added new tplot variable names, append to list of tnames
                                if ~undefined(loaded_tnames) then append_array, all_tnames, loaded_tnames
                                ; Include locally loaded versions of data into the array containing file versions
                                ;if ~undefined(the_loaded_versions) then append_array, versions, the_loaded_versions
                                ; forget about the daily files for this probe
                                undefine, files
                                undefine, loaded_tnames
                                undefine, the_loaded_versions
                                undefine, local_fn
                            endfor ; fileidx loop
                        endfor ; data_rates loop
                    endif ; datatype check
                endfor ; datatypes loop
            endif ; valid datatypes opts check
        endfor ; instrument loop    
    endfor ; probe loop
    
    ; Collect tplot variable names.
    ; just in case multiple datatypes loaded identical variables
    ; (this occurs with hpca moments & logicals)
    if undefined(all_tnames) then return else tplotnames=all_tnames
    if ~undefined(tplotnames) then tplotnames = spd_uniq(tplotnames)
    ; check that data was loaded
    ntvars = n_elements(tplotnames)
    if ntvars eq 1 && tplotnames[0] eq '' then return ; no data loaded
    ; remove any blank strings
    if ntvars GT 1 && tplotnames[0] eq '' then tplotnames=tplotnames[1:ntvars-1]   
    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        dt_timeclip = 0.0
        error = 0
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') and ~keyword_set(no_time_clip) then begin
            tc0 = systime(/sec)
            for tc=0,n_elements(tplotnames)-1 do begin
                time_clip, tplotnames[tc], tr[0], tr[1], replace=1, error=error
                if error EQ 1 then begin
                    dprint, dlevel=1, 'The time requested for '+tplotnames[tc]+' is out of range'
                    dprint, dlevel=1, 'No data was loaded for '+tplotnames[tc]
                    del_data, tplotnames[tc]
                    ;tplotnames=''
                    ;return 
                endif else begin
                    append_array, tclip_tplotnames, tplotnames[tc]
                endelse
            endfor
            dt_timeclip = systime(/sec)-tc0
        endif
        if ~undefined(tclip_tplotnames) then tplotnames=tclip_tplotnames
    endif
    ;temporary messages for diagnostic purposes
    ; TODO: remove in final version
    dprint, dlevel=2, 'Successfully loaded: '+ $
    strjoin( ['ts'+probes, instruments, data_rates, level, datatypes, time_string(tr)],' ')
    dprint, dlevel=2, 'Time querying remote server: '+strtrim(dt_query,2)+' sec'
    dprint, dlevel=2, 'Time downloading remote files: '+strtrim(dt_download,2)+' sec'
    dprint, dlevel=2, 'Time loading files into IDL: '+strtrim(dt_load,2)+' sec'
    dprint, dlevel=2, 'Time spent time clipping variables: '+strtrim(dt_timeclip,2)+' sec'
    dprint, dlevel=2, 'Total load time: '+strtrim(systime(/sec)-t0,2)+' sec'
end
