function spp_wpc_restore_file,file
   restore,verbose=verbose,file
   strct={  $
      filename:  file,  $
      scetstart_ur8:    scetstart_ur8,  $
      dcb_cycles:       dcb_cycles,  $
      dcb_subcycles:    dcb_subcycles,  $
      times_ur8:  time_series_times_ur8,  $
      times:      time_series_times,  $
      raw:        time_series_raw  $
   }
      
   return, strct
end


function spp_wpc_file_retrieve, i, ch  , rootname=rootname

files=['SPF_TDSSWP_20160908_214417_842935', 'SPF_TDSSWP_20160908_220201_447254', 'SPF_TDSSWP_20160908_220840_496968',  $
'SPF_TDSSWP_20160908_214509_243134', 'SPF_TDSSWP_20160908_220221_748757', 'SPF_TDSSWP_20160908_220910_886607',  $
'SPF_TDSSWP_20160908_214546_805215', 'SPF_TDSSWP_20160908_220227_818902', 'SPF_TDSSWP_20160908_220936_447009',  $
'SPF_TDSSWP_20160908_214627_875284', 'SPF_TDSSWP_20160908_220235_165969', 'SPF_TDSSWP_20160908_221003_144347',  $
'SPF_TDSSWP_20160908_214723_185531', 'SPF_TDSSWP_20160908_220252_375948', 'SPF_TDSSWP_20160908_221006_836603',  $
'SPF_TDSSWP_20160908_214832_595938', 'SPF_TDSSWP_20160908_220624_430804', 'SPF_TDSSWP_20160908_221007_688545',  $
'SPF_TDSSWP_20160908_214900_796258', 'SPF_TDSSWP_20160908_220626_440997', 'SPF_TDSSWP_20160908_222432_132445',  $
'SPF_TDSSWP_20160908_214923_516163', 'SPF_TDSSWP_20160908_220627_008953', 'SPF_TDSSWP_20160908_222446_501728',  $
'SPF_TDSSWP_20160908_215137_195388', 'SPF_TDSSWP_20160908_220634_393740', 'SPF_TDSSWP_20160908_222600_741936',  $
'SPF_TDSSWP_20160908_215200_483296', 'SPF_TDSSWP_20160908_220657_966747', 'SPF_TDSSWP_20160908_222643_639807',  $
'SPF_TDSSWP_20160908_215327_075834', 'SPF_TDSSWP_20160908_220724_380343', 'SPF_TDSSWP_20160908_222647_736717',  $
'SPF_TDSSWP_20160908_215336_478779', 'SPF_TDSSWP_20160908_220724_664405', 'SPF_TDSSWP_20160908_222657_710334',  $
'SPF_TDSSWP_20160908_215353_519780', 'SPF_TDSSWP_20160908_220728_356737', 'SPF_TDSSWP_20160908_222805_636710',  $
'SPF_TDSSWP_20160908_215403_744942', 'SPF_TDSSWP_20160908_220735_457218', 'SPF_TDSSWP_20160908_222809_506947',  $
'SPF_TDSSWP_20160908_215443_790063', 'SPF_TDSSWP_20160908_220759_314927', 'SPF_TDSSWP_20160908_222839_112974',  $
'SPF_TDSSWP_20160908_215739_018948', 'SPF_TDSSWP_20160908_220759_598882', 'SPF_TDSSWP_20160908_223159_034116',  $
'SPF_TDSSWP_20160908_215804_012997', 'SPF_TDSSWP_20160908_220817_208252', 'SPF_TDSSWP_20160908_223239_068433',  $
'SPF_TDSSWP_20160908_215929_215454', 'SPF_TDSSWP_20160908_220818_912608', 'SPF_TDSSWP_20160908_223300_465442',  $
'SPF_TDSSWP_20160908_215935_463581', 'SPF_TDSSWP_20160908_220837_656913', 'SPF_TDSSWP_20160908_223333_214935',  $
'SPF_TDSSWP_20160908_215936_031598', 'SPF_TDSSWP_20160908_220840_212997']

files = files[sort(files)]

dir = 'spp/data/sci/sweap/prelaunch/gsedata/EM/wpc/ion/' 
ending = ['_Ch0.sav', '_Ch1.sav']

rootname= files[i]

file = spp_file_retrieve(dir + rootname +ending[ch] )

return, file
end



function spp_wpc_time_rebin,x,nb,average=average
   nb = round(nb)
   ns = n_elements(x)
   ns2 = ns / nb
   remainder = ns mod nb
   dprint,remainder
   x2 = total(/preserv, reform(x[0:ns-remainder-1],nb,ns2 ) , 1)
   if keyword_set(average) then x2 /= nb
   return, x2
end


function spp_wpc_sin,time,param=par
  if n_elements(par) eq 0 then  par = {func: 'spp_wpc_sin',a:1d, f:1d, shift:0d }
  if n_params() eq 0 then return, par
  phase = time *par.f
  return, par.a* sin(2*!dpi*(phase - par.shift) )
end


function spp_wpc_get_phase,time,signal,par=par
  wpzc = where(signal le 0 and shift(signal,-1) gt 0,nwzc)
  if 0 then begin
   if wpzc[0] eq 0 then wpzc = wpzc[1:*]
   wnzc = where(signal gt 0 and shift(signal,-1) le 0,nwzc)
   if wpzc[0] eq 0 then wpzc = wpzc[1:*]
   par= polycurve()
   x = time[wzc]
   y =  findgen(n_elements(x)) +.25
   dprint,x,y
   fit,x,y,param=par,names='a0 a1'
   printdat,par
   phase = func(time,param=par)
   return,(phase - floor(phase))
  endif else begin
    par = spp_wpc_sin()
    trange = minmax(time)
    par.f  =  (nwzc > 1) / (trange[1]-trange[0])
    printdat,nwzc
    fit,time,signal,par=par,name='shift'
    fit,time,signal,par=par
    phase = time * par.f - par.shift  +.25
    return, phase -floor(phase)
  endelse
   
end

pro spp_wpc_make_plots,fn
if not keyword_set(fn) then fn=0

s0 = spp_wpc_restore_file( spp_wpc_file_retrieve(fn,0,rootname=rootname) )
s1 = spp_wpc_restore_file( spp_wpc_file_retrieve(fn,1) )


ns = n_elements(s0.raw)
dt = 5.2084215e-07; *1000
dt = 1/19.2d6 *10 ;* 1000   ; time res of SPP spane
time = dindgen(ns) * dt
wi,0
!p.multi = [0,1,3]
!p.charsize=2
signal = s1.raw / 16384.   ; Guessing scale here!
xrange = minmax(time *1000)

tres = dt
phase = spp_wpc_get_phase(time,signal,par=par)
stitle = file_basename(s0.filename) + '   F= '+ strtrim(round(par.f),2)+ ' Hz'
plot,/nodata,[0,1],yrange=[-1.2,1.2],/ystyle,xrange=xrange,xstyle=3,xtitle='Time (ms)',ytitle='Signal Voltage (V)',title=stitle
oplot,time*1000,signal
oplot,time*1000,phase , color=2,linestyle=2
oplot,time*1000,func(time,param=par),color=6
;plot,time*1000,phase,xrange=xrange,xstyle=3,xtitle='Time (ms)',ytitle='Signal Phase (radians)',title=''

tres_string = string(tres*1000000,format='(f0.3," uSec")')
tcounts = total(/pres,s0.raw)
ctitle = 'Time resolution = '+tres_string+ '  Total counts='+strtrim(tcounts,2)

plot,time*1000,s0.raw,xrange=xrange,xstyle=3,xtitle='Time (ms)',ytitle='Counts/bin',title=ctitle

nb=256
nb = round(16384/10.)   ;SPP SPAN time res
;nb /= 4
printdat,nb

tres = nb*dt
raw =  spp_wpc_time_rebin( s0.raw,nb) 
tcounts = total(/pres,raw)

t   =  spp_wpc_time_rebin( time,nb,/average)
tres_string = string(nb * dt*1000000,format='(f0.1," uSec")')
ctitle = 'Time resolution = '+tres_string+ '  Total counts='+strtrim(tcounts,2)
plot,t*1000,raw,psym=10,xrange=xrange,xstyle=3,ystyle=2,xtitle='Time (ms)',ytitle='Counts/bin',title=ctitle

makepng,rootname+'_plot1'

wshow
wi,1
!p.multi=[0,1,2]
!p.charsize=1.2
np = 20
pbin = floor(phase * np)
phasebins = (findgen(np)+.5) / np

sig_phase = average_hist(signal,pbin,ret_total=0)
plot,phasebins, sig_phase,psym=10,yrange=[-1.1,1.1],/ystyle,title=stitle,ytitle= 'Average Signal',xtitle='Signal Phase/2Pi'
oplot,phase,signal,psym=3,color=6

raw_phase = average_hist(s0.raw*1.,pbin,ret_total=0)
printdat,pbin,raw_phase,s0.raw
plot,phasebins,raw_phase,psym=10,title='',ytitle ='Average number of Counts',xtitle='Signal Phase / 2Pi '



printdat,total(s0.raw)
printdat,total(raw)
makepng,rootname+'_plot2'

;wi,2
;wsff=fft2(s0.raw)
stop

wshow
wi,0

end


spp_wpc_make_plots,fn


end
