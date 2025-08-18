; Download the files of the given type using the given query parameters.
; If 'local_dir' is defined, save the files there, otherwise use the current directory.
; 'type' must be one of the following:
;   science
;   ancillary
;   sitl_selections
;   abs_selections
;   gls_selections_<algorithm>, where <algorithm> is one of a small set
; The 'query' is directly passed to the web service.
; See the web service documentation for valid query options.
function download_mms_files, type, query, local_dir=local_dir, latest=latest, max_files=max_files, public=public
  ;TODO: make sure type is valid

  ; Define the maximum number of files to allow.
  if n_elements(max_files) eq 0 then max_files = 500

  ; Set local_dir to current working dir if not specified.
  if n_elements(local_dir) eq 0 then cd, current=local_dir

  ; Define the URL path for the download web service for the given data type.
  url_path = keyword_set(public) ? "mms/sdc/public/files/api/v1/download/" + type : "mms/sdc/sitl/files/api/v1/download/" + type

  ; Get the IDLnetURL singleton. May prompt for password.
  connection = get_mms_sitl_connection()
  
  ; Get the list of files. Names will be full path starting at "mms"?
  files = get_mms_file_names(type, query=query, public=public)
  ; Warn if no files. Error code or empty.
  if (size(files, /type) eq 3 || n_elements(files) eq 0) then begin
    printf, -2, "WARN: No files found for the " + type + " query: " + query 
    return, -1 
  endif
  
  ; Get the number of files.
  ; If the 'latest' keyword is set, only return the latest, 
  ;   which will be the first, so setting length to 1 will work.
  nfiles = n_elements(files)
  if KEYWORD_SET(latest) then nfiles = 1
  
  ; Error if too many files.
  if (nfiles gt max_files) then begin 
    printf, -2, "ERROR: The resulting set of files (" + strtrim(nfiles,2) + ") is too large for the " + type + " query: " + query 
    return, -1 ;TODO: better error codes? http://www.exelisvis.com/docs/IDLnetURL.html#objects_network_1009015_1417867
  endif
  
  ; Download files one at a time. 
  nerrs = 0 ;count number of errors
  for i = 0, nfiles-1 do begin
    ;TODO: flat or hierarchy? assume flat for now
    file = file_basename(files[i]) ;just the file name, no path
    local_file = local_dir + path_sep() + file ;all in one directory (i.e. flat)
    file_query = "file=" + file
    result = execute_mms_sitl_query(connection, url_path, file_query, filename=local_file)
    ;count failures so we can report a 'partial' status
    ;Presumably, execute_mms_sitl_query will print specific error messages.
    if size(result, /type) eq 3 then nerrs = nerrs + 1
  endfor

  ; Print error message if any of the downloads failed.
  if nerrs gt 0 then begin
    msg = "WARN: " + strtrim(nerrs,2) + " out of " + strtrim(nfiles,2) + " file downloads failed." 
    printf, -2, msg
    return, -1
  endif else return, 0
end
