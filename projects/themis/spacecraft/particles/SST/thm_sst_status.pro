

pro thm_sst_status,date,ndays

timespan,date,ndays
del_data,'*'
tplot_options,'datagap',1000
wi,wsize=[1100,900]
thm_load_sst
panels = 'th?_psif_en th?_psif_ang th?_psef_en th?_psef_ang'
tns=tnames(panels,np)
if np lt 1 then return
zlim,'th?_ps?f_*',1,3e4
tplot,'th?_psif_en th?_psif_ang th?_psef_en th?_psef_ang'
makepng,time_string(date,format=2,/date_only)
end





if not keyword_set(ttt) then ttt = time_double()
ndays = 1

repeat begin
   dprint,time_string(ttt)
   del_data,'*'
   thm_sst_status,ttt,ndays
   ttt = ttt + ndays *3600d*24
endrep until ttt gt systime(1)

end


