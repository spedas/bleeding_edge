;+
;PROCEDURE:   swe_snap_options
;PURPOSE:
;  Stores a structure of SWEA snapshot keyword options and provides
;  a mechanism for changing those options.  Keywords set by this
;  routine are persistent defaults in the SWEA snapshot routines.
;  They can be overridden by explicitly setting keywords in those
;  routines.
;
;  Call this routine from your idl_startup.pro to customize default
;  options for yourself.
;
;USAGE:
;  swe_snap_options, key
;
;INPUTS:
;       key:           Structure containing keyword(s) for any of the SWEA
;                      snapshot routines (engy, pad, 3d).  Unrecognized
;                      keywords can be added to the structure but will
;                      subsequently be ignored.
;
;                      {KEYWORD: value, KEYWORD: value, ...}
;
;KEYWORDS:
;       GET:           Set this to a named variable to return the current 
;                      default keyword structure (after changes, if any).
;
;       REPLACE:       If this keyword is set, then the input structure 
;                      replaces any existing structure.  Otherwise, the
;                      input structure is merged with any existing one.
;
;       DELETE:        An array of tag names to delete from the default
;                      keyword structure.
;
;       RESET:         Reset the default structure to something universally
;                      benign: {WSCALE: 1.}
;
;       LIST:          List the current keyword default structure.  This is
;                      the default when this routine is called without any
;                      inputs or keywords.
;
;       SILENT:        Suppresses output.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-03-02 10:38:37 -0800 (Tue, 02 Mar 2021) $
; $LastChangedRevision: 29725 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_snap_options.pro $
;-
pro swe_snap_options, key, get=get, replace=replace, delete=del, reset=reset, $
                           list=flist, silent=silent

  common snap_defaults, defkey

  list = size(key,/type) eq 0
  merge = ~keyword_set(replace)

  if keyword_set(silent) then list = 0

  if ((size(defkey,/type) eq 0) or keyword_set(reset)) then begin
    defkey = {wscale : 1.}  ; Snapshot window scale size (universal benign option)
    list = 0
  endif

  if (size(del,/type) eq 7) then begin
    for i=0,(n_elements(del)-1) do str_element, defkey, del[i], /delete
    list = 0
  endif

  if (size(key,/type) eq 8) then begin
    if (merge) then begin
      tag = tag_names(key)
      for i=0,(n_elements(tag)-1) do str_element, defkey, tag[i], key.(i), /add_replace
    endif else defkey = key
  endif

  if (list or keyword_set(flist)) then help, defkey

  get = defkey

  return

end
