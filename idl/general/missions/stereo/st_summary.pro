pro st_summary,daynum=daynum,date,probe=probe

stx = 'st'+probe
if not keyword_set(daynum) then daynum=0
if keyword_set(date) then begin
;if not keyword_set(date) then date = '6 11 1'

  t0=time_double(date)
  trange = (daynum + [0,1])*3600d*24d  +t0

   timespan,trange

   st_mag_load  ;,probe=probe
   xyz_to_polar,stx+'_B_RTN'
   st_swea_load  ;,probe=probe

   st_part_moments,probe=probe,dopad=1
   reduce_pads,stx+'_pad',1,4,4
   reduce_pads,stx+'_pad',2,0,0
   reduce_pads,stx+'_pad',2,7,7
   options,stx+'_pad-2-*', bins = indgen(16) lt 10



;store_data,'sta_s2',data='sta_s'
;store_data,'stb_s2',data='stb_s'

;options,'st?_s2',spec=0

  ylim,'st?_s2',.5,1e5,1
  zlim,'st?_s',.5,1e5,1
  ylim,'st?_s',1,2e3,1
  store_data,stx+'_B_RTN_',data=stx+['_B_RTN','_B_RTN_mag'],dlim={constant:0.}

  wi,0,wsize=[1000,1000]

endif

tplot,stx+['_B_RTN_','_pad-1-4:4','_pad-2-0:0','_pad-2-7:7','_mom_density','_mom_velocity','_mom_avgtemp']
if 0 then begin
  wset,0
  makepng,!stereo.local_data_dir+'plots/summary/'+stx+'/sum_'+time_string(format=2,prec=-3,trange[0]), /mkdir
endif

end


