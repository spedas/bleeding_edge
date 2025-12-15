;+
;
;FUNCTION:        ESC_FILE_SOURCE
;
;PURPOSE:         Returns a structure that contains all the information (or options)
;                 needed to download and return ESCAPADE data file names.
;                 This function will be used primarily for downloading the ESCAPADE science data.
;
;INPUTS:          Optional if this is a structure then it will be returned as the output.
;
;KEYWORDS:
;
;       SET:      If set, then new options are made to the common block variable are therefore persistant.
;
;     RESET:      If set, then the default is restored.
;
;
;NOTE:            Please refer to mvn_file_source().
;
;CREATED BY:      Takuya Hara on 2025-12-04.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2025-12-13 17:20:41 -0800 (Sat, 13 Dec 2025) $
; $LastChangedRevision: 33919 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/general/esc_file_source.pro $
;
;-
FUNCTION esc_file_source, default_source, local_data_dir=local_data_dir, verbose=verbose, set=set, reset=reset, _extra=extra
  COMMON esc_file_source_com, psource
  
  IF KEYWORD_SET(reset) THEN psource = 0
  
  IF NOT KEYWORD_SET(psource) THEN BEGIN                  ; Create the default
     user = GETENV('USER')                                ; Unix
     IF ~KEYWORD_SET(user) THEN user = GETENV('USERNAME') ; PC's
     IF ~KEYWORD_SET(user) THEN user = GETENV('LOGNAME')
     
     IF ~KEYWORD_SET(user) THEN BEGIN
        dprint, dlevel=2, verbose=verbose, 'Username cannot be identified.'
        RETURN, 0
     ENDIF
     
     psource = file_retrieve(/default_structure) ; Get typical default values
     IF FILE_TEST(psource.local_data_dir + 'escapade/science/tools/.hidden/.master', /regular) THEN BEGIN
        psource.no_server = 1   ; local directory IS the server directory
        psource.local_data_dir += 'escapade/science/data/'
     ENDIF ELSE BEGIN
        psource.local_data_dir += 'escapade/data/'
        psource.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/escapade/data/'
        user_pass = ''
        str_element, extra, 'user_pass', user_pass ; Get user_pass if it was passed in
        IF ~KEYWORD_SET(user_pass) THEN user_pass = IDL_BASE64(BYTE(user + ':' + user + '_esc'))
        
        str_element, psource, 'user_pass', user_pass, /add
        str_element, psource, 'preserve_mtime', 1, /add
     ENDELSE 
     str_element, psource, 'verbose', 2, /add
     str_element, psource, 'last_version', 1, /add
  ENDIF
  
  IF is_struct(default_source) THEN source = default_source ELSE source = psource
  IF is_string(local_data_dir) THEN str_element, source, 'local_data_dir', local_data_dir, /add_replace
  IF ~undefined(verbose) THEN str_element, source, 'verbose', verbose, /add_replace
  IF is_struct(extra) THEN extract_tags, source, extra
  
  IF KEYWORD_SET(set) THEN psource = source ; Set the common block structure
  RETURN, source
END 
