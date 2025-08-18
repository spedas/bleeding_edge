;+
; NAME:
; cross_spec
;
; PURPOSE:
; This function estimates the power cross-spectrum of two vectors.
;
; CATEGORY:
; Time Series Analysis
;
; CALLING SEQUENCE:
; Result = cross_spec(Y1, Y2)
;
; INPUTS:
; Y1:  A floating point vector of the same length as Y2.
; Y2:  A floating point vector of the same length as Y1.
;
; OPTIONAL INPUTS:
; -
; DELTAT, WIDTH, WINDOW
;
; KEYWORD PARAMETERS:
; AMPLITUDE:  Returns the amplitude component of the cross-spectrum.
; AUTOSPEC1:  Returns the auto-spectrum of Y1.
; AUTOSPEC2:  Returns the auto-spectrum of Y2.
; COHERENCY:  Returns the coherency of Y1 and Y2.
; DELTAT:  The time interval between values in the input vectors.
; DOUBLE:  If set the calculations are performed in double precision 
;   arithmetic.  The default is single precision.
; FREQ:  Returns the frequency values corresponding to the output 
;   cross-spectrum.
; PHASE:  Returns the phase component of the cross-spectrum, in radians. 
;   Positive values mean that Y1 is leading Y2 at that frequency.
; WIDTH:  The width, of type integer, of the smoothing window to be used 
;   by FILTER.pro.  If not given then no smoothing is performed.
; WINDOW:  A string containing the name of the smoothing window to be 
;   used by FILTER.pro.  Smoothing is only performed if WIDTH is 
;   given.
;
; OUTPUTS:
; Result:  Returns the cross-spectrum.
; AMPLITUDE, AUTOSPEC1, AUTOSPEC2, COHERENCY, FREQ, PHASE
;
; USES:
; FILTER.pro
;
; PROCEDURE:
; This function uses the FFT function to estimate the spectra.
;
; EXAMPLE:
; Create two time series of a periodic signal of period 23 and phase 
; difference pi/2.  Add a pinch of noise.
;   y1 = sin(6.28*findgen(1000)/23.)+0.1*randomn(1, 1000)
;   y2 = sin(6.28*(findgen(1000)/23.-0.25)) $
;       +0.1*randomn(2, 1000)
; Estimate the cross-spectrum.
;   result = cross_spec(y1, y2, amplitude=amplitude, phase=phase, freq=freq)
; The amplitude power spectrum should have a peak at freq=1./23., and 
; the phase at that frequency should be 0.5.
; 
;CODE:
; A. Shinbori, 30/09/2011.
;
;MODIFICATIONS:
; A. Shinbori, 30/10/2011
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-


function cross_spec, $
  Y1, Y2, $
  DELTAT=deltat, $
  WIDTH=width, WINDOW=window, $
  AMPLITUDE=amplitude, PHASE=phase, $
  AUTOSPEC1=autospec1, autospec2=autospec2, $
  COHERENCY=coherency, $
  FREQ=freq, $
  DOUBLE=doubleopt

;***********************************************************************
; Constants

; Vector length
ny = n_elements(y1)
if ny ne n_elements(y2) then begin
   print, 'In cross_spec(), y1 and y2 have diffferent array sizes!'
   return, 0
endif

; The default time step
if not(keyword_set(deltat)) then deltat = 1.

;***********************************************************************
; Estimate the Periodogram

; Estimate the Fourier Transforms
han = hanning(ny,ALPHA=0.54, /DOUBLE) 
z1 = fft(y1*han, double=doubleopt)
z2 = fft(y2*han, double=doubleopt)

; Estimate the periodograms
crossspec12 = z1*conj(z2)
autospec1 = real_part(z1*conj(z1))
autospec2 = real_part(z2*conj(z2))

; Optional smoothing of the periodograms
if keyword_set(width) then begin
   crossspec12 = filter(crossspec12, width, window)
   autospec1 = filter(autospec1, width, window)
   autospec2 = filter(autospec2, width, window)
endif

; Estimate the coherency
coherency = abs(crossspec12)^2/(abs(autospec1)*abs(autospec2))

; Transform output into positive frequency format
crossspec12 = [crossspec12[0], 2*crossspec12[1:ny/2-1], crossspec12[ny/2]]
autospec1 = [autospec1[0], 2*autospec1[1:ny/2-1], autospec1[ny/2]]
autospec2 = [autospec2[0], 2*autospec2[1:ny/2-1], autospec2[ny/2]]
coh = coherency[0:ny/2]

; And the corresponding frequencies are
freq = findgen(ny/2+1)/(ny*deltat)
freq=freq[1:ny/2]

; Extract the amplitude and phase components of the cross-spectrum
amplitude = abs(crossspec12)
phase = atan(imaginary(crossspec12), real_part(crossspec12))


;========================================================================================================================    
;Definition of structure of xspec_data containing the frequency, power spectrum, cross spectrum, coherence and phase lag:
;========================================================================================================================
xspec_data={f:freq,x:autospec1,y:autospec2,xy:crossspec12,absxy:amplitude,cxy:coh,lag:phase}

return, xspec_data
;***********************************************************************
; The End
end