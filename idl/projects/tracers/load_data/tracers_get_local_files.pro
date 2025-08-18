;+
;Procedure:
;  tracers_get_local_files
;
;Purpose:
;  Search for local TRACERS files in case a list cannot be retrieved from the
;  remote server. Returns a sorted list of file paths.
;
;Calling Sequence:
;
;  files = tracers_get_local_file_info( probe=probe, instrument=instrument, $
;            data_rate=data_rate, level=level, datatype=datatype, trange=trange)
;
;Input:
;  probe:  (string) Full spacecraft designation, e.g. 'ela'
;  instrument:  (string) Instrument designation, e.g. 'fgm'
;  data_rate:  (string) Data collection mode?  e.g. 'srvy'
;  level:  (string) Data processing level, e.g. 'l1'
;  trange:  (string/double) Two element time range, e.g. ['2015-06-22','2015-06-23']
;  datatype:  (string) Optional datatype specification, e.g. 'pos'
;  cdf_version: not yet implemented
;  latest_version: not yet implemented
;  min_version: not yet implemented
;  mirror: not yet implemented
;  pred: set this keyword if you want predicted state data. the default for state data is 
;        definitive
;
;Output:
;  return value:  Sorted string array of file paths, if successful; 0 otherwise
;
;Notes:
;  -Input strings should not contain wildcards (datatype may be '*')
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-07-31 17:36:13 -0700 (Thu, 31 Jul 2025) $
;$LastChangedRevision: 33518 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/tracers/load_data/tracers_get_local_files.pro $
;-

function tracers_get_local_files, probe = probe, instrument = instrument, data_rate = data_rate, $
  level = level, datatype = datatype, trange = trange_in, cdf_version = cdf_version, $
  latest_version = latest_version, min_version = min_version, mirror = mirror, pred=pred

  compile_opt idl2, hidden

  ;return value in case of error
  error = 0

  ;verify all inputs are present
  if undefined(probe) || $
    undefined(instrument) || $
    undefined(data_rate) || $
    undefined(level) || $
    undefined(trange_in) then begin
    dprint, dlevel=0, 'Missing required input to search for local files'
    return, error
  endif

  trange = time_double(trange_in)

  ;----------------------------------------------------------------
  ;Get list of files by probe and type of data
  ;----------------------------------------------------------------

  ;path & filename separators
  s = path_sep()
  f = '_'

  ;inputs common to all file paths and folder names
  dir_inputs = [probe, level, instrument]   

  dir_pattern = strjoin(dir_inputs, s) + s   ; + '('+s+dir_datatype+')?' +s+ '[0-9]{4}' +s+ '[0-9]{2}' + s
  if instrument eq 'state' then begin
     if keyword_set(pred) then dir_pattern = dir_pattern + 'pred/' + s $
        else dir_pattern = dir_pattern + 'defn' + s
  endif
  if instrument eq 'epd' then begin
    Case datatype of
      'pes': subdir='survey/electron/'
      'pis': subdir='survey/ion/'
      'pef': subdir='fast/electron/'
      'pif': subdir='fast/ion/'
    Endcase
    dir_pattern = dir_pattern + subdir + s
  endif
  if instrument eq 'fgm' then begin
    if datatype EQ 'fgs' then dir_pattern = dir_pattern + 'survey' + s $
    else dir_pattern = dir_pattern + 'fast' + s
  endif

  if instrument EQ 'epd' && level EQ 'l1' then file_inputs = [probe, level, instrument+strmid(datatype, 1, 2)] $
     else file_inputs = [probe, level, instrument]
  if instrument EQ 'epd' && level EQ 'l2' then file_inputs = [probe, level, instrument+strmid(datatype, 1, 2)] $
     else file_inputs = [probe, level, instrument]
  if instrument EQ 'fgm' && level EQ 'l1' then file_inputs = [probe, level, datatype]

  if instrument eq 'state' then begin
    if keyword_set(pred) then state_type = 'pred' else state_type = 'defn'
    file_pattern = strjoin( file_inputs, f) + f + state_type + f + '([0-9]{8})'
  endif else begin
     file_pattern = strjoin( file_inputs, f) + f + '([0-9]{8})'
  endelse
 
  ;escape backslash in case of Windows
  search_pattern = escape_string(dir_pattern  + file_pattern, list='\')
  ;get list of all .cdf files in local directory
  
  instr_data_dir = filepath('', ROOT_DIR=!tracers.local_data_dir + dir_pattern) 
  files = file_search(instr_data_dir, '*.cdf')

  ;----------------------------------------------------------------
  ;Restrict list to files within the time range
  ;----------------------------------------------------------------
  tstring=time_string(trange)
  ns=strmid(tstring[0],0,4)+strmid(tstring[0],5,2)+strmid(tstring[0],8,2)
  sp=strpos(files,ns)
  idx=where(sp GE 0, ncnt)
  if ncnt GT 0 then files_out=files[idx] else files_out = -1


  ;extract file info from file names
  ;  [file name sans version, data type, time]
;  file_strings = stregex( files, file_pattern, /subexpr, /extract, /fold_case)

  ;get file start times
;  time_strings = file_strings[1,*]
;  times = time_double(time_strings, tformat=tformat)
;  time_idx = where( times ge trange[0] and times le trange[1], n_times)

;  if n_times eq 0 then begin
    ; suppress redundant error message
    ;dprint, dlevel=2, 'No local files found between '+time_string(trange[0])+' and '+time_string(trange[1])
    ;return, error
;  endif

  ;restrict list of files to those in the time range
;  files = files[time_idx]
;  file_strings = file_strings[*,time_idx]
  ;ensure files are in chronological order, just in case (see note in tracers_load_data)
;  files_out = files[bsort(files)]
;stop
  return, files_out

end
