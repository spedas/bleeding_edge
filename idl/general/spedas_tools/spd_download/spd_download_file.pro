;+
;Function:
;  spd_download_file
;
;
;Purpose:
;  Primarily a helper function for spd_download.  This function will download
;  a single file and return the path to that file.  If a local file exists it
;  will only download if the remote file is newer.
;
;
;Calling Sequence:
;  path = spd_download_file(url=url, [,filename=filename] ... )
;
;
;Input:
;  url:  URL to remote file. (string)
;  filename:  Specifies local file path and name.  If a full path is not
;             provided it will assumes a relative path. (string)
;
;  user_agent:  Specifies user agent reported to remote server. (string)
;  headers:  Array of HTML headers to be sent to remote server.
;            Other IDLneturl properties are passed through _extra but
;            this one is extracted so that defaults can be appended:
;              -"User-Agent" is added by default
;              -"If-Modified-Since" is added if file age is checked
;
;  no_update:  Flag to not overwrite existing file
;  force_download:  Flag to always overwrite existing file
;  string_array:  Flag to download remote file and load into memory as an
;                 array of strings.
;
;  min_age_limit:  Files younger than this (in seconds) are assumed current
;
;  file_mode:  Bit mask specifying permissions for new files (see file_chmod)
;  dir_mode:  Bit mask specifying permissions for new directories (see file_chmod)
;
;  progress_object:  Status update object
;  disable_cdfcheck: Useful for large files
;  _extra:  Any idlneturl property (except callback_*) can be passed via _extra
;
;
;
;Output:
;  return value:
;    local file path (string) - if a file is downloaded or a local file is found
;    empty string (string) - if no file is found
;    file contents (string array)  - if /string_array is set
;
;
;Notes:
;  -precedence of boolean keywords:
;     string_array > force_download > no_update > default behavior
;  -checks contents of "http_proxy" environment variable for proxy server
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2024-11-20 07:53:04 -0800 (Wed, 20 Nov 2024) $
;$LastChangedRevision: 32966 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_download_file.pro $
;
;-

function spd_download_file_is_valid, nfile
  ; Check if the downloaded file is a valid cdf or netcdf file
  ;
  ; Sometimes the wifi system responds with code 200-OK and a "file" that only contains HTML,
  ; for example asking the user to agree to terms of use.
  ; These responses should not be saved as cdf or netcdf files and overwrite proper per-existing files.
  ; This check only considers cdf (.cdf) and netcdf (.nc) files.

  compile_opt idl2

  ; Set up a general error handler
  catch, theError
  if theError ne 0 then begin
    dprint, dlevel=1, 'An error occurred: '+ !ERROR_STATE.MSG
    catch, /CANCEL
    return, 0
  endif

  ; Check if the file exists
  if not FILE_TEST(nfile, /read) then begin
    dprint, dlevel=1, 'File does not exist: '+nfile
    ;return, 0
  endif

  ; Find if the file is cdf of netcdf
  cdfornetcdf = 0
  ; filename can contain random numbers at the end (temp file)
  reverse_nfile = ''
  for i=strlen(nfile), 0, -1 do begin
    reverse_nfile = reverse_nfile + strmid(nfile, i, 1)
  endfor
  first_non_digit = stregex(reverse_nfile, '[^0-9]+', length=diglen)
  if first_non_digit lt 1 then begin
    file_name = nfile
  endif else begin
    file_name = strmid(nfile, 0, strlen(nfile)-first_non_digit-1)
  endelse

  ; check if filename is .cdf or .nc
  if (strlen(file_name) ge 4) then begin
    last3let = strlowcase(strmid(file_name, 2, 3, /reverse_offset))
    last4let = strlowcase(strmid(file_name, 3, 4, /reverse_offset))
    if last3let eq '.nc' then begin
      cdfornetcdf = 2
    endif else if last4let eq '.cdf' then begin
      cdfornetcdf = 1
    endif
  endif

  ; Check if file can be opened
  if cdfornetcdf eq 1 then begin
    ; cdf file
    id = cdf_open(nfile, /readonly)
    cdf_close, id
  endif else if cdfornetcdf eq 2 then begin
    ; netcdf file
    id = ncdf_open(nfile, /nowrite)
    ncdf_close, id
  endif

  ; If no errors, then everything is ok
  return, 1
end

function spd_download_file, $

  url = url_in, $
  filename = filename_in, $

  user_agent = user_agent, $
  headers = headers_in, $

  no_update = no_update, $
  force_download = force_download, $
  min_age_limit = min_age_limit, $

  file_mode = file_mode, $
  dir_mode = dir_mode, $

  progress_object = progress_object, $

  string_array = string_array, $
  ssl_verify_peer = ssl_verify_peer, $
  ssl_verify_host = ssl_verify_host, $
  disable_cdfcheck=disable_cdfcheck, $
  _extra = _extra


  compile_opt idl2, hidden

  if undefined(ssl_verify_peer) then ssl_verify_peer=0
  if undefined(ssl_verify_host) then ssl_verify_host=0

  output = ''
  temp_filepath = ''

  if undefined(url_in) || ~is_string(url_in) then begin
    dprint, dlevel=1, 'No URL supplied'
    return, output
  endif

  if n_elements(url_in) gt 1 or n_elements(filename_in) gt 1 then begin
    dprint, dlevel=1, 'Single file downloads only, use SPD_DOWNLOAD for multiple files'
    return, output
  endif

  ;if file name is empty or not defined then attempt to pull file name from url
  if ~keyword_set(filename_in) then begin
    ;allow empty string output for remote index downloads
    filename_in = (stregex(url_in, '/([^/]*$)',/subexpr,/extract))[1]
  endif

  if ~is_string(filename_in,/blank) then begin
    dprint, dlevel=1, 'Invalid local file name'
    return, output
  endif

  ;get proxy server info from environment variable and add to _extra struct if not present
  spd_get_proxy, _extra

  ;this must be defined later
  if undefined(progress_object) then begin
    progress_object = obj_new()
  endif

  ;local file name should be ignored if string_array is set
  url = url_in
  filename = file_expand_path(filename_in)

  local_info = file_info(filename)


  ; Initialize idlneturl object
  ;----------------------------------------
  net_object = obj_new('idlneturl')


  ; Form custom header
  ;----------------------------------------

  ;headers should be passed via _extra from spd_download,
  ;but avoid mutating input just in case
  if ~undefined(headers_in) then begin
    headers = headers_in
  endif

  ;user agent is required sometimes
  if keyword_set(user_agent) then begin
    headers = array_concat('User-Agent: '+user_agent,headers)
  endif else begin
    headers = array_concat('User-Agent: '+'SPEDAS IDL/'+!version.release+' ('+!version.os+' '+!version.arch+')', headers)
  endelse

  ;The file will automatically be overwritten if server is not queried for
  ;its modification time.  If no_update is set and a file is found then there
  ;is nothing left to do.  If downloading to string array then no checks are needed
  if ~keyword_set(string_array) && ~keyword_set(force_download) && local_info.exists then begin

    if keyword_set(no_update) then begin
      dprint, dlevel=2, 'Found existing file: '+filename
      return, filename
    endif

    reference_time = time_string(local_info.mtime,tformat='DOW, DD MTH YYYY hh:mm:ss GMT')
    headers = array_concat('If-Modified-Since: '+reference_time,headers)

  endif


  ; Set neturl object properties
  ;  -any keywords passed through _extra will take precedent
  ;----------------------------------------

  ;flag to tell if there was an exception thrown in the idlneturl callback function
  callback_error = ptr_new(0b)

  ;if the "url" keyword is passed to get() then all "url_*" properties are ignored,
  ;set them manually here to avoid that
  url_struct = parse_url(url)

  ; the following check on url_struct.path is due to some servers (e.g., LASP) not supporting double-forward slashes
  ; e.g., (lasp.colorado.edu//path/to/the/file); IDLnetURL always appends a forward slash between the host and path
  if strlen(url_struct.path) gt 0 && strmid(url_struct.path, 0, 1) eq '/' then url_struct.path = strmid(url_struct.path, 1, strlen(url_struct.path))

  net_object->setproperty, $

    headers=headers, $

    url_scheme=url_struct.scheme, $
    url_host=url_struct.host, $
    url_path=url_struct.path, $
    url_query=url_struct.query, $
    url_port=url_struct.port, $
    url_username=url_struct.username, $
    url_password=url_struct.password, $
    ssl_verify_peer = ssl_verify_peer, $
    ssl_verify_host = ssl_verify_host, $
    _extra=_extra

  ;keep core properties from being overwritten by _extra
  net_object->setproperty, $
    callback_function='spd_download_callback', $
    callback_data={ $
    net_object: net_object, $
    msg_time: ptr_new(systime(/sec)), $
    msg_data: ptr_new(0ul), $
    progress_object: progress_object, $
    error: callback_error $
  }

  ; Download
  ;  -an unsuccessful get will throw an exception and halt execution,
  ;   the catch should allow these to be handled gracefully
  ;  -the file will be downloaded to temporary location to avoid
  ;   clobbering current files and/or leaving empty files
  ;   in the case of an error
  ;----------------------------------------

  ; recreate the url to display without the username and password.
  ; this prevents IDL from showing the username/password in the
  ; console output for each downloaded file
  if url_struct.username ne '' then begin
    url = url_struct.scheme + '://' + url_struct.host + '/' + url_struct.path
  endif

  dprint, dlevel=2, 'Downloading: '+url

  ;manually create any new directories so that permissions can be set
  if ~keyword_set(string_array) then begin
    spd_download_mkdir, file_dirname(filename), dir_mode
  endif

  ;download file to temporary location
  ;  -IDLnetURL creates the destination file almost immediately, clobbering any
  ;   existing file.  If an error occurs (e.g. incorrect URL, server timeout)
  ;   then an empty file will persist afterward.  Using a temporary filename
  ;   prevents current valid files from being immediately overwritten and allows
  ;   empty or incomplete files to be deleted safely in the case of an error.
  file_suffix = spd_download_temp()
  first_time_download = 1

  catch, error
  net_object->getproperty, response_code=response_code, response_header=response_header, url_scheme=url_scheme
  if (error ne 0) && (first_time_download eq 1) && (response_code eq 401) then begin
    ; when we have two directories with usename/password,
    ; sometimes we need to try again to get the file

    first_time_download = 0
    dprint, dlevel=2, 'Download failed. Trying a second time.'

    ;get the file
    temp_filepath = net_object->get(filename=filename+file_suffix,string_array=string_array)

    if ~keyword_set(string_array) then begin

      ; before moving the file, check if the file is a valid file
      if spd_download_file_is_valid(temp_filepath) then begin

        ;move file to the requested location
        file_move, temp_filepath, filename, /overwrite

        ;set permissions for downloaded file
        if ~undefined(file_mode) then begin
          file_chmod, filename, file_mode
        endif

        ;output the final location
        output = filename

        dprint, dlevel=2, 'Download complete:  '+filename

      endif else begin
        dprint, dlevel=2, 'File was invalid and was rejected: '+temp_filepath
      endelse

    endif else begin

      ;output file's contents
      output = temp_filepath

      dprint, dlevel=2, 'Download complete'

    endelse

  endif else if error eq 0 then begin

    ;get the file
    temp_filepath = net_object->get(filename=filename+file_suffix,string_array=string_array)

    if ~keyword_set(string_array) then begin

      ; before moving the file, check if the file is a valid file
      if spd_download_file_is_valid(temp_filepath) then begin

        ;move file to the requested location
        file_move, temp_filepath, filename, /overwrite

        ;set permissions for downloaded file
        if ~undefined(file_mode) then begin
          file_chmod, filename, file_mode
        endif

        ;output the final location
        output = filename

        dprint, dlevel=2, 'Download complete:  '+filename

      endif else begin
        dprint, dlevel=2, 'File was invalid and was rejected: '+temp_filepath
      endelse

    endif else begin

      ;output file's contents
      output = temp_filepath

      dprint, dlevel=2, 'Download complete'

    endelse

  endif else begin
    catch, /cancel

    ;remove temporary file
    file_delete, filename+file_suffix, /allow_nonexistent

    ;handle exceptions from idlneturl
    spd_download_handler, net_object=net_object, $
      url=url, $
      filename=filename, $
      callback_error=*callback_error

  endelse

  ; If there was a partial download, delete the file.
  net_object->getproperty, response_code=response_code2, response_header=response_header2, url_scheme=url_scheme2
  if (response_code2 eq 18) && file_test(filename) then begin
    dprint, dlevel=2, 'Error while downloading, partial download will be deleted:  ' + filename
    file_delete, filename, /allow_nonexistent
    output = ''
  endif

  ; Delete a cdf or netcdf file if it can't be openned.
  if ~keyword_set(disable_cdfcheck) then begin
    cant_open = spd_cdf_check_delete(filename, /delete_file)
    if n_elements(cant_open) gt 0 then begin
      dprint, dlevel=2, 'Error while downloading, corrupted download will be deleted:  ' + filename
      output = ''
    endif
  endif

  ; Delete temp_filepath, if it exists.
  if ~keyword_set(string_array) && (strlen(temp_filepath[0]) gt 12) && file_test(temp_filepath[0]) then begin
    file_delete, temp_filepath[0], /allow_nonexistent
  end

  obj_destroy, net_object

  return, output

end