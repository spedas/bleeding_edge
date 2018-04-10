;+
;Procedure:
;  mms_get_local_files
;
;Purpose:
;  Search for local MMS files in case a list cannot be retrieved from the
;  remote server.  Returns a sorted list of file paths.
;  
;Calling Sequence:
;  
;  files = mms_get_local_file_info( probe=probe, instrument=instrument, $
;            data_rate=data_rate, level=level, datatype=datatype, trange=trange)
;
;Input:
;  probe:  (string) Full spacecraft designation, e.g. 'mms1'
;  instrument:  (string) Instrument designation, e.g. 'hpca' 
;  data_rate:  (string) Data collection mode?  e.g. 'srvy'
;  level:  (string) Data processing level, e.g. 'l1b'
;  trange:  (string/double) Two element time range, e.g. ['2015-06-22','2015-06-23']
;  datatype:  (string) Optional datatype specification, e.g. 'moments'
;
;Output:
;  return value:  Sorted string array of file paths, if successful; 0 otherwise 
;
;Notes:
;  -Input strings should not contain wildcards (datatype may be '*')
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-04-09 12:14:36 -0700 (Mon, 09 Apr 2018) $
;$LastChangedRevision: 25023 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_get_local_files.pro $
;-

function mms_get_local_files, probe = probe, instrument = instrument, data_rate = data_rate, $
  level = level, datatype = datatype, trange = trange_in, cdf_version = cdf_version, $
  latest_version = latest_version, min_version = min_version, mirror = mirror

            
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
basic_inputs = [probe, instrument, data_rate, level]

;if datatype is a wildcard then allow any match
;empty strings should be fine
if undefined(datatype) || datatype eq '*' then begin
  dir_datatype = '[^'+s+']+'
  file_datatype = '[^'+f+']+'
endif else begin
  dir_datatype = datatype
  file_datatype = datatype
endelse

;directory and file name search patterns
;  -assume directories are of the form:
;     (srvy, SITL): spacecraft/instrument/rate/level[/datatype]/year/month/
;     (brst): spacecraft/instrument/rate/level[/datatype]/year/month/day/
;  -assume file names are of the form:
;     spacecraft_instrument_rate_level[_datatype]_YYYYMMDD[hhmmss]_version.cdf
if data_rate eq 'brst' then begin
    dir_pattern = strjoin( basic_inputs, s) + '('+s+dir_datatype+')?' +s+ '[0-9]{4}' +s+ '[0-9]{2}' + s + '[0-9]{2}' + s
endif else begin
    dir_pattern = strjoin( basic_inputs, s) + '('+s+dir_datatype+')?' +s+ '[0-9]{4}' +s+ '[0-9]{2}' + s
endelse
file_pattern = strjoin( basic_inputs, f) + '('+f+file_datatype+')?' +f+ '([0-9]{8,14})'

;escape backslash in case of Windows
search_pattern =  escape_string(dir_pattern  + file_pattern, list='\')

;get list of all .cdf files in local directory
;all_files = file_search(!mms.local_data_dir,'*.cdf')
; Updated with performance enhancement from Naritoshi Kitamura, 11/17/2015, 
;     to be more specific on which directory to look into. This can significantly speed up searching for local files
if keyword_set(mirror) then begin
  instr_data_dir = filepath('', ROOT_DIR=!mms.mirror_data_dir, $
                              SUBDIRECTORY=[probe, instrument, data_rate, level])
endif else begin
  instr_data_dir = filepath('', ROOT_DIR=!mms.local_data_dir, $
                              SUBDIRECTORY=[probe, instrument, data_rate, level])
endelse
all_files = file_search(instr_data_dir,'*.cdf')

;perform search
idx = where( stregex( all_files, search_pattern, /bool, /fold_case), n_files)

if n_files eq 0 then begin
 ; suppress redundant error message
 ; dprint, dlevel=2, 'No local files found for: '+strjoin(basic_inputs,' ') + ' ' +$
 ;                   (undefined(datatype) ? '':datatype)
  return, error
endif

files = all_files[idx]


;----------------------------------------------------------------
;Restrict list to files within the time range
;----------------------------------------------------------------

;extract file info from file names
;  [file name sans version, data type, time]
file_strings = stregex( files, file_pattern, /subexpr, /extract, /fold_case)

;get file start times
time_strings = file_strings[2,*]
tformat = 'YYYYMMDD' + (strlen(time_strings[0]) gt 8 ? 'hhmmss':'')
times = time_double(time_strings, tformat=tformat)

;determine which files are within the requested time range
;  TODO: This check is inadequate as it cannot determine if
;        files whose (start) times precede the time range will
;        intersect it.  Possible solutions:
;          -ascertain time range of each file by type (unlikely)
;          -guess file cadence based on file times within requested 
;           time range (inconsistent/untrustworthy)
;          -sort files by time and always load the file preceding the 
;           first in-range file, then allow time_clip to remove 
;           unwanted data (kludgy)
time_idx = where( times ge trange[0] and times lt trange[1], n_times)

if n_times eq 0 then begin
  ; suppress redundant error message
  ;dprint, dlevel=2, 'No local files found between '+time_string(trange[0])+' and '+time_string(trange[1])
  return, error
endif

;restrict list of files to those in the time range
files = files[time_idx]
file_strings = file_strings[*,time_idx]




;----------------------------------------------------------------
;Extract the latest version of each file 
;----------------------------------------------------------------

files_out = unh_mms_file_filter(files, /no_time, version=cdf_version, min_version=min_version, latest_version=latest_version)

if keyword_set(mirror) then begin
  mirror_dir = !mms.mirror_data_dir
  local_dir = !mms.local_data_dir
  ; need to spawn to handle shortcuts in the directories, e.g., ~/mirror_data -> /Users/username/mirror_data
  spawn, 'echo ' + mirror_dir, mirror_dir
  spawn, 'echo ' + local_dir, local_dir
  for fi=0, n_elements(files_out)-1 do begin
    mirror_file = files_out[fi]
    ; for windows machines, need forward slashes 
    mirror_file = strjoin(strsplit(mirror_file, '\', /extract), '/')
    str_replace, mirror_file, mirror_dir, local_dir
    append_array, local_files, mirror_file
    ; make the local data directory, if needed
    directory = file_dirname(local_files[fi])

    if file_test(directory,/dir) eq 0 then begin
      file_mkdir2, directory
    endif
  endfor

  file_copy, files_out, local_files, /overwrite, /allow_same
  files_out = local_files
endif
;ensure files are in chronological order, just in case (see note in mms_load_data) 
files_out = files_out[bsort(files_out)]

return, files_out


end
