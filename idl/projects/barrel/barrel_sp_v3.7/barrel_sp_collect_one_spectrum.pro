pro barrel_sp_collect_one_spectrum, payload, times, slow, spectrum, livetime, $
      level=level,rawtime,version=version

if (not keyword_set(level)) then level = 'l2'
if slow then begin
    datstr='SSPC' 
    dur=32.
endif else begin
    datstr='MSPC'
    dur=4.
endelse
ebins=barrel_make_standard_energies(slow=slow)

barrel_load_data, probe=payload, datatype=[datstr], level=level,$
     version=version,/no_update
varname='brl'+payload+'_'+datstr  ; KY 8/28 'brl???_' > 'brl'

tplot_names,varname, NAMES=matches,/ASORT
if (n_elements(matches) EQ 1) then get_data, matches[0], data=spect $
else message, 'Bad number of variable name matches ('+datstr+'): '+ $
        strtrim(n_elements(matches))

;Identify spectra with missing/bad parts:
nspect = n_elements(spect.y[*,0])
spectots = total(spect.y,2)
goodspect = (spectots GE 0.1)

barrel_load_data, probe=payload, datatype=['RCNT'], level=level,$
         /no_update,version=version
varname='brl'+payload+'_RCNT_Interrupt' ; KY 8/28 'brl???_' > 'brl'

tplot_names,varname, NAMES=matches,/ASORT
if (n_elements(matches) EQ 1) then get_data, matches[0], data=irq $
else message, 'Bad number of variable name matches (RCNT): '+ $
        strtrim(n_elements(matches))

;Identify missing/bad IRQ data:
badirq = (irq.y LT 0)

;keep both the starting and ending time of spectral accumulations
;within the requested time interval:
w=where((spect.x GE times[0]) and ((spect.x + dur) LE times[1]) $
        and (goodspect EQ 1) ,nw)
spect_time=spect.x[w]

if nw EQ 0 then message,'no data in time range.'

;To calculate livetime, use the IRQ rate. Still use "dur" even 
;though IRQ is available at 0.25 Hz so that the boundaries match:
wl=where((irq.x GE times[0]) and ((irq.x + dur) LE times[1]) $
          and (badirq EQ 0),nwl)
rate_irq = irq.y[wl] / 4. ;NOT dur here; units must match
irq_time = irq.x[wl]

;convert to per second; this is new in CDF files as of May 2013.

;Calculate the rate in the spectrum.
edge_products,ebins,mean=mean,width=width
rate_spect=fltarr(nw)
spectrum = fltarr(n_elements(width))
livetime = 0.
rawtime = 0.

;sum up, calculating livetime using nearest IRQ measurement to each
;spectrum as you go along:
;spect.y is /s/keV in level 2 and raw counts in level 1.

for i=0,nw-1 do begin
    if (level eq 'l2' or level eq 'L2') then rate_spect[i]= total(spect.y[w[i],*]*width) $
    else                                     rate_spect[i]= total(spect.y[w[i],*]/dur) 
    dts = abs(irq_time - spect_time[i])
    nearest_irq = rate_irq[(where(dts eq min(dts)))[0]]
;    while nearest_irq LT rate_spect[i]-12000. do nearest_irq += 16384.
    ;set units to counts/keV & we will divide by live seconds later:
    if (level eq 'l2' or level eq 'L2') then spectrum += dur*spect.y[w[i],*]/(1. - nearest_irq*8.0e-6) $
    else                                     spectrum +=    spect.y[w[i],*]/(1. - nearest_irq*8.0e-6)/width
    livetime += dur*(1.- nearest_irq*8.0e-6)
    rawtime += dur
endfor

end


