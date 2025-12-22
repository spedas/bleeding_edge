;+
; PROCEDURE: FA_FIELDS_COMBINE, dat1, dat2, result=result, add=add, $
;                   delt_t=delt_t, interp=interp, spline=spline, 
;                   tag_2=tag_2, talk=talk 
;                   tag_1=tag_1, time_offset=time_offset, svy=svy
;
; PURPOSE: Combines two time series data structures into one for dcE
;          analysis or cross-spectral analysis, etc.
;
; INPUT:   
;	dat1 -     MASTER data. dat1.time is used if /interp or dt options
;                  are used
;	dat2 -     .comp1 is put into result or are added to dat1 as 
;                  comp(n+1) if /add. For now, no
;                  multi-component data.
;
; KEYWORDS: 
;       result -      dat2.comp1 time aligned with dat1.time.
;       add -         Will cause result to be added to dat1 structure.
;                     Using /add is very slow!
;       delt_t -      Allowable delta t to determine a time match.
;                     This is interpreted as allowable gap in interpolate 
;                     and spline modes.
;       interp -      Interpolate dat2 values to dat1 times. 
;       spline -      Spline dat2 values to dat1 times. will not extrapolate.
;       tag_1 -       The new component label in dat1 such as 'phase'.
;                     If blank 'comp(n+1)' is used.
;       tag_2 -       The tag name in dat2 to be added (e.g. 'comp3') to
;                     dat1 structure. If not given, 'comp1' is assumed.
;       time_offset - Subtract time_offset from dat2.time to help match time.
;       svy -         Survey data. delt_t set to 0.9 of time step in dat1.
;       talk -        Prints out diagnostic messages.
;
; CALLING: fa_fields_combine,V58,V12,/svy,/add          ; Survey data.
;          Add phase to V58.
;          fa_fields_combine,V58,PHI,tag1='PHASE',/interp,delt_t=100., /add
;
; OUTPUT: Result or comp(n+1) in dat1: IDL fields time series data 
;         structure with multiple components. 
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-03-03
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
pro fa_fields_combine, dat1, dat2, result=result, add=add, $
             delt_t=delt_t, interp=interp, spline=spline, talk=talk, $
             tag_2=tag_2, tag_1=tag_1, time_offset=time_offset, svy=svy

; Check that the data are structures.
IF (data_type(dat1) ne 8) or (data_type(dat2) ne 8) then BEGIN
    print,'FA_FIELDS_COMBINE: STOPPED.'
    print,'Need two FAST time series data structures as input.'
    return
ENDIF
     
; Check data tags.
if not keyword_set(tag_1) then $
    tag_1 = strcompress('comp' + string(dat1.ncomp+1), /rem) 
if not keyword_set(tag_2) then tag_2='comp1'

; SET UP TAG
tags = strlowcase(tag_names(dat2))
tag2_n = where(tags eq tag_2, ntags)
IF ntags ne 1 then BEGIN
    print,'FA_FIELDS_COMBINE: STOPPED.'
    print,'Cannot find dat2 tag name: ',tag_2
    return
ENDIF
tag2_n=tag2_n(0)

; Set up the number of points.
npts1 = n_elements(dat1.time)
npts2 = n_elements(dat2.time)

; Set up array in double precision.
result = dblarr(npts1)
result(*) = !values.d_nan

IF (n_elements(dat2.(tag2_n)) ne npts2) then BEGIN
    print,'FA_FIELDS_COMBINE: STOPPED.'
    print,'Size of dat2 data array does not match size of time array.'
    return
ENDIF

; Check the rest of the call_external values.

if not keyword_set(delt_t) then begin
 if keyword_set(spline) then delt_t = 1.0d else delt_t = double(1.0e-5)
endif
if not keyword_set(time_offset) then time_offset = 0.d
if not keyword_set(svy) then svy = 0l else svy=1l
if svy then delt_t = 0.05d
ratio = 0.9d
IF (keyword_set(interp) and keyword_set(spline)) then BEGIN
    print, 'FA_FIELDS_CONBINE: STOPPED.'
    print, 'Both interp and spline keywords cannot be set at once.'
    return
ENDIF

if not keyword_set(interp) then interp = 0l else interp = 1;
if keyword_set(spline) then interp = 2l

    status = call_external('libfastfieldscals.so', 'ff_time_align', $
		dat1.time, $			; ARG 0
		result, $			; ARG 1
		long(npts1), $			; ARG 2
		(dat2.time-time_offset), $	; ARG 3
		double( dat2.(tag2_n) ), $	; ARG 4
		long(npts2), $			; ARG 5
		double(delt_t), $		; ARG 6
		long(svy), $			; ARG 7
		double(ratio), $		; ARG 8
		long(interp) )			; ARG 9

; Check if the call was successful.
if keyword_set(talk) then $
    print, "npts1 = ", npts1, "npts2 = ", npts2, "matched = ", status
if status le 0 then return
 
if data_type(dat2.(tag2_n)) eq 4 then result = float(result)

; Add data to dat1.
IF keyword_set(add) then BEGIN
    add_str_element, dat1, 'DEPTH', /del
    add_str_element, dat1, 'DEPTH', lonarr(dat1.ncomp+1)
    dat1.ncomp = dat1.ncomp + 1

    junk = create_struct(tag_1+'_NAME', dat2.data_name, tag_1+'_UNITS', $
                     dat2.units_name,  tag_1+'_CAL', dat2.CALIBRATED) 
    dat1 = create_struct(dat1,junk)
    add_str_element, dat1, tag_1, result
ENDIF
return
END

