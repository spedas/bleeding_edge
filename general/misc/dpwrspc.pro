;+
;NAME:
; dpwrspc
;PURPOSE:
;    Called with times time and data quantity, dpwrspc returns a dps
;    spectrum at frequencies fdps. A Hanning window is applied to the
;    input data, and its power is divided out of the returned
;    spectrum. A straight line is subtracted from the data to reduce
;    spurious power due to sawtooth behavior of a background. UNITS
;    ARE (UNITS)^2 WHERE UNITS ARE THE UNITS OF time. fdps is in
;    Hz. THUS THE OUTPUT REPRESENTS THE MEAN SQUARED AMPLITUDE OF THE
;    SIGNAL AT EACH SPECIFIC FREQUENCY. THE TOTAL (SUM) POWER UNDER
;    THE CURVE IS EQUAL TO THE MEAN (OVER TIME) POWER OF THE
;    OSCILLATION IN TIME DOMAIN. NOTE: IF KEYWORD notperhz IS SET,
;    THEN POWER IS IN UNITS OF NT^2 ELSE IT IS IN UNITS OF NT^2/HZ. 
;CALLING SEQUENCE:
; dpwrspc, time, quantity, tdps, fdps, dps, nboxpoints = nboxpoints, $
;          nshiftpoints = nshiftpoints, bin = bin, tbegin = tbegin,$
;          tend = tend, noline = noline, nohanning = nohanning, $
;          notperhz = notperhz
;INPUT:
; time = the time array
; quantity = the function for which you want to obtain a power
;            spectrum
;OUTPUT:
; tps = the time array for the dynamic power spectrum, the center time
;       of the interval used for the spectrum 
; fdps = the frequency array (units =1/time units)
; dps = the power spectrum, (units of quantity)^2/frequency_units
;KEYWORDS:
; nboxpoints = the number of points to use for the hanning window, the
;              default is 256
; nshiftpoints = this is the number of points to shift for each
;                spectrum, the first spectrum will cover the range
;                from 0 to nboxpoints, then next will cover the range
;                from nshiftpoints to nshiftpoints+nboxpoints, etc..
;                the default is 128.
; bin = a binsize for binning of the data along the frequency domain,
;       the default is 3
; tbegin = a start time, the default is time[0] 
; tend = an end time, the default is time[n_elements(time)-1]
; noline = if set, no straight line is subtracted
; nohanning = if set, then no hanning window is applied to the input
; notperhz = if set, the output units are simply the square of the
;            input units 
; noTmVariance = if set replaces output spectrum for any windows that
;                have variable cadence with NaNs
; tm_sensitivity = If noTmVariance is set, this number controls
;                         how much of a dt anomaly is accepted. The
;                         program will flag a time resolution
;                         discontinuity if the time resolution dt
;                         changes by a value greater than
;                         dt/dt_sensitivity; the default
;                         is 100.0; i.e. If, for a given spectrum, if
;                         there are points with abs(dt[i]-median(dt)
;                         Gt median(dt)/100.0, then this will
;                         be set to NaN. A larger value means
;                         more sensitivity. If you want to flag round-off
;                         errors then try a value of 1.0e8. 
; fail = if set to a named variable, returns 1 if an error occurs, 0 otherwise
;
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;
;-
pro dpwrspc, time, quantity, tdps, fdps, dps, nboxpoints = nboxpoints, $
             nshiftpoints = nshiftpoints, bin = bin, tbegin = tbegin, $
             tend = tend, noline = noline, nohanning = nohanning, $
             notperhz = notperhz, fail = fail, noTmVariance = noTmVariance,$
             tm_sensitivity = tm_sensitivity, _extra = _extra
;
fail = 1

tdps = -1 & fdps = -1 & dps = -1 ;init output variables
if keyword_set(tend) then begin
    t2 = tend
endif else begin
    t2 = time[n_elements(time)-1]
endelse
;
if keyword_set(tbegin) then begin
    t1 = tbegin
endif else begin
    t1 = time[0]
endelse
;
igood = where((time ge t1) and (time le t2), jgood)
if (jgood gt 0) then begin
    time2process = time[igood]
    quantity2process = quantity[igood]
endif else begin
    dprint,  'tbegin or tend incompatible with time array'
    return
endelse
;
if keyword_set(nboxpoints) then begin
    nboxpnts = nboxpoints
endif else begin
    nboxpnts = 256
endelse
;
if keyword_set(nshiftpoints) then begin
    nshiftpnts = nshiftpoints
endif else begin
    nshiftpnts = 128
endelse
;
if keyword_set(bin) then begin
    binsize = bin
endif else begin
    binsize = 3
endelse
;
if not(keyword_set(nohanning)) then  window = hanning(nboxpnts)
;
nboxpnts = long(nboxpnts)
nshiftpnts = long(nshiftpnts)
totalpoints = n_elements(time2process)
nspectra = long((totalpoints-nboxpnts/2l)/nshiftpnts)
;test nspectra, if the value of nshiftpnts is much smaller than
;nboxpnts/2 strange things happen
nbegin = nshiftpnts*lindgen(nspectra)
nend = nbegin+nboxpnts-1l
okspec = where(nend le totalpoints-1, nspectra)
if(nspectra le 0) then begin
    dprint, 'Not enough points for a calculation'
    return
endif
tdps = dblarr(nspectra)
nfreqs = long((long(nboxpnts/2l))/binsize)
if(nfreqs Le 1) then begin
    dprint, 'Not enough frequencies for a calculation'
    return
endif
dps = fltarr(nspectra, nfreqs)
fdps = dps
;
for nthspectrum = 0l, nspectra-1l do begin
;
    nbegin = long(nthspectrum*nshiftpnts)
    nend = nbegin+nboxpnts-1l
;
    if(nend le totalpoints-1) then begin
        t = double(time2process[nbegin:nend])
        t0 = t[0]
        t = t-t0
        x = double(quantity2process[nbegin:nend])
;Use center time
        tdps[nthspectrum] = double(time2process[nbegin]+time2process[nend])/2.0
        if not(keyword_set(noline)) then begin
            c = linfit(t, x, yfit = line) ;8-oct-2008, jmm
            x = x-line
        endif
;
        if not(keyword_set(nohanning)) then  x = x * window
;
        bign = nboxpnts
        if (bign-(bign/2l)*2l ne 0) then begin
            dprint, 'needs an even number of data points, dropping last point...'
            t = t[0:bign-2]
            x = x[0:bign-2]
            bign = bign - 1
        endif
;

        n_tm = n_elements(t)
      
;time variance can break power spectrum, this keyword skips over those gaps
        if keyword_set(noTmVariance) && n_tm gt 1 then begin
;if 1 && n_tm gt 1 then begin
            if keyword_set(tm_sensitivity) then tmsn = tm_sensitivity[0] else tmsn = 100.0
            tdiff = t[1:n_tm-1]-t[0:n_tm-2]
            med_diff = median(tdiff,/double) 
;if there is any signifcant difference from the median time, then skip this iteration.
            idx = where(abs(tdiff/med_diff -1.) gt 1.0/tmsn,c)

;if there is a cadence change insert NaNs
            if c gt 0 then begin
                dps[nthspectrum, *] = !VALUES.D_NAN
                fdps[nthspectrum, *] = !VALUES.D_NAN
;if this isn't the final window, then also put NaNs in the window after the gap so that data plots correctly
                if nthspectrum lt nspectra-1 then begin
                    nthspectrum++ ;this effectively skips the next iteration of the loop
                    nbegin = long(nthspectrum*nshiftpnts) ;rebuild any quantities that we need to ensure valid results
                    nend = nbegin+nboxpnts-1l
                    if(nend le totalpoints-1) then begin
                        dps[nthspectrum, *] = !VALUES.D_NAN
                        fdps[nthspectrum, *] = !VALUES.D_NAN
                        tdps[nthspectrum] = double(time2process[nbegin]+time2process[nend])/2.0
                    endif
                endif
                continue
            endif
        endif
; following Numerical recipes in Fortran, p. 421, sort of...
;
        dbign = double(bign)
        k = [0, dindgen(bign/2)+1]
        tres = median(t[1:n_elements(t)-1]-t[0:n_elements(t)-2])
        fk = k/(bign*tres)
;
        xs2 = abs(fft(x, 1))^2
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
; Now reduce variance by summing bin neighbors in frequency domain...
;
        dfreq = binsize*(fk[1]-fk[0])
;
        npwr = n_elements(pwr)-1
        nfinal = long(npwr/binsize)
        iarray = lindgen(nfinal)
        power = dblarr(nfinal)
;
; Note: zeroth point includes zero freq. power.
        freqcenter = (fk[iarray*binsize+1]+fk[iarray*binsize+binsize])/2.
;
        for i = 0l, binsize-1 do begin
            power = power+pwr[iarray*binsize+i+1]
        endfor
;
        if not(keyword_set(notperhz)) then begin
            power = power[*] / dfreq
            power0 = pwr[0] / (fk[1]-fk[0]) ; must also include zero freq power
        endif
;
        dps[nthspectrum, *] = power[*]
        fdps[nthspectrum, *] = freqcenter

    endif

endfor
;
fail = 0
;
return
end
