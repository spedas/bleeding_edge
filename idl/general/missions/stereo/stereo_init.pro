;+
;PROCEDURE:  stereo_init
;PURPOSE:    Initializes root and source directories

;-
pro stereo_init,reset=reset,altsource=altsource

defsysv,'!stereo',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!stereo',create_struct(file_retrieve(/structure_format),'probe','a')
endif

if keyword_set(reset) or keyword_set(altsource) then !stereo.init=0

if !stereo.init ne 0 then return

;!stereo = file_retrieve(/structure_format)
extract_tags,!stereo,file_retrieve(/structure_format)
!stereo.local_data_dir = root_data_dir() + 'misc/stereo/'
!stereo.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/misc/stereo/'

if keyword_set(altsource) or systime(1) lt time_double('2008-12-12') then begin
     !stereo.remote_data_dir = 'http://stereo-ssc.nascom.nasa.gov/data/ins_data/'
;     ldr = root_data_dir() + 'stereo/'
;     if file_test(/direc,/write,!stereo.local_data_dir) eq 0 then $
;          !stereo.local_data_dir = root_data_dir()+'misc/stereo/'
endif

;if file_test(/direc,!stereo.local_data_dir+'l1') then begin
;    s=''
;    read,Prompt='Do you wish to move files? ',s
;    if strmid(s,0,1) eq 'y' then begin
;      file_mkdir,!stereo.local_data_dir+'impact2/'
;      file_move,!stereo.local_data_dir+'l1',!stereo.local_data_dir+'impact2/level1'
;    endif
;endif


if file_test(!stereo.local_data_dir+'.htpasswd') then !stereo.no_server=1   ; Detects master directory at SSL

libs,'stereo_config',routine=name
if keyword_set(name) then call_procedure,name

!stereo.init=1

printdat,/values,!stereo,varname='!stereo'

end

