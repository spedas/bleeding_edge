;+
;   FUNCTION:
;       elf_files_in_interval
;
;   PURPOSE:
;       filters file list returned by the server to the trange. This filter is purposefully
;         liberal, it regularly grabs an extra file due to special cases
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-08-11 11:36:41 -0700 (Thu, 11 Aug 2016) $
; $LastChangedRevision: 21630 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/load_data/mms_files_in_interval.pro $
;-

function elf_files_in_interval, remote_file_info, trange, sorted_times = sorted_times
  if ~is_struct(remote_file_info) then begin
    dprint, dlevel = 0, 'Error finding files inside the time interval - need a valid array of structures.'
    return, -1
  endif
  tr = time_double(trange)
  all_files = remote_file_info.filename

  if ~is_array(all_files) && all_files eq '' then begin
    dprint, dlevel = 0, 'Error, no files found in the interval.'
    return, -1
  endif

  for file_idx = 0, n_elements(all_files)-1 do begin
    filename = strsplit(all_files[file_idx], '\', /extract)
    filename = filename[n_elements(filename)-1]
    timeval = stregex(filename, '[0-9]{8}|[0-9]{12}|[0-9]{14}', /extract)

    case strlen(timeval) of
      8: timeformat = 'YYYYMMDD'
      12: timeformat = 'YYYYMMDDhhmm'
      14: timeformat = 'YYYYMMDDhhmmss'
    endcase
    append_array, all_times, time_double(timeval, tformat=timeformat)
  endfor
  sorted_times = all_times ; only here to avoid a crash when there's only one time in the array

  ; if there's only one file, return that file
  if n_elements(all_times) eq 1 then return, remote_file_info
  ; more than one file, sort the arrays by time
  sorted_idx = bsort(all_times)
  sorted_file_structs = remote_file_info[sorted_idx]
  sorted_times = all_times[sorted_idx]

  ; idx_interval = where(sorted_times ge tr[0] and sorted_times le tr[1], file_count)
  idx_interval = where(sorted_times ge time_double(time_string(tr[0])) and sorted_times le tr[1], file_count)
  if file_count eq 0 then begin
    idx_interval = n_elements(sorted_times)-1
  endif else begin
    ; Super kludgy - the idea is that this grabs one extra file, for
    ; complete coverage
    idx_before_exists_in_list = where(idx_interval eq idx_interval[0]-1)
    if n_elements(idx_interval) ne n_elements(sorted_times) and idx_before_exists_in_list eq -1 then begin
      if idx_interval[0] ne 0 then idx_interval = [idx_interval[0]-1, idx_interval]
    endif
  endelse

  files_in_interval = sorted_file_structs[idx_interval]

  return, files_in_interval
end