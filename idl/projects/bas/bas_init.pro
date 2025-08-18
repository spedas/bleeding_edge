;+
;NAME:    bas_init_private
;
;PURPOSE:
;   Initializes system variables for bas. Currently the variable only contains information
;   on the basin local data directory. Lot's more features should be added. See thm_init
;   for examples.
;
;NOTE:
;   The system variable !bas is defined here, just like !THEMIS.
;   The elements of this structure are explained below:
;
;   !bas.LOCAL_DATA_DIR    This is the root location for all bas data files.
;                  The bas software expects all data files to reside in specific subdirectories relative
;                  to this root directory.;
;
;   !bas.REMOTE_DATA_DIR   This is not implemented yet because there is no server at this point in time.
;                  A URL will most likely be available after launch.
;
;   *******
;   WARNING: This version of bas_init uses the remote data dir in the PRIVATE AREA
;   *******
;
;KEYWORDS:
;   RESET:           Reset !bas to values in environment (or values in keywords).
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/basin/common/bas_init.pro $
;-

pro bas_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir,$
  no_color_setup=no_color_setup

  def_struct = file_retrieve(/structure_format)

  defsysv,'!bas',exists=exists
  if not keyword_set(exists) then begin; if !bas does not exist
    defsysv,'!bas', def_struct
  endif

  thm_init
  
  ;#######################################################
  ; On initial call or reset
  ;#######################################################

  !bas = def_struct; force setting of all elements to default values.
  !bas.preserve_mtime = 0
  
  ; keywords on first call to bas_init (or /reset) override environment and
  ; bas_config
  local_data_dir = !bas.local_data_dir + 'bas/' 
  !bas.remote_data_dir = "http://psddb.nerc-bas.ac.uk/data/psddata/atmos/space/lpm/" 
  !bas.local_data_dir = spd_addslash(local_data_dir)

  ;----------------
  !bas.init = 1
  ;----------------

  return

END
