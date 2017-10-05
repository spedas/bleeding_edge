;+
;
;NAME:
;s_trans
;
;PURPOSE:
; Calculate the local power spectrum for given time-series data and return the structure
; which contains {st:, ph: freq:, time:} where st is the S Transform.
;
;SYNTAX:
; results = s_trans(time-series)
;
;KEYWOARDS:
; \help               explains all the keywords and parameters
; \verbose            flags errors and size
; \samplingrate       if set returns array of frequency
; \maxfreq
; \minfreq
; \freqsmplingrate
; \piecewisenumber    divides the time series, and passes back array
; \power              returns the power spectrum
; \abs                returns the absolute value spectrum
; \Rremoveedge        removes the edge with a 5% taper, and takes out least-sqares fit parabola
;
; Added a "mask out edges" keyword, which STs a line (ie st of edges) and thresholds the returned st matrix.
; The value of masked edges is the percent at which to  make the threshold default = 5 %.
;
; Added an EXAMPLE keyword, will display a time series and the amplitude of the ST to the current graphics device
; WARNING, will call !P.multi=0

;===================== Modified hilbert transform ================================
;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;  hilbert
;
; PURPOSE:
;  Return a series that has all periodic terms shifted by 90 degrees.
;
;CODE:
; A. Shinbori, 04/06/2012.
;
;MODIFICATIONS:
; 
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-01-22 15:54:40 -0800 (Wed, 22 Jan 2014) $
; $LastChangedRevision: 13976 $
; $URL $
;-


function hilbert_trans,x,d, analytic = a   ; performs the Hilbert transform of some data.
  ;Return to caller if an error occurs
   on_error,2 
             
  ;Calculate the power spectrum of x.
   y=fft(x,-1)          
   n=n_elements(y)
   i=complex(0.0,-1.0)

   if n_params(x) eq 2 then i=i*d
   
  ;Effect of odd and even # of elements considered here.
   n2=ceil(n/2.)-1    
            
  ;Zero the DC value (required for hilbert trans.)                           ; 
   y(0) = complex(0,0)
   
  ;Multiplying by I rotates counter c.w. 90 deg.   
   y(1)=y(1:n2)*i       
   if (n mod 2) eq 0 then y(n2+1) = complex(0,0)
   n2=n-n2
   y(n2)=y(n2:n-1)/i
   
  ;Calculate the power spectrum of y.
   y=float(fft(y,1))
   if keyword_set(a) then y = complex(x,y)
   return,y
end

;========================================================================
; Gaussian Window Function
; Accepts variables length and width
; Returns the spectrum of the Gaussian window note this is length/2piw.
;========================================================================
function gaussian_window, l, w
   if w ne 0.0 then sigma = l/(2*!PI*w) else message,'width is zero!'
  ;Definition of array g and iarr. 
   g = fltarr(l)
   iarr = findgen(l)
   ex = (iarr - l/2)^2/(2*sigma^2)
   wl = where(ex lt 25)
  ;Calculate the gaussian.
   g(wl) = exp(-ex(wl))
   g = shift(g,-l/2)
   return, complex(g,0)
end


;========================================================================
; The S Transform function:
;========================================================================
FUNCTION s_trans, ts, factor, help = help,verbose = verbose, samplingrate = samplingrate $
    ,maxfreq = maxfreq, minfreq = minfreq  $
    ,freqsamplingrate = freqsamplingrate     $
    ,power = power, abs = abs, removeedge = removeedge   $
    ,maskedges=maskedges,example = example

;==================================
; Show example of a chirp function:
;==================================
if keyword_set(example) then begin  
   ex_len = 512
   ex_time = findgen(ex_len)
  
  ; ex_len/16
   ex_freq = 5
  
  ; cos(2*pi*f*t/T)
   ex_ts =  cos(2*!Pi*ex_freq*ex_time/ex_len)
   
  ; cos(2*pi*(T/5+2*cos(2*pi*f*t/T))*t/T) 
   ex_ts =  cos(2*!Pi*(ex_len/5+2*ex_ts)*ex_time/ex_len) 
  ;crossed chirp example commented out
  ;ex_ts = cos(2*!Pi*ex_freq*ex_time*(1+2*ex_time/ex_len)/ex_len)
  ;ex_ts = ex_ts + reverse(ex_ts)
  ;
  ;Output the line and contour plots
   !P.multi=[0,1,2]
   plot,ex_ts,xtitle='Time (units)',title='Time Series [h(t) = cos(cos(wt))]'
  
  ; Returns structure, amplitudes only returned
   s = s_trans(ex_ts,/samp, /abs)  
   contour,s.st,ex_time,s.freq,nlevels=14,/fill,xtitle='Time (units)', ytitle='Frequency (1/unit)',title='Amplitude of S-Transform'
   return,0
   !P.multi=0
endif

if keyword_set(HELP) then begin
  print,"S_TRANS()  HELP COMMAND"
  print,"S_trans() returns a matrix if succesful or a structure if required"
  print,"S_trans() returns  - 1 or an error message if it fails"
  print,"USAGE::    localspectra = s_trans(timeseries)
  print," "
  print,"Optional Parameters"
  print,"width             -size of time resolution"
  print,"                  -if not set, default WIDTH = 1"
  print," "
  print,"Keywords:
  print,"\help             -explains all the keywords and parameters
  print,"\verbose          -flags errors and size, tells time left etc.
  print,"\samplingrate     -if set returns array of frequency
  print,"\maxfreq
  print,"\minfreq
  print,"\freqsamplingrate
  print,"\power            -returns the power spectrum
  print,"\abs              -returns the absolute value spectrum
  print,"\removeedge       -removes the edge with a 5% taper, and takes
  print,"                  -out least-squares fit parabola
  return, -1
endif

;===========================
; Check number of arguments:
;===========================
CASE N_PARAMS() OF
  1: begin
    if n_elements(ts) eq 0 then MESSAGE, 'Invalid timeseries (check your spelling).'
    factor = 1
  end
 ; Two-argument case:
  2: if n_elements(factor) ne 1 then begin 
    ; Make sure factor is a number:
     factor = 1                          
     if keyword_set(verbose)then print,'Error in second parameter. Using default values.'
     endif
else: message, 'Wrong number of arguments'
endcase


if n_elements(ts) eq 0 then message, 'Invalid timeseries (check your spelling).'
time_series = ts

; Check to see if it is a vector, not a 1 x N matrix:
sz = size(time_series)
if sz(0) ne 1 then begin
    if sz(1) eq 1 and sz(2) gt 1 then begin
      ; A column vector, change it:
       time_series = reform(time_series)  
       if keyword_set(verbose)then print,'Reforming timeseries'
  endif else message, 'Must enter an array of data'
endif

if keyword_set(verbose) then print
if keyword_set(verbose) then print,'Performing S transform:'

if keyword_set(removeedge)  then begin
   if keyword_set(verbose) then  print,'Removing edges'
   ind = findgen(n_elements(time_series))
   r = poly_fit(ind,time_series,2,fit,yband,sigma,am)
   ts_power = sqrt(total(float(time_series)^2)/n_elements(time_series))
   if keyword_set(verbose) then  print,'Sigma is:',sigma,'power',ts_power,'ratio',sigma/ts_power
   if keyword_set(verbose) then print, 'total error',total(yband)/n_elements(yband)
   time_series = time_series - fit
   sh_len = n_elements(time_series)/10
   if sh_len gt 1 then begin
      wn = hanning(sh_len)
      time_series(0:sh_len/2-1) = time_series(0:sh_len/2-1)*wn(0:sh_len/2-1)
      time_series(n_elements(time_series)-sh_len/2:*) = time_series(n_elements(time_series)-sh_len/2:*)*wn(sh_len/2:*)
   endif
endif


; Here its dimension is one:
sz = size(time_series)
if sz(2) ne 6 then begin
   if keyword_set(VERBOSE) then print,'Not complex data, finding analytic signal.'
   
  ;Take hilbert transfrom
   time_series = (hilbert_trans(time_series,/analytic))
  ;The /2 is because the  spectrum is  *2 from an. sig.
  ;Note that the nyquist point and DC are 2*normal in AS(t)
endif

;Definition of array: 
length = n_elements(time_series)
spe_length = length/2
b = complexarr(length)
gw = complexarr(length)

;Calculate the inverse fft for the hilbert spectrum data:
h = fft(time_series,-1)

;Do the different sampling cases here:
if (keyword_set(maxfreq))  then begin
  if maxfreq lt 1 then maxfreq = fix(length*maxfreq)
endif
if not(keyword_set(minfreq))  then begin
    if keyword_set(verbose) then print,'Minimum Frequency is 0.'
   ; Loop starts at 0:
    minfreq = 0  
endif else begin
    if minfreq gt spe_length then begin
        minfreq = spe_length
        print,'minfreq too large, using default value'
    endif
    if keyword_set(verbose) then print,strcompress('Minimum Frequency is '+string(minfreq)+'.')
endelse
if not(keyword_set(maxfreq))  then begin
    if keyword_set(verbose) then print,strcompress('Maximum Frequency is '+string(spe_length)+'.')
    maxfreq = spe_length
endif else begin
    if maxfreq gt spe_length then begin
        maxfreq = spe_length
        print,'maxfreq too large, using default value'
    endif
    if keyword_set(verbose) then print,strcompress('Maximum Frequency is '+string(maxfreq)+'.')
endelse
if not(keyword_set(freqsamplingrate))  then begin
    if keyword_set(verbose) then print,'Frequency sampling rate is 1.'
    freqsamplingrate = 1
endif else if keyword_set(verbose) then print,strcompress('Frequency sampling rate is '+string(freqsamplingrate)+'.')

if freqsamplingrate eq 0 then freqsamplingrate = 1     ; if zero then use default

; Check for errors in frequency parameters:
; if min > max, switch them:
if maxfreq lt minfreq then begin  
   temp = maxfreq
   maxfreq = minfreq
   minfreq = temp
   temp = 0
   print,'Switching frequency limits.'+strcompress(' Now, (minfreq = '+string(minfreq) + ') and (MAXFREQ ='+string(maxfreq)+').')
endif

if maxfreq ne minfreq then begin
  if freqsamplingrate gt (maxfreq - minfreq)   then  begin
     print,strcompress('FreqSamplingRate='+string(freqsamplingrate)+' too big, using default = 1.')
    ; if too big then use default:
     freqsamplingrate = 1 
  endif
 ; if there is only one frequency:
endif else freqsamplingrate = 1 

spe_nelements = floor((maxfreq - minfreq)/freqsamplingrate)+1
if keyword_set(verbose) then print,strcompress('The number of frequency elements is'+string(spe_nelements)+'.')


; Calculate the ST of the data:
if keyword_set(abs) and keyword_set(power) then begin
  print,'You are a moron! Defaulting to Local Amplitude Spectra calculation'
  power = 0
endif

if keyword_set(abs) or keyword_set(power) then begin
   ; Definition of array:
    loc = fltarr(length,spe_nelements)
    phase = fltarr(length,spe_nelements)
   if keyword_set(abs)  then if keyword_set(verbose) then print,'Calculating Local Amplitude Spectra.'  $
   else if keyword_set(verbose) then print,'Calculating Local Power Spectra.'
   
  ; Move the array elements:
   h = shift(h,-minfreq)
   if minfreq eq 0 then  begin
      gw = fltarr(length)
      gw(0) = 1
      loc(*,0) = abs(fft(h*gw,1))
   endif else begin
      f = float(minfreq)
      width = factor * length/f
      gw = gaussian_window(length,width)
      b = h * gw
      loc(*,0) = abs(fft(b,1))
   endelse
   for index = 1,spe_nelements-1 do begin
      f = float(minfreq) + index*freqsamplingrate
      width = factor * length/f
      gw = gaussian_window(length,width)
      h = shift(h,-freqsamplingrate)
      b = h * gw
      loc(*,index) = abs(fft(b,1))
   endfor
   if keyword_set(power) then loc = loc^2
endif else begin  ; calculate complex ST
   if keyword_set(verbose) then print,'Calculating Local Complex Spectra'
   loc = complexarr(length,spe_nelements)
   h = shift(h,-minfreq)
   if minfreq eq 0 then begin
      gw = fltarr(length)
      gw(0) = 1
      loc(*,0) = fft(h*gw,1)     ; 0 freq. equal to DC level
   endif else begin
      f = float(minfreq)
      width = factor * length/f
      gw = gaussian_window(length,width)
      b = h * gw
      loc(*,0) = fft(b,1)
   endelse
   for index = 1,spe_nelements-1  do begin
      f = float(minfreq) + index*freqsamplingrate
      width = factor * length/f
      gw = gaussian_window(length,width)
      h = shift(h,-freqsamplingrate)
      b = h * gw
      loc(*,index) = fft(b,1)
   endfor
endelse

if keyword_set(maskedges) then begin
   if maskedges eq 1 then maskthreshold=0.05
   if maskedges gt 0 and maskedges lt 1 then maskthreshold=maskedges
   if maskedges gt 1 and maskedges le 100 then maskthreshold=float(maskedges)/100. $
   else  maskthreshold=0.05
   edgets = findgen(length)/length
   st = s_trans(edgets,/abs)
   mask=where(st gt maskthreshold,maskcount) ; 5 % is good = 0.05 based on snooping around
   loc(mask) = 0
endif

if keyword_set(samplingrate) then begin  ; make structure
;
   frequencies = (MINFREQ + findgen(spe_nelements)*freqsamplingrate)/(samplingrate*length)
   time = findgen(length)*samplingrate
   a = {st: loc, time: time, freq: frequencies}
   return,a
endif else return, loc

end ; end of function
