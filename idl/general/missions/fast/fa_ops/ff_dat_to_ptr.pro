;+
; PRO: FF_DAT_TO_PTR, dat, tags=tags, streak=streak, double=double
;
; PURPOSE: Converts all 'tags' to pointers. These include all arrays which
; 	   are length npts if npts > 100. Will convert streaks if asked.
;
; CALLING: fu_dat_to_ptr,dat, /streak, /double
; 	   Pretty simple! 
;
; INPUTS: A valid FAST fields data structure.
;       
; KEYWORD PARAMETERS: 
;           tags - 	OPTIONAL. If given, only tags are converted.
;           streak -    OPTIONAL. IF set, 'STREAK*' will be converted to ptr.
;           double -    OPTIONAL. IF set, 'COMP*' will be converted to double.
;
; OUTPUTS: Alters dat.
;
; INITIAL VERSION: REE 97_10_20
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
pro ff_dat_to_ptr, dat, tags=tags, streak=streak, double=double, talk=talk

if data_type(dat) NE 8 then return

; SET UP TAGS.
IF not keyword_set(tags) THEN BEGIN
    tags_all  = strlowcase(tag_names(dat))
    itag_all  = indgen(n_elements(tags_all))
    FOR i = 0, n_elements(tags_all) - 1 DO BEGIN
        IF n_elements(dat.(itag_all(i))) EQ dat.npts then BEGIN
            if n_elements(itag) GT 0 then itag=[itag,i] else itag=i
             
        ENDIF
    ENDFOR
    if n_elements(itag) GT 0 then tags = tags_all(itag)
ENDIF

IF keyword_set(streak) then BEGIN
    tags_all  = strlowcase(tag_names(dat))
    itag_strk = where(strmid(tags_all,0,6) eq 'streak',nstrk)
    IF nstrk GT 0 then BEGIN
        if n_elements(tags) GT 0 then tags=[tags,tags_all(itag_strk)] $
        else tags = tags_all(itag_strk)
    ENDIF
ENDIF

IF keyword_set(double) then BEGIN
    tags_all  = strlowcase(tag_names(dat))
    itag_strk = where(strmid(tags_all,0,4) eq 'comp',nstrk)
    IF nstrk GT 0 then BEGIN
        if n_elements(tags) GT 0 then tags=[tags,tags_all(itag_strk)] $
        else tags = tags_all(itag_strk)
    ENDIF
ENDIF

; NOW CONVERT TO POINTERS OR DOUBLE
FOR  i=0,n_elements(tags)-1 do BEGIN
    tags_all = strlowcase(tag_names(dat))
    itag     = where(tags_all eq tags(i), should_be_one)
    IF (should_be_one EQ 1) THEN BEGIN

        ; CASE WHERE ELEMENT IS A POINTER AND KEYWORD_SET DOUBLE.
        if ( ptr_valid( dat.(itag(0))(0) )    ) AND $
           ( keyword_set(double)              ) AND $
           ( strmid(tags(i),0,4) EQ 'comp'    ) then $
             IF ( data_type( *dat.(itag(0)) ) NE 5 ) then BEGIN
                 temp = ptr_new( double( *dat.(itag(0)) ) )
                 ptr_free, dat.(itag(0)) 
                 dat.(itag(0)) = temp
             ENDIF

        ; CASE WHERE ELEMENT IS NOT A POINTER
        IF NOT ptr_valid( dat.(itag(0))(0) ) then BEGIN
             if ( keyword_set(double)      ) AND $
                ( strmid(tags(i),0,4) EQ 'comp' ) then $
                  temp = ptr_new( double( dat.(itag(0)) ) ) $
             else temp = ptr_new( dat.(itag(0)) )
             add_str_element, dat, tags(i), /del
             add_str_element, dat, tags(i), temp
        ENDIF   

    ENDIF
ENDFOR

return
end
