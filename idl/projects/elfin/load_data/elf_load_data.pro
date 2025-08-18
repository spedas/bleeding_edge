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
;         no_time_clip: don't clip the data to the requested time range; note that if you do use 
;                       this keyword you may load a longer time range than requested. 
;         no_update:    (NOT YET IMPLEMENTED) set this flag to preserve the original data. if not set and newer 
;                       data is found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         cdf_records: specify the # of records to load from the CDF files; this is useful
;             for grabbing one record from a CDF file
;         spdf:         grab the data from the SPDF instead of ELFIN server - ***NOTE: only state and epdef data are 
;                       at SPDF available
;         available:    (NOT YET IMPLEMENTED) returns a list of files available at the SDC for the requested parameters
;                       this is useful for finding which files would be downloaded (along with their sizes) if
;                       you didn't specify this keyword (also outputs total download size)
;         versions:     this keyword returns the version #s of the CDF files used when loading the data
;         no_time_sort:    set this flag to not order by time and remove duplicates
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;         pred: set this flag for 'predicted' state data. default state data is 'definitive'. 
;         public_data: set this flag to retrieve data from the public area (default is private dir) 
;;          
;EXAMPLE:
;   elf_load_data,probe='a'
; 
;NOTES:
;   Since there is no data server - yet - files must reside locally.
;   Current file naming convention is el[a/b]_ll_instr_yyyymmdd_v0*.cdf.
;   Temporary fix for state CDF - state CDFs are the only CDFs that have version v02
;     
;--------------------------------------------------------------------------------------
PRO elf_load_data, trange = trange, probes = probes, datatypes_in = datatypes_in, $
  levels = levels, instrument = instrument, data_rates = data_rates, spdf = spdf, $
  local_data_dir = local_data_dir, source = source, pred = pred, versions = versions, $
  get_support_data = get_support_data, login_info = login_info, no_time_sort=no_time_sort, $
  tplotnames = tplotnames, varformat = varformat, no_color_setup = no_color_setup, $
  suffix = suffix, no_time_clip = no_time_clip, no_update = no_update, no_download=no_download, $
  cdf_filenames = cdf_filenames, cdf_version = cdf_version, cdf_records = cdf_records, $
  available = available, tt2000 = tt2000, public_data=public_data 

  ;temporary variables to track elapsed times
  t0 = systime(/sec)
  dt_query = 0d
  dt_download = 0d
  dt_load = 0d
  public = 0

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, no_color_setup = no_color_setup
 
  if undefined(source) then source = !elf

  if undefined(probes) then probes = ['a','b'] else probes = strlowcase(probes) ; default to ELFIN A
  if probes[0] eq '*' then probes = ['a','b']
  probes = strcompress(string(probes), /rem) ; probes should be strings
  
  if undefined(instrument) then instrument = 'fgm' else instrument = strlowcase(instrument)
  if undefined(levels) then begin
    if instrument EQ 'state' then levels = 'l1' else levels = 'l2'
  endif
  levels = strlowcase(levels)  
  if undefined(data_rates) then data_rates = 'srvy' else data_rates = strlowcase(data_rates)
  if (instrument NE 'epd' OR instrument NE 'fgm') then data_rates = ''
  if undefined(datatypes_in) then datatypes_in = '' else datatypes_in = strlowcase(datatypes_in)
  if undefined(pred) then pred = 0 else pred = 1
  
  ;ensure datatypes are explicitly set for simplicity
  if undefined(datatypes_in) || in_set('*',datatypes_in) then begin
    elf_load_options, instrument, rate=data_rates, level=levels, datatype=datatypes
  endif else begin
    datatypes = datatypes_in
  endelse

  if is_string(datatypes) && ~is_array(datatypes) then datatypes = strsplit(datatypes, ' ', /extract)

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

  if keyword_set(no_download) then no_download=1 else $
     no_download = source.no_download or source.no_server or (response_code ne 200) or ~undefined(no_update) or keyword_set(spdf)

  ;clear so new names are not appended to existing array
  undefine, tplotnames
  ; clear CDF filenames, so we're not appending to an existing array
  undefine, cdf_filenames

  total_size = 0d ; for counting total download size when requesting /available

  ;loop over probe, rate, level
  ;omitting some tabbing to keep format reasonable
  for probe_idx = 0, n_elements(probes)-1 do begin
    for rate_idx = 0, n_elements(data_rates)-1 do begin
      for level_idx = 0, n_elements(levels)-1 do begin
         for datatypes_idx = 0, n_elements(datatypes)-1 do begin

          ;options for this iteration
          probe = 'el' + strcompress(string(probes[probe_idx]), /rem)
          data_rate = data_rates[rate_idx]
          level = levels[level_idx]
          datatype = datatypes[datatypes_idx]

          ;ensure no descriptor is used if instrument doesn't use datatypes
          if datatype eq '' then undefine, descriptor else descriptor = datatype

          ; construct file names
          daily_names = file_dailynames(trange=tr, /unique, times=times)
          fnames=make_array(n_elements(daily_names), /string)
          
          Case instrument of
            'epd': begin
                idx = where(datatype EQ 'pif', ncnt)
                if ncnt GT 0 then append_array, ftypes, 'epdif'  
                idx = where(datatype EQ 'pis', ncnt)
                if ncnt GT 0 then append_array, ftypes, 'epdis'
                idx = where(datatype EQ 'pef', ncnt)
                if ncnt GT 0 then append_array, ftypes, 'epdef'
                idx = where(datatype EQ 'pes', ncnt)
                if ncnt GT 0 then append_array, ftypes, 'epdes'
            end
            'fgm': begin
              idx = where(datatype EQ 'fgs', ncnt)
              if ncnt GT 0 then append_array, ftypes, 'fgs'
              idx = where(datatype EQ 'fgf', ncnt)
              if ncnt GT 0 then append_array, ftypes, 'fgf'
            end
            'state': if pred then ftypes='state_pred' else ftypes='state_defn'
            'mrma': ftypes='mrma'
            'mrmi': ftypes='mrmi'
            'eng': ftypes='eng'
          endcase
          for dn=0, n_elements(daily_names)-1 do fnames[dn] = probe + '_' + level + '_' + ftypes + '_' + daily_names[dn] + '_v01.cdf'
            
          ;clear so new names are not appended to existing array
          undefine, tplotnames
          ; clear CDF filenames so we're not appending to an existing array
          undefine, cdf_filenames

          ; set up the path names
          ;if instrument EQ state then handle predicted vs definitive data directories
          subdir = ''
          if instrument EQ 'state' then begin
            if pred then subdir='pred/' else subdir='defn/'  
            ; **** Temporary fix for new state CDF with v02         
            if subdir EQ 'defn/' then for dn=0, n_elements(daily_names)-1 do fnames[dn] = probe + '_' + level + '_' + ftypes + '_' + daily_names[dn] + '_' + cdf_version +'.cdf'
          endif
          if instrument EQ 'epd' then begin
             Case datatype of 
               'pes': subdir='survey/electron/'
               'pis': subdir='survey/ion/'
               'pef': subdir='fast/electron/'
               'pif': subdir='fast/ion/'
             Endcase
          endif
          if instrument EQ 'fgm' then begin
            if datatype EQ 'fgs' then subdir = 'survey/' else subdir = 'fast/'
          endif
;          subdir = subdir + year_string[0] + '/'   ; moved below
          
          remote_path = remote_data_dir + strlowcase(probe) + '/' + level + '/' + instrument + '/' + subdir
          
          if keyword_set(public_data) then begin
            slen=strlen(remote_data_dir)
            this_remote=strmid(remote_data_dir,0,slen-6)
            remote_path = this_remote + strlowcase(probe) + '/' + level + '/' + instrument + '/' + subdir
          endif
          local_path = filepath('', ROOT_DIR=!elf.local_data_dir, $
            SUBDIRECTORY=[probe, level, instrument]) + subdir 

          if strlowcase(!version.os_family) eq 'windows' then local_path = strjoin(strsplit(local_path, '/', /extract), path_sep())

          for file_idx = 0, n_elements(fnames)-1 do begin 
           
              yeardir=strmid(daily_names[file_idx],0,4) + '/'
              this_local_path=local_path +  '/' + yeardir
              this_local_path = spd_addslash(this_local_path)
              this_remote_path=remote_path + yeardir
              paths = ''           
              ; download data as long as no flags are set or if spdf is set
              if ~undefined(spdf) && spdf EQ 1 then no_download=0
            
              if no_download eq 0 then begin
           
                if file_test(this_local_path,/dir) eq 0 then file_mkdir2, this_local_path
                dprint, dlevel=1, 'Downloading ' + fnames[file_idx] + ' to ' + local_path                    
                if ~undefined(spdf) && spdf EQ 1 then begin
                  spdf_datatypes=['state', 'epd']
                  if instrument EQ 'state' or instrument EQ 'epd' then begin
                    remote_path = 'https://spdf.gsfc.nasa.gov/pub/data/elfin/elfin'+probes[probe_idx]+'/'
                    if instrument eq 'state' then begin
                      remote_path=remote_path+'ephemeris/'
                      if pred then subdir='pred/'+strmid(daily_names, 0, 4)+'/' else subdir='defn/'+strmid(daily_names, 0, 4)+'/'
                      subdir=''
                    endif
                    if instrument EQ 'epd' then begin
                      if datatype eq 'pef' then subdir='l1/fast/electron/'+strmid(daily_names, 0, 4)+'/'
                      if datatype eq 'pif' then subdir='l1/fast/ion/'+strmid(daily_names, 0, 4)+'/'
                    endif                 
;                    relpath= 'elfin' + strcompress(string(probes[probe_idx]), /rem) +'/'+'ephemeris/'+subdir + '/' + yeardir
                    remote_path=remote_path+subdir
;                    relpathname=relpath + fnames[file_idx]

                    paths = spd_download(remote_file=fnames[file_idx], remote_path=remote_path[0], $
                      local_file=fnames[file_idx], local_path=this_local_path, ssl_verify_peer=0, ssl_verify_host=0)
                  endif  else begin
                      dprint, 'SPDF does not have data for instrument ' + instrument
                  endelse
                endif else begin
                  paths = spd_download(remote_file=fnames[file_idx], remote_path=this_remote_path, $
                                     local_file=fnames[file_idx], local_path=this_local_path, $
                                     ssl_verify_peer=0, ssl_verify_host=0)
                                     ;url_username=user, url_password=pw, ssl_verify_peer=1, $
                                     ;ssl_verify_host=1)    
                endelse
                if undefined(paths) or paths EQ '' then $
                   dprint, 'Unable to download ' + fnames[file_idx] else $
                   append_array, files, this_local_path+fnames[file_idx]
              endif              
              
              ; if remote file not found or no_download set then look for local copy
              if paths EQ '' OR no_download NE 0 then begin                
                ; get all files from the beginning of the first day
                day_string=strmid(daily_names[file_idx],0,4)+'-'+strmid(daily_names[file_idx],4,2)+'-'+strmid(daily_names[file_idx],6,2)
                end_string=time_string(time_double(day_string)+86399.)
                local_files = elf_get_local_files(probe=probe, instrument=instrument, $
                  data_rate=data_rate, datatype=datatype, level=level, $
                  trange=time_double([day_string, end_string]), cdf_version=cdf_version, $
                  min_version=min_version, latest_version=latest_version, pred=pred)
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

          endfor

          if ~undefined(files) then begin
            unique_files = files[uniq(files, sort(files))]
            if ~undefined(cdf_version) then begin 
               if n_elements(unique_files) GT 1 then begin
                 sidx = strpos(unique_files, cdf_version)
                 fidx = where(sidx NE -1, ncnt)
                 if ncnt GT 0 then unique_files = unique_files[fidx]
                 endif
            endif
            if instrument eq 'epd' and level eq 'l2' then begin
              elf_cdf2tplot, unique_files, tplotnames = loaded_tnames, varformat=varformat, $
                suffix = suffix, get_support_data = get_support_data, /load_labels, $
                min_version=min_version,version=cdf_version,latest_version=latest_version, $
                number_records=cdf_records, center_measurement=center_measurement, $
                loaded_versions = the_loaded_versions, major_version=major_version, $
                tt2000=tt2000, instrument=instrument, level=level
            endif else begin
              spd_cdf2tplot, unique_files, tplotnames = loaded_tnames, varformat=varformat, $
                suffix = suffix, get_support_data = get_support_data, /load_labels, $
                min_version=min_version,version=cdf_version,latest_version=latest_version, $
                number_records=cdf_records, center_measurement=center_measurement, $
                loaded_versions = the_loaded_versions, major_version=major_version, $
                tt2000=tt2000
            endelse            
          endif
                  
          append_array, cdf_filenames, files
          if ~undefined(loaded_tnames) then append_array, all_tnames, loaded_tnames
          if ~undefined(the_loaded_versions) then append_array, versions, the_loaded_versions

          ; forget about the daily files for this probe
          undefine, files
          undefine, loaded_tnames
          undefine, the_loaded_versions
          undefine, ftypes
         
          ; don't go loop through data type for state, mrmi, mrma, or eng
          if instrument EQ 'state' then break
          if instrument EQ 'mrmi' then break
          if instrument EQ 'mrma' then break
          if instrument EQ 'eng' then break
        endfor
      endfor
    endfor
  endfor
  
  ; print the total size of requested data if the user specified /available
  if keyword_set(available) then print, 'Total download size: ' + strcompress(string(total_size, format='(F0.1)'), /rem) + ' MB'
  if undefined(all_tnames) then return else tplotnames=all_tnames

  ; just in case multiple datatypes loaded identical variables
  ; (this occurs with hpca moments & logicals)
  if ~undefined(tplotnames) then tplotnames = spd_uniq(tplotnames)

  ; check that data was loaded
  ntvars = n_elements(tplotnames)
  if ntvars eq 1 && tplotnames[0] eq '' then return ; no data loaded
  ; remove any blank strings
  if ntvars GT 1 && tplotnames[0] eq '' then tplotnames=tplotnames[1:ntvars-1]   
  if ~undefined(tr) && ~undefined(tplotnames) then begin
    ; time clip the data
    dt_timeclip = 0.0
    error = 0
    if (n_elements(tr) eq 2) and (tplotnames[0] ne '') and ~keyword_set(no_time_clip) then begin
     tc0 = systime(/sec)
      ;;if instrument EQ 'state' && pred then begin
      ;;  idx=where(strpos(tplotnames, 'att') GE 0 OR strpos(tplotnames, 'spin') GE 0, ncnt)
      ;;  if ncnt GT 0 then del_data, tplotnames[idx]
      ;;  idx=where(strpos(tplotnames, 'vel') GE 0 OR strpos(tplotnames, 'pos') GE 0, ncnt)
      ;;  if ncnt GT 0 then tplotnames=tplotnames[idx]
      ;;  dprint, dlevel=1,'Attitude or spin tplot variables are not valid for predicted state data.'
      ;;endif 
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
    
    ; sort times and remove duplicates
    if ~keyword_set(no_time_sort) && ~undefined(tplotnames) then begin
      for t=0,n_elements(tplotnames)-1 do begin
        tplot_sort, tplotnames[t]
        get_data, tplotnames[t], data=d, dlimits=dl, limits=l
        if size(d, /type) EQ 8 then begin
          idx=uniq(d.x,sort(d.x))
          ydim = n_elements(size(d.y, /dimensions))
          if ydim LT 3 then store_data, tplotnames[t], data={x:d.x[idx], y:d.y[idx,*]}, dlimits=dl, limits=l
          if ydim EQ 3 then begin
            dpos=strpos(tplotnames[t], 'pef_hs_Epat')
            if dpos GE 0 then begin
              thistn=tnames('*pef_hs_epa_spec')
              get_data, thistn[0], data=dv
            endif else begin
              thistn=tnames('*pef_fs_epa_spec')
              get_data, thistn[0], data=dv              
            endelse
            store_data, tplotnames[t], data={x:d.x[idx], y:d.y[idx,*,*], v:dv.y[idx,*]}, dlimits=dl, limits=l
          endif
        endif
      endfor
    endif
    
  endif

  ;temporary messages for diagnostic purposes
  dprint, dlevel=2, 'Successfully loaded: '+ $
    strjoin( ['el'+probes, instrument, data_rates, levels, datatypes, time_string(tr)],' ')
  dprint, dlevel=2, 'Time querying remote server: '+strtrim(dt_query,2)+' sec'
  dprint, dlevel=2, 'Time downloading remote files: '+strtrim(dt_download,2)+' sec'
  dprint, dlevel=2, 'Time loading files into IDL: '+strtrim(dt_load,2)+' sec'
  dprint, dlevel=2, 'Time spent time clipping variables: '+strtrim(dt_timeclip,2)+' sec'
  dprint, dlevel=2, 'Total load time: '+strtrim(systime(/sec)-t0,2)+' sec'
 
END
