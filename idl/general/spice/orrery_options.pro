;+
;PROCEDURE:   orrery_options
;PURPOSE:
;  Stores a structure of ORRERY keyword options and provides a
;  mechanism for changing those options.  Keywords set by this
;  routine are persistent defaults.  They can be overridden by
;  explicitly setting keywords in ORRERY.
;
;  Call this routine from your idl_startup.pro to customize default
;  options for yourself.
;
;USAGE:
;  orrery_options, key
;
;INPUTS:
;       key:           Structure containing keyword(s) for ORRERY.
;                      Unrecognized keywords are simply ignored.
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
;                      benign: {SCALE: 1.}
;
;       LIST:          List the current keyword default structure.  This is
;                      the default when this routine is called without any
;                      inputs or keywords.
;
;       SILENT:        Suppresses output.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-07-29 17:09:18 -0700 (Tue, 29 Jul 2025) $
; $LastChangedRevision: 33509 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/orrery_options.pro $
;-
pro orrery_options, key, get=get, replace=replace, delete=del, reset=reset, $
                         list=flist, silent=silent

  common planetorb, planet, css, i3a, sta, stb, sorb, psp, mvn, orrkey, madeplot

  list = size(key,/type) eq 0
  merge = ~keyword_set(replace)

  if keyword_set(silent) then list = 0

  if ((size(orrkey,/type) eq 0) or keyword_set(reset)) then begin
    orrkey = {scale : 1.}  ; Snapshot window scale size (universal benign option)
    list = 0
  endif

  if (size(del,/type) eq 7) then begin
    for i=0,(n_elements(del)-1) do str_element, orrkey, del[i], /delete
    list = 0
  endif

  if (size(key,/type) eq 8) then begin
    if (merge) then begin
      tag = tag_names(key)
      for i=0,(n_elements(tag)-1) do str_element, orrkey, tag[i], key.(i), /add_replace
    endif else orrkey = key
  endif

  if (list or keyword_set(flist)) then help, orrkey

  get = orrkey

  return

end
