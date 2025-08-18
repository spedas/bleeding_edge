; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-03-20 10:09:28 -0700 (Wed, 20 Mar 2024) $
; $LastChangedRevision: 32498 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_response_bin_matrix_plot.pro $
; $ID: $






; ADC bin Response  MATRIX (transposed)
pro swfo_stis_response_bin_matrix_plot,r,window=win,face=face,transpose=transpose,overplot=overplot,energy_range=ei_range,zlog=zlog,limit=lim
  nbins = r.nbins
  if n_elements(zlog) eq 0 then zlog=1
  if ~keyword_set(ei_range) then ei_range = minmax(r.e_inc)
  bin_range = [-10,nbins+10]
  if n_elements(face) eq 0 then face=0
  face_str = (['Aft','Both','Front'])[face+1]
  atten_str = '' ;(['Open','Closed'])[r.attenuator]
  SEP  =  (['???','STIS1','STIS2'])[r.sensornum]
  title= r.desc+' '+r.particle_name+' ('+r.mapname+' '+atten_str+' '+sep+') '+face_str
  resp_matrix = float(r.bin3[*,*,0:r.nbins-1] )   * (r.sim_area /100 / r.nd * 3.14)
  zrange = minmax(resp_matrix ,/pos)
  if keyword_set(face) then z = reform( resp_matrix[*, face lt 0, *] ) else z = total(/pres,resp_matrix,2)
  str_element,r,'fdesc',subtitle
  if keyword_set(transpose) then begin
    options,lim,ylog=1,xrange=bin_range,yrange=ei_range,/xstyle,/ystyle,xmargin=[10,10],zlog=zlog,zrange=zrange,/no_interp,ytitle='Incident Energy (keV)',xtitle='Bin Number',title=title
    if keyword_set(win) then     wi,win,wsize=[1100,500] ;,/show,icon=0
    x = indgen(nbins)
    y = r.e_inc
    z = transpose(z)
  endif else begin
    options,lim,xlog=1,xrange=ei_range,yrange=bin_range,/xstyle,/ystyle,xmargin=[10,10],zlog=zlog,zrange=zrange,/no_interp,xtitle='Incident Energy (keV)',ytitle='Bin Number',title=title;,subtitle=subtitle
    if keyword_set(win) then     wi,win,wsize=[500,800] ;,/show,icon=0
    y = indgen(nbins)
    x = r.e_inc
  endelse
  ;if not keyword_set(ok1) then ok1 = 1
  specplot,x,y,z,limit=lim
  overplot=get_plot_state()
  ;bmap = swfo_stis_get_bmap(r.mapnum,r.sensornum)
  bmap = r.bmap
  labpos1 = 5.
  labpos2 = 8.
  for tid=0,1 do begin
    for fto=1,7 do begin
      w = where(bmap.tid eq tid and bmap.fto eq fto,nw)
      if nw gt 0 then begin
        b = bmap[w].bin
        bmap0 = bmap[w[0]]
        if keyword_set(transpose) then begin
          oplot,b,b*0.+ labpos1,psym=bmap0.psym,symsize=.5,color=bmap0.color
          xyouts,average(b),labpos2,' '+bmap0.name,color=bmap0.color  ,align=.5
        endif else begin
          oplot,b*0.+ ei_range[0]*1.5,b,psym=bmap0.psym,symsize=.5,color=bmap0.color
          xyouts,ei_range[0]*1.5,average(b),' '+bmap0.name,color=bmap0.color
        endelse
      endif
    endfor
  endfor

  calval = swfo_stis_inst_response_calval()
  particle = r.particle_name
  instrument_name = calval.instrument_name
  title = instrument_name+'  '+lim.title
  
  fname = str_sub(title,' ','_')
  printdat,fname
  plot_dir = struct_value(calval,'plot_directory')
  if plot_dir then makepng,plot_dir+fname


end





