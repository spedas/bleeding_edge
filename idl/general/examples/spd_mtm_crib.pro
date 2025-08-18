pro spd_mtm_crib
t = [0:511] ; time vector, suppose dt = 1s
x = 0.5*cos(2.0*!pi*t/8.0) + randomn(3,512,1) ; time series
data = [[t],[x]]

spd_mtm, data=data, NW=3, Ktpr=5, padding=1, dpss=dpss, $
  flim=[0,1], smoothing='all', $   ;  psmooth=2, $
  model='wht', procpeak=['gt','gft'], $
  conf=[0.90,0.95d],$
  /makeplot, $
  x_label='Time', y_units='##', $
  x_units='min', x_conv=1.0/60.0, $
  f_units='mHz', f_conv=1d3, $
  spec=spec, peak=peak, par=par, ipar=ipar
stop 

; plot the adaptive MTM PSD
r = plot(spec.ff, spec.raw, /ylog)

stop

; plot the selected PSD background
r = plot(spec.ff, spec.back, 'r', /overplot)
stop

; plot confidence threshold for the PSD
r = plot(spec.ff, spec.back*spec.conf[0], 'r--', /overplot)
stop

; plot a smoothed PSD
; (N.B. The smoothing approach has to be present the inputs)
r = plot(spec.ff, spec.smth[1,*]) ; med
r = plot(spec.ff, spec.smth[2,*]) ; mlog
r = plot(spec.fbin, spec.smth[3,*]) ; bin
r = plot(spec.ff, spec.smth[4,*]) ; but
stop

; plot a fitted PSD model on a smoothed PSD
; (N.B. The model has to be present the inputs)
r = plot(spec.ff, spec.modl[0,0,*]) ; raw/WHT
r = plot(spec.ff, spec.modl[3,1,*]) ; bin/PL
r = plot(spec.ff, spec.modl[2,2,*]) ; mlog/AR(1)
r = plot(spec.ff, spec.modl[3,3,*]) ; bin/BPL
stop

; to recover the identified peaks:
indices_peaks = where(peak.pkdf[0,0,*] gt 0)

; N.B.
; peak.pkdf[0,0,*] -> gamma test, lowest confidence level (from conf)
; peak.pkdf[2,0,*] -> gamma and F test, lowest confidence level (from conf)
; peak.pkdf[0,-1,*] -> gamma test, highest confidence level (from conf)

if (indices_peaks[0] ge 0) then begin
   signals_frequency = peak.ff[indices_peaks]
endif

print,signals_frequency


end
