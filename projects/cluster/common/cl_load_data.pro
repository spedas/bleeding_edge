;+
; PROCEDURE:
;         cl_load_data
;         
; PURPOSE:
;         Load Cluster data from NASA/SPDF
;         
;         This routine is not meant to be called directly - please use 
;         the instrument specific wrappers: cl_load_xxx 
; 
; KEYWORDS:
;         See the instrument load routines.
;         
; EXAMPLE:
;    cl_load_fgm, probe=1, level='l2', trange=['2016-01-10', '2016-01-11']
; 
; NOTES:
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-08-06 11:40:23 -0700 (Thu, 06 Aug 2020) $
;$LastChangedRevision: 29003 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/common/cl_load_data.pro $
;-

pro cl_load_data, probes = probes, datatype = datatype, instrument = instrument, $
                   trange = trange, source = source, $
                   remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
                   no_download = no_download, $
                   no_server = no_server, tplotnames = tplotnames, $
                   get_support_data = get_support_data, varformat = varformat, $
                   cdf_filenames = cdf_filenames, $
                   cdf_records = cdf_records, min_version = min_version, $
                   cdf_version = cdf_version, latest_version = latest_version, $
                   time_clip = time_clip, suffix = suffix, versions = versions

    if not keyword_set(datatype) then datatype = 'up'
    if not keyword_set(instrument) then instrument = 'fgm'
    if not keyword_set(probes) then probes = ['1']
    
    ; make sure important strings are lower case
    instrument = strlowcase(instrument)
    
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    cl_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    
    if not keyword_set(remote_data_dir) then remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/cluster/'
    if not keyword_set(local_data_dir) then local_data_dir = !cluster.local_data_dir
    
    pathformat = strarr(n_elements(probes)*n_elements(datatype))
    path_count = 0 
    
    probes = strcompress(string(probes), /rem) ; probes should be strings
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        time_format = 'YYYYMMDD'
        prb = probes[probe_idx]
        case strlowcase(instrument) of
            'fgm': begin
                ; note: datatype=='cp' has _spin_ in the file names
                if datatype eq 'cp' then begin
                  pathformat[path_count] = 'c' + prb + '/cp/YYYY/c' + prb + $
                    '_cp_'+instrument+'_spin_'+time_format+'_v??.cdf'
                endif else begin
                  pathformat[path_count] = 'c' + prb + '/' +  datatype + '/'+instrument+'/YYYY/c' + prb + $
                    '_' +datatype+'_'+instrument+'_'+time_format+'_v??.cdf'
                endelse
                path_count += 1
              end
             'aspoc': begin
                pathformat[path_count] = 'c' + prb + '/' +  datatype + '/asp/YYYY/c' + prb + $
                    '_' +datatype+'_asp_'+time_format+'_v??.cdf'
                path_count += 1
              end
             'edi': begin
                pathformat[path_count] = 'c' + prb + '/' +  datatype + '/'+instrument+'/YYYY/c' + prb + $
                    '_' +datatype+'_'+instrument+'_'+time_format+'_v??.cdf'
                path_count += 1
              end
             'cis': begin
               pathformat[path_count] = 'c' + prb + '/' +  datatype + '/'+instrument+'/YYYY/c' + prb + $
                 '_' +datatype+'_'+instrument+'_'+time_format+'_v??.cdf'
               path_count += 1
              end
             'dwp': begin
               pathformat[path_count] = 'c' + prb + '/' +  datatype + '/'+instrument+'/YYYY/c' + prb + $
                 '_' +datatype+'_'+instrument+'_'+time_format+'_v??.cdf'
               path_count += 1
              end
             'efw': begin
               pathformat[path_count] = 'c' + prb + '/' +  datatype + '/'+instrument+'/YYYY/c' + prb + $
                 '_' +datatype+'_'+instrument+'_'+time_format+'_v??.cdf'
               path_count += 1
              end
              'pea': begin
                pathformat[path_count] = 'c' + prb + '/' +  datatype + '/'+instrument+'/YYYY/c' + prb + $
                  '_' +datatype+'_'+instrument+'_'+time_format+'_v??.cdf'
                path_count += 1
              end
              'rap': begin
                pathformat[path_count] = 'c' + prb + '/' +  datatype + '/'+instrument+'/YYYY/c' + prb + $
                  '_' +datatype+'_'+instrument+'_'+time_format+'_v??.cdf'
                path_count += 1
              end
              'sta': begin
                pathformat[path_count] = 'c' + prb + '/' +  datatype + '/'+instrument+'/YYYY/c' + prb + $
                  '_' +datatype+'_'+instrument+'_'+time_format+'_v??.cdf'
                path_count += 1
              end
              'whi': begin
                pathformat[path_count] = 'c' + prb + '/' +  datatype + '/'+instrument+'/YYYY/c' + prb + $
                  '_' +datatype+'_'+instrument+'_'+time_format+'_v??.cdf'
                path_count += 1
              end
              'wbd': begin
                pathformat[path_count] = 'c' + prb + '/'+instrument+'/YYYY/MM/c' + prb + $
                  '_' +datatype+'_'+instrument+'_'+time_format+'????_v??.cdf'
                path_count += 1
              end
        endcase
    endfor

    data_count = 0 
    for probe_idx = 0, n_elements(probes)-1 do begin
      for datatype_idx = 0, n_elements(datatype)-1 do begin
        relpathnames = file_dailynames(file_format=pathformat[data_count], trange=tr, /unique, resolution=resolution)

        files = spd_download(remote_file=relpathnames, remote_path=remote_data_dir, $
          local_path = local_data_dir, ssl_verify_peer=0, ssl_verify_host=0)
        
        if n_elements(files) eq 1 && files eq '' then continue

        spd_cdf2tplot, files, tplotnames = new_tplotnames, varformat=varformat, $
                suffix = suffix, get_support_data = get_support_data, /load_labels, $
                min_version=min_version,version=cdf_version,latest_version=latest_version, $
                number_records=cdf_records, $
                loaded_versions = the_loaded_versions
        append_array, tplotnames, new_tplotnames
        
        ; add the loaded files to the cdf_filenames keyword
        append_array, cdf_filenames, files
        
        ; add the loaded version #s
        append_array, versions, the_loaded_versions
        
        ; forget about the daily files for this probe
        undefine, files
        undefine, new_tplotnames
        undefine, the_loaded_versions
        
        data_count += 1
      endfor
    endfor
    
    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') and ~undefined(time_clip) then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
end