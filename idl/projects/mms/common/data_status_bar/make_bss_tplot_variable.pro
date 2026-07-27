pro make_bss_tplot_variable, start_times=start_times, end_times=end_times, suffix=suffix

  if undefined(suffix) then suffix=''
  for idx = 0, n_elements(start_times)-1 do begin
    append_array, bar_x, [start_times[idx], start_times[idx], end_times[idx], end_times[idx]]
    append_array, bar_y, [!values.f_nan, 0.,0., !values.f_nan]
  endfor

  if undefined(bar_x) then return

  store_data,'mms_bss_fast'+suffix,data={x:bar_x, y:bar_y}
  options,'mms_bss_fast'+suffix,thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=0.09,colors=4, labels=['Fast'], charsize=2.

end