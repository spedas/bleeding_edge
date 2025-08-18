;+
;Procedure: file_retrieve_v
;
;Purpose:  Wrapper for file_retrieve that searches for highest
;available version first, with no need to retrieve remote-index.
;
;Keywords:
;
;   relpathnames:  the list of relative pathnames that are being
;   searched
;
;   version_list(optional): if the user wants to override the default
;   version priority list so this function prioritizes versions
;   differently, a different version list can be passed in
;
;
; $LastChangedBy: kenb-mac $
; $LastChangedDate: 2007-08-21 08:33:59 -0700 (Tue, 21 Aug 2007) $
; $LastChangedRevision: 1463 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_retrieve_v.pro $
;-


function file_retrieve_v,relpathnames, version_list = version_list, _extra = _extra

if not keyword_set(relpathnames) then return, -1L

;maintains the order in which versions should be searched
if not keyword_set(version_list) then $
  version_list = ['v02', 'v01', 'v00']

;;remove the version number so search is only on the file root
temp_path = strmid(relpathnames, 0, transpose(strlen(relpathnames))-8)

return_list = relpathnames

files_found = intarr(n_elements(relpathnames))
;;try to retrieve files in the order specified by the version_list array
for j = 0, n_elements(version_list) -1L do begin

   file = file_retrieve(temp_path[where(~ files_found)] + '_' + version_list[j] + '.cdf', _extra = _extra)

   file_retrieved = file_test(file)
   
   ;; expand the file_retrieve index to index the full relpathnames array,
   ;; rather than just the subset of files not previously found
   file_retrieved_full = intarr(n_elements(relpathnames))
   file_retrieved_full[where(~ files_found)] = file_retrieved

   if total(file_retrieved) gt 0 then begin
      return_list[where(file_retrieved_full)] =  file[where(file_retrieved)]

      files_found = files_found or file_retrieved_full

      if total(files_found) eq n_elements(files_found) then break

   endif

endfor

return, return_list[where(files_found)]

end
