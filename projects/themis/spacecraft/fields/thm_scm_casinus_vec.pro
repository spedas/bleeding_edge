; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

      PRO thm_SCM_casinus_vec, xi,fe,fs,ns,amp,pha,n,nbi, xo, fe_max=fe_max
 
;     ------------------------------------------------------------------
; *   Object : Compute a pure sine from a given signal
; *   Class  : Data processing for GEOS/UBF
; *   Author : P. Robert, CRPE, 1977-1984
;            : Conversion Fortran to IDL, P. Robert, CETP, May 2007
;            : Vectorized by K. Bromund, SPSystems/GSFC, May 2007
;     ------------------------------------------------------------------
 
 
;     The input signal contains a high sine signal, with a known
;     frequency, superimposed to a useful signal.
 
;     Input  :
;          xi:  array containing the signal
;          fe:  sampling frequency 
;          fs:  frequency of the sine signal to be removed
;          ns:  number of spins to use to comput sine wave fit
;     Output :
;         amp:  amplitude of the compute sine signal
;         pha:  phase (d) of the compute sine signal
;           n:  number of points in output
;         nbi:  number of point taken for sine computation
;          xo:  sine-subtracted signal
;     Keyword:
;      fe_max:  max sampling rate: if fe_max is set, then
;               higher sampling rates will be decimated
;               to fe_max, and amplitude and phase results will be linearly
;               interpolated up to full input rate.
 
;     ------------------------------------------------------------------
 
; *** computation of the number of points coresponding to an integer
;     number of the sine period to remove
 

      n= N_ELEMENTS(xi)
      if keyword_set(fe_max) && fe gt fe_max then begin 
         fe_priv = fe_max
         decimation = fe/fe_max
         if decimation ne fix(decimation) then begin
            dprint,  '*** desinus: warning non-integer decimation'
         endif
         n_priv = long(n/decimation)
         xi_index = lindgen(n_priv)*decimation
      endif else begin
         fe_priv = fe
         n_priv = n
         xi_index = lindgen(n)
      endelse
         
         
      nbsp=LONG(FLOAT(n_priv)*fs/fe_priv)  ; number of spins in input data
      nbi =LONG((FLOAT(ns)*fe_priv/fs)+0.5) ;; nuber of points required to 
                                       ;; fit requested number of spins
      if not (nbi mod 2) then nbi+=1  ;; algorithm seems to work better w/ odd
; *** test if one have enough points
      IF (nbsp EQ 0 OR nbi GT n_priv) THEN BEGIN
               DPRINT,  '*** desinus: not enough points to remove the sine'
               DPRINT,  '    at least one sine period is required'
               DPRINT,  '    sampling frequency=',fe_priv
               DPRINT,  '    sine frequency    =',fs
               DPRINT,  '    Number of spins requested for fit: ', ns
               DPRINT,  '    number of points required:',nbi, $
                      '    available=',n_priv
               amp=0.
               pha=0.
;Return NaN's for the output values, jmm 23-Oct-2007
               xo = xi & xo[*] = !values.f_nan
               RETURN
               ENDIF
 
      ; compute the sine waves for fitting
      phase_s = dindgen(nbi)*2*!dpi*fs/fe_priv ;; phase of each sample in kernel
      ss=sin(phase_s) * hanning(nbi) * 2.0
      cc=cos(phase_s) * hanning(nbi) * 2.0

      center = nbi/2  ;integer division intentional


      zs = convol(xi[xi_index], ss)
      zc = convol(xi[xi_index], cc)
      amp=2.*sqrt(zs*zs+zc*zc)/FLOAT(nbi)
      pha=ATAN(zc,zs)  ;; this is correct, because we subtract sin rather than
                       ;; cosine  wave.
      pha += phase_s[center]

      ;; interpolate amplitude and phase to full range and resolution

      amp = interpol(amp[center:n_priv-center-1], $
                     xi_index[center:n_priv-center-1], $
                     lindgen(n))

      ;; be careful when interpolating the phase!  
      ;; first, make phase monotonically increasing
      supplement = 0.d
      for i = center+1, n_priv-center-1 do begin
         diffp = pha[i] + supplement - pha[i-1]
         if diffp gt !dpi then supplement -= 2*!dpi  $
         else if diffp lt -!dpi then supplement += 2*!dpi
         pha[i]+=supplement
      endfor
         
      pha = interpol(pha[center:n_priv-center-1], $
                     xi_index[center:n_priv-center-1], $
                     lindgen(n))
      
; *  subtract sine wave while pha is still in pha radians
      xo = xi - amp * sin(pha)

; *  convert phase in degree for output
 
      pha *= 180./!dpi

      pha mod= 360.

      END

; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

