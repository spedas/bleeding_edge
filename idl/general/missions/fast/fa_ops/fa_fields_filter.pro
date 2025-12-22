;+
;PROCEDURE:  FA_FIELDS_FILTER, $
;  dat, freq, mag=mag, db=db, recursive=recursive, 
;  poles=poles, tags=tags, buf_len=buf_len, min_dt=min_dt,
;  nan=nan, buf_dt=buf_dt 
;		       
;PURPOSE:   Filters the data COMP*.
; 
;INPUT:   
;	dat       - NEEDED. Fields data of any type.
;       freq      - NEEDED. Pole of filter. If band_pass: [f1,f2] f1<f2
;                 - If low-pass: [0,f]. If high-pass [f,0]
; 
; KEYWORDS: 
;       mag       - OPTIONAL. IF set, freq is % of Nyquist.
;                   Note: /MAG IGNORED in recursive filter. 
;       db        - OPTIONAL. If convol option is taken, default = 120. 
;       recursive - OPTIONAL. Use of recursive filter:
;                 - advantages: Faster and Mimics SDT.  
;                 - disadvantages: Causes phase shift.  
;       poles     - OPTIONAL. If recursive option is taken, 1-8 default = 8. 
;       tag       - OPTIONAL. The tag name(s) of the data to be filtered. 
;       buf_len   - OPTIONAL. The min stretch of continous data (DFLT = 10). 
;       min_dt    - OPTIONAL. Allowable error in timeing. Default=1.e-6, may
;                   want to set to 1.e-7 for HSBM.
;       nan       - OPTIONAL. If set, will NAN data near edges. 
;       buf_dt    - OPTIONAL. Allowable error in fa_fields_bufs call.
;
; USE: fa_fields_filter,dat,[0,1.0] ; Filter data to 1 Hz.
;
; RETURN: Filters the data in place.
;
;CREATED BY:	REE, 97-03-17 - modified 97-10-03 REE added buf_dt
;FILE:  fa_fields_filter.pro
;VERSION:  0.0
;LAST MODIFICATION:  
;REE 97-04-08, Added NAN option.
;-
pro fa_fields_filter, dat, freq, mag=mag,db=db, recursive=recursive, $
    poles=poles, tags=tags, buf_length=buf_length, min_dt=min_dt, nan=nan, $
    buf_dt=buf_dt

fnan = !values.f_nan

; Check that the dat is a structures.
IF data_type(dat) ne 8 then BEGIN
    message, /info,'Need FAST time series data structures as input.'
    return
ENDIF
     
; Check that the freq is given.
IF n_elements(freq) ne 2 then BEGIN
    message, /info,'Need to input a frequency pair.'
    return
ENDIF
freq = double(freq)

; Check keyword tags.
tagl = strlowcase(tag_names(dat))
IF not keyword_set(tags) then BEGIN
    list = where(strmid(tagl,0,4) eq 'comp',ntags) 
    IF ntags eq 0 then BEGIN
        message, /info,'Cannot find comp*.'
        return
    ENDIF
    tags = tagl(list)
ENDIF ELSE BEGIN
    IF (missing_tags(dat,tags,absent=absent) gt 0) then BEGIN
        message, /info,'Missing tags!.'
        return
    ENDIF
    ntags = n_elements(tags)
ENDELSE     

; Check for time tag.
IF (missing_tags(dat,'time',absent=absent) gt 0) then BEGIN
    message, /info,'Missing time in structure!.'
    return 
ENDIF

; Check if buf_len, db, or poles are set.
if n_elements(buf_len) ne 1 then buf_len=10
if n_elements(db) ne 1 then db = double(120)
if n_elements(poles) eq 0 then poles = [4,4]
if n_elements(poles) eq 1 then poles = [poles,poles]
if n_elements(poles) gt 3 then poles = [4,4]
poles = poles < 8
poles = poles > 1
if n_elements(min_dt) ne 1 then min_dt = double(1.e-6)
min_dt = double(min_dt)

; BREAK THE DATA INTO USABLE BUFFERS..
fa_fields_bufs,dat,buf_len,buf_starts=buf_starts,buf_ends=buf_ends, $
                          delta_t=buf_dt
nbufs = n_elements(buf_starts)

; DO CASE FOR CONVOL FIRST!
IF not keyword_set(recursive) then BEGIN

    ; START LOOP FOR BUFFERS.
    FOR i = 0, nbufs-1 do BEGIN

        ; For each buffer, calculate the digital filter cofs.
        dt = dat.time( buf_starts(i) + 1 ) - dat.time( buf_starts(i) )
        nyquist = 0.5d/dt
        if not keyword_set(mag) then f = double(freq/nyquist) else $
            f=double(freq)
        if f(1) le 0 then f(1) = 1.d
        fmin = min(f)
        if fmin eq 0 then fmin = f(1)

        npts = long(5.0/fmin) > 1
        npts = npts < 5000.
        cofs = digital_filter(f(0),f(1),db,npts)
        if f(0) eq 0 then cofs = cofs/total(cofs)
        start = buf_starts(i)
        stop = buf_ends(i)

        ; START LOOP FOR COMPONENTS - COMP1, COMP2, ...
        IF (stop-start) gt 2*npts+1 then BEGIN

            FOR j = 0, ntags-1 do BEGIN
                tag_num = where(tagl eq tags(j), better_be_one)
                tag_num = tag_num(0)

                ; CHECK NAN OPTION.
                IF keyword_set(nan) then BEGIN
                    dat.(tag_num)(start) = fnan 
                    dat.(tag_num)(stop) = fnan 
                    dat.(tag_num)(start:stop) = $
                        convol(dat.(tag_num)(start:stop),cofs,/edge_t)
                ENDIF ELSE BEGIN
                dat.(tag_num)(start:stop) = $
                    convol(dat.(tag_num)(start:stop),cofs,/edge_t )
                ENDELSE
            ENDFOR
        ENDIF
    ENDFOR
ENDIF

; Do recursive case.
IF keyword_set(recursive) then BEGIN

    ; START LOOP FOR COMPONENTS - COMP1, COMP2, ..
    FOR j = 0, ntags-1 do BEGIN
        tag_num = where(tagl eq tags(j), better_be_one)
        tag_num = tag_num(0)
        npts = n_elements(dat.(tag_num))
        x    = double(dat.(tag_num))
        freq1 = double(freq(0))
        freq2 = double(freq(1))
        npoles1 = long(poles(0))
        npoles2 = long(poles(1))

        status = call_external('libfastfieldscals.so', 'ff_filter', $
		x, $				; ARG 0
		double(dat.time), $		; ARG 1
		long(npts), $			; ARG 2
		freq1, $  			; ARG 3
		freq2, $  			; ARG 4
		npoles1, $  			; ARG 5
		npoles2, $  			; ARG 6
		min_dt) 			; ARG 7

        if (status ne 0) then dat.(tag_num) = x

    ENDFOR
ENDIF

return

END
