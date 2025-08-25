;+
; PURPOSE: to read a parameterSet file and to return  a list of tplot-variables
;
; INPUT:
;   paramset: The name of the parameterSet. e.g., "01_wi_basic"
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sppeva/source/data/sppeva_data_paramsetread.pro $
;-
FUNCTION sppeva_data_paramSetRead, paramset
  compile_opt idl2

  ; ensure there is no file extension such as .txt
  paramset_tmp = strsplit(paramset,'.',/extract)
  paramset = paramset_tmp[0]

  ; find the parameter-set file
  dir = file_search(ProgramRootDir(/twoup)+'parameterSets',/MARK_DIRECTORY,/FULLY_QUALIFY_PATH,/FOLD_CASE); directory
  paramFileList = file_search(dir,'*',/FULLY_QUALIFY_PATH,count=cmax,/FOLD_CASE); full path to the files
  if cmax gt 0 then begin
    idx = where(strmatch(paramFileList,'*'+paramset+'*',/FOLD_CASE),ct)
    if ct eq 1 then begin
      filename = paramFileList[idx[0]]
    endif else begin
      msg = 'ERROR: Multiple parameterSets found with the string *'+paramset+'*. Please be more specific.'
      if ct eq 0 then msg = paramset+' is not found.'
      result = dialog_message(msg,/center,/error)
      return, -1
    endelse
  endif else begin
    msg = 'ERROR: No parameter in the specified parameterSet directory'
    result = dialog_message(msg,/center,/error)
    return, -1
  endelse

  ; read the paremeters
  result = read_ascii(filename,template=eva_data_template())
  paramlist = result.param
  if n_elements(paramlist) eq 0 then begin
    msg = 'WARNING: Selected parameterSet not available.'
    return, -1
  endif
  return, paramlist
END