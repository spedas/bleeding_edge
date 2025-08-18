;+
;PROCEDURE:  secs_init
;PURPOSE:    Initializes system variables for secs.
;
;HISTORY
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-02-13 08:50:37 -0800 (Mon, 13 Feb 2017) $
;$LastChangedRevision: 22761 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/secs_init.pro $
;-
pro secs_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir

; need !cdf_leap_seconds to convert CDFs with TT2000 times
cdf_leap_second_init

defsysv,'!secs',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!secs',  file_retrieve(/structure_format)
endif

if keyword_set(reset) then !secs.init=0

if !secs.init ne 0 then return

!secs = file_retrieve(/structure_format)
;Read saved values from file
ftest = secs_read_config()

If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !secs.local_data_dir = ftest.local_data_dir
    !secs.remote_data_dir = ftest.remote_data_dir
    !secs.no_download = ftest.no_download
    !secs.no_update = ftest.no_update
    !secs.downloadonly = ftest.downloadonly
    !secs.verbose = ftest.verbose
Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting secs to default configuration'
    endif else begin
      print,'No secs config found...creating default configuration'
    endelse
    !secs.local_data_dir = !secs.local_data_dir + 'secs'
    !secs.remote_data_dir = 'http://vmo.igpp.ucla.edu/data1/SECS'
endelse

!secs.local_data_dir = spd_addslash(!secs.local_data_dir)
!secs.remote_data_dir = spd_addslash(!secs.remote_data_dir)

!secs.init = 1

printdat,/values,!secs,varname='!secs'

end

