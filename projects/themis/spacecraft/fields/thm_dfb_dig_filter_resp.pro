

;------------------------------------------------
; Calculates the transfer function for the FIR filters internal to each
; stage in the DFB cascade.  To get the transfer function for a given stage,
; call DFB_transfer (which uses this function as a subroutine).
;   Input:  normalized angular frequency
;   Output: transfer function of FIR filters
;------------------------------------------------
function DFB_FIR_transfer,omega
  ; Calculate transfer function of filter 1
  ; with coefficients [-8,0,72,128,72,0,-8]/256
  I = dcomplex(0,1)
  h = (-8)  + $
        72*(cos(2*omega)-I*sin(2*omega)) + $
       128*(cos(3*omega)-I*sin(3*omega)) + $
        72*(cos(4*omega)-I*sin(4*omega)) + $
      (-8)*(cos(6*omega)-I*sin(6*omega))
  h/=256.

  ; Multiply by transfer function of filter 2
  ; with coefficients [1/4, 1/2, 1/4]
  h *= 0.25 + $
        0.5*(cos(  omega)-I*sin( omega)) + $
       0.25*(cos(2*omega)-I*sin(2*omega))
return,h
end

;------------------------------------------------
; Calculates the transfer function for the DFB filters at a given level
;   Inputs: frequency normalized to sampling Nyquist frequency
;              (i.e. f/4096 or f/8192)
;           filter bank level
;   Output: complex transfer function at given frequencies
;------------------------------------------------
function DFB_transfer,f,level
  ; Use normalized angular frequency
  omega = f*!dpi

  if level eq 0 then return, dcomplexarr(n_elements(f)) + dcomplex(1,0)

  ; For level 1, transfer function is just FIR transfer function
  h = DFB_FIR_transfer(omega)

  ; For higher levels, multiply by all transfer functions,
  ; making sure to appropiately fold in aliasing
  for i=1,level-1 do h*= DFB_FIR_transfer(omega*2^i)

return,h
end

;------------------------------------------------
;+
; function thm_dfb_filter(f, fsamp)
;  purpose: Calculates the transfer function for the DFB digital
;           filters at a given sample rate.
;   Inputs: f     frequency in Hz
;           fsamp Sampling frequency of telemetry signal.
;                 Level of DFB filtering will be calculated
;                 based on the raw sampling rate.
;   Keyword:Eac   Set this keyword if the data is AC-coupled EFI data.
;   Output: transfer function at given frequencies -- abs taken, since
;           phase is adjusted for in L0->L1 processing.
;   Author: Ken Bromund, as a wrapper around routines written by Chris Cully.
;   Change history:
;     2012-08-30: CMC. Added EAC support.
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2012-08-30 14:10:35 -0700 (Thu, 30 Aug 2012) $
;$LastChangedRevision: 10886 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_dfb_dig_filter_resp.pro $
;-
;------------------------------------------------
function thm_dfb_dig_filter_resp, f, fsamp, Eac=Eac
  if keyword_set(Eac) then f_native=16384.0 else f_native=8192.0
  level = fix(alog(f_native/fsamp)/alog(2) + 0.4)
  dprint, dlevel=4, 'Fsamp: ', fsamp, '  Filter bank level: ', level
  if level lt 0 then message, 'fsamp is greater than DFB sampling rate for ' + $
                              'DC-coupled inputs'
  return, abs(DFB_transfer(2*f/f_native,level))
end

