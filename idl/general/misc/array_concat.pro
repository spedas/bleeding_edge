;+ 
;FUNCTION:
;  array_concat
;
;PURPOSE:
;  Performs array concatenation in a way that handles an empty list.
;  Simple code that gets duplicated everywhere.
;
;Inputs:
;  arg: The argument to be concatenated
;  array: The array to which it should be concatenated, or nothing
;  no_copy: Flag to effectively call array_concat( x, temporary(y) ), which 
;           throws an exception in IDL versions without the null variable.  
;
;Output:
;  [ array , arg ]
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-10 18:58:16 -0700 (Thu, 10 Sep 2015) $
;$LastChangedRevision: 18766 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/array_concat.pro $
;-

function array_concat,arg,array, no_copy=no_copy

  compile_opt idl2
  
  if undefined(array) then begin ;trying a *hopefully*, more reliable and more legible test-pcruce 2013-01-30
 ; if ~is_array(array) && ~keyword_set(array) then begin
    return,[arg]
  endif else begin
    if keyword_set(no_copy) then begin
      return, [temporary(array),arg]
    endif else begin
      return,[array,arg]
    endelse
  endelse

end

