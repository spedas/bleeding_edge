;+
;
;Function: is_equal
;
;Purpose: determines if two inputs are equal
;         like array_equal, but inputs can be structs
;         Will descend structs within structs recursive
;         Requires names of fields within structs to be the same
;         
;         Does not descend pointers to verify targets, if two
;         different pointers have the same destination, it will return
;         false.  This may cause some problems, but it also prevents any infinite
;         looping that can occur with pointer objects.  (Future versions should fix this)
;         
;         Will not work on objects.It will always return false. (It should be made to)
;         
;         This is designed to be similar to the equal operation in LISP or Scheme.  A
;         high level equivalency operator that will test without halting regardless of input type.
;         
;         Does allow ambiguity between 0 element array and one element array
;         
;
;Inputs: a,b: can be anything
;
;Outputs: 1:yes 0:no
;
;Keywords: array_strict: set this if you don't want it to allow conflation of 0 dimensional types and 1 element arrays
;
;
;NOTES:
;        Right now this routine has only been tested to demonstrate its adequacy for use with the mini_language,
;        It should be used with other routines with caution.  If it ever reaches general purpose maturity, it will
;        be placed in a different ssl_general directory.
;        
;TODO:  1. Pointer & Object support needs to be added 
;       2.  Also struct tag strictness needs supported
;      
; $LASTCHANGEDBY: DAVIN-WIN $
; $LASTCHANGEDDATE: 2007-10-22 07:26:16 -0700 (MON, 22 OCT 2007) $
; $LASTCHANGEDREVISION: 1758 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/is_equal.pro $
;-

function struct_equal,a,b,array_strict=array_strict,nan=nan

  compile_opt hidden,idl2

  if ~keyword_set(array_strict) then begin
    at = [a]
    bt = [b]
  endif else begin
    at = a
    bt = b
  endelse

  if ~is_struct(at) || ~is_struct(bt) then begin
    return,0
  endif

  a_tags = tag_names(at)
  b_tags = tag_names(bt)
  
  if ~array_equal(a_tags,b_tags) then begin
    return,0
  endif
  
  for i = 0,n_elements(a_tags)-1L do begin
  
    if ~array_equal(size(at.(i)),size(bt.(i))) then begin
      return,0
    endif
  
    if ~is_equal(at.(i),bt.(i),nan=nan) then begin
      return,0
    endif
  endfor
  
  return,1
      
end

function is_equal,a,b,array_strict=array_strict,nan=nan

  compile_opt idl2

  if n_elements(a) eq 0 && n_elements(b) eq 0 then return, 1
  if n_elements(a) eq 0 || n_elements(b) eq 0 then return, 0
  
  if ~keyword_set(array_strict) then begin
    at = [a]
    bt = [b]
  endif else begin
    at = [a]
    bt = [b]
  endelse
  
  if ~array_equal(size(at),size(bt)) then return,0

;  if ~keyword_set(a) && ~keyword_set(b) then begin 
;  
;    if n_elements(a) ne 0 then begin
;      if ~keyword_set(array_strict) then begin
;        at = [a]
;      endif else begin
;        at = a
;      endelse
;    endif
;    
;    if n_elements(b) ne 0 then begin
;      if ~keyword_set(array_strict) then begin
;        bt = [b]
;      endif else begin
;        bt = b
;      endelse
;    endif
;  
;    if array_equal(size(at),size(bt)) then begin ;ambiguity here, keyword_set returns 0 for undefined variables or for '' or 0
;      return,1
;    endif else begin
;      return,0
;    endelse
;  
;  endif else if ~keyword_set(a) || ~keyword_set(b) then begin
;    return,0
;  endif
  
  if is_struct(at) then begin ;only need to check one, already verified that are same type
    return,struct_equal(at,bt,nan=nan)
  endif else begin
  
  
    if keyword_set(nan) then begin
      ;check equivalency of nans
      
      ;positive nan
      idx_a = where(finite(at,/nan,sign=1),a_cnt)
      idx_b = where(finite(bt,/nan,sign=1),b_cnt)
      
      if a_cnt ne b_cnt then return,0   
      if a_cnt gt 0 && ~array_equal(idx_a,idx_b) then return,0
     
      ;negative nan
      idx_a = where(finite(at,/nan,sign=-1),a_cnt)
      idx_b = where(finite(bt,/nan,sign=-1),b_cnt)
     
      if a_cnt ne b_cnt then return,0   
      if a_cnt gt 0 && ~array_equal(idx_a,idx_b) then return,0
      
      ;not nan
      idx_a = where(~finite(at,/nan),a_cnt)
      idx_b = where(~finite(bt,/nan),b_cnt)
      
      if a_cnt ne b_cnt then return,0
      
      if a_cnt gt 0 then begin
        return,array_equal(at[idx_a],bt[idx_b])
      endif
          
    endif else begin
      return,array_equal(at,bt)
    endelse
  endelse
  
end