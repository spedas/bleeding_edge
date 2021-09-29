;+
; PROCEDURE:
;       mex_marsis_spectrogram
; PURPOSE:
;       generates tplot variables of MARSIS spectrograms
; CALLING SEQUENCE:
;       mex_marsis_spectrogram
; KEYWORDS:
;       
; CREATED BY:
;       Yuki Harada on 2017-05-11
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-04-06 01:38:33 -0700 (Fri, 06 Apr 2018) $
; $LastChangedRevision: 25009 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/marsis/mex_marsis_spectrogram.pro $
;-

pro mex_marsis_spectrogram, suffix=suffix, drange=drange, aaltrange=aaltrange

if ~keyword_set(suffix) then suffix = ''

@mex_marsis_com

if size(marsis_ionograms,/type) eq 0 then begin
   dprint,'No ionogram data are loaded'
   return
endif

t = marsis_ionograms.time
ff = transpose(marsis_ionograms.freq) /1e6
sss = transpose(marsis_ionograms.spec,[2,0,1])

drtitle = ''
if n_elements(drange) eq 2 then begin
   drtitle = 'Delay: '+string(drange[0],f='(f3.1)')+'-' $
             +string(drange[1],f='(f3.1)')+' ms!c'
   w = where( marsis_delay_times/1e3 gt drange[0] $
              and marsis_delay_times/1e3 lt drange[1] , comp=cw, ncomp=ncw)
   if ncw gt 0 then sss[*,*,cw] = !values.f_nan
endif

if n_elements(aaltrange) eq 2 and size(marsis_geometry,/type) ne 0 then begin
   arange = transpose(rebin( 0.1499 * marsis_delay_times , 80, n_elements(t) ))
   alt = interp(marsis_geometry.alt,marsis_geometry.time,t,interp=10)
   aalt = rebin(alt,n_elements(t),80) - arange
   drtitle = 'H'+string(39b)+': '+string(aaltrange[0],f='(i0)')+'-' $
             +string(aaltrange[1],f='(i0)')+' km!c'
   w = where( aalt gt aaltrange[0] $
              and aalt lt aaltrange[1] , comp=cw, ncomp=ncw)
   ww = aalt*!values.f_nan
   ww[w] = 1.
   www = rebin(ww,n_elements(t),80,160)
   www = transpose(www,[0,2,1])
   sss = sss * www
endif

store_data,'mex_marsis_freq_sdens'+suffix, $
           data={x:t,y:average(sss,3,/nan),v:ff}, $
           dlim={ytitle:drtitle+'Frequency!c[MHz]',yrange:[0,max(ff,/nan)], $
                 ystyle:1, $
                 ztitle:'Average!cSpectral Density!c[(V/m)!u2!n/Hz]', $
                 spec:1,zlog:1,zrange:[1e-18,1e-10],datagap:10}

store_data,'mex_marsis_freq_sdens_med'+suffix, $
           data={x:t,y:median(sss,dim=3),v:ff}, $
           dlim={ytitle:drtitle+'Frequency!c[MHz]',yrange:[0,max(ff,/nan)], $
                 ystyle:1, $
                 ztitle:'Median!cSpectral Density!c[(V/m)!u2!n/Hz]', $
                 spec:1,zlog:1,zrange:[1e-18,1e-10],datagap:10}

store_data,'mex_marsis_freq_sdens_max'+suffix, $
           data={x:t,y:max(sss,dim=3,/nan),v:ff}, $
           dlim={ytitle:drtitle+'Frequency!c[MHz]',yrange:[0,max(ff,/nan)], $
                 ystyle:1, $
                 ztitle:'Max.!cSpectral Density!c[(V/m)!u2!n/Hz]', $
                 spec:1,zlog:1,zrange:[1e-18,1e-10],datagap:10}

end
