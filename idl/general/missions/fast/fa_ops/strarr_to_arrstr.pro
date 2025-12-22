;+
; PROCEDURE: strarr_to_arrstr
;
; USAGE: strarr_to_arrstr, strarr, arrstr
;
; PURPOSE:
;     convert a structure of time-based arrays to a time-based array of structures
;
; INPUTS: 
;     strarr:
;         a structure, each tag of which contains a time-based array
;
; OUTPUTS:
;     arrstr:
;         the time-based array of structures that corresponds to the input structure
;         of time-based arrays, such that arrstr(i).(j) = (strarr.(j))(i).
;     
; DETAILS:
;     This routine is used in the building of a CDF file that is to contain the data
;     from a number of tplot structures that have been created with "store_data".
;     (See "make_cdf_structs.pro" and "makecdf.pro").
;     Make_cdf_structs.pro first builds a structure containing all the data values
;     that are to be written to the cdf (each tag of this structure is a time-based
;     array of data quantities), then this structure of time-based arrays is converted
;     into the equivalent time-based array of structures (using this routine), and this
;     resulting array of structures can then be used to call makecdf.pro, which
;     writes the cdf.
;
; SEE ALSO:
;     "make_cdf_structs.pro", "makecdf.pro"
;
; CREATED BY: Vince Saba
;
; LAST MODIFICATION: @(#)strarr_to_arrstr.pro	1.1 08/22/96
;-


pro strarr_to_arrstr, strarr, arrstr

tag_list = tag_names(strarr)
n_tags   = n_elements(tag_list)
for i = 0, n_tags - 1 do begin
    tag_name  = tag_list(i)
    tag_value = strarr.(i)
    val = tag_value(0,*,*,*,*,*)
    sz = size(val)
    if sz(0) ne 0 then val = reform(val)
    dim = dimen(tag_value)
    if i eq 0 then begin
	n_times = dim(0)
        element = create_struct(tag_name,val)
    endif else begin
	if dim(0) ne n_times then begin
	    message, 'str_to_arr: structure tags have different leading dim.'
	    return
	endif
        add_str_element, element, tag_name, val
    endelse
endfor

arrstr = replicate(element, n_elements(strarr.(0)))

for i = 0, n_tags - 1 do begin
    tag_name  = tag_list(i)
    lhs  = 'arrstr(*).' + tag_name
    rhs  = 'strarr.' + tag_name
    rhs = 'dimen_shift(' + rhs + ', -1)'
    stmt = lhs + ' = ' + rhs
    status = execute(stmt)
endfor

return
end

