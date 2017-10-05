;+
;NAME:
; mvn_file_source( [default_source] )
;PURPOSE:
; Returns a structure that contains all the information (or options) needed to download and return MAVEN data file names.
; The structure is stored in a common block variable and has persistance.
; This funtion is used primarily by the routine mvn_pfp_file_source().  However users might wish to change the default values.
; see "file_retrieve" for specific information on how to use the options in this structure.
;Typical Usage:  
;  source=mvn_file_source()   ; get the options
;  printdat, source           ; display the options
;Examples:
; #1a:
;  tempsource = mvn_file_source(verbose=4,local_data_dir='tempdir/')  ; temporarily change VERBOSE and LOCAL_DATA_DIR
;  files = mvn_pfp_file_retrieve(source=tempsource)
;INPUT:
;  default_source  (optional)  if this is a structure then it will be returned as the output
;KEYWORDS:
;  SET = [0,1]  : If set, then new options (KEYWORDS or DEFAULT_SOURCE) are made to the common block variable are therefor persistant.
;      DO NOT USE THIS KEYWORD INSIDE publically distributed code - IT WILL PRODUCE SIDE EFFECTS FOR OTHERS! !
;  RESET = [0,1]  : If set then the default is restored.
;      DO NOT USE THIS KEYWORD INSIDE publically distributed code - IT WILL PRODUCE SIDE EFFECTS FOR OTHERS! !
;EXAMPLE 1:
;     printdat, mvn_file_source(/set,  USER_PASS='user:password')   ; Add the user and password to enable authentication on the remote server.
; #1b
;  help,/structure, mvn_file_source(verbose=3,/set)    ; Permanentaly change the verbose level for all subsequent calls
;  files = mvn_pfp_file_retrieve()
; #1c
;  help,/structure, mvn_file_source(no_server=1,/set)  ; Permanently disable searching on the remote server
; #2
;  help,/structure,   mvn_file_source(/reset)       ; reset structure to the default.
;OUTPUT:
; Structure:
;  see "FILE_RETRIEVE" for a description of each structure element.
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2015-11-06 14:01:30 -0800 (Fri, 06 Nov 2015) $
; $LastChangedRevision: 19295 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_file_source.pro $
;-



function mvn_file_source,DEFAULT_SOURCE,set=set,reset=reset,_extra=ex
common mvn_file_source_com,  psource

if keyword_set(reset) then psource=0

if not keyword_set(psource) then begin    ; Create the default
    user = getenv('USER')       ;  Unix 
    if ~keyword_set(user) then user = getenv('USERNAME')   ; PC's 
    if ~keyword_set(user) then user = getenv('LOGNAME')    
    if ~keyword_set(user) then user = 'guest'                ; This line may get deleted in the future!
    psource = file_retrieve(/default_structure,local_data_dir=local_data_dir)   ; get typical default values.    
    if file_test(psource.local_data_dir+'maven/.master',/regular) then psource.no_server =1  $  ; local directory IS the server directory
    else begin   ; Files will be downloaded from the web
       psource.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/'
       user_pass = ''
       str_element,ex,'USER_PASS',user_pass                 ;  Get user_pass if it was passed in
       if ~keyword_set(user_pass) then  user_pass = getenv('MAVENPFP_USER_PASS')
       if ~keyword_set(user_pass) then  user_pass = idl_base64(byte(user + ':' + user + '_pfp'))
       str_element,/add,psource,'USER_PASS',user_pass
       str_element,/add,psource,'PRESERVE_MTIME',1
;       psource.no_update=1   ; this can be set to 1 only because all files use version numbers and will not be updated.  (no longer true!)
 ;      psource.min_age_limit=300  ; five minute delay before checking remote server for file index
    endelse
;    psource.archive_ext = '.arc'   ; archive old files instead of deleting them
;    psource.archive_dir = psource.local_data_dir+ 'maven/' + 'archive/'  ; archive directory
    str_element,/add,psource,'VERBOSE',2
    str_element,/add,psource,'LAST_VERSION',1            ;  set this as default since version numbers are generally used.   This is sloppy!
endif

if size(/type,default_source) eq 8 then  source= default_source  else source = psource

if keyword_set(ex) then begin                  ; change options that are passed in as keywords
    tags = tag_names(ex)
    for i=0,n_elements(tags)-1 do begin
       str_element,/add,source,tags[i],ex.(i)
    endfor
endif


if keyword_set(set) then begin    ; set the common block structure
    psource = source      
endif 

return,source
end
