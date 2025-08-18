;+
;Procedure:
;  mms_get_local_state_files
;
;Purpose:
;  Search for local state MMS files in case a list cannot be retrieved from the
;  remote server.  Returns a sorted list of file paths.
;  
;Calling Sequence:
;  
;  files = mms_get_local_state_files(probe=probe, level=level, filetype=filetype, trange=trange)
;
;Input:
;  probe:  (string) Full spacecraft designation, e.g. 'mms1'
;  filetype:  (string) state file type, e.g. 'eph' or 'att' 
;  level: (string) state level; either 'def' (for definitive) or 'pred' (for predicted)
;  trange:  (string/double) Two element time range, e.g. ['2015-06-22','2015-06-23']
;
;Output:
;  return value:  Sorted string array of file paths, if successful; 0 otherwise 
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-09-08 13:45:22 -0700 (Tue, 08 Sep 2020) $
;$LastChangedRevision: 29123 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec_ascii/mms_get_local_state_files.pro $
;-

function mms_get_local_state_files, $
 
            probe = probe, $
            level = level, $
            filetype = filetype, $             
            trange=trange_in

compile_opt idl2, hidden

;return value in case of error
error = 0

;verify all inputs are present
if undefined(probe) || $
   undefined(level) || $
   undefined(filetype) || $
   undefined(trange_in) then begin
  dprint, dlevel=0, 'Missing required input to search for local files'
  return, error
endif

trange = time_double(trange_in)
instrument = 'state'
;----------------------------------------------------------------
;Get list of files by probe and type of data
;----------------------------------------------------------------

;path & filename separators
s = path_sep()
f = '_'

;inputs common to all file paths and folder names
basic_inputs = [probe, instrument, level, filetype]

;directory and file name search patterns
;  For now
;  -all ancillary data is in one directory:
;     mms\ancillary
;  -assume file names are of the form:
;     SPACECRAFT_FILETYPE_startDate_endDate.version
;     where SPACECRAFT is [MMS1, MMS2, MMS3, MMS4] in uppercase
;     and FILETYPE is either DEFATT, PREDATT, DEFEPH, PREDEPH in uppercase
;     and start/endDate is YYYYDOY
;     and version is Vnn (.V00, .V01, etc..)
; dir_pattern = strjoin( basic_inputs, s)+s ; not actually used?
file_pattern = strupcase(probe)+f+strupcase(level)+strupcase(filetype)+f+'[0-9]{7}'+f+'[0-9]{7}'

;escape backslash in case of Windows
;search_pattern =  escape_string(dir_pattern  + file_pattern, list='\')

;get list of all state files in local directory
instr_data_dir = filepath('', ROOT_DIR=!mms.local_data_dir, $
                              SUBDIRECTORY=['ancillary', probe, level+filetype])
all_files = file_search(instr_data_dir,'*.V*')

;perform search
idx = where( stregex( all_files, file_pattern, /bool), n_files)

if n_files eq 0 then begin
  dprint, dlevel=2, 'No local files found for: '+strjoin(basic_inputs,' ')
  return, error
endif

files = all_files[idx]

;----------------------------------------------------------------
;Restrict list to files within the time range
;----------------------------------------------------------------
;extract file info from file names
;  [file name sans version, data type, time]
file_strings = stregex( files, file_pattern, /subexpr, /extract)

; extract the start and end times from the file names
date_pattern = '([0-9]{7})_([0-9]{7})'
date_strings = stregex( files, date_pattern, /subexpr, /extract)
tformat = 'YYYYDOY' 
start_times = time_double(date_strings[1,*], tformat=tformat)
end_times = time_double(date_strings[2,*], tformat=tformat)

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
time_idx = where(start_times lt trange[1] and end_times gt trange[0] , n_times)

;time_idx = where((start_times ge trange[0] and start_times lt trange[1]) $
;                 OR (end_times ge trange[0] and end_times lt trange[1]) $
;                 OR (start_times lt trange[1] and end_times gt trange[0])  , n_times)

if n_times eq 0 then begin
  dprint, dlevel=2, 'No local files found between '+time_string(trange[0])+' and '+time_string(trange[1])
  return, error
endif

;restrict list of files to those in the time range
files = files[time_idx]
file_strings = file_strings[time_idx]

;----------------------------------------------------------------
;Extract the latest version of each file
;----------------------------------------------------------------

;get file versions
versions = stregex(files, '.V([0-9]{2})', /subexpr, /extract)

; Solution to duplicate files
;   - Loop over unique file times, not all file times.
;iuniq        = uniq(file_strings[2,*], sort(file_strings[2,*]))
;uniq_strings = file_strings[*,iuniq]
iuniq        = uniq(file_strings, sort(file_strings))
uniq_strings = file_strings[iuniq]

;loop over file names to find files with multiple versions 
for i=0, n_elements(iuniq)-1 do begin
  
  ;find files with identical names (excluding version)
  vidx = where(uniq_strings[i] eq file_strings[*], n_versions)
  
  ;sort results by ascending version and use last in list
  highest_version = (  (files[vidx])[sort(versions[vidx])]  )[n_versions-1]

  ;add to output list
  files_out = array_concat(highest_version,files_out)  
           
endfor

return, files_out
end
