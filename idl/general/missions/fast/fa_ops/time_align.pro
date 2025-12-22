;+
; PROCEDURE: time_align, tplist
;
; PURPOSE: interpolate a colloction of stored data so that they have a common time array
;
; INPUTS:
;     tplist:
;         an array of either tplot numbers of tplot names
;     
; KEYWORDS:
;     times:
;         an array of times to which all the tplot variables will be interpolated.
;         if this keyword is not set, its default value is the 'x' component of the
;         first tplot variable in the argument 'tplist'.
;     overwrite:
;         if set, store all the interpolated variables with the same names as the
;         original input variables.
;     output_names:
;         this keyword parameter must be set if the keyword parameter 'overwrite' is
;         not set.  It is a list of strings giving the names under which all the
;         interpolated variables should be stored.
;     status:
;         if set, a value of 0 will be written to this variable if the procedure
;         executes normally, else a value of -1 will be written to this variable.
;         It is suggested that, in general, this keyword parameter always be set
;         in order for the user to determine if this procedure completed normally.
;
; CREATED BY: Vince Saba, 09/96
;
; LAST MODIFICATION: @(#)time_align.pro	1.2 10/23/96
;-


; time align all the specified tplot variables to the same time array,
; and store the resulting data.
pro time_align, tplist, $
    times=times, $
    overwrite=overwrite, $
    output_names=output_names, $
    status=status
@tplot_com.pro

status = -1

; if tplist is a list of tplot numbers, convert it into a list of tplot names
if (data_type(tplist) ge 1) and (data_type(tplist) le 3) then begin
    tplist = [data_quants(tplist).name]
endif

if keyword_set(overwrite) then begin
    output_names = tplist
endif else begin
    if n_elements(output_names) ne n_elements(tplist) then begin
        message, /info, 'time_align:  output_names array is the wrong size.'
        return
    endif
endelse

; loop over each of the tplot variables, doing the interpolations
for i = 0, n_elements(tplist) - 1 do begin
    name = tplist(i)
    get_data, name, data=data, limit=limit
    outdata = data
    if n_elements(limit) ne 0 then outlimit = limit else outlimit = 0

    if i eq 0 then begin
        if not keyword_set(times) then times = data.x
    endif

    outdata.x = times
    ;print, 'time_align: outdata.x = ', outdata.x

    ; interpolate data.y, using the times array
    ;print, 'just before calling data_cut'
    ;print, 'data.y = ', data.y
    ;print, 'times  = ', times
    outdata.y = data_cut(data, times)
    ;print, 'outdata.y = ', outdata.y

    ; if data has a field named 'v', interpolate it if data.v is time variant
    tags = tag_names(data)
    for j = 0, n_elements(tags) - 1 do begin
	if tags(j) eq 'v' then begin
	    y_dims  = dimen(data.y)
	    y_ndims = ndimen(data.y)
	    v_dims  = dimen(data.v)
	    v_ndims = ndimen(data.v)

	    ; case of v scalar
	    if (v_ndims eq 0) then variance = 0

	    ; case of v 1-D and y 1-D
	    if (v_ndims eq 1) and (y_ndims eq 1) and (v_dims(1) eq y_dims(1)) then variance = 1

	    ; case of v 1-D, and y 2-D
	    if (v_ndims eq 1) and (y_ndims eq 2) and (v_dims(1) eq y_dims(2)) then variance = 0

	    ; case of v 2-D and y 2-D
	    if (v_ndims eq 2) and (y_ndims eq 2) and $
		(v_dims(1) eq y_dims(1)) and (v_dims(2) eq y_dims(2)) then variance = 1

	    ; account for all other cases
	    if n_elements(variance) eq 0 then begin
		message, /info, 'time_align: can not figure out if v is time variant or not.'
		return
	    endif

	    outdata.v = data_cut({x:data.x, y: data.v}, times)
	endif
    endfor
    ;print, 'outdata = ', outdata
    store_data, output_names(i), data=outdata, limit=outlimit
endfor

status = 0
return
end

