;+
; $LastChangedBy: nikos $
; $LastChangedDate: 2025-01-06 11:01:53 -0800 (Mon, 06 Jan 2025) $
; $LastChangedRevision: 33045 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/strfilter.pro $
;-
;FUNCTION:
;  res =  strfilter(stringarray,searchstring)
;PURPOSE:
;  Returns the subset of stringarray that matchs searchstring
;  '*' will match all (non-null) strings
;  ''  will match only the null string
;  Output can be modified with keywords
;  NOTE: this routine is very similar to the STRMATCH routine introduced in IDL 5.3
;     it has some enhancements that make it useful.
;     (i.e.: filterstring can also be an array)
;INPUT:
;  stringarray:  An array of strings to be filtered
;  searchstring: A string that may contain wildcard characters ("*")
;           (If searchstring is an array then results are OR'd together)
;RETURN VALUE:
;  Either:
;     Array of matching strings.
;  or:
;     Array of string indices.
;  or:
;     Byte array with same dimension as input string.
;  Depends upon keyword setting (See below)
;
;KEYWORDS:
;  FOLD_CASE: if set then CASE is ignored.   (only IDL 5.3 and later)
;  STRING: if set then the matching strings are returned.  (default)
;  INDEX:  if set then the indices are returned.
;  BYTES:  if set then a byte array is returned with same dimension as input string array (similar to STRMATCH).
;  NEGATE: pass only strings that do NOT match.
;  DELIMITER: Set this to a delimiter that will break searchstring into an array of searchstrings
;  COUNT:  A named variable that will contain the number of matched strings.
;  NO_MATCH:  A named variable that will contain either a subset of searchstring that
;             failed to match stringarray, an array of indices to that subset, or a
;             byte array whose dimensions match the number of elements in searchstring.
;             The data type returned will match that of the return value.
;             (only IDL 5.3 and later)
;Limitations:
;  This function still needs modification to accept the '?' character
;  July 2000;  modified to use the IDL strmatch function so that '?' is accepted for versions > 5.4
;EXAMPLE:
;  Print,strfilter(findfile('*'),'*.pro',/negate) ; print all files that do NOT end in .pro
;AUTHOR:
;  Davin Larson,  Space Sciences Lab, Berkeley; Feb, 1999
;VERSION:  01/10/08
;-
function strfilter,str,matchs,count=count,wildcard=wildcard,fold_case=fold_case,  $
  delimiter=delimiter,no_match=no_match,null = null,  $
  index=index,string=retstr,byte=bt,negate=negate

  if !version.release ge '5.3' then begin
    if ~isa(str) then return,!null
    matcharray = keyword_set(matchs) ? matchs : ''
    if keyword_set(delimiter) and size(/dimen,matcharray) eq 0 then $
      matcharray = strsplit(matcharray,delimiter,/extract)
    if keyword_set(wildcard) then dprint,'Wildcard "'+wildcard+'" ignored'

    ;initialize vars for return values and substrings with no matches
    ret = 0b
    missed = replicate(1b, n_elements(matcharray))

    ;loop over substrings to find matches within the array
    for k=0L,n_elements(matcharray)-1L do begin
      new = strmatch(str,matcharray[k],fold_case=fold_case)
      ret = new or ret
      if total(new) gt 0 then missed[k] = 0b
    endfor

    ;pass back info on which searches found no matches,
    ;the type of data passed back should match that of the return value
    midx = where(missed, nm)
    no_match = nm gt 0  ?  matcharray[midx] : ''
    if keyword_set(string) then no_match = no_match
    if keyword_set(index) then no_match = midx
    if keyword_set(bt) then no_match = missed

  endif else begin   ; Old version follows:

    ns = strlen(str)
    ret = ns eq -1   ; set to 0

    if not keyword_set(wildcard) then wildcard='*'

    for k=0L,n_elements(matchs)-1 do begin
      match = matchs[k]

      ;mss=str_sep(match,wildcard)
      mss=strsplit(match,wildcard,/extract)
      nmss= keyword_set(match) ? n_elements(mss) : 0

      ;quick test to improve speed,  required to find a null string
      if match eq wildcard then begin
        ret[*] = 1
        goto,skip   ; pass all strings
      endif

      ;quick test to improve speed, but not required
      if nmss eq 1 then begin        ;no wildcards to match do the simple thing
        ret = (str eq match) or ret
        goto,skip
      endif

      lms = strlen(mss)

      for i=0L,n_elements(str)-1 do begin    ; Unfortunately strmid and strpos don't allow pos to be vectors
        temp = str[i]                     ; so an extra loop is required here
        p = 0
        for j=0L,nmss-1 do begin
          p2 = (j lt nmss-1) ? strpos(temp,mss[j],p) : strpos(temp,mss[j],/REVERSE_SEARCH)
          if j eq 0 then r = (p2 eq 0) else r = (p2 ge p)
          p = p2 + lms[j]
          if r eq 0 then goto,break
        endfor
        r = p eq ns[i]
        break:
        ret[i]= ret[i] or r
      endfor
      skip:

    endfor
  endelse    ; end of old version

  if keyword_set(negate) then ret = (ret eq 0)
  if n_elements(null) ne 0 then begin
    ind = where(ret,count, null=null)
  endif else begin
    ind = where(ret,count)
  endelse
  nstr = count eq 0 ?  '' : str[ind]
  if keyword_set(retstr) then return, nstr
  if keyword_set(index)  then return, ind
  if keyword_set(bt)     then return, ret
  ;message,/info,'Please use KEYWORD, default will change to STRING'
  return,nstr   ; this default may change!
end

