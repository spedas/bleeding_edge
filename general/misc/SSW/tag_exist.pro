;+
; Project     : SOHO - CDS     
;                   
; Name        : TAG_EXIST()
;               
; Purpose     : To test whether a tag name exists in a structure.
;               
; Explanation : Routine obtains a list of tagnames and tests whether the
;               requested one exists or not. The search is recursive so 
;               if any tag names in the structure are themselves structures
;               the search drops down to that level.  (However, see the keyword
;		TOP_LEVEL).
;               
; Use         : IDL>  status = tag_exist(str, tag)
;    
; Inputs      : str  -  structure variable to search
;               tag  -  tag name to search for
;               
; Opt. Inputs : None
;               
; Outputs     : Function returns 1 if tag name exists or 0 if it does not.
;               
; Opt. Outputs: None
;               
; Keywords    : INDEX	  = Index of matching tag
;
;		TOP_LEVEL = If set, then only the top level of the structure is
;			    searched.
;               RECURSE  = set to recurse on nested structures
;               
; Category    : Util, structure
;
; Written     : C D Pike, RAL, 18-May-94
;               
; Modified    : Version 1.1, D Zarro, ARC/GSFC, 27-Jan-95
;               Passed out index of matching tag
;		Version 2, William Thompson, GSFC, 6 March 1996
;			Added keyword TOP_LEVEL
;               Version 2.1, Zarro, GSFC, 1 August 1996
;                       Added call to help 
;               Version 3, Zarro, EIT/GSFC, 3 June 2000
;                       added check for input array structure
;               Version 4, Zarro, EIT/GSFC, 23 Aug 2000
;                       removed calls to DATATYPE
;               Version 5, Zarro, EIT/GSFC, 29 Sept 2000
;                       added /quiet
;               Version 6, Zarro (EER/GSC), 22 Dec 2002
;                       made recursion NOT the default
;               Removed datatype calls, jmm, 4-jun-2007 
;-            

function tag_exist, str, tag, index = index, top_level = top_level, $
                    quiet = quiet, recurse = recurse

;dprint,'% TAG_EXIST: ', get_caller()

loud=1-keyword_set(quiet)


if n_params() lt 2 then begin
   if loud then print,'Use:  status = tag_exist(structure, tag_name)'
   return,0b
endif

;
;  check quality of input
;

sz=size(str)
stype=sz(n_elements(sz)-2)
sz=size(tag)
dtype=sz(n_elements(sz)-2)
if (stype ne 8) or (dtype ne 7) then begin
  if loud then begin
   if stype ne 8 then help,str
   if dtype ne 7 then help,tag
   print,'Use: status = tag_exist(str, tag)'
   print,'str = structure variable'
   print,'tag = string variable'
  endif
   return,0b
endif

i=-1
tn = tag_names(str)
nt = where(tn eq strupcase(tag)) & index=nt[0]
if nt[0] eq -1 then begin
   status = 0b
   if (not keyword_set(top_level)) and keyword_set(recurse) then begin
      for i=0,n_elements(tn)-1 do begin
       sz=size(str[0].(i))
       dtype=sz(n_elements(sz)-2)
       if dtype eq 8 then $
		status=tag_exist(str[0].(i),tag,index=index)
        if status eq 1b then return,status
      endfor
   endif
   return,0b
endif else begin
   return,1b
endelse
end
