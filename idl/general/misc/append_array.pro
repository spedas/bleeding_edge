;+
;PROCEDURE: append_array, a0, a1
;PURPOSE:
;   Append an array to another array.  Can also copy an array into a
;   subset of another. It is equivalent to :    a0 = [a0,a1];  but it doesn't fail if a0 is undefined (or 0)
;INPUT:
;   a0:   Array to be enlarged.
;   a1:   Array (or single value) to be appended to a0.
;KEYWORDS:
;   INDEX:  an input variable that will VASTLY improve performance when repeatedly appending a small array onto the end of a large array.
;        When using this keyword, the array a0 is enlarged a little bit more than needed so that subsequent appends of a1 will be
;        written into a0 instead of creating a new array each time.  The INDEX value represents the number of valid elements.
;        If INDEX is a named variable then it will be auto incremented.
;        If INDEX is not a named variable then the calling routine should set it using the NEW_INDEX output,
;        After all appending is completed, make the call:
;            append_array,a0,index=index
;        to truncate to the proper size.
;   NEW_INDEX:  Output, size of new array.  This can be used if index is NOT a named variable.  Don't use if INDEX is a NAMED variable
;   FILLNAN:  Set this keyword to fill padded values with NANs.
;   DONE: Equivalent to calling without the a1 argument.
;CREATED BY:    Davin Larson
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/append_array.pro $

;LAST MODIFIED: @(#)append_array.pro    1.6 98/08/13
;-
pro append_array,a0,a1,index=index,new_index=new_index,done=done,fillnan=fillnan,verbose=verbose,error=error

a0_set = keyword_set(a0) or size(/n_dimension,a0) ge 1    ; a0 is defined

if arg_present(index) or n_elements(index) ne 0 then begin

   dim0 = size(/dimension,a0)  &   n0 = dim0[0]>1
   dim1 = size(/dimension,a1)  &   n1 = dim1[0]>1

   if keyword_set(done) or (n_elements(a1) eq 0) then begin   ; truncate a0 properly
        new_index = dim0[0]  ; or n0 ?
        if not keyword_set(index) then return
        a0 = a0[0:index-1,*]
        return
    endif

    if dim0[0] eq 0 and keyword_set(a0) eq 0  then begin   ; Initialize if starting value of a0 is 0 or undefined.       [0] is valid array!
        a0 = [a1]
        index = n1
        new_index=index
        return
    endif

error = 0
if a0_set && size(/type,a0) ne size(/type,a1) then begin
   if debug(2) then printdat,a0,a1
   dprint,dlevel=2,verbose=verbose,'Incompatible types! Can not append'
   error = 1
   return
endif

if a0_set && n_tags(/length,a0) ne n_tags(/length,a1) then begin
   if debug(3) then printdat,a0,a1
   dprint,dlevel=2,verbose=verbose,'Incompatible structures! Can not append'
   error = 2
   return
endif

if a0_set && n_tags(a0) ne n_tags(a1) then begin
  if debug(3) then printdat,a0,a1
  dprint,dlevel=2,verbose=verbose,'Incompatible structures! Can not append'
  error = 2
  return
endif


if a0_set then begin
  dim0 = size(/dimen,a0)
  dim1 = size(/dimen,a1)
  if n_elements(dim0) eq 2 && n_elements(dim1) eq 2 && dim0[1] ne dim1[1] then begin
    dprint,dlevel=2,verbose=verbose,'Size mismatch'    
    error = 3
    return
  endif
endif

    if not keyword_set(index) then index = n0
    index = index < n0    ; safety net

    if n1+index gt n0 then begin
        xfactor = .5
        fill = keyword_set(fillnan) ?  fill_nan(a1[0]) : a1[0]
        if n_elements(dim1) ne n_elements(dim0) then begin
          dprint,dlevel=2,'Incompatible appending'
          if debug(3) then printdat,a0,a1
        endif
        dim = dim0
        add = floor(n0 * xfactor + n1)
        dim[0] = add
;        dprint,dlevel=4,"Enlarging array by ",add
        a0 = [a0,replicate(fill,dim)]
        n0=n0+add
    endif
    a0[index:index+n1-1,*] = a1
    index = index + n1
    new_index = index
    return
endif

if n_elements(a1) eq 0 then return

if keyword_set(a0) or size(/n_dimension,a0) ge 1 then a0=[a0,a1]  $
else  if size(/n_elements,a1) ge 1 then a0=[a1]

dim = size(/dimension,a0)
new_index = dim[0]

end



;;testing:

;a0= 0
;a1= findgen(1,3)
;ind = 0
;append_array,a0,a1++,index=ind,/fill  &  printdat,a0,a1,ind
;
;end

