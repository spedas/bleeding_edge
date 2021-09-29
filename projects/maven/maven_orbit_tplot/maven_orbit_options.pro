;+
;PROCEDURE:   maven_orbit_options
;PURPOSE:
;  Stores a structure of MAVEN_ORBIT keyword options and provides
;  a mechanism for changing those options.  Keywords set by this
;  routine are persistent defaults in the MAVEN_ORBIT routines.
;  They can be overridden by explicitly setting keywords in those
;  routines.
;
;  Call this routine from your idl_startup.pro to customize default
;  options for yourself.
;
;USAGE:
;  maven_orbit_options, key
;
;INPUTS:
;       key:           Structure containing keyword(s) for MAVEN_ORBIT_TPLOT 
;                      and MAVEN_ORBIT_SNAP.  Unrecognized keywords can be 
;                      added to the structure but will subsequently be ignored.
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
; $LastChangedDate: 2021-03-22 19:18:19 -0700 (Mon, 22 Mar 2021) $
; $LastChangedRevision: 29805 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_options.pro $
;-
pro maven_orbit_options, key, get=get, replace=replace, delete=del, reset=reset, $
                              list=flist, silent=silent

  @maven_orbit_common

  list = size(key,/type) eq 0
  merge = ~keyword_set(replace)

  if keyword_set(silent) then list = 0

  if ((size(optkey,/type) eq 0) or keyword_set(reset)) then begin
    optkey = {wscale : 1.}  ; Snapshot window scale size (universal benign option)
    list = 0
  endif

  if (size(del,/type) eq 7) then begin
    for i=0,(n_elements(del)-1) do str_element, optkey, del[i], /delete
    list = 0
  endif

  if (size(key,/type) eq 8) then begin
    if (merge) then begin
      tag = tag_names(key)
      for i=0,(n_elements(tag)-1) do str_element, optkey, tag[i], key.(i), /add_replace
    endif else optkey = key
  endif

  if (list or keyword_set(flist)) then help, optkey

  get = optkey

  return

end
