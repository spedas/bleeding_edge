; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-01-03 22:37:44 -0800 (Wed, 03 Jan 2024) $
; $LastChangedRevision: 32333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_response_rate_plot.pro $
; $ID: $






pro swfo_stis_response_rate_plot,bmap,rate,overplot=over,lim=lim,name_match = name_match
   ;if ~keyword_set(lim) then lim= dictionary('xrange',[1,1e5],'xlog',1,'yrange',[1e-6,1e4],'ylog',1,'ystyle',1)
   
   if keyword_set(lim) then box,lim
   ind = indgen(48,14)
   b = bmap[ind]
   r = rate[ind]
   ;names = reform(b[ind[0,*]].name)
   for i=0,14-1 do begin
      name = b[0,i].name
      if isa(name_match,'string') && strmatch(name,name_match) eq 0 then continue
      nrg = b[*,i].nrg_meas
      f   = r[*,i]   ;/ b[*,i].nrg_meas_delta / b[*,i].geom
      oplot,nrg,f  > 1e-10 , color=b[0,i].color, psym = -b[0,i].psym
   endfor


end





