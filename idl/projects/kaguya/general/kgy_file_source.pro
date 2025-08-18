;+
; FUNCTION:
;       kgy_file_source
; PURPOSE:
;       Provides a structure that contains dummy information
; CALLING SEQUENCE:
;       source = kgy_file_source()
; INPUTS:
;       default_source  (optional)  if this is a structure then it will be returned as the output
; KEYWORDS:
;       PUBLIC: use publicly available data
;       SET = [0,1]  : If set, then new options (KEYWORDS or DEFAULT_SOURCE) are made to the common block variable are therefor persistant.
;                      DO NOT USE THIS KEYWORD INSIDE publically distributed code - IT WILL PRODUCE SIDE EFFECTS FOR OTHERS! !
;       RESET = [0,1]  : If set then the default is restored.
;                        DO NOT USE THIS KEYWORD INSIDE publically distributed code - IT WILL PRODUCE SIDE EFFECTS FOR OTHERS! !
; CREATED BY:
;       Yuki Harada on 2015-07-15
;       Modified from mvn_file_source
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2021-01-14 23:35:04 -0800 (Thu, 14 Jan 2021) $
; $LastChangedRevision: 29602 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/general/kgy_file_source.pro $
;-

function kgy_file_source,default_source,set=set,reset=reset,_extra=ex,public=public
common kgy_file_source_com, psource

if keyword_set(reset) then psource=0

if not keyword_set(psource) then begin ; Create the default
   psource = file_retrieve(/struc)     ; get typical default values.
   psource.remote_data_dir = ''        ;- from local data dir
   psource.local_data_dir  += 'kaguya/'
;   psource.archive_ext = '.arc'  ; archive old files instead of deleting them
;   psource.archive_dir = 'archive/' ; archive directory
   psource.no_server = 1        ;- download manually
   psource.preserve_mtime = 1
   psource.verbose=2
   psource.min_age_limit=300    ; five minute delay before checking remote server for file index
   str_element,/add,psource,'LAST_VERSION',0
endif

if size(/type,default_source) eq 8 then  source= default_source  else source = psource

if keyword_set(public) then begin ;- public setting
;   source.remote_data_dir = 'http://l2db.selene.darts.isas.jaxa.jp/dl/load_datafile.cgi?f=' ;MAG_TS20071221 obsolete
   source.remote_data_dir = 'https://darts.isas.jaxa.jp/pub/pds3/'
   source.local_data_dir  += 'public/'
   source.no_server = 0
endif


if keyword_set(ex) then begin   ; change options that are passed in as keywords
   tags = tag_names(ex)
   for i=0,n_elements(tags)-1 do begin
      str_element,/add,source,tags[i],ex.(i)
   endfor
endif

if keyword_set(set) then begin  ; set the common block structure
   psource = source      
endif 

return,source
end
