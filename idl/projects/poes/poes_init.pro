;+
;PROCEDURE:  poes_init
;PURPOSE:    Initializes system variables for POES.
;
;HISTORY
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-02-13 08:50:37 -0800 (Mon, 13 Feb 2017) $
;$LastChangedRevision: 22761 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_init.pro $
;-
pro poes_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir

; need !cdf_leap_seconds to convert CDFs with TT2000 times
cdf_leap_second_init

defsysv,'!poes',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!poes',  file_retrieve(/structure_format)
endif

if keyword_set(reset) then !poes.init=0

if !poes.init ne 0 then return

!poes = file_retrieve(/structure_format)
;Read saved values from file
ftest = poes_read_config()
If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !poes.local_data_dir = ftest.local_data_dir
    !poes.remote_data_dir = ftest.remote_data_dir
    !poes.no_download = ftest.no_download
    !poes.no_update = ftest.no_update
    !poes.downloadonly = ftest.downloadonly
    !poes.verbose = ftest.verbose
Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting POES to default configuration'
    endif else begin
      print,'No POES config found...creating default configuration'
    endelse

    !poes.local_data_dir = spd_default_local_data_dir()
    !poes.remote_data_dir = 'https://cdaweb.gsfc.nasa.gov/istp_public/data/'
endelse
if file_test(!poes.local_data_dir+'poes/.master') then begin  ; Local directory IS the master directory
   !poes.no_server=1    ;   
   !poes.no_download=1  ; This line is superfluous
endif


!poes.init = 1

printdat,/values,!poes,varname='!poes'

end

