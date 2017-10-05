;+
;NAME:    elf_init
;
;PURPOSE:
;   Initializes system variables for elf. Currently the variable only contains information
;   on lomo elfin local data directory. Lot's more features should be added. See thm_init
;   for examples.
;
;NOTE:
;   The system variable !ELF is defined here, just like !THEMIS.
;   The elements of this structure are explained below:
;
;   !MMS.LOCAL_DATA_DIR    This is the root location for all MMS data files.
;                  The MMS software expects all data files to reside in specific subdirectories relative
;                  to this root directory.;
;
;   !MMS.REMOTE_DATA_DIR   This is not implemented yet because there is no server at this point in time. 
;                  A URL will most likely be available after launch. 
;
;KEYWORDS:
;   RESET:           Reset !mms to values in environment (or values in keywords).
;   LOCAL_DATA_DIR:  use given value for local_data_dir, rather than environment. Only works on
;                    initial call or reset.
;   REMOTE_DATA_DIR: Not yet implemented. 
;   NO_COLOR_SETUP   do not set colors if already taken care of
;
;
;HISTORY:
; 2015-04-10, moka, Created based on 'thm_init'
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-07-07 11:34:49 -0700 (Tue, 07 Jul 2015) $
; $LastChangedRevision: 18027 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_init.pro $
;-

pro elf_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir,$
  no_color_setup=no_color_setup

  defsysv,'!elf',exists=exists
  ;defsysv,'!elf', file_retrieve(/structure_format)

  if not keyword_set(exists) then begin; if !mms does not exist
    defsysv,'!elf', file_retrieve(/structure_format)
  endif

  !elf.local_data_dir = !elf.local_data_dir + 'lomo/elfin/'
  !elf.remote_data_dir = 'http://themis-data.igpp.ucla.edu/ell/'   ; use as backup web server
  ;!elf.no_download=1
  ;!elf.no_server=1
;  elf_config
    
  return
END

