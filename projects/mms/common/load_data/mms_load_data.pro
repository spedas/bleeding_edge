;+ 
; PROCEDURE:
;         mms_load_data
;         
; PURPOSE:
;         Generic MMS load data routine; typically called from instrument specific 
;           load routines - mms_load_???, i.e., mms_load_fgm, mms_load_fpi, etc.
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         instrument: instrument, 'fpi', 'hpca', 'fgm', etc.
;         datatypes: depends on instrument; see header of the instrument's load routine
;         levels: level of data processing 
;         data_rates: instrument data rate
;         local_data_dir: local directory to store the CDF files
;         source: sets a different system variable. By default the MMS mission system variable 
;             is !mms
;         login_info: string containing name of a sav file containing a structure named "auth_info",
;             with "username" and "password" tags with your API login information
;         tplotnames: returns a list of the loaded tplot variables
;         get_support_data: when set this routine will load any support data
;             (support data is specified in the CDF file)
;         no_color_setup: don't setup graphics configuration; use this
;             keyword when you're using this load routine from a
;             terminal without an X server running
;         time_clip: clip the data to the requested time range; note that if you
;             do not use this keyword, you may load a longer time range than requested
;         no_update: use local data only, don't query the SDC for updated files. 
;         suffix: append a suffix to tplot variables names
;         varformat: should be a string (wildcards accepted) that will match the CDF variables
;             that should be loaded into tplot variables
;         cdf_filenames:  returns the names of the CDF files used when loading the data
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         latest_version: only grab the latest CDF version in the requested time interval
;             (e.g., /latest_version)
;         major_version: only open the latest major CDF version (e.g., X in vX.Y.Z) in the requested time interval
;         min_version:  specify a minimum CDF version # to load
;         cdf_records: specify the # of records to load from the CDF files; this is useful
;             for grabbing one record from a CDF file
;         spdf: grab the data from the SPDF instead of the LASP SDC (only works for public access)
;         available: returns a list of files available at the SDC for the requested parameters
;             this is useful for finding which files would be downloaded (along with their sizes) if 
;             you didn't specify this keyword (also outputs total download size)
;         versions: this keyword returns the version #s of the CDF files used when loading the data
;         always_prompt: set this keyword to always prompt for your username and password;
;             useful if you accidently save an incorrect password, or if your SDC password has changed
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in 
;             SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;         
;         
; EXAMPLE:
;     See the instrument specific crib sheets in the examples/ folder for usage examples
; 
; NOTES:
;     The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;
;     1) See the following regarding rules for the use of MMS data:
;         https://lasp.colorado.edu/mms/sdc/public/about/
;          
;     2) CDF version 3.6.3+ is required to correctly handle leap seconds.  
;         
;     3) The local paths will mirror the SDC/SPDF directory structures
;         
;     4) Warning about datatypes and paths:
;           -- many of the MMS instruments contain datatype details in their path names; for these CDFs
;           to be stored in the correct location locally (i.e., mirroring the SDC directory structure)
;           these datatypes must be passed to this routine by a higher level routine via the "datatype"
;           keyword. If the datatype keyword isn't passed, or datatype "*" is passed, the directory names
;           won't currently match the SDC. We can fix this by defining what "*" is for datatypes 
;           (by a list of all datatypes) in the instrument specific load routine, and passing those to this one.
;           
;               Example for HPCA: mms1/hpca/srvy/l1b/moments/2015/07/
;               
;               "moments" is the datatype. without passing datatype=["moments", ..], the data are stored locally in:
;                                 mms1/hpca/srvy/l1b/2015/07/
;               
;      5) For data availability:
;               https://lasp.colorado.edu/mms/sdc/
;             
;      6) Logging into the SDC: 
;           - If you have an internet connection, you'll be prompted for a username and password the 
;           first time you use the MMS plugin. There's an option in the widget that allows you 
;           to save your password in a save file on the local machine; if you select this option, 
;           the login prompt will never come up again and your saved password will be used to 
;           login to the SDC. This is insecure and should not be used if you use a common 
;           password with other services. 
;           
;           - Use an empty username and password for public access to the data
;
;           - If you don't have an internet connection or you can't login remotely, the plugin will 
;           look for the files on the local machine using a directory structure that matches 
;           the directory structure at the SDC.
;      
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-02-12 11:20:23 -0800 (Tue, 12 Feb 2019) $
;$LastChangedRevision: 26613 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_load_data.pro $
;-

pro mms_load_data, trange = trange, probes = probes, datatypes = datatypes_in, $
                  levels = levels, instrument = instrument, data_rates = data_rates, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, login_info = login_info, $
                  tplotnames = tplotnames, varformat = varformat, no_color_setup = no_color_setup, $
                  suffix = suffix, time_clip = time_clip, no_update = no_update, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, latest_version = latest_version, $
                  min_version = min_version, cdf_records = cdf_records, spdf = spdf, $
                  center_measurement = center_measurement, available = available, $
                  versions = versions, always_prompt = always_prompt, major_version=major_version, $
                  tt2000=tt2000

    ;temporary variables to track elapsed times
    t0 = systime(/sec)
    dt_query = 0d
    dt_download = 0d
    dt_load = 0d
    public = 0
   
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, no_color_setup = no_color_setup
    
    if undefined(source) then source = !mms

    if undefined(probes) then probes = ['1'] ; default to MMS 1
    probes = strcompress(string(probes), /rem) ; probes should be strings
    if undefined(levels) then levels = 'l2' else levels = strlowcase(levels)
    if undefined(instrument) then instrument = 'fgm' else instrument = strlowcase(instrument)
    if undefined(data_rates) then data_rates = 'srvy' else data_rates = strlowcase(data_rates)
    if ~undefined(datatypes_in) then datatypes_in = strlowcase(datatypes_in)

    ;ensure datatypes are explicitly set for simplicity 
    if undefined(datatypes_in) || in_set('*',datatypes_in) then begin
        mms_load_options, instrument, rate=data_rates, level=levels, datatype=datatypes
    endif else begin
        datatypes = datatypes_in
    endelse

    if undefined(local_data_dir) then local_data_dir = source.local_data_dir
    ; handle shortcut characters in the user's local data directory
    spawn, 'echo ' + local_data_dir, local_data_dir
    
    if is_array(local_data_dir) then local_data_dir = local_data_dir[0]

    ; varformat and get_support_data are conflicting; warn the user 
    ; if they're both set, and default to varformat
    if ~undefined(varformat) && ~undefined(get_support_data) then begin
        dprint, dlevel = 1, 'Conflicting keywords set (varformat and get_support_data). Using varformat'
        get_support_data = 0
    endif
    
    if ~undefined(center_measurement) then begin
        dprint, dlevel = 0, 'Centering the measurement to the middle of the measurement interval'
     ;   get_support_data = 1
     ;   undefine, varformat
    endif
        
    if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
      dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
      return
    endif
    
    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
      else tr = timerange()
    
    ;response_code = spd_check_internet_connection()
    response_code = 200

    ;combine these flags for now, if we're not downloading files then there is
    ;no reason to contact the server unless mms_get_local_files is unreliable
    no_download = source.no_download or source.no_server or (response_code ne 200) or ~undefined(no_update) or keyword_set(spdf)

    ; only prompt the user if they're going to download data
    if no_download eq 0 then begin
        status = mms_login_lasp(login_info = login_info, username=username, always_prompt=always_prompt)
        
        if status ne 1 then no_download = 1
        if username eq '' || username eq 'public' then public=1
    endif
    
    if undefined(username) then username = 'none'
    current_user = username eq '' || username eq 'public' ? 'public' : username

    ;clear so new names are not appended to existing array
    undefine, tplotnames
    ; clear CDF filenames, so we're not appending to an existing array
    undefine, cdf_filenames



    if keyword_set(spdf) then begin
        mms_load_data_spdf, probes = probes, datatype = datatypes, instrument = instrument, $
          trange = trange, source = source, level = level, tplotnames = tplotnames, $
          remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
          attitude_data = attitude_data, no_download = no_download, $
          no_server = no_server, data_rate = data_rates, get_support_data = get_support_data, $
          varformat = varformat, center_measurement=center_measurement, cdf_filenames = cdf_filenames, $
          cdf_records = cdf_records, min_version = min_version, cdf_version = cdf_version, $
          latest_version = latest_version, time_clip = time_clip, suffix = suffix, versions = versions
        return
    endif
        
    total_size = 0d ; for counting total download size when requesting /available

    ;loop over probe, rate, level, and datatype
    ;omitting some tabbing to keep format reasonable
    for probe_idx = 0, n_elements(probes)-1 do begin
    for rate_idx = 0, n_elements(data_rates)-1 do begin
    for level_idx = 0, n_elements(levels)-1 do begin
    for datatype_idx = 0, n_elements(datatypes)-1 do begin
        ;options for this iteration
        probe = 'mms' + strcompress(string(probes[probe_idx]), /rem)
        data_rate = data_rates[rate_idx]
        level = levels[level_idx]
        datatype = datatypes[datatype_idx]

        ;ensure no descriptor is used if instrument doesn't use datatypes
        if datatype eq '' then undefine, descriptor else descriptor = datatype

        day_string = time_string(tr[0], tformat='YYYY-MM-DD') 
        ; note, -1 second so we don't download the data for the next day accidently
        end_string = time_string(tr[1]-1., tformat='YYYY-MM-DD-hh-mm-ss')
        
        ;get file info from remote server
        ;if the server is contacted then a string array or empty string will be returned
        ;depending on whether files were found, if there is a connection error the 
        ;neturl response code is returned instead
        if ~keyword_set(no_download) then begin
            qt0 = systime(/sec) ;temporary
            data_file = mms_get_science_file_info(sc_id=probe, instrument_id=instrument, $
                    data_rate_mode=data_rate, data_level=level, start_date=day_string, $
                    end_date=end_string, descriptor=descriptor, public=public, cdf_version=cdf_version)
            dt_query += systime(/sec) - qt0 ;temporary
        endif

        ;if a list of remote files was retrieved then compare remote and local files
        if is_string(data_file) then begin
          
            remote_file_info = mms_parse_json(data_file)
            ; limit the CDF files to the requested time range
            remote_file_info = mms_files_in_interval(remote_file_info, tr)

            if ~is_struct(remote_file_info) then begin
                dprint, dlevel = 0, 'Error getting the information on remote files'
                return
            endif
            
            filename = remote_file_info.filename
            num_filenames = n_elements(filename)
            
            if keyword_set(available) then begin
              ; filter the files first
              unfiltered_files = remote_file_info.filename
              filtered_files = unh_mms_file_filter(unfiltered_files, min_version=min_version, version=cdf_version, latest_version=latest_version, major_version=major_version, /no_time)
              
              if ~is_array(filtered_files) && filtered_files eq '' then continue
              
              ; now loop through them, printing the filename and size
              for file_idx = 0, n_elements(filtered_files)-1 do begin
                filtered_file_loc = where(unfiltered_files eq filtered_files[file_idx])
                this_size = remote_file_info[filtered_file_loc].filesize

                print, filtered_files[file_idx], ' ', '('+strcompress(string(this_size/(1024.*1024), format='(F0.1)'), /rem) + ' MB'+')'
                total_size += this_size/(1024.*1024) ; in MB
              endfor
              continue
            endif
            
            for file_idx = 0, num_filenames-1 do begin
                ; For Survey and SITL products, the bottommost level are monthly directories,
                ; which are full of daily files. For Burst products, the bottommost level are daily
                ; directories
                dir_path = data_rate eq 'brst' ? '/YYYY/MM/DD' : '/YYYY/MM'

                ;daily_names = file_dailynames(file_format=dir_path, trange=tr, /unique, times=times)
                timetag = time_string(time_double(remote_file_info[file_idx].timetag), tformat ='YYYY-MM-DD')

                daily_names = file_dailynames(file_format=dir_path, /unique, trange=timetag)

                ; updated to match the path at SDC; this path includes data type for
                ; the following instruments: EDP, DSP, EPD-EIS, FEEPS, FIELDS, HPCA, SCM (as of 7/23/2015)
                sdc_path = instrument + '/' + data_rate + '/' + level
                sdc_path = datatype ne '' ? sdc_path + '/' + datatype + daily_names : sdc_path + daily_names
                file_dir = local_data_dir + strlowcase(probe + '/' + sdc_path)
                
                ; correct the path separator for this OS
                if strlowcase(!version.os_family) eq 'windows' then file_dir = strjoin(strsplit(file_dir, '/', /extract), path_sep())
                
                same_file = mms_check_file_exists(remote_file_info[file_idx], file_dir = file_dir)

                if same_file eq 0 then begin
                    td0 = systime(/sec) ;temporary
                    dprint, dlevel = 1, 'Downloading ' + filename[file_idx] + ' to ' + file_dir
                    status = get_mms_science_file(filename=filename[file_idx], local_dir=file_dir, public=public)

                    dt_download += systime(/sec) - td0 ;temporary
                    if status eq 0 then append_array, files, file_dir + path_sep() + filename[file_idx]
                endif else begin
                    dprint, dlevel = 1, 'Loading local file ' + file_dir + path_sep() + filename[file_idx]
                    append_array, files, file_dir + path_sep() + filename[file_idx]
                endelse
            endfor
        
        ;if no remote list was retrieved then search locally   
        endif else begin
            ; get all files from the beginning of the first day
            local_files = mms_get_local_files(probe=probe, instrument=instrument, $
                    data_rate=data_rate, level=level, datatype=datatype, $
                    trange=time_double([day_string, end_string]), cdf_version=cdf_version, $
                    min_version=min_version, latest_version=latest_version, major_version=major_version)

            if is_string(local_files) then begin
                ; prepare the file list as a list of structs, (required input to mms_files_in_interval)
                local_file_info = replicate({filename: '', timetag: ''}, n_elements(local_files))
                for local_file_idx = 0, n_elements(local_files)-1 do begin
                    local_file_info[local_file_idx].filename = local_files[local_file_idx]
                endfor

                ; filter to the requested time range
                local_files_filtered = mms_files_in_interval(local_file_info, tr)
                local_files = local_files_filtered.filename
                append_array, files, local_files
            endif else begin
                ; check the network mirror site
                str_element, !mms, 'mirror_data_dir', success=mirror_available
                if mirror_available && !mms.mirror_data_dir ne '' then begin
                  mirror_files = mms_get_local_files(probe=probe, instrument=instrument, $
                    data_rate=data_rate, level=level, datatype=datatype, $
                    trange=time_double([day_string, end_string]), cdf_version=cdf_version, $
                    min_version=min_version, latest_version=latest_version, major_version=major_version, /mirror)

                  if is_string(mirror_files) then begin
                    ; prepare the file list as a list of structs, (required input to mms_files_in_interval)
                    local_file_info = replicate({filename: '', timetag: ''}, n_elements(mirror_files))
                    for local_file_idx = 0, n_elements(mirror_files)-1 do begin
                      local_file_info[local_file_idx].filename = mirror_files[local_file_idx]
                    endfor
  
                    ; filter to the requested time range
                    local_files_filtered = mms_files_in_interval(local_file_info, tr)
                    mirror_files = local_files_filtered.filename
                    append_array, files, mirror_files
                  endif else begin
                    dprint, dlevel = 0, 'Error, no local, remote or mirror data files found: '+$
                      probe+' '+instrument+' '+data_rate+' '+level+' '+datatype+' (user: '+current_user+')'
                    continue
                  endelse
                endif else begin
                  dprint, dlevel = 0, 'Error, no local or remote data files found: '+$
                           probe+' '+instrument+' '+data_rate+' '+level+' '+datatype+' (user: '+current_user+')'
                  continue
                endelse
            endelse
        endelse       

        ; if files is undefined, no data were loaded
        if undefined(files) then continue
        
        ; sort the data files in time (this is required by
        ; HPCA (at least) due to multiple files per day
        ; the intention is to order in time before passing
        ; to cdf2tplot
        files = files[bsort(files)]

        if ~undefined(files) then begin
            lt0 = systime(/sec) ;temporary
            spd_cdf2tplot, files, tplotnames = loaded_tnames, varformat=varformat, $
                suffix = suffix, get_support_data = get_support_data, /load_labels, $
                min_version=min_version,version=cdf_version,latest_version=latest_version, $
                number_records=cdf_records, center_measurement=center_measurement, $
                loaded_versions = the_loaded_versions, major_version=major_version, $
                tt2000=tt2000
            dt_load += systime(/sec) - lt0 ;temporary
        endif

        append_array, cdf_filenames, files
        if ~undefined(loaded_tnames) then append_array, tplotnames, loaded_tnames
        if ~undefined(the_loaded_versions) then append_array, versions, the_loaded_versions
        
        ; forget about the daily files for this probe
        undefine, files
        undefine, loaded_tnames
        undefine, the_loaded_versions

    ;end loops over probe, rate, level, and datatype
    endfor
    endfor
    endfor
    endfor

    ; print the total size of requested data if the user specified /available
    if keyword_set(available) then print, 'Total download size: ' + strcompress(string(total_size, format='(F0.1)'), /rem) + ' MB'

    ; just in case multiple datatypes loaded identical variables
    ; (this occurs with hpca moments & logicals)
    if ~undefined(tplotnames) then tplotnames = spd_uniq(tplotnames)

    if n_elements(tplotnames) eq 1 && tplotnames[0] eq '' then return ; no data loaded

    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        dt_timeclip = 0.0
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') and ~undefined(time_clip) then begin
            tc0 = systime(/sec)
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
            dt_timeclip = systime(/sec)-tc0
        endif
        ;temporary messages for diagnostic purposes
        dprint, dlevel=2, 'Successfully loaded: '+ $
            strjoin( ['mms'+probes, instrument, data_rates, levels, datatypes, time_string(tr)],' ')
        dprint, dlevel=2, 'Time querying remote server: '+strtrim(dt_query,2)+' sec'
        dprint, dlevel=2, 'Time downloading remote files: '+strtrim(dt_download,2)+' sec'
        dprint, dlevel=2, 'Time loading files into IDL: '+strtrim(dt_load,2)+' sec'
        dprint, dlevel=2, 'Time spent time clipping variables: '+strtrim(dt_timeclip,2)+' sec'
        dprint, dlevel=2, 'Total load time: '+strtrim(systime(/sec)-t0,2)+' sec'

    endif
end