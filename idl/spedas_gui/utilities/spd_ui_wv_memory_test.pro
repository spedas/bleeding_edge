;+
;NAME:
;spd_ui_wv_memory_test
;PURPOSE: 
;Estimate of memory used by a wavelet transform. The estimated memory
;use is 36.26*n_elements(transformed_data.y). The factor of 36 comes
;from testing different transforms for different types of data, for
;fgm (FGH and FGS) data, 2009-01-14, for ESA L2 density data
;2007-07-07, and for GMAG data for both of those days. Note that this
;is currently only useful for default inputs.
;INPUT: 
; t = the time array
;OUTPUT: 
; jv = the number of wavelets to eventually be used, jv must be GT 1
;      for the wavelet2 routine to work.
; prange = the default period range of the output, 
;          nyquist period, 5% of time period]
; info_txt = Informational test array, with memory sizes, and jv value
;HISTORY:
; 10-jun-2009, jmm, added jv output to test for a reasonable number of
; wavelets later.
; 19-Jan-2015, jmm, Changed the name and separated into a new file
; 6-feb-2015, jmm, Added frange output, for the default frequency range
;$LastChangedBy: jimm $
;$LastChangedDate: 2015-02-09 13:28:13 -0800 (Mon, 09 Feb 2015) $
;$LastChangedRevision: 16922 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_wv_memory_test.pro $
;-
Function spd_ui_wv_memory_test, varname, t, jv, prange, info_txt, $
                                memok = memok, jvok = jvok

  memok = 0b & jvok = 0b
  jv = 0 & prange = [0.0, 0.0]
  
  n = n_elements(t)
  dt = (t[1:*]-t)
  
  ;dt = mean(t[1:*]-t)
;Hacked from wavelet2.pro -- these are defaults different from wavelet.pro
  ;w0 = 2.*!pi
  ;dj = 1/8.*(2.*!pi/w0)
  ;prange = [2.*dt, 0.05*n*dt] ; default range = nyquist period - 5% of time period
  ;srange = (2.*dt > prange < n*dt) * (w0+sqrt(2+w0^2))/4/!pi
  ;srange = (prange) * (w0+sqrt(2+w0^2))/4/!pi ;srange are the scales of the wavelets
  ;jv = FIX((ALOG(srange[1]/srange[0])/ALOG(2))/dj);jv+1 is the number of wavelets used


;Check for resampling later in wave_data procedure,
;default is to use mean value
  if total(abs(minmax(dt)/mean(dt)-1)) gt .01 then begin
    dprint,'Using resampled estimate'
        
    ;Resampling will occur at intervals of the median period, 
    times = round(dt/median(dt))

    ;Get total number of points in resample
    n = total(times, /preserve) + 1
    
  endif
  ;jv+1 is the number of wavelets used
  jv = fix( 8*( alog(.05*n)/alog(2) -1 ) ) ;simplified calculation
;prange = [2.*dt, 0.05*n*dt] ; default range = nyquist period - 5% of time period
  prange = [2.*median(dt), 0.05*n*median(dt)]
  
;The memory used in bytes is approximately 36 times the number of
;elements in the final product.  Added 16% margin to account for spikes.
  memtest = 1.16*36.26*float(n)*float(jv+1)/1.0e6
  mem_av = get_max_memblock2()
  info_txt = ['Variable; '+varname,$
              'Estimated Memory Usage: '+string(memtest, '(e10.2)')+' Mbytes, ', $
              'Estimated Memory Available: '+string(mem_av, '(e10.2)')+' Mbytes.', $
              'Estimated number of wavelet values: '+string(jv, '(i9)')+'.', $
              'Minimum wavelet period: '+string(prange[0], '(e10.2)')+' Seconds.', $
              'Maximum wavelet period: '+string(prange[1], '(e10.2)')+' Seconds.'  ]
  If(mem_av Gt memtest) Then memok = 1b Else memok = 0b
  If(memok) Then imem = 'Memory Test: OK' Else imem = ['Memory Test: FAIL', 'Maybe choose a shorter time range']
  If(jv Gt 2) Then jvok = 1b Else jvok = 0b
  If(jvok) Then jmem = 'Number Test: OK' Else jmem = ['Number Test: FAIL', 'Maybe choose a longer time range']
  info_txt = [info_txt, imem, jmem]


  Return, memtest
  
End


