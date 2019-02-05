;+
;NAME: 
;  elf_load_data
;          This routine loads local ELFIN data. 
;          There is no server available yet so all files must
;           be local. The default value is currently set to
;          'C:/data/elfin/el[ab]/l[0,1,2]/instrument/yyyy/mm/dd/*.cdf'
;          If you do not want to place your cdf files there you 
;          must change the elfin system variable !elf.local_data_dir = 'yourdirectorypath'
;KEYWORDS (commonly used by other load routines):
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for ELFIN probes are ['a','b'].
;                       if no probe is specified the default is probe 'a'
;         level:        indicates level of data processing. levels include 'l1' and 'l2'
;                       The default if no level is specified is 'l1' (l1 default needs to be confirmed)
;         datatype:     depends on the instrument, see header for the instruments load routine
;         data_rate:    instrument data rates 
;         tplotnames:   returns a list of the names of the tplot variables loaded by the load routine
;         get_support_data: load support data (defined by VAR_TYPE="support_data" in the CDF)
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load routine from a terminal without an X server running
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer 
;                       data is found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         latest_version: only grab the latest CDF version in the requested time interval
;                       (e.g., /latest_version)
;         major_version: only open the latest major CDF version (e.g., X in vX.Y.Z) in the requested time interval
;         min_version:  specify a minimum CDF version # to load
;         cdf_records: specify the # of records to load from the CDF files; this is useful
;             for grabbing one record from a CDF file
;         spdf:         grab the data from the SPDF instead of the LASP SDC (only works for public data)
;         available:    returns a list of files available at the SDC for the requested parameters
;                       this is useful for finding which files would be downloaded (along with their sizes) if
;                       you didn't specify this keyword (also outputs total download size)
;         versions:     this keyword returns the version #s of the CDF files used when loading the data
;         always_prompt: set this keyword to always prompt for the user's username and password;
;                       useful if you accidently save an incorrect password, or if your SDC password has changed
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;         pred: set this flag for 'predicted' state data. default state data is 'definitive'.  
;;          
;EXAMPLE:
;   elf_load_data,probe='a'
; 
;NOTES:
;   Since there is no data server - yet - files must reside locally.
;   Current file naming convention is el[a/b]_ll_instr_yyyymmdd_v01.cdf.
;     
;--------------------------------------------------------------------------------------
PRO elf_load_data, trange = trange, probes = probes, datatypes = datatypes_in, $
  levels = levels, instrument = instrument, data_rates = data_rates, $
  local_data_dir = local_data_dir, source = source, pred = pred, $
  get_support_data = get_support_data, login_info = login_info, $
  tplotnames = tplotnames, varformat = varformat, no_color_setup = no_color_setup, $
  suffix = suffix, time_clip = time_clip, no_update = no_update, $
  cdf_filenames = cdf_filenames, cdf_version = cdf_version, latest_version = latest_version, $
  min_version = min_version, cdf_records = cdf_records, spdf = spdf, major_version=major_version, $
  available = available, versions = versions, always_prompt = always_prompt, tt2000=tt2000

  ;temporary variables to track elapsed times
  t0 = systime(/sec)
  dt_query = 0d
  dt_download = 0d
  dt_load = 0d
  public = 0

  elf_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, no_color_setup = no_color_setup

  if undefined(source) then source = !elf

  if undefined(probes) then probes = ['a'] else probes = strlowcase(probes) ; default to ELFIN A
  probes = strcompress(string(probes), /rem) ; probes should be strings
  if undefined(instrument) then instrument = 'fgm' else instrument = strlowcase(instrument)
  if undefined(levels) then begin
    if instrument EQ 'state' then levels = 'l1' else levels = 'l2'
  endif
  levels = strlowcase(levels)  
  if undefined(data_rates) then data_rates = 'srvy' else data_rates = strlowcase(data_rates)
  if undefined(datatypes_in) then datatypes_in = strlowcase(datatypes_in)
  if undefined(pred) then pred = 0 else pred = 1
  
  ;ensure datatypes are explicitly set for simplicity
  if undefined(datatypes_in) || in_set('*',datatypes_in) then begin
    elf_load_options, instrument, rate=data_rates, level=levels, datatype=datatypes
  endif else begin
    datatypes = datatypes_in
  endelse

  if undefined(remote_data_dir) then remote_data_dir = source.remote_data_dir
 
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

  ;clear so new names are not appended to existing array
  undefine, tplotnames
  ; clear CDF filenames, so we're not appending to an existing array
  undefine, cdf_filenames

  if keyword_set(spdf) then begin
    ;elf_load_data_spdf, probes = probes, datatype = datatypes, instrument = instrument, $
    ;  trange = trange, source = source, level = level, tplotnames = tplotnames, $
    ;  remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
    ;  attitude_data = attitude_data, no_download = no_download, $
    ;  no_server = no_server, data_rate = data_rates, get_support_data = get_support_data, $
    ;  varformat = varformat, center_measurement=center_measurement, cdf_filenames = cdf_filenames, $
    ;  cdf_records = cdf_records, min_version = min_version, cdf_version = cdf_version, $
    ;  latest_version = latest_version, time_clip = time_clip, suffix = suffix, versions = versions
    ;return
    dprint, dlevel=1, 'ELFIN data is not yet avaialabe from the SPDF'
  endif

  total_size = 0d ; for counting total download size when requesting /available

  ;loop over probe, rate, level, and datatype
  ;omitting some tabbing to keep format reasonable
  for probe_idx = 0, n_elements(probes)-1 do begin
    for rate_idx = 0, n_elements(data_rates)-1 do begin
      for level_idx = 0, n_elements(levels)-1 do begin
        for datatype_idx = 0, n_elements(datatypes)-1 do begin
          ;options for this iteration
          probe = 'el' + strcompress(string(probes[probe_idx]), /rem)
          data_rate = data_rates[rate_idx]
          level = levels[level_idx]
          datatype = datatypes[datatype_idx]

          ;ensure no descriptor is used if instrument doesn't use datatypes
          if datatype eq '' then undefine, descriptor else descriptor = datatype

          day_string = time_string(tr[0], tformat='YYYYMMDD')
          ; note, -1 second so we don't download the data for the next day accidently
          end_string = time_string(tr[1], tformat='YYYYMMDD')          

          ; construct file names
          daily_names = file_dailynames(trange=tr, /unique, times=times)
          if instrument EQ 'fgm' && level EQ 'l1' then $
             fnames = probe + '_' + level + '_' + datatype + '_' + daily_names + '_v01.cdf' else $           
             fnames = probe + '_' + level + '_' + instrument + '_' + daily_names + '_v01.cdf' 
          
          ;clear so new names are not appended to existing array
          undefine, tplotnames
          ; clear CDF filenames, so we're not appending to an existing array
          undefine, cdf_filenames

          ; set up the path names
          ;if instrument EQ state then handle predicted vs definitive data directories
          state_subdir = ''
          if instrument EQ 'state' then begin
            if pred then state_subdir='pred/' else state_subdir='defn/'           
          endif

          remote_path = remote_data_dir + strlowcase(probe) + '/' + level + '/' + instrument + '/' + state_subdir

          local_path = filepath('', ROOT_DIR=!elf.local_data_dir, $
            SUBDIRECTORY=[probe, level, instrument]) + state_subdir
; NOTE: temporarily commented these lines out since it doesn't work for windows ftp
;          if strlowcase(!version.os_family) eq 'windows' then remote_path = strjoin(strsplit(remote_path, '/', /extract), path_sep())
          if strlowcase(!version.os_family) eq 'windows' then local_path = strjoin(strsplit(local_path, '/', /extract), path_sep())

          for file_idx = 0, n_elements(fnames)-1 do begin 
              ; download data as long as no flags are set
              if no_download eq 0 then begin
                if file_test(local_path,/dir) eq 0 then file_mkdir2, local_path
                dprint, dlevel=1, 'Downloading ' + fnames[file_idx] + ' to ' + local_path   
                paths = '' 

                ; NOTE: directory is temporarily password protected. this will be
                ;       removed when data is made public.
                print, 'Please enter your ELFIN user name and password' 
                read,user,prompt='User Name: '
                read,pw,prompt='Password: '
                 
                paths = spd_download(remote_file=fnames[file_idx], remote_path=remote_path, $
                                     local_file=fnames[file_idx], local_path=local_path, $
                                     url_username=user, url_password=pw, ssl_verify_peer=1, $
                                     ssl_verify_host=1)
                if undefined(paths) or paths EQ '' then $
                   dprint, devel=1, 'Unable to download ' + fnames[file_idx] else $
                   append_array, files, local_path+fnames[file_idx]

              endif 
              
              ; if remote file not found or no_download set then look for local copy
              if paths EQ '' OR no_download NE 0 then begin                
                ; get all files from the beginning of the first day
                local_files = elf_get_local_files(probe=probe, instrument=instrument, $
                  data_rate=data_rate, datatype=datatype, level=level, $
                  trange=time_double([day_string, end_string]), cdf_version=cdf_version, $
                  min_version=min_version, latest_version=latest_version)

                if is_string(local_files) then begin
                  ; prepare the file list as a list of structs, (required input to mms_files_in_interval)
                  local_file_info = replicate({filename: '', timetag: ''}, n_elements(local_files))
                  for local_file_idx = 0, n_elements(local_files)-1 do begin
                    local_file_info[local_file_idx].filename = local_files[local_file_idx]
                  endfor
                  ; filter to the requested time range
                  local_files_filtered = elf_files_in_interval(local_file_info, tr)
                  local_files = local_files_filtered.filename
                  append_array, files, local_files
                endif                 
              endif      

              if ~undefined(files) then begin
                spd_cdf2tplot, files, tplotnames = loaded_tnames, varformat=varformat, $
                  suffix = suffix, get_support_data = get_support_data, /load_labels, $
                  min_version=min_version,version=cdf_version,latest_version=latest_version, $
                  number_records=cdf_records, center_measurement=center_measurement, $
                  loaded_versions = the_loaded_versions, major_version=major_version, $
                  tt2000=tt2000
              endif
              
              append_array, cdf_filenames, files
              if ~undefined(loaded_tnames) then append_array, tplotnames, loaded_tnames
              if ~undefined(the_loaded_versions) then append_array, versions, the_loaded_versions

              ; forget about the daily files for this probe
              undefine, files
              undefine, loaded_tnames
              undefine, the_loaded_versions

          endfor
          
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
      strjoin( ['el'+probes, instrument, data_rates, levels, datatypes, time_string(tr)],' ')
    dprint, dlevel=2, 'Time querying remote server: '+strtrim(dt_query,2)+' sec'
    dprint, dlevel=2, 'Time downloading remote files: '+strtrim(dt_download,2)+' sec'
    dprint, dlevel=2, 'Time loading files into IDL: '+strtrim(dt_load,2)+' sec'
    dprint, dlevel=2, 'Time spent time clipping variables: '+strtrim(dt_timeclip,2)+' sec'
    dprint, dlevel=2, 'Total load time: '+strtrim(systime(/sec)-t0,2)+' sec'

  endif

END
