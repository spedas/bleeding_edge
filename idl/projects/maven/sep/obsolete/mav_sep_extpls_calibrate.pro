

function mav_sep_dapcal,vstep,param=p,channel=channel   ;  input step voltage : output peak height.

if not keyword_set(channel) then channel=0
if not keyword_set(p) then begin
    p = {  $
      ch:0, $
      s0: 0d,  $
      s1:2.7d, $
      s2:0d, $
      e0:0d , $
      e1:.2d , $
      func:((scope_traceback(/structure))[scope_level()-1]).routine  }
endif
if n_params() eq 0 then return,p

dv = (vstep - p.s0)
zz =  p.s1*dv + p.s2*dv^2 + p.e0 *  (exp(- dv /p.e1) -1 )

return,zz
end









function mav_sep_adc_resp3,vstep,param=p  ,channel=channel   ; input voltage pulseheight ; output bin number
if not keyword_set(p) then begin
    ph1= mav_sep_dapcal(channel=channel)

    p = { func:((scope_traceback(/structure))[scope_level()-1]).routine, $
          ph : ph1,  $
          binwidth: 4,$
          channel: channel, $
          g: 4096d/2.500d, $
          baseline: 0d, $
          md:256  }
endif
if n_params() eq 0 then return,p

peak_height = func(vstep,param=p.ph )
adc =   peak_height * p.g  + p.baseline
return,(adc / p.binwidth) mod p.md
end




pro set_tplot_cal
    store_data,'SCIENCE',data='SEP_SCIENCE_DATA SEP_SCIENCE_X0'
    options,'SCIENCE',psym=3,/ynozero,panel_size=3,yrange=[0,260]
    store_data,'NOISE', data='SEP_NOISE_SIGMA SEP_SCIENCE_S'
    tplot,'SCIENCE SEP_SCIENCE_S SEP_SCIENCE_A SEP_HKP_MAPID SEP_HKP_RATE NOISE SEP_NOISE_BASELINE SEP_RATES'

end





pro mav_sep_extpls_calibrate,threshold=thresh,pnames=pnames

col=0

if not keyword_set(col) then col = 0

col = col mod 6 +1

print,col

ctime,t,npoints=2
s = reform( tsample('SEP_SCIENCE_X0',t,times=ts) )
s1= reform( tsample('SEP_SCIENCE_A', t) )
s2= reform( tsample('SEP_SCIENCE_S', t) )
addr = reform( tsample('SEP_HKP_MEM_ADDR',t) )
;addr = 256. * reform( tsample('SEP_HKP_MAPID',t))
fto = reform( tsample('SEP_HKP_MODE_FLAGS',t) )
baselines = tsample('SEP_NOISE_BASELINE',t, /average)
sigmas    = tsample('SEP_NOISE_SIGMA',t, /average)
;mp = shift(mp,2)
w = where(finite(s) and ((fto and '4000'x) ne 0) )
wmm = minmax(w)
ss =  s[w]
ss1 =  s1[w]
ss2 =  s2[w]
ts =  ts[w]
addr =  addr[w]

ta = average(ts)
pmode = tsample( 'SEP_HKP_MODE_FLAGS' ,ta)
fto = ishft(pmode,-8) and '3f'x
ch = round( alog(fto) / alog(2) ) +1
baseline = baselines(ch-1)
sigma    = sigmas(ch-1)


wi,1  ,/show
plot,ss,psy=-1
plotxyerr,indgen(n_elements(ss)),ss,.4,ss2
oplot,ss1/10.,psym=-1,col=5
oplot,addr,psym=-1,col=6
printdat,ss
wi,4
plot,ss2,psym=-1
oplot,ss2*0 + sigma,color=5


col = ch+1
col=0

xx = addr ;* 0.01
;x = findgen(12) * '400'x
;x[0] = '2000'x
;xx = replicate(1,acctime) # x

p = mav_sep_adc_resp3(channel=0)
p.binwidth = 4

;p.binwidth =2
;if not keyword_set(pp) then $
   pp = replicate(p,7)
p.channel  = ch
p0=p
res = ss * 0.
if not keyword_set(thresh) then thresh = 50.
printdat,thresh
if not keyword_set(pnames) then pnames = 'g  baseline'
; PNAMES = 'ph.s1 ph.d0 ph.e0 ph.e1 baseline'


wi,2,/show
;if col eq 1 then  $
  plot,xx,ss,/nodat,xstyle=3,title = time_string(ta),xtitle='Test Pulse DAC value',ytitle='Pulse Height ADC value',yrange=[-50,260]
oplot,xx,ss,psym=2,col=col
oplot,!x.crange,!x.crange*0,linestyle=1

for i=0,2 do begin
  w = where(finite(ss) and ss1 gt 400. and abs(res) lt thresh,ns )
;  if i eq 0 then fit,xx[w],ss[w],param=p ,name='baseline'
  fit,xx[w],ss[w],param=p ,name=pnames,res=r,/overplot
  pf,p,color = 5
  res =  ss - func(param=p,xx)
endfor
pf,p,color = 6

oplot,xx[w],ss[w],psym=4,col=6
oplot,xx,res*10,psym=1,col=4
oplot,xx[w],res[w]*10,psym=1,col=6

dp = r.dpar
printdat,p,ns
printdat,p,ns,baseline,output=outs1,/value
printdat,dp,ns,sigma,output=outs2,/value
xyouts,.15,.85,strjoin(outs1+'!c'),/norm,color=col
xyouts,.55,.85,strjoin(outs2+'!c'),/norm,color=col

pp[p.channel > 0]= p

;makepng,'TPcal2',time=ta,window=2
;makepng,'TPcal1',time=ta,window=1
wshow
end







;pro mav_sep_dap_calibrate,param=p,pnames=pnames,overplot=overplot,col=col,ttime=tt
!p.multi=0

if  ~keyword_set(defcom) then defcom=''
if  ~keyword_set(col) then col = 0
if  ~keyword_set(overplot) then overplot= 0

ctime,tt,npoints=2
if n_elements(tt) eq 2 then t=tt
comment = tsample('CMNBLK_USER_NOTE',t)
if  size(/type,comment) ne 7 then comment=defcom  else comment=comment[0]

s = reform( tsample('SEP_SCIENCE_X0',t,times=ts) )
s1= reform( tsample('SEP_SCIENCE_A', t) )
s2= reform( tsample('SEP_SCIENCE_S', t) )
mp1 = reform( tsample('SEP_HKP_MAPID',t) )
mp = reform( tsample('SEP_SCIENCE_MAPID',t) )
add1= reform( tsample('SEP_HKP_MEM_ADDR',t) )
add= reform( tsample('SEP_SCIENCE_MEM_ADDR',t) )
baselines = tsample('SEP_NOISE_BASELINE',t, /average)
sigmas    = tsample('SEP_NOISE_SIGMA',t, /average)
;mp = shift(mp,2)
if n_elements(mp) ne n_elements(s) then message,'Data mismatch'
w = where( mp ne 0)
wmm = minmax(w)
printdat,s,s1,s2,ts,mp
ss =  s[w]
ss1 =  s1[w]
ss2 =  s2[w]
ts =  ts[w]
mp =  mp[w]
add =add[w]

ta = average(ts)
pmode = tsample( 'SEP_HKP_MODE_FLAGS' ,ta)
fto = ishft(pmode,-8) and '3f'x
ch = round( alog(fto) / alog(2) ) +1
baseline = baselines(ch-1)
sigma    = sigmas(ch-1)

if 1 then begin
wi,1  ,/show
plot,ss,psy=-1
plotxyerr,indgen(n_elements(ss)),ss,.4,ss2
oplot,ss1/10.,psym=-1,col=5
oplot,mp,psym=-1,col=6
oplot,add,psym=-1,col=2
printdat,ss
wi,4
plot,ss2,psym=-1
oplot,ss2*0 + sigma,color=3
endif

colors = [1,2,6,4,2,6]
col = colors[ch-1]

;col=0
if n_elements(stepsize) ne 1 then stepsize = .0001

xx = add * stepsize

if not keyword_set(p) then begin
    p = mav_sep_adc_resp3(channel=ch)
    p.baseline = baseline
endif
if ~keyword_set(binwidth) then binwidth = 1

p.binwidth = binwidth

;if not keyword_set(pp) then $
;   pp = replicate(fill_nan(p),7)
;p.channel  = ch
p0=p
res = ss * 0.
if not keyword_set(thresh) then thresh = 3.
;if not keyword_set(pnames) then pnames = 'g  baseline'
;if not keyword_set(pnames) then  PNAMES = 'ph.s1 ph.d0 ph.e0 ph.e1 baseline'
if not keyword_set(pnames) then pnames = 'ph.s0 ph.s1 ph.s2 baseline'




wi,2,/show
xrange = minmax(xx)
;overplot = ch ne 4
!p.multi= [0,1,2]
cgplot,xx,ss,xstyle=3,title=time_string(ta)+' '+comment,xtitle='Test Pulse delta V',ytitle='Binned ADC Pulse height value',xrange=xrange,/ystyle,overplot=overplot,color=col,psym=1,yrange=minmax(ss)*[0,1]
;oplot,xx,ss,psym=1,col=col
oplot,!x.crange,!x.crange*0,linestyle=1

;pf,p,color = 6


;mslope = median( (ss-shift(ss,1)) / (xx-shift(xx,1)) ) / p.g *p.binwidth
;if 0 then begin
;    p.ph.s1 =  mslope *1000  ;initial guess
;;    p.ph.s2=0
;endif

chi = 5.
res =0
lw=0
res =   (xx gt 11000) *  100
for i=0,5 do begin
;  thresh = 20; chi * 4  ; 3 sigma threshold
  w = where(finite(ss) and ss lt 256 and abs(ss1-500) lt 15. and abs(res) lt thresh,ns )
  dprint,/phelp,i,ns,xx,thresh
  fit,xx[w],ss[w],param=p ,name=pnames,res=r
  res =  ss - func(param=p,xx)
  chi = r.chi
;  pf,p,color = 5
  if array_equal(w,lw) then break
  lw = w
endfor
dprint,i+1,' Cycles'

pf,p,color = col

oplot,xx[w],ss[w],psym=4,col=col
ps1 = get_plot_state()

expand = 1
yrange = [-1,1]*thresh
if overplot then restore_plot_state,ps2
cgplot,overplot=overplot,xrange,yrange *0,xrange=xrange,yrange=yrange,xstyle=3,ystyle=3,linestyle=1
oplot,xx,yrange[0] > res*expand < yrange[1],psym=1,col=col
oplot,xx[w],res[w]*expand,psym=4,col=col
;oplot,minmax(xx[w]), [1,1]*thresh*expand,col=0,linestyle=1
;oplot,minmax(xx[w]),-[1,1]*thresh*expand,col=0,linestyle=1
;oplot,xx,ss2*10,psym=3,col=col
ps2=get_plot_state()
restore_plot_state,ps1
dp = r.dpar
printdat,p,ns
printdat,p,ns,baseline,output=outs1,/value
printdat,dp,ns,sigma,output=outs2,/value
xyouts,.15,.55,strjoin(outs1+'!c'),/norm,color=col
;xyouts,.55,.35,strjoin(outs2+'!c'),/norm,color=col

;;;pp[p.channel]= p

preamp = uint(strmid(comment,5,9))

result = { time: t,ta:ta, comment:comment, preamp:preamp, channel:ch, baseline:baseline, sigma:sigma, fitr:r }

!p.multi=0
;makepng,'ExtTPcal-low',time=ta,window=2
;makepng,'TPcal1',time=ta,window=1

wshow


if 0 then begin
append_array,results,result  & help,results



ch4 = results[where(results.channel eq 4)]
ch4= ch4[sort(ch4.fitr.par.ph.s1)]
cgplot,ch4.fitr.par.ph.s1,psy=-1,col=4,/ynozero,yrange=[6.5,9.5]
xyouts,indgen(22),ch4.fitr.par.ph.s1,strtrim(ch4.preamp,2)

ch5 = results[where(results.channel eq 5)]
ch5= ch5[sort(ch5.fitr.par.ph.s1)]
cgplot,ch5.fitr.par.ph.s1,psy=-1,col=2,/ynozero,yrange=[6.5,9.5],/overplot
xyouts,indgen(22),ch5.fitr.par.ph.s1,strtrim(ch5.preamp,2)

ch6 = results[where(results.channel eq 6)]
ch6= ch6[sort(ch6.fitr.par.ph.s1)]
cgplot,ch6.fitr.par.ph.s1,psy=-1,col=6,/ynozero,/overplot
xyouts,indgen(22),ch6.fitr.par.ph.s1,strtrim(ch6.preamp,2)


s = sort(results.preamp+results.channel/10. )
res = results[s]
i = indgen(3,18)
res = res[transpose(i)]
avgain = average(res.fitr.par.ph.s1,2)
s = sort(avgain)
i = indgen(18) # [1,1,1]
;res = res[[[s],[s+1],[s+2]]]
cgplot,i,res.fitr.par.ph.s1,psym=-1,/ynozer;,col = i
xyouts,i,res.fitr.par.ph.s1,strtrim(res.preamp,2)

for i=0,2 do cgplot,indgen(18),res[s,i].fitr.par.ph.s1,overplot= i ne 0,yrange=[6,9],psym=-1
for i=0,2 do xyouts,indgen(18),res[s,i].fitr.par.ph.s1,strtrim(res[s,i].preamp,2)


h = histogram(preamp,reverse_ind=r,locations=l,min=0)
printdat,preamp,h,r,l

endif


end


;mav_sep_extpls_calibrate,threshold=threshold,pnames=pnames
;mav_sep_dap_calibrate
;end


