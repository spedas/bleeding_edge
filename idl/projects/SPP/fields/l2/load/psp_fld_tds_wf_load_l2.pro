pro psp_fld_tds_wf_load_l2, files, _extra = _extra
  compile_opt idl2

  if n_elements(files) eq 0 then begin
    print, 'No input files!'

    return
  endif

  cdf2tplot, files, /get_support, _extra = _extra

  ex_flags_all = tnames('*Exists_Flag')

  ex_flags = []

  ; If a TDS channel is switched in the middle of the day, the
  ; corresponding Time_Series value is sometimes loaded with
  ; mismatched dimensions. This is a workaround to fix the problem by
  ; using the Exists_Flag values to identify the valid data points in
  ; the Time_Series variable and set the rest to NaN.

  foreach ex_flag, ex_flags_all do begin
    src = (strsplit(ex_flag, '_', /ex))[-3]
    options, ex_flag, 'ytitle', src
    options, ex_flag, 'psym', -1

    get_data, ex_flag, data = d_ex_flag

    if total(d_ex_flag.y gt 0) then ex_flags = [ex_flags, ex_flag]

    if min(d_ex_flag.y) ne max(d_ex_flag.y) then begin
      tname_ts = 'PSP_FLD_L2_TDS_WF_Burst_Time_Series_' + src + '_Engineering_mV'

      get_data, tname_ts, data = d_ts

      if size(/type, d_ts) eq 8 then begin
        if array_equal(size(/dim, d_ts.y), size(/dim, d_ts.v)) eq 0 then begin
          if total(d_ex_flag.y) eq (size(/dim, d_ts.y))[0] then begin
            new_y = fltarr(size(/dim, d_ts.v)) + !values.f_nan

            new_y[where(d_ex_flag.y gt 0), *] = d_ts.y

            store_data, tname_ts, data = {x: d_ts.x, y: new_y, v: d_ts.v}

            ; stop
          endif
        endif
      endif
    endif
  endforeach
end
