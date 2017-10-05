obsolete routine


;  mav_sep_plot_spectra,presult=pp




pro mav_sep_plot_spectra,tr,xlog=xlog,spec=spec,lut=lut,binstr=binstr,window=window,overplot=overplot,presult=pp,sep=sep

if size(/type,sep) ne 7 then SEP = 'SEP1'

if 1 then begin
    if n_elements(tr) ne 2 then ctime,tr,npoints=2
    s=tsample(SEP+'_SCIENCE_DATA',tr)
    spec =  0  ? average(s,1) : total(s,1)
    dim = size(/dimen,s)
    dt=dim[0]
    LUT = tsample(SEP+'_MEMDUMP_LUT',tr[1])
    LUT = LUT[2L^16:2L^17-1]
    baselines = tsample(SEP+'_NOISE_BASELINE',tr,/average)
    printdat,spec,lut
;    wi,1
;    plot,spec > .5 ,/ylog,psym=10
endif
if keyword_set(lut) then begin
    mav_sep_lut_decom,lut,binstr=binstr,brr=brr
endif

wsize = [800,700]
if keyword_set(window) then wi,window,wsize=wsize else wi,2,wsize=wsize

title = strjoin(time_string(tr),' - ')
xtitle = 'ADC value'
ytitle = 'Count Rate / binwidth'
yrange = [1e-4,1e4]
if keyword_set(xlog) then xrange=[.1,5000]  else xrange=[-10,70]

if ~keyword_set(overplot) then plot,[1,2],title=title,xtitle=xtitle,ytitle=ytitle,xlog=xlog,/ylog,xrange=xrange,yrange=yrange,/nodata,/ystyle,/xstyle
tags = tag_names(binstr)
printdat,tags
colors = [0,  2,2,4,4,1,1,6,6,3,3,0,0]
psym=-1
p = mgauss2(num=4)
p.shift=1
p.binsize=1
p.a0 = 0
p.a1 = 1.46
p.xunits = 'KeV'
p.g.x0 = [17.3,20.9,26.3,59.54]
;p.g.s  = 2
p.sigma_fix =2
pp=0
p=0
pnames = 'a1 sigma_fix g.a'
for i=0,n_elements(tags)-1 do begin
    bsi = binstr.(i)
    if size(/type,bsi) ne 8 then continue
    counts= [float(spec[bsi.bin])]
    adc =[ float(bsi.adc[0]+bsi.width/2.)]
    width = [ bsi.width]
    x = adc
    y = counts/dt/width
    oplot,adc,counts/dt/width > yrange[0]/2,color=colors[i],psym=psym
    if keyword_set(p) && n_elements(x) ge 45 then begin
        p.g.name = tags[i]
        mx = max(y,bmx)
;        bmx = 41
;        p.g.x0 = bmx
;        w = indgen(5) -2 + bmx
        w0 = [10,11,12,13]  &  p.g[0].a = total(y[w0]) ; & p.g[0].x0 = 12
        w1 = [14,15,16]   &  p.g[1].a = total(y[w1])  ;& p.g[1].x0 = 17
        w2 = [17,18,19]   &  p.g[2].a = total(y[w2])  ;& p.g[1].x0 = 17
        w3 = [38,39,40,41,42,43,44]  &  p.g[3].a = total(y[w3]) ;& p.g[2].x0 = 41
        w = [w0,w1,w2,w3]
        oplot,x[w],y[w],psym=4,color=colors[i]
;        p.g.s = 1.4
;        p.g.a = total(y[w])
        fit,x[w],y[w],param=p,name=pnames ; ,silent=1;,verbose=0
        pf,p,/over ,col=colors[i]
        append_array,pp,p
    endif
    dprint,dlevel=3,i
endfor
if keyword_set(pp) then begin
    print_struct,pp.g
endif
for i=0,6-1 do begin
    oplot,[baselines[i]],[i/3+2],color = ([2,4,6,2,4,6])[i],psym=1
endfor

wshow
;printdat



end
