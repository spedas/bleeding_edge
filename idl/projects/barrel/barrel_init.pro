;+
;NAME: barrel_init
;DESCRIPTION: Initializes system variables for BARREL.  Can be called 
;  from idl_startup or customized for non-standard installations.  The
;  system variable !BARREL is defined here.  The elements of this
;  structure are (mostly) the same as for !THEMIS.
;
;REQUIRED INPUTS:
; none
;
;KEYWORD ARGUMENTS (OPTIONAL):
; RESET:        If set, force
;
;
;STATUS:
;
;TO BE ADDED: n/a
;
;EXAMPLE:
;
;REVISION HISTORY:
;Version 0.96a KBY 06/15/2014 cleaned up commented out (dead) code
;Version 0.92f KBY 08/09/2013 REMOTE_DATA_DIR pointed to BARRELDATA.UCSC.EDU
;Version 0.92 KBY 06/04/2013 added support for data directories sorted by version number
;Version 0.91d KBY 06/04/2013 REMOTE_DATA_DIR pointed to SOC1 local; LOCAL_DATA_DIR to /barrel/
;Version 0.90b KBY 04/19/2013 REMOTE_DATA_DIR pointed to test directory for beta testing
;Version 0.84 KBY 12/04/2012 REMOTE_DATA_DIR pointed to SSL; added header 
;Version 0.83 KBY 12/04/2012 initial beta release
;Version 0.80 KBY 10/29/2012 from 'goesmag/goes_init.pro' by JWL(?)
;-

pro barrel_init,reset=reset
defsysv,'!barrel',exists=exists
if ~keyword_set(exists) || keyword_set(reset) then begin
    defsysv,'!barrel', file_retrieve(/structure_format)
    ftest = barrel_read_config()
    if (size(ftest, /type) EQ 8) && ~keyword_set(reset) then begin
        print, 'Loading saved BARREL config.'
        !barrel.local_data_dir = ftest.local_data_dir
        !barrel.remote_data_dir = ftest.remote_data_dir
        !barrel.no_download = ftest.no_download
        !barrel.no_update = ftest.no_update
        !barrel.downloadonly = ftest.downloadonly
        !barrel.verbose = ftest.verbose
        !barrel.user_agent = ftest.user_agent

    endif else begin
        if keyword_set(reset) then begin
            print, 'Resetting BARREL to default configuration'
        endif else begin
            print, 'No BARREL config found.. creating default configuration'
        endelse

        defsysv,'!barrel', file_retrieve(/structure_format)
        !barrel.remote_data_dir = 'http://barreldata.ucsc.edu/data_products/'
        !barrel.local_data_dir = root_data_dir() + 'barrel/'
        !barrel.no_download = file_test(!barrel.local_data_dir + '.barrel_master',/regular)
        !barrel.user_agent = ''
        print, 'Saving default BARREL config...'
        barrel_write_config
    endelse
    printdat,/values,!barrel,varname='!barrel'
    spd_graphics_config
endif

RETURN
END
