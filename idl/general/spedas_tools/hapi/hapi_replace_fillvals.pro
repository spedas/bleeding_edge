pro hapi_replace_fillvals, data_array, fillval, varname
  compile_opt idl2

  if n_elements(varname) eq 0 then varname = '<unknown>'
  if n_elements(data_array) eq 0 then return
  if n_elements(fillval) eq 0 then return

  ; Complete conversion before modifying any data.
  ; CATCH also handles errors from LIST::ToArray.
  catch, error_status
  if error_status ne 0 then goto, bad_conversion
  on_ioerror, bad_conversion

  if isa(fillval, 'LIST') then begin
    numeric_fillval = fillval.ToArray(type=5)
  endif else begin
    numeric_fillval = double(fillval)
  endelse

  on_ioerror, null
  catch, /cancel

  if n_elements(numeric_fillval) eq 0 then return

  fill_ndim = size(numeric_fillval, /n_dimensions)

  ; Scalar fill value: apply everywhere.
  if fill_ndim eq 0 then begin
    ; NaNs already have the desired replacement value.
    ; Skip the comparison to avoid "illegal operand" warnings under Windows
    if finite(numeric_fillval, /nan) then return
    idx = where(data_array eq numeric_fillval, count, /l64)
    if count gt 0 then data_array[idx] = !values.d_nan
    return
  endif

  message, 'Array-valued fill for ' + varname + $
    ' may not be standard-compliant.', /informational

  ; Array fill shape must match the dimensions after time.
  data_ndim = size(data_array, /n_dimensions)
  data_dims = size(data_array, /dimensions, /l64)
  fill_dims = size(numeric_fillval, /dimensions, /l64)

  if data_ndim ne (fill_ndim + 1) then begin
    message, 'Fill shape does not match data dimensions after time for ' + $
      varname + '; skipping replacement.', /informational
    return
  endif

  if array_equal(fill_dims, data_dims[1:*]) eq 0 then begin
    message, 'Fill shape does not match data dimensions after time for ' + $
      varname + '; skipping replacement.', /informational
    return
  endif

  n_times = data_dims[0]
  n_components = n_elements(numeric_fillval)

  ; Flatten only the component dimensions.
  work = reform(data_array, n_times, n_components)
  flat_fill = reform(numeric_fillval, n_components)

  for i = 0LL, n_components - 1LL do begin
    ; NaNs already have the desired replacement value.
    ; Skip the comparison to avoid "illegal operand" warnings under Windows
    if finite(flat_fill[i], /nan) then continue
    idx = where(work[*, i] eq flat_fill[i], count, /l64)
    if count gt 0 then work[idx, i] = !values.d_nan
  endfor

  ; REFORM is not a NumPy view: explicitly assign the result back.
  data_array = reform(work, data_dims)
  return

  bad_conversion:
  conversion_message = !error_state.msg
  on_ioerror, null
  catch, /cancel
  message, /reset
  message, 'Cannot convert fill for ' + varname + ': ' + $
    conversion_message + '; skipping replacement.', /informational
  return
end