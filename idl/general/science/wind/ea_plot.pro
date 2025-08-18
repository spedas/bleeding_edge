pro ea_plot,dat,erange=erange,frange=frange,elog=elog,plts=plts, $
  cpd=cpd,npa=npa,xvel=xvel, $
  title=title, $
  evals = evals, avals=avals, $
  bins = bins, $
  cutdirs=cutdir, $
  linestyle=linestyle,psym=psym, $
  _extra=extra

if data_type(dat) ne 8 then return

;colors = get_colors('mbcgyr')
colors = get_colors('bgr')
ncolors = n_elements(colors)

;add_magf,dat,'wi_B3'
;add_vsw,dat,'Vp'
dfi = convert_vframe(dat,/int)
df  = convert_vframe(dat)
pd=pad(dfi,num_pa=npa)
mass=pd.mass

dfpar = distfunc(pd,df=pd.data)
nrg = pd.energy
xval  = keyword_set(xvel) ? velocity(nrg,mass) : nrg
y  = pd.angles
nx = pd.nenergy
ny = pd.nbins
f  = pd.data

pos = plot_positions(ysize=[3,1],ygap=4,xsize=[3,1],xgap=4,opt={xmargin:[10,10]})

if n_elements(bins) eq 1 then bins=dat.bins
if n_elements(elog) eq 0 then elog =1
if n_elements(psym) eq 0 then psym=-4

if n_elements(avals) eq 0 then avals=[0,90,180.]
if not keyword_set(erange) then erange= elog ? [1.,1500.]: [0,1200.] 
if not keyword_set(vrange) then vrange= elog ? [1000.,30000.]: [0.,22000.]
if not keyword_set(frange) then frange=[1e-18,5e-10]
if not keyword_set(arange) then arange=[0,180.]
flog =1
xrange = keyword_set(xvel) ? vrange : erange
xtitle = keyword_set(xvel) ? 'Velocity (km/s)' : 'Energy (eV)'
ytitle = units_string(pd.units_name)
if not keyword_set(title) then title=time_string(dat.time)

if keyword_set(plts) then begin
  restore_plot_state,plts[0] 
  newplot=0
  endif else begin
  plot,[0],/nodata,pos=pos[*,0],yrange=frange,xrange=xrange,ylog=flog,xlog=elog, $
  xtitle=xtitle,ytitle=ytitle,/xstyle,/ystyle,title=title
  plt1=get_plot_state()
  newplot=1
endelse

col = colors[indgen(nx) mod ncolors]
col = bytescale(findgen(ny))

if keyword_set(pdat) then $
 for i=0,ny-1 do $
  oplot,xval[*,i],f[*,i],psym=psym,col=col[i],lines=linestyle,_extra=extra

xv=dgen() 
for i=0,n_elements(avals)-1 do begin
  e = keyword_set(xvel) ? .5*mass*xv^2 : xv
  oplot,xv,distfunc(e,avals[i],mass=mass,param=dfpar),lines=linestyle,col=bytescale(avals[i],range=[0,180.])
endfor

if keyword_set(bins) then begin
  w = where(bins)
  xv = keyword_set(xvel) ? velocity(df.energy,mass) : df.energy
  a = pangle(df.theta,df.phi,vec=df.magf)
  plots,noclip=0,psym=3,xv[w],df.data[w],col=bytescale(a[w],range=[0,180.])
endif

if keyword_set(cutdir) then begin
  b = nearest_bins(dat,cutdir)
  col = get_colors(keyword_set(cutcols) ? cutcols : 'ggbggr')
  printdat,b
  for i=0,n_elements(b)-1 do begin
     oplot,df.energy[*,b[i]],df.data[*,b[i]],psym=4,col=col[i]
  endfor

endif


;  PITCH ANGLE PLOT


if keyword_set(plts) then restore_plot_state,plts[1]  else begin
  plot,[0],/nodata,/noerase,pos=pos[*,1],  $
    xrange=arange,yrange=frange,xlog=0,ylog=flog, $
    /xstyle,/ystyle,xtitle='Pitch Angle', $
    ytickname=replicate(' ',30), $
    xtickv=[0,90,180.],xticks=3,xminor=9
  plt2=get_plot_state()
endelse

col = bytescale(findgen(nx))
col = colors[indgen(nx) mod ncolors]
if keyword_set(pdat) then $
 for i=0,nx-1 do $
  oplot,y[i,*],f[i,*],psym=psym,col=col[i],lines=linestyle,_extra=extra




if keyword_set(bins) then begin
  xv = pangle(dfi.theta,dfi.phi,vec=dfi.magf)
  for i=0,nx-1 do begin
    w = where(bins[i,*])
    oplot,psym=3,xv[i,w],dfi.data[i,w],col=col[i]
  endfor
endif

xv=dgen() 
evals = average(nrg,2)
;printdat,evals
for i=0,n_elements(evals)-1 do begin
  yv = distfunc(evals[i],xv,mass=mass,param=dfpar)
  oplot,xv,distfunc(evals[i],xv,mass=mass,param=dfpar),col=col[i],lines=linestyle
  if (reverse(yv))[0] gt frange[0] and newplot then $
 ; xyouts,(reverse(xv))[0],(reverse(yv))[0],' '+strtrim(roundsig(evals[i])+' eV',2),col=col[i]
  xyouts,(reverse(xv))[0],(reverse(yv))[0],' '+string(fix(roundsig(evals[i])),format='(i0.0)')+' eV',col=col[i]
endfor




if keyword_set(plts) then restore_plot_state,plts[2]  else begin
  plot,[0],/nodata,/noerase,pos=pos[*,2],  $
    yrange=arange,xrange=xrange,ylog=0,xlog=elog, $
    /xstyle,/ystyle,ytitle='Pitch Angle', $
    ytickv=[0,90,180.],yticks=3,yminor=9
  plt3=get_plot_state()
  plts=[plt1,plt2,plt3]
endelse

n_a = 19
n_e = 25
ang = dgen(n_a,/y)
xv  = dgen(n_e,/x)
nrg = keyword_set(xvel) ? .5*mass*xv^2 : xv

f2= distfunc(nrg # replicate(1,n_a),replicate(1,n_e) #ang,param=dfpar,mass=mass)
if not keyword_set(cpd) then cpd = 2
mmf = round(alog10(minmax(f2))*cpd)
nl = mmf[1]-mmf[0]+1
levels = (findgen(nl)+mmf[0])/cpd
c_label = abs(levels mod 1) le .001
c_col = colors[floor(-levels) mod ncolors]
;c_col = bytescale(levels mod 10)

if keyword_set(bins) then begin
   a = pangle(df.theta,df.phi,vec=df.magf)
   x = keyword_set(xvel) ? velocity(df.energy,mass) : df.energy
   w = where(bins)
   oplot,x[w],a[w],ps=3
  
endif


contour,alog10(f2),xv,ang,/over,levels=levels,c_label=c_label,c_col=c_col, $
  c_lines=linestyle,_extra=extra
  
  
;if keyword_set(dfpar0) then begin
;set_plot_state,plts[0]


;endif


end



