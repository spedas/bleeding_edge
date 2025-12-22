;	@(#)missing_tags.pro	1.9	04/06/98
;+
; NAME: missing_tags
;
;
; PURPOSE: to check a structure for a set of required tags
;
;
; CALLING SEQUENCE: missing = missing_tags(my_structure,required_tags)
;
; 
; INPUTS: REQ_TAGS_CALL: a string or string array of tags to look for in the
;         structure STRUCT.  
;
;
; KEYWORDS: The keyword ABSENT can be used to return the mising tag
;           names. If no tags are missing, ABSENT contains the null
;           string on return. 
;           QUIET can be used to get MISSING_TAGS to not report
;           missing tags to the user.
;
; OUTPUTS: The number of missing tags is returned. A -1 is returned if
;           MISSING_TAGS was called incorrectly.
;
; MODIFICATION HISTORY: Written 23-July-1996 by Bill Peria, UCBerkeley
;                       Space Sciences Lab
;
;-
function missing_tags,struct,req_tags_call,absent = absent, quiet = quiet

quiet = keyword_set(quiet)
;
; check args...
;
req_tags = req_tags_call
;
; define absent, in case of early return...
;
absent = ''

if (idl_type(struct) ne 'structure') then begin
    if not quiet then message,'input structure is not a structure!',/continue
    return,-1
endif
if (idl_type(req_tags) ne 'string') then begin
    if not quiet then message,'REQ_TAGS must be of string type...',/continue
    return,-1
endif
;
; remove all whitespace from tags...
;
req_tags = [strlowcase(strcompress(req_tags,/remove_all))]
;
; check tags one-by-one
;
tags = strlowcase(tag_names(struct))
nrt = n_elements(req_tags)
ntags = n_elements(tags)
for i=0,nrt-1 do begin
    rlen = strlen(req_tags(i))
    bad = 0
    if (strpos(req_tags(i),'*') ge 0) then begin ; allow wildcard '*'
        strings = str_sep(req_tags(i),'*')
        nstr = n_elements(strings)
        match = indgen(ntags)   ; check all tags to start
        j=0
        pos = 0
        repeat begin
                                ; narrow the field
                                ; on each required substring
                                ; check if substring is at either end of req_tags(i)...
            slen = strlen(strings(j))
            pos = strpos(req_tags(i),strings(j),pos)
            if ((pos eq 0) or (pos eq (rlen-slen))) then begin
                if (pos eq 0) then begin
                    tmpmat = where(strmid(tags(match),pos,slen) eq $
                                   strings(j),nmat)
                endif else begin ; must match tag tails
                    tag_tails = strarr(ntags)
                    tlen = strlen(tags)
                    for k=0,ntags-1 do begin
                        tag_tails(k) = $
                          strmid(tags(k),tlen(k)-slen,slen)
                    endfor
                    tmpmat = where(tag_tails(match) eq strings(j),nmat)
                endelse
            endif else begin
                tmpmat = where(strpos(tags(match),strings(j)) ge $
                               0,nmat)
            endelse
            
            if nmat gt 0 then begin
                match = match(tmpmat)
            endif else begin
                match = -1      ; causes repeat loop to break
            endelse
            
            j = j + 1
        endrep until((j eq nstr) or  (match(0) eq -1))

        if match(0) eq -1 then bad = 1
    endif else begin
        chk = where(tags eq req_tags(i),nchk)
        if (nchk le 0) then bad = 1
    endelse
    
    if bad then begin
        if not quiet then begin
            message,'no '+strupcase(req_tags(i))+' tag in input ' + $
              'structure!',/continue
        endif
        
        if not defined(awol) then begin
            awol = req_tags(i)
        endif else begin
            awol = [awol,req_tags(i)]
        endelse
    endif
endfor

if defined(awol) then begin
    absent = awol
endif

return,n_elements(awol)

end

