;+
; swfo_pulser_cal
; $LastChangedBy: ali $
; $LastChangedDate: 2021-09-08 19:12:56 -0700 (Wed, 08 Sep 2021) $
; $LastChangedRevision: 30285 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_pulser_cal.pro $
; $ID: $
;-


function swfo_testpulse_response,x,parameter=p
  if ~keyword_set(p) then begin
    p= { func:'swfo_testpulse_response',dac0:1600d,adc0:0.3d,gain:14d,gain2:0d,gain3:0d,gain4:0.d,modv:256.}
  endif
  if n_params() eq 0 then return, p
  dx = (x-p.dac0)/1000
  adc = p.adc0 + abs( p.gain * dx + p.gain2 * dx^2  + p.gain3 * dx^3 + p.gain4 * dx^4)
  adc = abs(adc mod p.modv)
  return,adc
end

function swfo_testpulse_response2,x,parameter=p
  if ~keyword_set(p) then begin
    p= { func:'swfo_testpulse_response2',dac0:1600d,adc0:0.3d,gain:14d,gain2:0d,gain3:0d,gain4:0.d,modv:256.}
  endif
  if n_params() eq 0 then return, p
  dx = p.gain*(x-p.dac0)/1000
  adc = p.adc0 + abs( dx + p.gain2 * dx^2  + p.gain3 * dx^3 + p.gain4 * dx^4)
  adc = abs(adc mod p.modv)
  return,adc
end


pro swfo_pulser_cal, results=results  ;,dat=dat,trange=trange,param=p,bkg_trange=bkg_trange

  if ~isa(results,'dictionary') then begin
    results = dictionary()
  endif

  if ~results.haskey('trange') then begin
    ctime,trange,npoints=2
    results.trange = trange
    if results.haskey('ddata') then results.remove,'ddata'
  endif

  if ~results.haskey('ddata') then begin
    hkp1 = swfo_apdat('stis_hkp1')
    sci =  swfo_apdat('stis_sci')
    trange = results.trange
    timebar,trange
    hkp_sample = hkp1.data.sample(range=trange,tag='time')
    w = where(hkp_sample.last_cmd eq 0x38,nw)
    tb = hkp_sample[w].time
    ;timebar,tb
    t1=tb[0:-2]
    t2=tb[1:-1]
    ;print,t2-t1
    tr2 = transpose([[t1],[t2]])
    ns = nw-1
    da = dynamicarray(name='peakfit')


    if n_elements(bkg_trange) eq 2 then begin
      dprint,'Subtracting background'
      bkg_sample =sci.data.sample(range=bkg_trange,tag='time')
      bkg_avg = average(bkg_sample)
      bkg_dat = bkg_avg.counts
    endif else bkg_dat=0

    for i=0,ns-1 do begin
      tr = tr2[*,i]
      hkp_samples = hkp1.data.sample(range=tr,tag='time')
      sci_samples = sci.data.sample(range=tr,tag='time')
      sci_average = average(sci_samples)
      if n_elements(sci_samples) le 2 then continue
      ser_num = median(sci_samples.mode2)
      dac = median( hkp_samples.dac_vals[10] )
      h = average(sci_samples.counts,2) - bkg_dat
      ;plot,h
      pks = find_mpeaks(h)
      if (n_elements(pks.g)  gt 1) && (abs(pks.g[0].x0 - pks.g[1].x0) lt 15) then begin
        dprint,'two samples'
        print,pks.g
      endif else begin
        mx = max( pks.g.x0 ,bmx)
        g = pks.g[bmx]
        res = {time:sci_average.time, dac:dac,amp: g.a , x0:g.x0,  sigma:g.s }
        da.append,res
      endelse
    endfor
    da.trim
    results.ddata = da
    printdat,ser_num
    results.ser_num = round(ser_num)
  endif

  if ~results.haskey('param') then begin
    da = results.ddata
    dat = da.array
    p =  swfo_testpulse_response2()
    title = 'A250F Serial Num: '+string(results.ser_num) + '    '+strjoin(time_string(results.trange),' to ')

    ok=1
    med_amp = median(dat.amp)
    med_sigma = median(dat.sigma)

    ok = ok and dat.amp gt .8 * med_amp
    ok = ok and dat.amp lt 1.2 * med_amp
    ok = ok and dat.sigma gt .8 * med_sigma
    ok = ok and dat.sigma lt 1.2 * med_sigma

    ;ok = ok and dat.x0 gt 5
    ok = ok and dat.x0 lt 250

    ; ok = ok and dat.dac lt 1.7e4
    ; ok = ok and dat.dac gt 3e3

    w=where(ok and dat.dac lt 1.7e4)
    fit,dat[w].dac,dat[w].x0,dy = dat[w].sigma,param=p,result=fit_result

    w=where(ok and dat.dac lt 3.4e4)
    fit,dat[w].dac,dat[w].x0,dy = dat[w].sigma,param=p,result=fit_result

    w=where(ok and dat.dac lt 5.2e4)
    fit,dat[w].dac,dat[w].x0,dy = dat[w].sigma,param=p,result=fit_result

    w=where(ok and dat.dac lt 6.6e4)
    fit,dat[w].dac,dat[w].x0,dy = dat[w].sigma,param=p,result=fit_result
    fit,dat[w].dac,dat[w].x0,dy = dat[w].sigma,param=p,result=fit_result

    !p.multi = [0,1,2]
    wi,1
    plot,dat.dac,dat.x0,psym=4,xstyle=3,xtitle='DAC number',ytitle='ADC Bin of pulse',yrange=[-10,265],/ystyle,title=title
    oplot,dgen(),dgen()*0,linestyle=1
    oplot,dat.dac, dat.amp/10,color=4,psym=-4
    oplot,dat.dac, dat.sigma*100, psym=-4,color=2
    ;oplot,dat.dac, dat.x0 ,psym=4
    pf,p
    oplot,dat[w].dac, dat[w].x0, psym=4, color=6

    residual = dat.x0 - func(dat.dac,param=p)
    plot,dat.dac, residual, psym=2, yrange =[-3,3],xstyle=3,xtitle='DAC number',ytitle='Residual ADC '  ;,color=4
    oplot,dgen(),dgen()*0,linestyle=1
    oplot,dat[w].dac,residual[w],color=6,psym=2
    !p.multi=0
    results.fit_res = fit_result
  endif

end


