; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;                         deconvolib
;
;     Library of routines for deconvolution of UBF waveforms
;
; Allows despinning and calibration in nT of waveforms to low
; frequency (typically  0.1-10 Hz)
; 
; Assumes existence of function which returns the 
; complex gain of the antennas in V/nT for a given frequency, 
; antenna,calibration file for a given satellite, and sample 
; frequency.  If given a negative frequency, it must return the
; complex conjugate of the gain. The form of the function must be 
; gainant(f, ix, isat, fe),
; 
; Based on deconvolib by P. Robert CNRS/CETP
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2012-02-21 12:13:01 -0800 (Tue, 21 Feb 2012) $
; $LastChangedRevision: 9797 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_scm_deconvo_vec.pro $
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

pro thm_scm_apotrap, s, ns
; thm_scm_apotrap: apply a trapeziodal window to a waveform. waveform
;                  may be real or complex
; Based on P. Robert's apotrap in deconvolib.f90

na = ns/16

ap = dindgen(na)/double(na-1)

ap_ind = lindgen(na)
s[ap_ind] *= ap

ap_ind = ns -1 - ap_ind
s[ap_ind] *= ap

end

; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0XX

pro thm_scm_corgain, s, ns, df, fe, gainant, ix, pathfil,frq, init=init
; thm_scm_corgain: apply correction for antenna gain to complex 
;                  spectrum s
; parameters:
;   s  : complex spectrum input/output
;   ns : size of s
;   df : frequency step between values of s
;   fe : sampling frequency
;   gainant:  name of gainant routine.
;             if gainant is an empty string, unity gain is used.
;   pathfil:  pathname to calibration file used by gainant
;   ix : antenna number.
;   frq : output: the frequency values for spectrum s.
; keywords:
;   init:  initialize s to unity
; Based on P. Robert's corgain in deconvolib.f90

  if keyword_set(init) then s = dcomplexarr(ns)+complex(1.0,0)
  frq = findgen(ns)*df
  frq[ns/2+1:*] -= float(ns)*df
  ;; IDL version of gainant handles negative frequencies.
  if keyword_set(gainant) then $
     c = call_function(gainant, frq, ix, pathfil, fe) $
  else c = complex(1.0, 0)
  smallc = where(abs(c) lt 1.e-6, nsmallc)
  if nsmallc gt 0 then c[smallc] = complex(1.e-6, 0.)
  s /= c
  ;; FFT of real function must be real at f=0
  s[0]=abs(s[0])*((real_part(s[0]) lt 0) ? -1 : 1) 
end

; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0XX

pro thm_scm_coretar, s, ns, fe, tau
; thm_scm_coretar: apply correction for sample delay of tau seconds 
;                  to complex spectrum s
; Based on P. Robert's coretar in deconvolib.f90

  t = double(ns)/fe
  ns2=ns/2
  
  n = lindgen(ns)
  n[ns2+1:*] -= ns
  teta = 2.0d*!dpi*n*double(tau)/t
  srot = exp(dcomplex(0, 1)*teta)
  s *= srot

end

; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0XX
     
pro thm_scm_filtspe, s, ns, df, f1, f2
; thm_scm_filtspe: filter a complex spectrum s below f1 and above f2
; Based on P. Robert's filtspe in deconvolib.f90

f = findgen(ns)*df
f[ns/2+1:*] -= float(ns)*df
f = abs(f)

; light smoothing below f1 [sic]

;arg = (f/(2*df))**2
;arg = arg < 37.
;af2 = 1.-exp(-arg)

; changed January 21, 2002: rectangular filter
af2 = 1.

filt = where(f lt f1 or f gt f2, nfilt)
if nfilt gt 0 then s[filt] = complex(0., 0.)

;filt = where(f ge f1 && f le f2, nfilt)
;if nfilt gt 0 then s[filt] *= af2

end

; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0XX

;+
; function thm_scm_fastconvol(a, kernel)
; purpose: a wrapper that gives a unified interface to convol and blk_con -
;          Unlike convol, it implements convolution in the mathematical sense 
;          while centering the kernel over each data point. center is at 
;          n_elements(k)/2
;          Unlike blk_con, it implements centering the kernel and the 
;          /edge keywords
;          Default is to zero the edges within n_elements(k)/2 of the edge.
; parameters: 
;       a the data (floating point array).
;       k the kernel to be convolved with the data (floating point array)
; keywords:
;  edge_zero: pad beginning and ending of data with zero
;  edge_truncate: pad beginning and ending of data with first/last value
;  edge_wrap:  pad beginning and ending of data by wrapping data around edge.
;  blk_con: if non-zero, set block size to blk_con times kernel size. if zero
;           always use brute-force convolution.  Defaults to 8.
; Author:
;    Ken Bromund Sept 18, 2007
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2012-02-21 12:13:01 -0800 (Tue, 21 Feb 2012) $
; $LastChangedRevision: 9797 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_scm_deconvo_vec.pro $
;
;-

function thm_scm_fastconvol, a, kernel, edge_zero=edgez, edge_wrap=edgew, $
                             edge_truncate=edget, $
                             blk_con=blk_c

  nbp = n_elements(a)
  nk = n_elements(kernel)
  if size(blk_c, /type) ne 0 then b_length = blk_c * nk else b_length = 8 * nk

  ;; Pad the edges 

  ;;    This duplicates the implementation of the various /edge keywords used by
  ;;    the convol function here to allow use of blk_con as an alternative.
  ;;    This also enables us to avoid using the /center keyword in convol 
  ;;    (i.e. the default behavior):  
  ;;    /center causes convol to use an unconventional definition that would 
  ;;    require reversal of the kernel and re-adjustment of the center. 

  if keyword_set( edgez) then begin
     ao = [fltarr(nk/2), a, fltarr(nk/2)]
  endif else if keyword_set(edget) then begin
     ao = [fltarr(nk/2) + a[0], a, fltarr(nk/2) + a[nbp-1]]
  endif else if keyword_set(edgew) then begin
     ao = [a[nk/2-1-lindgen(nk/2)], a, a[nbp-1-lindgen(nk/2)]]
  endif else ao = a

  ;; perform the convolution.
  if keyword_set(b_length) && b_length lt nbp then begin
     ;; use fast convolution.  
     ao = blk_con(kernel, ao, b_length=b_length)
     ;; if no edge padding, then zero out the edge
     ;; to make blk_con() behave like convol()
     if n_elements(ao) eq nbp then begin
        ao[0:nk-2] = 0
     endif
  endif else begin
     ;; use brute-force convolution
     ao = convol(ao, kernel, center=0)
  endelse

  ;; shift back to zero delay 
  ao = shift(ao, -nk/2)  

  ;; trim any edge padding 
  if n_elements(ao) ne nbp then begin
     ao = ao[nk/2:nbp+nk/2-1]
  endif 
  return, ao
end

; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

pro thm_scm_deconvo_vec, xio, nbp, nk, f1, f2, fe, gainant, ix, pathfil, tau, $
                         edge_truncate=edget, edge_wrap=edgew, edge_zero=edgez,$
                         blk_con=blk_con, plotk=plotk

;+
;Name:
; thm_scm_deconvo_vec
;Purpose:
; continuous calibration accomplished by 
; convolveing a signal with a kernel.
; The kernel is derived by taking the fft of the 
; inverse of the frequency reponse.  The  kernel is also constructed
; to account for any sample delay.
;Inputs:
;    xio: input/output waveform
;    nbp: number of points in xio
;     nk: number of points in kernel: power of 2.
;     f1: low frequency
;     f2: high frequency
;     fe: sample frequency
;gainant: gain function, such as thm_scm_gainant.  If gainant is an empty
;         string, unity gain will be used.
;     ix: antenna number (1,2,3)
;pathfil: calibration file name
;    tau: time correction
;Keywords:
; edge_truncate
; edge_wrap
; edge_zero     same functionality as keywords of same name to convol()
; blk_con       if non-zero, use block convolution (fast FFT-based convolution)
;               with a block size of the value of this keyword times the kernel
;               size.  If data size is too small, it will revert to
;               brute-force convolution.
; plotk         create diagnostic plots of the kernel and frequency response.
;-

  cx = ['','X','Y','Z']

  df = fe/float(nk)

  ;; pre-centering
  xavg = total(xio)/nbp
  xio -= xavg
  
  ;; generate kernel that compensates for gain and sample delay.
  ;; first get desired complex frequency reponse of filter

  s = dcomplexarr(nk)+dcomplex(1.0, 0)

  ;; corgain: inverse of antenna gain (s,nk,df,fe,gainant,ix,pathfil)
  thm_scm_corgain, s, nk, df, fe, gainant, ix, pathfil, frq

  ;; coretar: correct for sample delay (s,nk,fe,tau)
  thm_scm_coretar, s, nk, fe, tau
  
  ;; filtspe: bandpass filter between f1 and f2 (s,nbp,df,f1,f2)
  thm_scm_filtspe, s, nk, df, f1, f2

  ;; inverse fft to obtain kernel
  ks = fft(s, 1) 
  kernel = real_part(ks)

  ;; if we did everything right, the imaginary part truly is negligible
  pr = total(kernel*kernel)
  pi = total(imaginary(ks)*imaginary(ks))
  if pi/pr gt 1.e-5 then begin
     dprint, dlevel=4,  '*** thm_scm_deconvo: Imag/Real for impulse reponse for ', cx[ix], $
            ' =', pi/pr
  endif
  
  ;; zero time of the kernel is at index 0.  Now, shift that to index nk/2
  ;; to get a kernel suitable for linear convolution and
  ;; to allow application of the window.  
  kernel = shift(kernel, nk/2)
  
  ;; As this is a continuous calibration, the window must be applied to the 
  ;; kernel, rather than to the waveform.

  kernel_orig = kernel
  kernel *= hanning(nk, /double) 
  ;; note: application of window introduces a slight offset, which must be 
  ;; removed from the signal afterwards.  
  ;; Correcting for the offset in the kernel itself 
  ;; would nullify the benefit the of window.

  if keyword_set(plotk) then begin
     ;; Optionally make some plots of the kernel and the frequency response.

     ;; show the effect of the window on the frequency response:
     ;; (we expect to see an effect on the phase, when compared
     ;;  to ideal correction spectrum, due to centering of kernel)

     oldwin = !d.window
     oldpmulti = !p.multi
     olddev = !d.name

;     wset, plotk
;     !p.multi=[0,0,4]
     !p.multi=[0,0,3]
     set_plot, 'z'              ;run in z-buffer
     device, set_resolution = [640, 640]


     ;; plot kernel - compare windowed to unwindowed
     plot, lindgen(nk) - nk/2, kernel_orig, /xstyle, color=1, title='red: full kernel, blue: windowed kernel'
     oplot, lindgen(nk) - nk/2, kernel, color=2

     ;; plot amplitude response, compare shifted windowed and unwindowed to
     ;; ideal.
     nk21 = nk/2+1
     plot, shift(frq,-nk21), shift(abs(s),-nk21), /ylog, $
           yrange=[0.01,max(abs(s))], /xstyle, ytitle='log gain', title='amplitude freq. response - white: ideal, red: full kernel, blue: windowed kernel'
     oplot, shift(frq,-nk21), shift(abs(fft(kernel_orig)),-nk21), $
            color=1
     oplot, shift(frq,-nk21), shift(abs(fft(kernel)),-nk21), $
            color=2

     ;; plot phase response, compare shifted windowed and unwindowed to ideal.
     plot, shift(frq,-nk21), shift(atan(s,/ph)*!radeg,-nk21), /xstyle, $
           ytitle='degrees', title='phase freq. response - white: ideal, red: full kernel, blue: windowed kernel'
     oplot, shift(frq,-nk21),shift(atan(fft(shift(kernel_orig, -nk/2)),/ph)*!radeg,-nk21), $
            color=1
     oplot, shift(frq,-nk21), shift(atan(fft(shift(kernel, -nk/2)),/ph)*!radeg,-nk21), color=2

     ;; plot group delay
;     plot, shift(frq,-nk21), -(shift(atan(s, /ph),-nk21-1) - $
;                               shift(atan(s,/ph),-nk21))/(df*2*!dpi), /xstyle

     tvlct, r, g, b, /get
     pfile = plotk
     write_png, pfile, tvrd(), r, g, b

;     wset, oldwin
;     !p.multi = oldpmulti
     set_plot, olddev
;     stop
  endif

  ;; normalize the kernel
  kernel /= nk

  ;; perform the convolution.
  
  ;;  notes on edge behavior:
  ;;  default: zero output when kernel overlaps edge
 ;;;  /edge_zero: usually good, but can emphasize low frequency trends, i.e.
 ;;;                             artifiacts of despin
 ;;;  /edge_wrap; similar to edge zero (based on analysis of cal signal).
 ;;;  /edge_truncate: usually bad

  xio = thm_scm_fastconvol(xio, kernel, blk_con=blk_con, $
                           edge_w=edgew, edge_t=edget, edge_z=edgez)

  ;; post-centering of waveform (necessary because of window)
  xavg = total(xio)/nbp
  xio -= xavg
  
end
