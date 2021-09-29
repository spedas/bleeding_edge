;+
; PROCEDURE:
;         mms_remove_old_files
;
; PURPOSE:
;         Removes old MMS CDF data files stored on your local file system. 
;
; KEYWORDS:
;         trange: time range of interest; default is full mission
;         probes: list of probes - values for MMS SC #; default is all probes
;         instruments: ['fpi', 'hpca', 'fgm'], etc; default is all instruments
;         levels: level of data processing; default is all levels
;         data_rates: instrument data rate; default is all data rates
;         no_warning: disable warning before deleting files
; 
; NOTES:
;         WARNING: this routine requires an internet connection
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-04-10 13:26:52 -0700 (Wed, 10 Apr 2019) $
;$LastChangedRevision: 26996 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/mms_remove_old_files.pro $
;-

pro mms_remove_old_files, probes=probes, instruments=instruments, data_rates=data_rates, $
  levels=levels, trange=trange, cdf_version=cdf_version, latest_version, $
  min_version=min_version, major_version=major_version, no_warning=no_warning
  
  mms_init

  if undefined(local_data_dir) then local_data_dir = !mms.local_data_dir
  ; handle shortcut characters in the user's local data directory
  spawn, 'echo ' + local_data_dir, local_data_dir

  if is_array(local_data_dir) then local_data_dir = local_data_dir[0]
  
  if undefined(probes) then probes = ['1', '2', '3', '4'] else probes = strcompress(string(probes), /rem)
  if undefined(instruments) then instruments = ['fgm', 'fpi', 'edp', 'hpca', 'feeps', 'eis', 'dsp', 'afg', 'dfg', 'scm', 'edi', 'aspoc', 'mec']
  if undefined(levels) then levels = ['ql', 'l1a', 'l1b', 'l2']
  if undefined(data_rates) then data_rates = ['srvy', 'fast', 'brst', 'slow']
  if undefined(trange) then trange = [time_double('2015-03-01'), systime(/seconds)] else trange = time_double(trange)
  
  status = mms_login_lasp(login_info = login_info, username=username, always_prompt=always_prompt)
  if username eq '' || username eq 'public' then public=1
  
  ; verify the SDC is up and running, to avoid accidently deleting all files
  data_file = mms_get_science_file_info(sc_id='mms1', instrument_id='fgm', data_rate_mode='srvy', data_level='l2', start_date='2015-12-15', end_date='2015-12-16', public=public)
  
  if data_file[0] eq '' then begin
    dprint, dlevel=0, 'Error, trouble connecting to the SDC; try again later.'
    return
  endif
  
  dprint, dlevel=2, 'Checking local files against those available at the SDC...'
  
  for probe_idx = 0, n_elements(probes)-1 do begin
  for instr_idx = 0, n_elements(instruments)-1 do begin
  for rate_idx = 0, n_elements(data_rates)-1 do begin
  for level_idx = 0, n_elements(levels)-1 do begin
    mms_load_options, instruments[instr_idx], rate=data_rates[rate_idx], level=levels[level_idx], datatype=datatypes
    for datatype_idx = 0, n_elements(datatypes)-1 do begin

      files = mms_get_local_files(probe = 'mms'+probes[probe_idx], instrument = instruments[instr_idx], data_rate = data_rates[rate_idx], $
        level = levels[level_idx], datatype=datatypes[datatype_idx], trange = trange, cdf_version = cdf_version, $
        latest_version = latest_version, min_version = min_version, major_version=major_version)

      if is_string(files[0]) then begin
        append_array, local_files, files
        for file_idx=0l, n_elements(files)-1 do begin

          data_file = mms_get_science_file_info(file=(strsplit(files[file_idx], strlowcase(!version.os_family) eq 'windows' ? '\' : '/', /extract))[-1], public=public)
          
          if data_file[0] eq '' then append_array, remove_files, files[file_idx]
        endfor
      endif
    endfor ; datatypes
    undefine, datatypes
  endfor ; levels
  endfor ; data rates 
  endfor ; instruments
  endfor ; probes
  
  if undefined(remove_files) then begin
    dprint, dlevel=0, 'No old files found.'
    return
  endif

  if ~undefined(remove_files) and undefined(no_warning) then begin
    dprint, dlevel=0, '*********************************************************************************************'
    dprint, dlevel=0, '******* WARNING: removing ' + strcompress(string(n_elements(remove_files)), /rem) + ' files
    dprint, dlevel=0, '******* to see which files will be removed, type: "print, remove_files" in the console'
    dprint, dlevel=0, '******* to stop before removing any files, type: ".full_reset_session" in the console'
    dprint, dlevel=0, '******* to continue, type: ".continue" in the console'
    stop
  endif
  
  if ~undefined(remove_files) then file_delete, remove_files, /verbose

end