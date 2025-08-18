;+
; Procedure:  goes_init
; 
; Purpose:    Initializes system variables for GOES data.  Can be called from idl_startup to set
;             custom locations.
;  
; Keywords:
;            reset: resets configuration data already in place on the machine
;            local_data_dir: location to save data files on the local machine
;            remote_data_dir: location of the data on the remote machine
;            no_color_setup: skip setting up the graphics configuration
;            
;             
;$LastChangedBy: nikos $
;$LastChangedDate: 2023-02-02 07:46:23 -0800 (Thu, 02 Feb 2023) $
;$LastChangedRevision: 31461 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/goes_init.pro $
;-
pro goes_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, no_color_setup = no_color_setup

defsysv,'!goes',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!goes',  file_retrieve(/structure_format)
endif

if keyword_set(reset) then !goes.init=0

if !goes.init ne 0 then return

!goes = file_retrieve(/structure_format)
;Read saved values from file
ftest = goes_read_config()
If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !goes.local_data_dir = ftest.local_data_dir
    !goes.remote_data_dir = ftest.remote_data_dir
    !goes.no_download = ftest.no_download
    !goes.no_update = ftest.no_update
    !goes.downloadonly = ftest.downloadonly
    !goes.verbose = ftest.verbose
Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting GOES to default configuration'
    endif else begin
      print,'No GOES config found...creating default configuration'
    endelse
    !goes.local_data_dir  = spd_default_local_data_dir() + 'goes' + path_sep()
    !goes.remote_data_dir = 'https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/'
endelse
!goes.min_age_limit = 900    ; Don't check for new files if local file is less than 900 seconds old.

if file_test(!goes.local_data_dir+'.master') then begin ; Local directory IS the master directory
   !goes.no_server = 1
endif

; Do not do color setup if taken care for already
if not keyword_set(no_color_setup) then begin

  spd_graphics_config,colortable=colortable
  
endif ; no_color_setup

!goes.init = 1

printdat,/values,!goes,varname='!goes'

end


