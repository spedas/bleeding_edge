;+
; PROCEDURE:
;         mms_load_data_spdf
;         
; PURPOSE:
;         Load MMS data from NASA/SPDF (backup to loading from SDC)
;         
;         This routine is not meant to be called directly - please use 
;         mms_load_xxx with the /spdf keyword set. 
; 
; KEYWORDS:
;         See mms_load_data for keyword definitions
;         
; EXAMPLE:
;    mms_load_fgm, /spdf, probe=1, level='l2', trange=['2016-01-10', '2016-01-11']
; 
; NOTES:
;       *** IMPORTANT NOTE ON BURST DATA *** 
;       Burst data files downloaded with this routine will not be in the same 
;       directory structure as the burst files downloaded with mms_load_data using
;       the SDC. This is because the SDC puts burst files in daily folders, while
;       SPDF doesn't. 
;       
;       *** Did you download the data using FTP? ***
;       If you download burst data from SPDF using FTP, be sure to use
;       the /spdf keyword when calling the mms_load_xxx routines. This
;       is due to the different directory structures mentioned above.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-05-15 09:38:15 -0700 (Fri, 15 May 2020) $
;$LastChangedRevision: 28695 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_load_data_spdf.pro $
;-

pro mms_load_data_spdf, probes = probes, datatype = datatype, instrument = instrument, $
                   trange = trange, source = source, level = level, $
                   remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
                   attitude_data = attitude_data, no_download = no_download, $
                   no_server = no_server, data_rate = data_rate, tplotnames = tplotnames, $
                   get_support_data = get_support_data, varformat = varformat, $
                   center_measurement=center_measurement, cdf_filenames = cdf_filenames, $
                   cdf_records = cdf_records, min_version = min_version, $
                   cdf_version = cdf_version, latest_version = latest_version, $
                   time_clip = time_clip, suffix = suffix, versions = versions, $
                   download_only=download_only

    if not keyword_set(datatype) then datatype = '*'
    if not keyword_set(level) then level = 'l2'
    if not keyword_set(probes) then probes = ['1']
    if not keyword_set(data_rate) then data_rate = 'srvy'
    
    if undefined(instrument) then begin
      dprint, dlevel = 0, 'Error, no instrument keyword provided; this routine is not meant to be called directly; use mms_load_xxx with the /SPDF keyword set'
      return
    endif
    
    ; make sure important strings are lower case
    instrument = strlowcase(instrument)
    level = strlowcase(level)
    
    if not keyword_set(remote_data_dir) then remote_data_dir = 'https://spdf.sci.gsfc.nasa.gov/pub/data/mms/'

    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    ;if not keyword_set(source) then source = !mms
    
    pathformat = strarr(n_elements(probes)*n_elements(datatype))
    path_count = 0 
    
    if instrument eq 'dfg' or instrument eq 'afg' then begin
        dprint, dlevel = 0, 'Error, no AFG/DFG data available at SPDF - these are only available via the SDC'
        return
    endif

    for probe_idx = 0, n_elements(probes)-1 do begin
        if data_rate eq 'brst' then time_format = 'YYYYMMDDhhmmss' else time_format = 'YYYYMMDD'
        case strlowcase(instrument) of
            'fgm': begin
                ; FGM
                ; mms1/fgm/srvy/l2/2016/01/
                pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                    instrument + '/'+data_rate+'/'+level+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                    '_' + instrument + '_'+data_rate+'_'+level+'_'+time_format+'_v*.cdf'
                path_count += 1
              end
             'aspoc': begin
                ; ASPOC
                ; mms1/aspoc/srvy/l2/2016/02/
                pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                    instrument + '/'+data_rate+'/'+level+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                    '_' + instrument + '_'+data_rate+'_'+level+'_'+time_format+'_v*.cdf'
                path_count += 1
              end
             'edi': begin
                ; EDI
                ; mms1/edi/srvy/l2/efield/2016/01/
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'fpi': begin
                ; FPI
                ; mms1/fpi/fast/l2/des-dist/2016/01/
                ; special case for FPI
                if data_rate eq 'brst' then time_format = 'YYYYMMDDhhmmss' else time_format = 'YYYYMMDDhh0000'
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'epd-eis': begin
                ; EIS
                ; mms1/epd-eis/srvy/l2/extof/2016/01/
                instru = 'epd-eis' ; different instrument name for EIS data in the directory structure
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instru + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instru + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'feeps': begin
                ; FEEPS
                ; mms1/feeps/srvy/l2/electron/2016/01/
                if data_rate eq 'brst' then time_format = 'YYYYMMDDhhmmss' else time_format = 'YYYYMMDD000000'
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'hpca': begin
                ; HPCA
                ; mms1/hpca/srvy/l2/ion/2016/01/ 
                ;if data_rate eq 'brst' then time_format = 'YYYYMMDDhhmm00' else time_format = 'YYYYMMDD??????'
                ; HPCA is no longer using 00 seconds as of 11/30/17 at SPDF
                time_format = 'YYYYMMDD??????'
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'mec': begin
                ; MEC
                ; mms1/mec/srvy/l2/ephts04d/2016/01/
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'scm': begin
                ; SCM
                ; mms1/scm/srvy/l2/scsrvy/2016/01/
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
              'dsp': begin
                 ; DSP
                 ; mms1/dsp/fast/l2/swd/2016/04/
                 for datatype_idx = 0, n_elements(datatype)-1 do begin
                   pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                     instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                     '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                   path_count += 1
                 endfor
              end
              'edp': begin
                ; EDP
                ; mms1/edp/fast/l2/dce/2016/03/
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                  pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                    instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                    '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                  path_count += 1
                endfor
              end
        endcase
    endfor

    data_count = 0 
    for probe_idx = 0, n_elements(probes)-1 do begin
      for datatype_idx = 0, n_elements(datatype)-1 do begin
        if instrument eq 'fpi' then resolution = 7200 ; 2-hour resolution on FS files
        if data_rate eq 'brst' then resolution = 1 ; 1 second resolution for burst files
        
        ; for burst, we need to start ~10 minutes earlier, so we always get the data when requested
        ; this fixes a bug for FPI, L2, des-dist, MMS3, ['2015-10-16/13:07:00','2015-10-16/13:07:04']
        ; reported by Steve Martin @ GSFC
       
        if data_rate eq 'brst' then tr_for_filenames = [tr[0]-600.0, tr[1]] else tr_for_filenames = tr
        
        relpathnames = file_dailynames(file_format=pathformat[data_count], trange=tr_for_filenames, /unique, resolution=resolution)

        ; the following is a kludge to deal with the fact that "mm" in "mms" 
        ; is interpreted by file_dailynames as 00 (minute?)
        for path_idx = 0, n_elements(relpathnames)-1 do begin
            real_path = relpathnames[path_idx]
            str_replace, real_path, 'PROBE', 'mms'
            str_replace, real_path, 'PROBE', 'mms' ; str_replace only replaces the first it finds
            relpathnames[path_idx] = real_path
        endfor

        files = spd_download(remote_file=relpathnames, remote_path=remote_data_dir, $
          local_path = local_data_dir, ssl_verify_peer=0, ssl_verify_host=0)
        
        if n_elements(files) eq 1 && files eq '' then continue

        if ~keyword_set(download_only) then begin
          mms_cdf2tplot, files, tplotnames = new_tplotnames, varformat=varformat, $
                  suffix = suffix, get_support_data = get_support_data, /load_labels, $
                  min_version=min_version,version=cdf_version,latest_version=latest_version, $
                  number_records=cdf_records, center_measurement=center_measurement, $
                  loaded_versions = the_loaded_versions
          append_array, tplotnames, new_tplotnames
        endif
        
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