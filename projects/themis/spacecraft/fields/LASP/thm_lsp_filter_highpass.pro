;+
; NAME: 
;     THM_LSP_FILTER_HIGHPASS (FUNCTION)
;                        
; PURPOSE:
;     CAUTION: THIS ROUTINE ONLY WORKS FOR DATA SAMPLED AT EITHER 8192 HZ OR
;              16384 HZ.
;     In general, this routine works as a high-pass filter on the input data.
;     The data to be filtered must be a continuously sampled 1D array. The basic
;     process of this routine is the following. First, the input data will be
;     low-pass filtered with two Finite Impulse Response filters and 2:1
;     decimations. The details of this procedure is described in the paper
;        Cully, Space Sci Rev, 2008, V141, 343-355.
;     Second, the output from the first step is extracted from the input data to
;     generate the final output. This whole process is equivalent to a high-pass
;     filter. 
;     If the routine exit unsuccessfully, -1 will be retured.
;
; CALLING SEQUENCE:
;     output = thm_lsp_filter_highpass(datain, dt, [keywords])
;
; ARGUMENTS:
;     datain: (INPUT, REQUIRED) The data to be filtered. It must be a 1D array.
;     dt: (INPUT, REQUIRED) The sample interval of DATAIN in seconds; 
;           1/dt = sample_rate.
;
; KEYWORDS:
;     freqlow: (OUTPUT, OPTIONAL) The approximate lower bound of the frequency
;              range of the output of the routine.
;
;HISTORY:
;    2009-05-03: Created by Jianbao Tao, CU/LASP.
;    2009-05-17: Fixed the edge effect due to sectioning original data.
;                Jianbao Tao, CU/LASP
;    2010-01-22: Fixed the issue of dealing with a too-short input array.
;                Jianbao Tao, CU/LASP
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-07-27 12:29:50 -0700 (Fri, 27 Jul 2012) $
; $LastChangedRevision: 10753 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/LASP/thm_lsp_filter_highpass.pro $
;-

function thm_lsp_filter_highpass, datain, dt, freqlow = freqlow

;check if the argument list is complete
con1 = n_elements(datain) eq 0
con2 = n_elements(dt) eq 0
con = con1 + con2 
if con ge 1 then begin
   print, 'THM_LSP_FILTER_HIGHPASS: ' + $
         'At least one argument is missing. Please check the'+$
            'help of the routine for required arguments.'
   return, -1
endif
;check the dimension of data
data = datain
tmp1 = size(data,/dim)
if n_elements(tmp1) gt 1 then begin
   print, 'THM_LSP_FILTER_HIGHPASS: ' + $
         'The data to be filtered must be a 1-D array.'
   return, -1
endif
;check the dimension of dt
tmp1 = size(dt,/dim)
if tmp1[0] ne 0 then begin
   print, 'THM_LSP_FILTER_HIGHPASS: ' + $
         'The sample interval of the data must be a scalar.'
   return, -1
endif

npt = float(n_elements(data))
tlen = dt * (npt - 1)
fmin = 1. / tlen  ; the minimum freq that the input data can include.

;clean up all NAN's, if there are any, in the data by interpolation.
dumx = dindgen(npt)
ind = where(~finite(data,/nan))
if ind[0] eq -1 then begin
   print, 'THM_LSP_FILTER_HIGHPASS: ' + $
      'All data points are NaNs. Do nothing.'
   return, data
endif
data = interpol(data[ind],dumx[ind],dumx)
data = data - median(data) ; Remove offset

; Filter the data with a Finite Impulse Response digital filter.
; reference:
;     Cully, Space Sci Rev, 2008, 141:343-355
;fhigh = 0.035
;flow = 0.0
;amp = 120.
;nterms = 100.
;level = 6 ; decimating level
fhigh = 0.090
flow = 0.0
amp = 120.
nterms = 40.

; If sample rate = 8192, level = 7. If sample rate = 16384, level=8
srate = 1/dt
if abs(srate - 8192) lt 10. then level = 7
if abs(srate - 16384) lt 10. then level = 8

; If fmin greater than 3 Hz, only remove the linear offset.
tmin = (2.*nterms+1)* 2^level * dt ; the minimum time length accepted by CONVOL
if tlen lt tmin then begin
   print, ''
   print, 'THM_LSP_FILTER_HIGHPASS: ' + $
      'The input data is too short. No filtering is taken. '
   print, 'Instead, the '+$
      'linear offset is removed using the LADFIT routine.'
   print, ''
   freqlow = fmin
   tmp = ladfit(dumx, data, /double)
   data = data - poly(dumx, tmp)
   return, data
endif

filter = digital_filter(flow, fhigh, amp, nterms, /double) ; low-pass FIR filter
dec = [0.25d, 0.5d, 0.25d] ; decimating filter
out = data
lowdumx = dumx
for i = 1, level do begin
   out = convol(out, filter, /edge_zero)
   out = convol(out, dec, /edge_zero)
   out = out[0:*:2]
   lowdumx = lowdumx[0:*:2]
endfor
out = interpol(out, lowdumx, dumx)
data = data - out

freqlow = 5.  ; the lower edge of the high-pass filter is about 5 Hz.
return, data
end
