;+
;Procedures:
;  thm_map_ex_1
;  thm_map_ex_2
;  thm_map_ex_3
;  thm_map_ex_4
;  thm_map_ex_5
;  thm_map_ex_6
;  thm_map_ex_7
;  thm_map_ex_8
;  thm_map_ex_9
;  thm_map_ex_12
;  thm_map_ex_13
;  thm_map_ex_cdf_full
;
;Purpose:
;  Multiple examples of how to use thm_map_set and thm_map_add.
;
;Input:
;  None
;
;Notes:
;  -all these examples reset the plotting window
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-22 16:54:25 -0700 (Fri, 22 May 2015) $
;$LastChangedRevision: 17683 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_map.pro $
;-



pro thm_map_ex_1
  compile_opt idl2
   thm_init
   thm_map_set
   thm_map_add,invariant_lats=[60,65,70,75],invariant_color=0,invariant_thick=2
   thm_map_add,geographic_lats=50+5*indgen(5),geographic_lons=245+findgen(3)*20,geographic_linestyle=2
   xyouts,0.02,0.05,'thm_map_ex_1'   ,color=0,/normal
   xyouts,0.02,0.02,'PACE mag lats and geographic lats and longs over central Canada',color=0,/normal
return
end

pro thm_map_ex_2
  compile_opt idl2
   thm_init
   thm_map_set
   thm_map_add,invariant_lats=[60,65,70,75],invariant_color=0,invariant_thick=2,/invariant_lons
   xyouts,0.02,0.05,'thm_map_ex_1'   ,color=0,/normal
   xyouts,0.02,0.02,'PACE mag lats and longs over central Canada',color=0,/normal
return
end


pro thm_map_ex_3
  compile_opt idl2
    thm_init ;ensure !themis is defined
    sav_file = spd_download(remote_file='thg/l2/asi/cal/thm_map_add.sav', _extra=!themis)
    restore, sav_file
    usersym,[-1,0,1,0,-1],[0,1,0,-1,0],/fill
    thm_map_set,scale=50e6
    loadct,39
    xyouts,0.02,0.3,'THEMIS ASIs',/normal,color=0
    w=where(thg_map_gb_sites.themis_asi eq 1)
    tt=thg_map_gb_sites[w]
    for i=0,n_elements(tt)-1 do plots,tt[i].longitude,tt[i].latitude,psym=8,color=0,symsize=1.7
    wait,0.5
    xyouts,0.02,0.26,'UCLA THEMIS mags',/normal,color=0
    w=fix(where(thg_map_gb_sites.themis_fluxgate eq 1 or thg_map_gb_sites.augo_fluxgate eq 1))
    thm_map_add,asi_fovs=w,asi_fov_color=0,asi_fov_thick=2,asi_emission_height=30
    wait,0.5
    xyouts,0.02,0.22,'CARISMA mags that feed to THEMIS',/normal,color=250
    w=fix(where(thg_map_gb_sites.carisma_fluxgate eq 1 and thg_map_gb_sites.themis_asi eq 1))
    thm_map_add,asi_fovs=w,asi_fov_color=250,asi_fov_thick=2,asi_emission_height=30
    wait,0.5
    xyouts,0.02,0.18,'NRCan mags that feed to THEMIS',/normal,color=110
    w=where(thg_map_gb_sites.nrcan_fluxgate eq 1 and thg_map_gb_sites.themis_asi eq 1)
    thm_map_add,asi_fovs=fix(w),asi_fov_color=110,asi_fov_thick=2,asi_emission_height=30
    ;wait,0.5 & xyouts,0.02,0.14,'AUGO mags that feed to THEMIS',/normal,color=150
    ;w=where(gb_sites.augo_fluxgate eq 1)
    ;thm_map_add,asi_fovs=fix(w),asi_fov_color=150,asi_fov_thick=2,asi_emission_height=30
    wait,0.5
    xyouts,0.02,0.14,'GIMA mags that feed to THEMIS',/normal,color=30
    w=where(thg_map_gb_sites.gima_fluxgate eq 1)
    thm_map_add,asi_fovs=fix(w),asi_fov_color=30,asi_fov_thick=2,asi_emission_height=30
    wait,0.5
    xyouts,0.02,0.10,'non-GBO THEMIS EPO fluxgates',/normal,color=0
    w=where(thg_map_gb_sites.themis_epo_fluxgate eq 1 and thg_map_gb_sites.themis_fluxgate eq 0)
    thm_map_add,asi_fovs=fix(w),asi_fov_color=0,asi_fov_thick=2,asi_emission_height=30
return
end

pro thm_map_ex_4
  compile_opt idl2
   thm_init
   window
   thm_map_set
   thm_map_add,invariant_lats=[60,65,70,75],invariant_color=0,invariant_thick=1,/invariant_lons
   thm_map_add,asi_fovs=1,asi_fov_color=250,asi_fov_thick=2
   xyouts,0.02,0.02,'Show ASI FOVs at one height',color=0,/normal
return
end


pro thm_map_ex_5
  compile_opt idl2
   thm_init
   window
   thm_map_set
   thm_map_add,invariant_lats=[60,65,70,75],invariant_color=0,invariant_thick=1,/invariant_lons
   thm_map_add,asi_fovs=1,asi_fov_color=250,asi_fov_thick=2
   thm_map_add,asi_fovs=1,asi_fov_color=150,asi_fov_thick=2,asi_emission_height=230
   xyouts,0.02,0.02,'Show ASI FOVs at two heights',color=0,/normal
return
end

pro thm_map_ex_6
  compile_opt idl2
   thm_init ;ensure !themis is defined
   sav_file = spd_download(remote_file='thg/l2/asi/cal/thm_map_add.sav', _extra=!themis)
   restore, sav_file
   thm_map_set
   thm_map_add,invariant_lats=[65,70,75],invariant_color=250,invariant_thick=1,/invariant_lons
   thm_map_add,asi_fovs=1,asi_fov_color=0,asi_fov_thick=2
   thm_map_add,asi_fovs='RABB',asi_fov_color=150,asi_fov_thick=4
   xyouts,0.02,0.02,'NORSTAR-Rainbow Starlight Express Imager at Rabbit Lake',color=0,/normal
return
end

pro thm_map_ex_7
  compile_opt idl2
   thm_init
   dx=0.3333
   dy=0.3333
   cc=10 * (indgen(6)+2)
   for i=0,2 do for j=0,1 do begin
      pa=[i*dx,(2-j)*dy,(i+1)*dx,((2-j)+1)*dy]
      thm_map_set,position=pa,scale=85e6,noerase=i+j,color_continent=cc[3*j+i], xsize=700, ysize=700
      xyouts,pa[0]+0.01,pa[1]+0.01,'color_background=default',/normal,color=255
      xyouts,pa[0]+0.01,pa[1]+0.03,'color_continent='+strcompress(string(cc[3*j+i]),/remove_all),/normal,color=255
   endfor
   cc=[2,4,6]
   dd=[4,2,2]
   for i=0,2 do for j=2,2 do begin
      pa=[i*dx,(2-j)*dy,(i+1)*dx,((2-j)+1)*dy]
      thm_map_set,position=pa,scale=85e6,noerase=i+j,color_background=cc[i],color_continent=dd[i]
      xyouts,pa[0]+0.01,pa[1]+0.03,'color_continent='+strcompress(string(dd[i]),/remove_all),/normal,color=255
      xyouts,pa[0]+0.01,pa[1]+0.01,'color_background='+strcompress(string(cc[i])+' (broken)',/remove_all),/normal,color=255
   endfor
return
end



pro thm_map_ex_8
  compile_opt idl2
   thm_init
   dx=0.3333
   dy=1.0
   cc=250+20*indgen(3)
   for i=0,2 do begin
      pa=[i*dx,0,(i+1)*dx,dy]
      thm_map_set,position=pa,scale=85e6,noerase=i,central_lon=cc[i], xsize=900,ysize=300
      thm_map_add,geographic_lats=50+5*indgen(5),geographic_lons=245+findgen(3)*20
      xyouts,pa[0]+0.01,pa[1]+0.02,'central_lon='+strcompress(string(cc[i]),/remove_all),/normal,color=255
      xyouts,pa[0]+0.01,pa[1]+0.07,'central_lat=default',/normal,color=255
      plots,pa[[0,0,2,2,0]],pa[[1,3,3,1,1]],color=255,thick=2,/normal
   endfor
return
end

pro thm_map_ex_9
  compile_opt idl2
   thm_init ;ensure !themis is defined
   sav_file = spd_download(remote_file='thg/l2/asi/cal/thm_map_add.sav', _extra=!themis)
   restore, sav_file
   usersym,[-1,0,1,0,-1],[0,1,0,-1,0],/fill
   w=where(thg_map_gb_sites.abbreviation eq 'GILL')
   tt=thg_map_gb_sites[w[0]]
   dx=0.3333
   dy=1.0
   cc=20e6+17e6*indgen(3)
   for i=0,2 do begin
      pa=[i*dx,0,(i+1)*dx,dy]
      thm_map_set,position=pa,noerase=i,scale=cc[i],central_lat=tt.latitude,central_lon=tt.longitude, xsize=900,ysize=300
      plots,tt.longitude,tt.latitude,psym=8,color=250,symsize=1.4
      thm_map_add,asi_fovs=[fix(w[0])],asi_fov_color=250,asi_emission_height=110,asi_fov_thick=2
      xyouts,pa[0]+0.01,pa[1]+0.12,'scale='+strcompress(string(round(cc[i]/1e6)),/remove_all)+'e6',/normal,color=255
      xyouts,pa[0]+0.01,pa[1]+0.07,'central_lon=longitude of Gillam',/normal,color=255
      xyouts,pa[0]+0.01,pa[1]+0.02,'central_lat=latitude of Gillam',/normal,color=255
      plots,pa[[0,0,2,2,0]],pa[[1,3,3,1,1]],color=255,thick=2,/normal
   endfor
   x0=0.05
   y0=0.87
   dx=0.32
   dy=0.1
   polyfill,x0+[0,0,1,1,0]*dx,y0+[0,1,1,0,0]*dy,color=255,/normal
   xyouts,x0+0.02,y0+0.06,'each thm_map_set is centered on Gillam',color=0,/normal
   xyouts,x0+0.02,y0+0.015,'each thm_map_set uses a different scale',color=0,/normal
return
end

;-----------------------------------------------------------------------






pro thm_map_ex_12
  compile_opt idl2
    thm_init
    iy=2006
    im1=12
    id=23
    ih=6
    timespan,'2006-12-23/06:00:00',1,/hour
  	; change to for-loop if you like
    ;  for im=17,30 do for is=0,57,3 do begin
    im=17
    is=0
    date_time_string=string(iy,im1,id,format='(i4.4,2i2.2)')+'_'+string(ih,im,is,format='(3i2.2)')
    factor=1/55.0  ;kluge
    minimum_elevation_to_plot=8 ;degrees
    n1=long(256)*long(256)
    thm_map_set,central_lon=255,central_lat=65
    site_list=['fsmi','gill','snkq','inuv','fykn']
    thm_mosaic_array,iy,im1,id,ih,im,is,site_list,$
        image,corners,elevation,pixel_illuminated,n_sites
    loadct,0
    for pixel=long(0),n1-long(1) do for i_site=0,n_sites-1 do begin
      if pixel_illuminated[pixel,i_site] eq 1 and elevation[pixel,i_site] gt minimum_elevation_to_plot then begin
         xx=corners[pixel,[0,1,2,3,0],0,i_site]
         yy=corners[pixel,[0,1,2,3,0],1,i_site]
         cc=(image[pixel,i_site]/50.0) < 255
         polyfill,xx,yy,color=cc
      endif
    endfor
    thm_map_add,invariant_lats=[60,65,70,75],invariant_color=210,invariant_linestyle=2
    xyouts,0.005,0.018,date_time_string,color=0,/normal
    xyouts,0.005,0.060,'THEMIS-GBO ASI',color=0,/normal
;    write_png,'20061223_mosaics/mosaic_'+date_time_string+'.png',tvrd(/true)
;  endfor
return
end



pro thm_map_ex_13
  compile_opt idl2
    thm_init
    starttime=systime(1)
    iy=2006
    im1=12
    id=23
    ih=6
    im=18
    is=0
    timespan,'2006-12-23/06:18:00',1,/hour
    date_time_string=string(iy,im1,id,format='(i4.4,2i2.2)')+'_'+string(ih,im,is,format='(3i2.2)')
    factor=1/55.0  ;kluge
    minimum_elevation_to_plot=8 ;degrees
    n1=long(256)*long(256)
    thm_map_set,central_lon=255,central_lat=65
    site_list=['fsmi','gill','snkq','inuv','fykn']
    thm_mosaic_array,iy,im1,id,ih,im,is,site_list,$
        image,corners,elevation,pixel_illuminated,n_sites
    loadct,0
    for pixel=long(0),n1-long(1) do for i_site=0,n_sites-1 do begin
      if pixel_illuminated[pixel,i_site] eq 1 and elevation[pixel,i_site] gt minimum_elevation_to_plot then begin
         xx=corners[pixel,[0,1,2,3,0],0,i_site]
         yy=corners[pixel,[0,1,2,3,0],1,i_site]
         cc=(image[pixel,i_site]/50.0) < 255
         polyfill,xx,yy,color=cc
      endif
    endfor
    thm_map_add,invariant_lats=[60,65,70,75],invariant_color=210,invariant_linestyle=2
    xyouts,0.005,0.018,date_time_string,color=0,/normal
    xyouts,0.005,0.060,'THEMIS-GBO ASI',color=0,/normal
    write_png,'thm_map_ex_13.png',tvrd(/true)
    print,'Takes ',systime(1)-starttime
return
end



pro thm_map_ex_cdf_full
  compile_opt idl2
    thm_init
    starttime=systime(1)
    iy=2006
    im1=12
    id=23
    ih=6
    im=18
    is=0
    timespan,'2006-12-23',1,/days
    date_time_string=string(iy,im1,id,format='(i4.4,2i2.2)')+'_'+string(ih,im,is,format='(3i2.2)')
    factor=1/55.0  ;kluge
    minimum_elevation_to_plot=8 ;degrees
    n1=long(256)*long(256)
    thm_map_set,central_lon=255,central_lat=65
    site_list=['fsmi','gill','snkq','inuv','fykn']
    thm_mosaic_array,iy,im1,id,ih,im,is,site_list,$
        image,corners,elevation,pixel_illuminated,n_sites
    loadct,0
    for pixel=long(0),n1-long(1) do for i_site=0,n_sites-1 do begin
      if pixel_illuminated[pixel,i_site] eq 1 and elevation[pixel,i_site] gt minimum_elevation_to_plot then begin
         xx=corners[pixel,[0,1,2,3,0],0,i_site]
         yy=corners[pixel,[0,1,2,3,0],1,i_site]
         cc=(image[pixel,i_site]/50.0) < 255
         polyfill,xx,yy,color=cc
      endif
    endfor
    thm_map_add,invariant_lats=[60,65,70,75],invariant_color=210,invariant_linestyle=2
    xyouts,0.005,0.018,date_time_string,color=0,/normal
    xyouts,0.005,0.060,'THEMIS-GBO ASI',color=0,/normal
    write_png,'thm_map_ex_13.png',tvrd(/true)
    print,'Takes ',systime(1)-starttime
return
end
