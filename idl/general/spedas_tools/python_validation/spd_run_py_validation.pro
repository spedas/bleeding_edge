;+
; FUNCTION:
;     spd_run_py_validation
;     
; PURPOSE:
;     Runs a Python script and checks that tplot variables match those currently loaded in IDL
;     
; INPUT:
;     py_script: Python script, specified as a string or array of strings
;     vars: variables to check, specified as a string or array of strings
; 
; KEYWORDS:
;     tolerance: maximum percent difference between the data and time values (default: 1e-3)
;     py_exe_dir: location of the python executable on your machine
;     tmp_dir: local directory where the Python scripts are stored prior to running
;     points_to_check: number of data points to check
;     
; NOTES:
;     - IDL variables must already be loaded
;     - This routine only checks a few data points throughout the variables (set by the 'tolerance' keyword)
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2021-08-20 15:33:18 -0700 (Fri, 20 Aug 2021) $
; $LastChangedRevision: 30232 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/python_validation/spd_run_py_validation.pro $
;-

function spd_run_py_compare, idl_result, py_result, tolerance=tolerance
  if undefined(tolerance) then tolerance = 1e-3
  notused = where(abs((py_result-idl_result)*100d/idl_result) ge tolerance, bad_count)
  return, bad_count eq 0 ? 1 : 0
end

; converts an array stored in a string to an actual array
function spd_run_py_str_to_arr, str
  if strmid(str, 0, 1) ne '[' then return, str ; not an array
  return, strsplit(strmid(str[-1], 1, strlen(str[-1])-2), ', ', /extract)
end

function spd_run_py_validation, py_script, vars, tolerance=tolerance, py_exe_dir=py_exe_dir, tmp_dir=tmp_dir, points_to_check=points_to_check
  if undefined(tolerance) then tolerance = 1e-3
  if undefined(points_to_check) then points_to_check = 10
  if undefined(py_exe_dir) then py_exe_dir = ''
  if undefined(tmp_dir) then tmp_dir = ''
  
  if ~is_array(py_script) then py_script = [py_script]
  if ~is_array(vars) then vars = [vars]
  
  passed = 1b
  
  di = file_info(tmp_dir)
  if tmp_dir ne '' && ~di.exists then file_mkdir2, tmp_dir
  
  if tmp_dir ne '' then tmp_dir = spd_addslash(tmp_dir)
  if py_exe_dir ne '' then py_exe_dir = spd_addslash(py_exe_dir)
  
  var_table = hash()
  
  for var_idx=0, n_elements(vars)-1 do begin
    get_data, vars[var_idx], data=d
    if ~is_struct(d) then begin
      dprint, dlevel=0, 'Error, variable not found: ' + vars[var_idx]
      return, 0b
    endif
    var_table[vars[var_idx]] = hash('ntimes', n_elements(d.x), 'dimen', n_elements(d.y[0, *]), 'spec', tag_exist(d, 'v'), 'data', d)
  endfor
  
  ; now write the python script
  out_file = 'tmp_py_'+strcompress(string(ulong(randomn(!NULL, /ulong)*1000000)), /rem)+'.py'
  openw, tmpunit, tmp_dir+out_file, /get_lun
  
  for py_line=0, n_elements(py_script)-1 do begin
    printf, tmpunit, py_script[py_line]
  endfor
  
  printf, tmpunit, 'from pytplot import get_data'
  
  for var_idx=0, n_elements(vars)-1 do begin
    printf, tmpunit, "d = get_data('" + vars[var_idx] + "')"
    printf, tmpunit, "print(d[0][0:10].tolist())"
    for n=0, points_to_check-1 do begin
      printf, tmpunit, "print(d[1]["+strcompress(string((var_table[vars[var_idx]])['ntimes']*n/points_to_check), /rem)+"].tolist())"
    endfor
  endfor

  free_lun, tmpunit
  
  ; pause to give IDL time to finish writing the python file
  wait, 5
  
  dprint, dlevel=2, 'Running python test script at: ' + tmp_dir+out_file
  
  spawn, py_exe_dir + 'python '+tmp_dir+out_file, pyoutput
  
  count = 0

  for var_idx=n_elements(vars)-1, 0, -1 do begin
    data = (var_table[vars[var_idx]])['data']
    for n=points_to_check-1, 0, -1 do begin
      idx = (var_table[vars[var_idx]])['ntimes']*n/points_to_check
      
      pyresult = spd_run_py_str_to_arr(pyoutput[-1-count])
      idlresult = data.Y[idx, *]
      
      matches = spd_run_py_compare(idlresult, pyresult, tolerance=tolerance)
      if matches eq 0 then begin
        dprint, dlevel=0, 'Error, python validation test failed for: ' + vars[var_idx] + ' (' + strcompress(string(idx), /rem) + ')'
        passed = 0b
      endif

      count += 1
    endfor
    
    pyresult = spd_run_py_str_to_arr(pyoutput[-1-count])
    idlresult = data.x[0:9]
    matches = spd_run_py_compare(idlresult, pyresult, tolerance=tolerance)
    if matches eq 0 then begin
      dprint, dlevel=0, 'Error, python validation test failed for: ' + vars[var_idx] + ' (times)'
      passed = 0b
    endif
    
    count += 1
  endfor
  
  return, passed
end

