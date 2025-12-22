;+
; PROCEDURE: FF_REDUCE, dat, t1, t2, tags=tags
;
; PURPOSE: Reduces data to time interval supplied. POINTER FRIENDLY!
;
; CALLING: ff_reduce,dat,t1,t2
;
; INPUTS: dat 		FAST time series structure with one to four comps.
; 	 		All time series data are OK. 
; 	  t1	 	Start time.
; 	  t2	 	End time.
;       
; KEYWORD PARAMETERS:  	
; 	  tags	 	If given, the tag names to be reduced.
;
; OUTPUTS: Will alter structure.
;
; SIDE EFFECTS: May blow memory.
;
; INITIAL VERSION: REE 97-12-22
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
pro ff_reduce, dat, t1,t2, tags=tags

; CHECK KEYWORDS.
IF data_type(dat) ne 8 then BEGIN
    message, /info,"Data must be a FAST time series structure."
    return
ENDIF

; SET UP TIME
IF n_elements(t1) eq 2 then BEGIN
    ts = t1(1)
    te = t1(0)
ENDIF ELSE BEGIN
    if n_elements(t1) eq 1 then ts = t1
    if n_elements(t2) eq 1 then te = t2
ENDELSE

IF n_elements(ts) ne 1 or n_elements(te) ne 1 then BEGIN
    message, /info,"Time must be supplied."
    return
ENDIF

; CHECK FOR TIME TAG.
IF (missing_tags(dat,'time') gt 0) then BEGIN
    message, /info,'Missing time in structure!.'
    return 
ENDIF

; CHECK TO SEE IF DATA ARE POINTERS
IF ptr_valid(dat.time(0)) then is_ptr=1 else is_ptr=0

; CHECK KEYWORD TAGS
IF not keyword_set(tags) then BEGIN
    tagl   = strlowcase(tag_names(dat))
    itagl  = indgen(n_elements(tagl))
    FOR i = 0, n_elements(tagl) - 1 DO BEGIN
        IF (is_ptr) then BEGIN
            IF ptr_valid((dat.(itagl(i)))(0)) THEN BEGIN
                IF n_elements(*dat.(itagl(i))) EQ dat.npts then BEGIN
                    if n_elements(itag) GT 0 then itag=[itag,i] else itag=i
                ENDIF
            ENDIF
        ENDIF ELSE BEGIN
            IF n_elements(dat.(itagl(i))) EQ dat.npts then BEGIN
                if n_elements(itag) GT 0 then itag=[itag,i] else itag=i
            ENDIF
    ENDELSE
    ENDFOR
    if n_elements(itag) GT 0 then tags = tagl(itag)
ENDIF

; GET A LIST OF INDECIES TO KEEP.
if (is_ptr) then $
     index = where( (*dat.time GE t1) AND (*dat.time LE t2), n_keep) $
     else index = where( (dat.time GE t1) AND (dat.time LE t2), n_keep)

; DO CASE WHERE n_keep = 0 
IF n_keep EQ 0 then BEGIN
    message, /info,'Time limits out of range.'
    message, /info,'No data to keep! Doing nothing.'
    return 
ENDIF

; DO CASE WHERE n_keep = dat.npts 
IF n_keep EQ 0 then BEGIN
    message, /info,'Time limits encompass all data.'
    message, /info,'No data to throw away! Doing nothing.'
    return 
ENDIF

; REDUCE THE TIME ARRAY
if (is_ptr) then time = ptr_new((*dat.time)(index)) ELSE BEGIN
    time = dat.time(index)
    add_str_element,dat, 'time', /del
ENDELSE

; START LOOP THROUGH COMPS.
ntags = n_elements(tags)
FOR i = 0, ntags-1 do BEGIN
    tagl = strlowcase(tag_names(dat))
    tag_num = where(tagl eq tags(i), better_be_one)
    IF (better_be_one EQ 1) THEN BEGIN
        tag_num = tag_num(0)
        IF (is_ptr) then BEGIN
            comp = ptr_new( (*dat.(tag_num))(index) )
            ptr_free, dat.(tag_num)
            dat.(tag_num) = comp
        ENDIF ELSE BEGIN
            comp = dat.(tag_num)(index)
            add_str_element,dat, tags(i), /del
            add_str_element,dat, tags(i), comp
        ENDELSE
    ENDIF
ENDFOR

if (is_ptr) then dat.time=time else add_str_element,dat, 'time', time
dat.npts = n_keep
if (is_ptr) then dat.start_time = (*dat.time)(0) $
    else dat.start_time = dat.time(0)
if (is_ptr) then dat.end_time = (*dat.time)(n_keep-1) $
    else dat.end_time = dat.time(n_keep-1)

return
END
