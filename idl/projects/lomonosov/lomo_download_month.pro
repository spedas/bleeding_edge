pro lomo_download_month

   timespan, '2016-11-30'
   tr0 = timerange()
   
   for i = 0,90 do begin
     tr = tr0 + (i*86400.)
     ;lomo_load_state, trange=tr
     lomo_load_att, trange=tr
   endfor
   
end