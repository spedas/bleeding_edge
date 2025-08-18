;+
; PROCEDURE:
;         mms_config_crib
;
; PURPOSE:
;         Crib sheet showing how to set MMS configuration settings
;
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_config_crib.pro $
;-

; Setup the MMS system variable, !mms; this is where important configuration settings are stored
; Note: !mms.remote_data_dir is not used (since the MMS remote data server is either the LASP SDC or the SPDF)
mms_init
help, !mms
stop

; temporarily change the directory where data is stored with local_data_dir
mms_init, local_data_dir='/new/data/dir/', /reset
help, !mms
stop

; Use a mirror of the MMS dataset on your local network
; 
; note: mirror_data_dir is similar to local_data_dir, but is read-only; setting this
;       will cause the load routines to check this directory for files after checking your local data directory.
;       If files are found here, they're copied to your local data directory, and the copied files
;       are loaded
mms_init, mirror_data_dir='/path/to/network/mirror/', /reset
stop

; if you would prefer to only load data from the local data directories/mirror (and not download from the web)
; use the NO_DOWNLOAD attribute
!mms.NO_DOWNLOAD = 1b
stop

; reset to defaults
mms_init, /reset
help, !mms
stop

; save these settings using the MMS config panel and they will persist through IDL sessions
mms_ui_config
stop

; set the verbosity level to control the amount of detail sent to the IDL console
; verbose of 2 is the default; higher will be more verbose and lower will be less verbose
mms_set_verbose, 0
stop

end