;+ 
;FUNCTION:
;    array_concat_wrapper
;
;PURPOSE:
;     Wrapper for the array_concat function -- correctly handles 
;     the case when the input array is an empty string
;
;Inputs:
;  arg: The argument to be concatenated
;  array: The array to which it should be concatenated, or nothing
;  
;Output:
;  array + arg
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2013-10-22 12:49:25 -0700 (Tue, 22 Oct 2013) $
;$LastChangedRevision: 13372 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/array_concat_wrapper.pro $
;
;-

function array_concat_wrapper, arg, array
    compile_opt idl2, hidden
    if (n_elements(array) eq 1 && array eq '') then undefine, array
    return, array_concat(arg, array)
end
