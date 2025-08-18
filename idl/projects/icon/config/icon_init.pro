;+
;NAME:
;   icon_init
;
;PURPOSE:
;   Initializes system variables for ICON.
;   The system variable !icon is defined here.
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2020-01-28 17:58:46 -0800 (Tue, 28 Jan 2020) $
;$LastChangedRevision: 28246 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/config/icon_init.pro $
;
;-------------------------------------------------------------------

pro icon_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, no_color_setup = no_color_setup

  defsysv,'!icon',exists=exists
  if not keyword_set(exists) then begin
    defsysv,'!icon',  file_retrieve(/structure_format)
  endif

  if keyword_set(reset) then !icon.init=0

  if !icon.init ne 0 then return

  !icon = file_retrieve(/structure_format)
  ;Read saved values from file
  ftest = icon_read_config()
  If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !icon.local_data_dir = ftest.local_data_dir
    !icon.remote_data_dir = ftest.remote_data_dir
    !icon.no_download = ftest.no_download
    !icon.no_update = ftest.no_update
    !icon.downloadonly = ftest.downloadonly
    !icon.verbose = ftest.verbose
  Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting ICON to default configuration'
    endif else begin
      print,'No ICON config found...creating default configuration'
    endelse
    !icon.local_data_dir  = spd_default_local_data_dir() + 'icon' + path_sep()
    ;http://themis.ssl.berkeley.edu/data/icon/Repository/Archive/LEVEL.1/FUV/2017/
    ;!icon.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/icon/Repository/Archive/Simulated-Data/'
    !icon.remote_data_dir = '/disks/data/icon/Repository/Archive/Simulated-Data/'
  endelse
  !icon.min_age_limit = 900    ; Don't check for new files if local file is less than 900 seconds old.

  if file_test(!icon.local_data_dir+'.master') then begin ; Local directory IS the master directory
    !icon.no_server = 1
  endif

  ; Do not do color setup if taken care for already
  if not keyword_set(no_color_setup) then begin

    spd_graphics_config,colortable=colortable

  endif ; no_color_setup

  !icon.init = 1

  printdat,/values,!icon,varname='!icon'

end

