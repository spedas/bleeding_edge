

function mvn_sep_spectra,trange,sep=sep,archive=archive,dataname=dataname
if ~keyword_set(sep) then sep = 2 
if keyword_set(archive) then suffix='_arc' else suffix='_svy'
if ~keyword_set(dataname) then dataname='mvn_sep'+strtrim(sep,2)+suffix
if ~keyword_set(trange) then begin
   trange=timerange(trange,/cursor)
   timebar,trange
endif
mvn_sep_extract_data,dataname,data,trange=trange ,num=num  ;,tnames=tnames,tags=tags,num=num
;if 1 then begin   ; remove when trange elements are added to structure
;  tr = reform([data.time-data.duration/2.,data.time+data.duration/2.],2,n_elements(data))
;  str_element,/add,data,'trange',tr    
;endif
if num eq 0 then dat=0 else begin
 dat = data[0]

 if n_elements(data) gt 1 then begin
  dat.trange = minmax(data.trange)
  dat.time = average(data.time)
  dat.data  = total(data.data,2)
  dat.rate  = average(data.rate)
  dat.counts_total = total(data.counts_total)
  dat.duration = total(data.duration)
 endif
endelse
;printdat,data
return,dat
end





pro mvn_sep_spectra_plot,spectra,time,trange=tr,window=win,limit=lim,overplot=overplot,sep=sep,linestyle=linestyle, $
    units=units,tids=tids,ftos=ftos,par=par,verbose=verbose

if size(/type,spectra) eq 7 then begin
  delta_t = [-300,300]*.05*0
  if strmid(spectra,0,7) eq 'mvn_sep' then sepn = fix(strmid(spectra,7,1)) else sepn = 1
  sp = mvn_sep_spectra(time+delta_t,sep=sepn)
  if keyword_set(sp) then $
     mvn_sep_spectra_plot, sp,units='eflux'    ; useful for ctime,routine_name ='mvn_sep_spectra_plot'
  return
endif
if ~keyword_set(spectra) || keyword_set(sep) then spectra = mvn_sep_spectra(tr,sep=sep)

str_element,lim,'units',units
;if ~keyword_set(units) then units='Eflux'
if ~keyword_set(units) then units='Rate'

mapnum = spectra.mapid
bmap = mvn_sep_get_bmap(mapnum,spectra.sensor)
;mvn_sep_det_cal,bmap,spectra.sensor ,units=1    

case strupcase(units) of
  'COUNTS' : yrange = minmax(spectra.data) > .5
  'RATE'   : yrange = [.000001,1e3]    
  'EFLUX'  : yrange = [.01,1e6]
  'FLUX'   : yrange = [.0000001,1e4] 
endcase

if ~keyword_set(xrange) then xrange = [1.,1e5]

if not keyword_set(lim) then begin
  xlim,lim,xrange[0],xrange[1],1
;  ylim,lim,.00001,1e5,1
  ylim,lim,yrange[0],yrange[1],1
  title = 'SEP'+strtrim(fix(spectra.sensor),2)+'  '+time_string(spectra.trange[0])+'  '+strtrim(spectra.duration,2)
  options,lim,title=title ,ytitle = units,units=units
endif

if keyword_set(win) then overplot=0
if keyword_set(overplot) then restore_plot_state,overplot,/show else begin
   if keyword_set(win) then wi,win,wsize=[900,700],/show
   box,lim
   overplot = get_plot_state()
endelse

;printdat,spectra
;print_struct,bmap
if n_elements(tids) eq 0 then tids = [0,1]
if n_elements(ftos) eq 0 then ftos = [0,1,2,3,4,5,6,7]
for i=0,n_elements(tids)-1 do begin
  tid = tids[i]
  for j=0,n_elements(ftos)-1 do begin
     fto = ftos[j]
     w = where((bmap.tid eq tid) and (bmap.fto eq fto),nw)
     if nw ne 0 then begin
        e = bmap[w].nrg_meas_avg 
;        if units eq 'Eflux' then e += 10  ; approximate energy loss
        de = bmap[w].nrg_meas_delta
        if (fto eq 1) or (fto eq 4) then begin
          de[nw-1] = 1000.
          e[nw-1] += 1000./2
        endif
        y = spectra.data[w]               ;/ spectra.duration 
        nan = !values.f_nan
geom = ([nan,.18,0.18/100,nan])[spectra.att]
        case strupcase(units) of
        'COUNTS' : norm = 1d
        'RATE'   : norm = 1d / spectra.duration     ; scaler
        'EFLUX'  : norm = e / de / geom /spectra.duration
        'FLUX'   : norm =  1d / de / geom / spectra.duration
        endcase
        psym = bmap[w[0]].psym
        color  = bmap[w[0]].color
        name = bmap[w[0]].name
        y = y * norm
        e1 = e-de/2. > .1
        e2 = e+de/2.
        nan=!values.f_nan
        dprint,dlevel=3,verbose=verbose,name
        dprint,dlevel=3,verbose=verbose,e
        dprint,dlevel=3,verbose=verbose,y
        y = y > yrange[0]*1.1
        xr = transpose([[e1],[e2],[e2*nan]])   
        yr = transpose( [[y],[y],[y*nan]] )
        oplot, xr,yr,color=color
;        oplot,x,y,psym = psym,color=color
        xm=average(xr,1,/nan)
;        xm = exp( average( alog(xr),1,/nan ) )
        oplot,xm,y,color=color    ,linestyle=linestyle;,psym=10
        oplot,xm,y,color=color,psym=psym,symsize=.75  ;  ,linestyle=linestyle
;        oplot,x,y,psym =10,color=color
     endif
  endfor
endfor

end



