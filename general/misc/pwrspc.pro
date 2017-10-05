;+
;NAME:
; pwrspc
;PURPOSE:
;    Called with times time and data quantity, PWRSPC returns a power
;    spectrum power at frequencies freq. A Hanning window is applied to
;    the input data, and its power is divided out of the returned
;    spectrum. A straight line is subtracted from the data to
;    reduce spurious power due to sawtooth behavior of a background.
;    UNITS ARE (UNITS)^2 WHERE UNITS ARE THE UNITS OF quantity. freq
;    is in 1/timeunits.
;    THUS THE OUTPUT REPRESENTS THE MEAN SQUARED AMPLITUDE OF THE SIGNAL
;       AT EACH SPECIFIC FREQUENCY. THE TOTAL (SUM) POWER UNDER THE CURVE IS
;       EQUAL TO THE MEAN (OVER TIME) POWER OF THE OSCILLATION IN TIME DOMAIN.
;    NOTE: IF KEYWORD notperhz IS SET, THEN POWER IS IN UNITS^2. If notset
;           power is (as normal) in UNITS^2/Hz.
;CALLING SEQUENCE:
; pwrspc, time, quantity, freq, power, noline = noline, $
;         nohanning = nohanning, bin = bin, notperhz = notperhz
;INPUT:
; time = the time array
; quantity = the function for which you want to obtain a power
;            spectrum
;OUTPUT:
; freq = the frequency array (units =1/time units)
; power = the power spectrum, (units of quantity)^2/frequency_units
;KEYWORDS:
; noline = if set, no straight line is subtracted
; nohanning = if set, then no hanning window is applied to the input
; bin = a binsize for binning of the data, the default is 3
; notperhz = if set, the output units are simply the square of the
;            input units 
; err_msg = named variable that contains any error message that might occur
;
;$LastChangedBy$
;$LastChangedDate$
;$LastChangedRevision$
;$URL$
;
;-
pro pwrspc, time, quantity, freq, power, noline = noline, $
            nohanning = nohanning, bin = bin, notperhz = notperhz, $
            err_msg=err_msg, _extra = _extra

err_msg=''

;
t = double(time)-double(time[0])
x = double(quantity)
;
if keyword_set(bin) then begin
    binsize = bin
endif else begin
    binsize = 3
endelse
;
if not(keyword_set(noline)) then begin
    c = linfit(t, x, yfit = line) ;8-oct-2008, jmm
    x = x-line
endif
;
if not(keyword_set(nohanning)) then begin
    window = hanning(n_elements(x))
    x = x * window
endif
;
nt = n_elements(t)
bign = nt
dprint, 'bign=',bign
if (bign-(bign/2l)*2l ne 0) then begin
    dprint,'needs an even number of data points, dropping last point...'
    t = t[0:nt-2]
    x = x[0:nt-2]
    bign = bign - 1
endif
dprint, 'bign=',bign
;
; following Numerical recipes in Fortran, p. 421, sort of...
;
dbign = double(bign)
k = [0,dindgen(bign/2)+1]
tres=median(t[1:n_elements(t)-1]-t[0:n_elements(t)-2])
fk = k/(bign*tres)
;
xs2 = abs(fft(x,1))^2
;
pwr = dblarr(bign/2+1)
pwr[0] = xs2[0]/dbign^2
pwr[1:bign/2-1] = (xs2[1:bign/2-1] + xs2[bign - dindgen(bign/2-1)])/dbign^2
pwr[bign/2] = xs2[bign/2]/dbign^2
;
if not keyword_set(nohanning) then begin
    wss = dbign*total(window^2)
    pwr = dbign^2*pwr/wss
endif
;
; Now reduce variance by summing bin neighbors in frequency domain...except zero
;
dfreq=binsize*(fk[1]-fk[0])
;
npwr = n_elements(pwr)-1
nfinal=long(npwr/binsize)
iarray=lindgen(nfinal)
power = dblarr(nfinal)

freq = fk[(iarray+0.5)*binsize+1]

for i=0l,binsize-1 do begin
    power = power+pwr[iarray*binsize+i+1]
endfor

if not(keyword_set(notperhz)) then begin
    power = power / dfreq
endif
dprint, 'dfreq=',dfreq

return
end
