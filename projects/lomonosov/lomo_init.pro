;+
;NAME:    lomo_init
;
;PURPOSE:
;   Initializes system variables for lomo. Currently the variable only contains information
;   on lomo elfin local data directory. Lot's more features should be added. See thm_init
;   for examples.
;
;NOTE:
;   The system variable !LOMO is defined here, just like !THEMIS.
;   The elements of this structure are explained below:
;
;   !LOMO.LOCAL_DATA_DIR    This is the root location for all Lomonosov data files.
;                  The Lomonosov software expects all data files to reside in specific subdirectories relative
;                  to this root directory.;
;
;   !LOMO.REMOTE_DATA_DIR   This is not implemented yet because there is no server at this point in time. 
;                  A URL will most likely be available after launch. 
;
;KEYWORDS:
;   RESET:           Reset !lomo to values in environment (or values in keywords).
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/lomonosov/lomo_init.pro $
;-

pro lomo_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir,$
  no_color_setup=no_color_setup

  def_struct = file_retrieve(/structure_format)
  
  defsysv,'!lomo',exists=exists

  if not keyword_set(exists) then begin; if !mms does not exist
    defsysv,'!lomo', file_retrieve(/structure_format)
  endif

  !lomo.local_data_dir = !lomo.local_data_dir + 'lomo/'
  !lomo.remote_data_dir = 'http://themis-data.igpp.ucla.edu/lomo/'   ; use as backup web server
  return
  
END

