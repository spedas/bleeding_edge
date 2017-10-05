;+
;NAME:
; wrapper for spd_download that returns local versions of files, if
; they are available. SPd_download only will return a local version if
; the file is specified without wildcards.
;CALLING SEQUENCE:
; paths = spd_download_plus( [remote_file=remote_file] | [,remote_path=remote_path]
;                          [,local_file=local_file] [,local_path=local_path] ... )
;Example Usage:
;
;  Download file to current directory
;  ------------------------------------  
;    ;"file.dat" will be placed in current directory 
;    paths = spd_download( remote_file='http://www.example.com/file.dat' )
;  
;  Download file to specific location
;  ------------------------------------
;    ;remote file downloaded to "c:\data\file.dat"
;    paths = spd_download( remote_file='http://www.example.com/file.dat', $
;                          local_path='c:\data\')
;
;  Download multiple files to specified location and preserve remote file structure
;  -------------------------------------
;    ;remote files downloaded to "c:\data\folder1\file1.dat"
;    ;                           "c"\data\folder2\file2.dat"
;    paths = spd_download( remote_file = ['folder1/file1.dat','folder2/folder2.dat'], $
;                          remote_path = 'http://www.example.com/', $
;                          local_path = 'c:\data\')
;
; 
;Input:
;
;  Specifying File names
;  ---------------------
;    remote_file:  String or string array of URLs to remote files
;    remote_path:  String consisting of a common URL base for all remote files
;
;      -The full remote URL(s) will be:  remote_path + remote_file
;      -If no url scheme is recognized (e.g. 'http') then it is 
;       assumed that the url is a path to a local resource (e.g. /mount/data/)
;  
;    local_file:  String or string array of local destination file names
;    local_path:  String consisting of a common local path for all local files
;
;      -The final local path(s) will be:  local_path + local_file
;      -The final path(s) can be full or relative
;      -If local_file is not set then remote_file is used
;      -If remote_file is a full URL then only the file name is used
;
;      -Remote and local file names may contain wildcards:  *  ?  [  ]
;
;  Download Options
;  ---------------------
;    last_version:  Flag to only download the last in file in a lexically sorted 
;                   list when multiple matches are found using wildcards
;    no_update:  Flag to not overwrite existing file
;    force_download:  Flag to always overwrite existing file
;    no_download:  Flag to not download remote files
;
;    user_agent:  Specifies user agent reported to remote server. (string)
;
;    file_mode:  Bit mask specifying permissions for new files (see file_chmod)
;    dir_mode:  Bit mask specifying permissions for new directories (see file_chmod)
;    
;    no_wildcards: assume no wild cards in the requested url/filename
;
;  IDLnetURL Properties
;  ---------------------
;    All IDLnetURL properties may be specified as keywords to this routine.
;    See "IDLnetURL Properties" in the IDL documentation for more information.
;    Some examples are:
;    ------------------
;      url_query
;      url_username       
;      url_password
;      url_port
;      proxy_hostname
;      proxy_username
;      proxy_password
;
;  Other
;  ---------------------
;    progress_object:  Object reference for status updates
;
;  Backward Support
;  ---------------------
;    local_data_dir:  mapped to local_path
;    remote_data_dir:  mapped to remote_path
;    no_server:  mapped to no_download
;    no_clobber:  mapped to no_update    
;    valid_only:  only return paths to files that exist (ideally this would be default)
;
;
;Output:
;  return value:  String array specifying the full local path to all requested files
;
;
;Notes:
;  -unsupported file_retrieve keywords:
;     progress, preserve_mtime, progobj, ignore_filesize, 
;     ignore_filedate, archive_ext, archive_dir, min_age_limit
;  -Note that the program still only returns the local file if a)
;   the local_file keyword is set, or the local_path and remote_file
;   keywords are set.
;$LastChangedBy: jimm $
;$LastChangedDate: 2017-02-06 15:51:25 -0800 (Mon, 06 Feb 2017) $
;$LastChangedRevision: 22741 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_download_plus.pro $
;
;-
Function spd_download_plus, $
   remote_path = remote_path, $
   remote_file = remote_file, $
   local_path = local_path, $
   local_file = local_file, $
   last_version = last_version, $
   _extra = _extra

  ;call spd_download
  files_out = spd_download(remote_path = remote_path, remote_file = remote_file, $
                           local_path = local_path, local_file = local_file, $
                           last_version = last_version, _extra = _extra)
  ;A file with either ? or * is a failure
  q = strpos(files_out, '?')
  s = strpos(files_out, '*')
  If(q[0] ne -1 or s[0] ne -1) Then files_out = ''
  ;If nothing comes out, then do a file check
  If(~is_string(files_out)) Then Begin
     If(keyword_set(local_file)) Then Begin
        files_out = file_search(local_file)
     Endif Else If(keyword_set(local_path)) Then Begin
        If(keyword_set(remote_file)) Then Begin
           lfile = file_basename(remote_file)
           files_out = file_search(local_path+lfile, count = n_local)
           If(keyword_set(last_version)) Then Begin
              files_out = files_out[(n_local-1) > 0]
           Endif
        Endif
     Endif
  Endif
  Return, files_out
End
           
        
