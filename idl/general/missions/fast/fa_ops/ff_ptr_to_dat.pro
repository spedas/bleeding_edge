;+
; PRO: FF_PTR_TO_DAT, dat, tags=tags
;
; PURPOSE: Converts all pointer 'tags' to data arrays.
;
; CALLING: ff_ptr_to_dat,dat
; 	   Pretty simple! 
;
; INPUTS: A valid data structure.
;       
; KEYWORD PARAMETERS: 
; tags
; string[ N], if given, only the given tags are converted.
;
; OUTPUTS: Alters dat.
;
; INITIAL VERSION: REE 97_10_20
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
pro ff_ptr_to_dat, dat, tags=tags, streak=streak, double=double, talk=talk

; SET UP TAGS.
IF not keyword_set(tags) THEN BEGIN
    tags_all  = strlowcase(tag_names(dat))
    itag_all  = indgen(n_elements(tags_all))
    FOR i = 0, n_elements(tags_all) - 1 DO BEGIN
        IF ptr_valid( (dat.(itag_all(i)))(0) ) then BEGIN
            if n_elements(itag) GT 0 then itag=[itag,i] else itag=i
        ENDIF
    ENDFOR
    if n_elements(itag) GT 0 then tags = tags_all(itag)
ENDIF

; CHANGE ALL TAGS BACK TO BEING POINTERS
; THIS METHOD TAKES A LONG TIME ... PLEASE IMPROVE IF YOU CAN!
FOR  i=0,n_elements(tags)-1 do BEGIN
    tags_all = strlowcase(tag_names(dat))
    itag     = where(tags_all eq tags(i), should_be_one)
    IF (should_be_one EQ 1) THEN BEGIN
        temp = *dat.(itag(0))
        ;ptr_free, dat.(itag(0)) ; CAN'T DO THAT!
        add_str_element, dat, tags(i), /del
        add_str_element, dat, tags(i), temp
    ENDIF
ENDFOR

heap_gc

return
end
