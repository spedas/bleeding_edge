;This is a sample idl_startup batch file.
; If you choose to make changes, we recommend placing the edited file in a new directory that is near the front of your IDL_PATH.


!quiet=1            ; if !quiet ==1 then (some)  error messages are suppressed
on_error,0          ; if == 1 the process control returns to main program whenever errors occur

;repath   ; ,except='obsolete' ; resets path

dprint,print_trace=4  ;Display full path when printing debug messages
dprint,/print_dlevel  ;Display debug level when printing messages

init_devices   ; This procedure sets color tables and initilizes devices.

tplot_options,window=0            ; Forces tplot to use only window 0 for all time plots
tplot_options,'wshow',1           ; Raises tplot window when tplot is called
tplot_options,'verbose',1         ; Displays some extra
tplot_options,'psym_lim',100
tplot_options,'ygap',.5
tplot_options,'lazy_ytitle',1     ; breaks "_" into carriage return on ytitle
tplot_options,'xmargin',[15,12]

; Uncomment and edit either of the following lines to change root data directory (Trailing / is required)
;if !version.os_family eq 'Windows' then  setenv,'ROOT_DATA_DIR=e:/data/'
;if !version.os_family eq 'unix'   then setenv,'ROOT_DATA_DIR=/disks/data/'

;if !version.os_family eq 'Windows' then idl_prompt='IDL'
;
;if !version.os_family eq  'unix' then idl_prompt= getenv('USER')+'@'+getenv('HOST')
;
;setenv,'IDL_PROMPT='+idl_prompt
;!prompt=idl_prompt+'> '

cwd,prompt='IDL> '     ; Display current working directory


!warn.obs_routines = 1
;!warn.OBS_SYSVARS = 1
;!warn.PARENS = 1
;!warn.TRUNCATED_FILENAME = 1
!quiet = 0


; to run a custom startup script,  create a procedure (in your IDL path) with the name "idl_startup_USER"  where USER is replaced by your username
user = getenv('USER')  ; Unix
if not keyword_set(user) then user= getenv('USERNAME')   ; Windows
if not keyword_set(user) then user= getenv('LOGNAME')    ; Other???
libs,'idl_startup_'+user,routine_names=rtnames             ; Test to see if procedure exists
if rtnames then call_procedure,'idl_startup_'+user


