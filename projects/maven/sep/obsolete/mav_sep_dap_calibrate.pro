

function mav_sep_pulseheight,dacv,param=p
if not keyword_set(p) then  p = {  $
      ch:0, $
      d0: 5534d,   a1:0.008867d, $
      e0:9.177d , e1:7915d , $
      func:'mav_sep_pulseheight'}
if n_params() eq 0 then return,p

ddac = dacv - p.d0
ph =  p.a1 * ddac + p.e0 *  (exp(- ddac /p.e1) -1 )
return,ph
end


function mav_sep_pulseheight2,dacv,param=p
if not keyword_set(p) then  p = {  $
      ch:0, $
      v0: -30d,   a1:0.008867d, $
      e0:9.177d , e1:7915d , $
      func:'mav_sep_pulseheight2'}
if n_params() eq 0 then return,p

;ddac = dacv - p.d0
ph =  p.a1 *  dacv + p.v0  + p.e0 *  (exp(- dacv /p.e1) -1 )
return,ph
end





function mav_sep_pulseheight3,dacv,param=p,channel=channel

if not keyword_set(channel) then channel=0
if not keyword_set(p) then begin
    p = {  $
      ch:0, $
      sgn: 1, $
      d0: 2780d,  $
      v0: 2d,  $
      s1:0.008867d *1000, $
      s2:0d, $
      e0:0d , $
      e1:7.000d , $
      func:'mav_sep_pulseheight3'}
    if  channel le 0 then begin
      p.ch = channel
      p.d0 = 0
      p.v0 = 0
      p.s1 = 0.01 * 2  * 1000
      p.e0 = 1
      p.e1 = 1000
    endif
endif
if n_params() eq 0 then return,p

ddac = (dacv - p.d0)/1000
zz =  p.s1*ddac + p.s2*ddac^2 + p.e0 *  (exp(- ddac /p.e1) -1 )

sgn = p.sgn

if size(/n_dimen,dacv) eq 2 then begin
   sgn = dacv *0 +1
   sgn[*,1] = -1
endif else if sgn eq 0 then begin
   sgn = (zz gt 0) *2 -1
endif

ph =  p.v0 + sgn* zz
return,ph
end







pro mav_sep_tp_calibrate,param=p,window=ww ,channel=channel  ,overplot=overplot,color=color

tpdac = ['0000'x,'0400'x,'0800'x,'0C00'x,'1000'x,'1400'x,'1800'x,'1C00'x,'2000'x,'2800'x, $
    '3000'x,'4000'x,'5000'x,'6000'x,'8000'x,'A000'x,'C000'x,'E000'x,'FFFF'x]


;channel 5
tphght5 = [[-25.5,-19,-12.1,-4.9,1.8,9.2,16.1,24,31.3,47.4,63.4,96.1,130.5,165,233.8,302,373,443,516 ], $
           [29.3,22.6,15.6,8.8,2,-4.7,-12.2,-20.2,-28.3,-44.3,-60.5,-92.5,-128.4,-162.1,-230.5,-298.5,-369.3,-436,-504.5] ]

;channel 6
tphght6 = [[ -30.4,-23.8,-17,-9.2,-2.4,6.4,14.2,22,30.2, 47.2,63.6,98,133,171,242,314,386,460,532  ], $
           [29,22.2,15,7.2,0.2,-8.6,-16.4,-24.2,-32.6,-48.8, -66,-98,-135,-172,-244,-314,-390,-468,-536 ] ]


;tpdel = [0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.08,0.09,0.1,0.11,0.12,0.13,0.14,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1.1,1.2,1.3,1.4]
;tphght0 = [20.22,40.46,60.15,80.28,100.1,121.1,141.7,161.3,181.5,201.7,222,243,262.2,282,401,603,802,995,1190,1377,1573,1760,1950,2145,2336,2516,2704]


if not keyword_set(channel) then channel=0

tpdac = [[tpdac],[tpdac]]

case channel of
    3: tphght = tphght5
    4: tphght = tphght5
    5: tphght = tphght5
    6: tphght = tphght6

    0: begin
        tpdac = 1000*[0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.08,0.09,0.1,0.11,0.12,0.13,0.14,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1.1,1.2,1.3,1.4]
        tphght = [20.22,40.46,60.15,80.28,100.1,121.1,141.7,161.3,181.5,201.7,222,243,262.2,282,401,603,802,995,1190,1377,1573,1760,1950,2145,2336,2516,2704]
       end
endcase
;tphght_all = [[tphght5_1],[tphght5_2],[tphght6_1],[tphght6_2]]



n=n_elements(tpdac)

;if not keyword_set(color) then color=(channel mod 6)+1
;printdat,channel,color

if not keyword_set(p) then begin
   p = mav_sep_pulseheight3(channel=channel)
;   p.ch = channel
endif

dy = sqrt( (tphght * .02)^2 + (.5)^2 )  ;estimate of relative uncertainty

if channel eq 0 then names='d0 s1 e0 e1'

fit,tpdac,tphght,param=p,dy=dy, res=res ,names=names
printdat,p

if keyword_set(ww) then begin
    wi,ww
    if not keyword_set(overplot) then plot,tpdac,tphght,psym=4,xtitle='Test Pulser DAC value',ytitle='Peak Height (mV)',Title='Response to Test Pulser',/nodata,ystyle=2
    oplot,tpdac,tphght,psym=4,color=color
    oplot,!x.crange,!y.crange*0,linestyle = 2,color=color
    pf,p ,col=color
    oplot,tpdac, 10*(tphght - func(tpdac,param=p) ),psym=1,color=color
    pm = p  & pm.sgn = -1
    pf,pm, col=color;+1
    printdat,p,out=out
    xyouts,.15,.85,/norm,strjoin(out+'!c'),color=color
    dp = res.dpar
    printdat,dp,out=out
    xyouts,.55,.85,/norm,strjoin(out+'!c'),color=color
endif

end


function mav_sep_adc_resp,dacv,param=p  ;, peakheight = ph1
if not keyword_set(p) then begin
    if not keyword_set(ph1) then mav_sep_tp_calibrate,param=ph1,window=3,channel=0
    if not keyword_set(ph2) then mav_sep_tp_calibrate,param=ph2,window=3,channel=1,/overplot
    p = { func:'mav_sep_adc_resp', $
          ph1 : ph1,  $
          ph2 : ph2,  $
          binwidth: 1,$
          channel: 0, $
          g:4096d/2500d, $
          baseline: 0d, $
          md:128  }
endif
if n_params() eq 0 then return,p

peak_height = func(dacv,param=p.ph1) >  ( -func(dacv,param=p.ph2) )
adc =  abs( peak_height * p.g ) + p.baseline
return,(adc /p.binwidth) mod p.md
end





function mav_sep_adc_resp2,dacv,param=p  ,channel=channel
if not keyword_set(p) then begin
;    if channel ge -1 then $
;    mav_sep_tp_calibrate,param=ph1,window=3,channel=channel ; $
;    else
    ph1= mav_sep_pulseheight3(channel=channel)

    ph1.sgn = 0

    p = { func:'mav_sep_adc_resp2', $
          ph : ph1,  $
          binwidth: 1,$
          channel: channel, $
          g: 4096d/2500d, $
          baseline: 0d, $
          md:128  }
endif
if n_params() eq 0 then return,p

peak_height = func(dacv,param=p.ph ) - p.ph.v0
adc =  abs( peak_height * p.g ) + p.baseline
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

p = mav_sep_adc_resp2(channel=0)
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

if  ~keyword_set(defcom) then defcom=''
if  ~keyword_set(col) then col = 0
if  ~keyword_set(overplot) then overplot= 0

ctime,tt,npoints=2
if n_elements(tt) eq 2 then t=tt
comment = tsample('CMNBLK_USER_NOTE',t)

if  size(/type,comment) ne 7 then comment=defcom ; else comment=comment[0]
wcomm = where(strmid(comment,0,4) eq 'A250',ncomm)
if ncomm gt 0 then comment=comment[wcomm[0]]

s = reform( tsample('SEP1_SCIENCE_X0',t,times=ts) )
s1= reform( tsample('SEP1_SCIENCE_A', t) )
s2= reform( tsample('SEP1_SCIENCE_S', t) )
mp = reform( tsample('SEP1_HKP_MAPID',t) )
add= reform( tsample('SEP1_HKP_MEM_ADDR',t) )
baselines = tsample('SEP1_NOISE_BASELINE',t, /average)
sigmas    = tsample('SEP1_NOISE_SIGMA',t, /average)
mp = shift(mp,2)
w = where(finite(s))
wmm = minmax(w)
ss =  s[wmm[0]:wmm[1]]
ss1 =  s1[wmm[0]:wmm[1]]
ss2 =  s2[wmm[0]:wmm[1]]
ts =  ts[wmm[0]:wmm[1]]
mp =  mp[wmm[0]:wmm[1]]

ta = average(ts)
pmode = tsample( 'SEP1_HKP_MODE_FLAGS' ,ta)
fto = ishft(pmode,-8) and '3f'x
ch = round( alog(fto) / alog(2) ) +1
baseline = baselines(ch-1)
sigma    = sigmas(ch-1)

if 0 then begin
wi,1  ,/show
plot,ss,psy=-1
plotxyerr,indgen(n_elements(ss)),ss,.4,ss2
oplot,ss1/10.,psym=-1,col=5
oplot,mp,psym=-1,col=6
printdat,ss
wi,4
plot,ss2,psym=-1
oplot,ss2*0 + sigma,color=5
endif

colors = [1,2,3,4,2,6]
col = colors[ch-1]

;col=0

xx = mp * 256.
;xx = add * .1

if not keyword_set(p) then begin
    p = mav_sep_adc_resp2(channel=ch)
    p.baseline = baseline
endif
if ~keyword_set(binwidth) then binwidth = 1

p.binwidth = binwidth
p.md = 256

if not keyword_set(pp) then $
   pp = replicate(fill_nan(p),7)
p.channel  = ch
p0=p
res = ss * 0.
if not keyword_set(thresh) then thresh = 3.
;if not keyword_set(pnames) then pnames = 'g  baseline'
;if not keyword_set(pnames) then  PNAMES = 'ph.s1 ph.d0 ph.e0 ph.e1 baseline'
if not keyword_set(pnames) then pnames = 'ph.d0 ph.s1 ph.s2 baseline'




wi,2,/show
xrange = minmax(xx)
;overplot = ch ne 4
!p.multi= [0,1,2]
cgplot,xx,ss,xstyle=3,title=time_string(ta)+' '+comment,xtitle='Test Pulse DAC value',ytitle='Binned ADC Pulse height value',xrange=xrange,yrange=[-10,260],/ystyle,overplot=overplot,color=col,psym=1
;oplot,xx,ss,psym=1,col=col
oplot,!x.crange,!x.crange*0,linestyle=1

;pf,p,color = 5


mslope = median( (ss-shift(ss,1)) / (xx-shift(xx,1)) ) / p.g *p.binwidth
if 0 then begin
    p.ph.s1 =  mslope *1000  ;initial guess
;    p.ph.s2=0
endif

chi = 5.
res =0
lw=0
res =   (xx gt 11000) *  100
for i=0,5 do begin
  thresh = 5; chi * 4  ; 3 sigma threshold
  w = where(finite(ss) and ss lt 250 and abs(ss1-437) lt 10. and abs(res) lt thresh,ns )
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
yrange = [-1,1]*1
if overplot then restore_plot_state,ps2
cgplot,overplot=overplot,xrange,yrange *0,xrange=xrange,yrange=yrange,xstyle=3,ystyle=3,linestyle=1
oplot,xx,yrange[0] > res*expand < yrange[1],psym=1,col=col
oplot,xx[w],res[w]*expand,psym=4,col=col
;oplot,minmax(xx[w]), [1,1]*thresh*expand,col=0,linestyle=1
;oplot,minmax(xx[w]),-[1,1]*thresh*expand,col=0,linestyle=1
oplot,xx,ss2*10,psym=3,col=col
ps2=get_plot_state()
restore_plot_state,ps1
dp = r.dpar
printdat,p,ns
printdat,p,ns,baseline,output=outs1,/value
printdat,dp,ns,sigma,output=outs2,/value
;xyouts,.15,.35,strjoin(outs1+'!c'),/norm,color=col
;xyouts,.55,.35,strjoin(outs2+'!c'),/norm,color=col

pp[p.channel]= p

preamp = uint(strmid(comment,5,9))

result = { time: t,ta:ta, comment:comment, preamp:preamp, channel:ch, baseline:baseline, sigma:sigma, fitr:r }

!p.multi=0
;makepng,'TPcal2',time=ta,window=2
;makepng,'TPcal1',time=ta,window=1

wshow


if 0 then begin
makepng,'DAP007_cal',window=2,time=average(t)
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


