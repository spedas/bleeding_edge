; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-17 15:01:15 -0800 (Sun, 17 Dec 2023) $
; $LastChangedRevision: 32298 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_response_matrix_plots.pro $
; $ID: $






;  Multiple matrix plots
pro swfo_stis_response_matrix_plots,resp,window=win,single=single,tid=tid,fto=fto

  
  if keyword_set(win) then     wi,win,wsize=[1000,1000] ;,/show

  calval = swfo_stis_inst_response_calval()
  particle = resp.particle_name
  ;  dprint, 'Energy lost calc for', simstat.particle_name
  if ~keyword_set(tid) then tid = 0
  if ~keyword_set(fto) then fto = 4
  ifto_type = calval.names_fto[tid,fto-1]
  particle_fto = particle+'-'+ifto_type

  
  r=resp
  
  
  ;labels = strsplit('XXX O T OT F FO FT FTO Total',/extract)
  labels = strsplit('XXX 1 2 12 3 13 23 123 Total',/extract)
  zrange = minmax(r.g4,/pos)
  xrange = r.xbinrange
  yrange = r.ybinrange
  options,lim,xlog=1,/ylog,xrange=xrange,/ystyle,/xstyle,yrange=yrange,xmargin=[10,10],/zlog,zrange=zrange,/no_interp,xtitle='Energy incident (keV)',ytitle='Enery Deposited (keV)'
  if not keyword_set(single) then !p.multi = [0,4,4]
  if not keyword_set(ok1) then ok1 = 1
  wnum=0
  atten = ''  ;(['Open','Closed'])[r.attenuator]
  SEP  = 'STIS' ; (['???','SEP1','SEP2'])[r.sensornum]
  title = r.desc+' '+r.particle_name+' '+SEP+' '+atten+' '

  for side =0,1 do begin
    ;slabel = side ? 'B' : 'A'
    slabel = side ? 'F' : 'O'
    for fto = 1,8 do begin
      if fto eq 8 then G2 = total(r.g4[*,*,1:7,side],3) $
      else G2 = r.g4[*,*,fto,side]
      dprint,dlevel=3,side,fto,total(g2)
      options,lim,title = title+slabel+'_'+labels[fto]
      if keyword_set(single) then begin
        if single ne fto then continue
        if side ne 0 then continue
      endif
      specplot,r.e_inc,r.e_meas,G2,limit=lim
      oplot,dgen(),dgen();,linestyle=1
      oplot,dgen()+12,dgen() ;, color = 6 ;,linestyle=1
    endfor
  endfor
  !p.multi=0
end





