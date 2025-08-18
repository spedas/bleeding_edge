;+
;PROCEDURE:   options, str, tag_name, value
;PURPOSE:
;  Add (or change) an element of a structure.
;  This routine is useful for changing plotting options for tplot, but can also
;  be used for creating limit structures for other routines such as "SPEC3D"
;  or "CONT2D"
;
;INPUT:
;  str:
;    Case 1:  String (or array of strings)
;       The limit structure associated with the "TPLOT" handle name is altered.
;       Warning!  wildcards accepted!  "*" will change ALL tplot quantities!
;    Case 2:  Number (or array of numbers)
;       The limit structure for the given "TPLOT" quantity is altered.  The
;       number/name association is given by "TPLOT_NAMES"
;    Case 3:  Structure or not set (undefined or zero)
;       Structure to be created, added to, or changed.
;  tag_name:     string,  tag name for value.
;  value:    (any type or dimension) value of new element.
;NOTES:
;  if VALUE is undefined then it will be DELETED from the structure.
;  if TAG_NAME is undefined, then the entire limit structure is deleted.
;
;KEYWORDS:
;  DEFAULT:  If set, modify the default limits structure rather than the
;	    regular limits structure (tplot variables only).
;SEE ALSO:
;  "GET_DATA","STORE_DATA", "TPLOT", "XLIM", "YLIM", "ZLIM", "STR_ELEMENT"
;
;CREATED BY:	Jasper Halekas
;Modified by:   Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-03-06 23:44:21 -0800 (Mon, 06 Mar 2023) $
; $LastChangedRevision: 31594 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/options.pro $

;
;-
;obsolete:
;  DELETE:  If set, then the corresponding tag_name is removed.
;  GET:	    If set, return the current value for the tag name in a
;	    structure or array of structures.  To use this keyword, the
;	    value variable must be previously defined.

pro options, struct, tag_name, value,default=default,_extra=ex,verbose=verbose ;,get=get, delete=delete
@tplot_com


;if keyword_set(delete) then message,/info,'Unnecessary use of DELETE keyword'
;
;if keyword_set(get) then begin
;dprint,'Unnecessary use of get keyword'
;   n = n_elements(struct)
;   value = value(0)
;   for i=0,n-1 do begin
;      get_data,struct(i),alimit=limit
;      str_element,limit,tag_name,value=v
;      value = [value,v]
;   endfor
;   value=value(1:n)
;   return
;endif


if size(/type,value) eq 0 and not keyword_set(ex) then delete=1
dt = size(/type,struct)
if (dt eq 8) || (dt eq 11) || ~keyword_set(struct) then begin
    if keyword_set(tag_name) then $
        str_element, struct, tag_name, value  ,delete=delete, /add  $
    else  extract_tags,struct,ex
endif else begin
    names = tnames(struct,n)                              ;  (tplot variable)
    for i=0L,n-1 do begin
        name = names[i]
        if keyword_set(default) then $
           get_data,name,dlimit = limit     $        ;  get stored limit
        else  $
           get_data,name,limit = limit             ;  get stored limit
        if keyword_set(tag_name) then $
           str_element, limit, tag_name, value  ,delete=delete, /add  $
        else  extract_tags,limit,ex
        if keyword_set(default) then $
           store_data,name,dlimit = limit   $        ;  store new structure
        else  $
           store_data,name,limit = limit
    endfor
    if n eq 0 then dprint,dlevel=2,verbose=verbose,'No TPLOT names found that match: '+string(/print,struct)
endelse
return
end
