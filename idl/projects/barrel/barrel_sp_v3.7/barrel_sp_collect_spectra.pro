;At this stage, if the spectra were collected from level 1 files, they
;will be converted to /keV/s.

;10/29/13 DMS fix time normalization so that background model is
;         considered to be one second, not 4 or 32 seconds as before.


pro barrel_sp_collect_spectra,ss,altitude=altitude,maglat=maglat,level=level,$
   version=version

if keyword_set(altitude) then ss.altitude=altitude
if keyword_set(maglat) then ss.maglat = maglat
if not keyword_set(level) then level='l2'
ss.level=level

edge_products, ss.ebins, mean=mean, width=width
timespan, ss.askdate, ss.askduration, /hour

for i=0,ss.numsrc-1 do begin
   barrel_sp_collect_one_spectrum, ss.payload, ss.trange[*,i], ss.slow, spectrum, $
       livetime, rawtime,level=level, version=version
   if i eq 0 then begin 
       ss.srcspec = spectrum 
       ss.srclive = livetime
       ss.srctime = rawtime
   endif else begin 
       ss.srcspec += spectrum 
       ss.srclive += livetime
       ss.srctime += rawtime
   endelse
endfor

;Revert to cts/bin instead of cts/keV to calculate errors:
raw = ss.srcspec*(width*ss.srclive/ss.srctime)
;Average of upper and lower limits from Gehrels 1986:
ss.srcspecerr = ( sqrt(raw-0.25) + sqrt(raw+0.75) + 1. ) / 2.
;Return to /keV for the error:
ss.srcspecerr /= (width*ss.srclive/ss.srctime)

if ss.bkgmethod eq 1 then begin

 for i=0,ss.numbkg-1 do begin
   barrel_sp_collect_one_spectrum, ss.payload, ss.bkgtrange[*,i], ss.slow, $
        spectrum, livetime, rawtime, level=level,version=version
   if i eq 0 then begin 
       ss.bkgspec = spectrum 
       ss.bkglive = livetime
       ss.bkgtime = rawtime
   endif else begin 
       ss.bkgspec += spectrum 
       ss.bkglive += livetime
       ss.bkgtime += rawtime
    endelse
 endfor

;Revert to cts/bin instead of cts/keV to calculate errors:
raw = ss.bkgspec*(width*ss.bkglive/ss.bkgtime)
;Average of upper and lower limits from Gehrels 1986:
ss.bkgspecerr = ( sqrt(raw-0.25) + sqrt(raw+0.75) + 1. ) / 2.
;Return to /keV for the error:
ss.bkgspecerr /= (width*ss.bkglive/ss.bkgtime)

endif else begin
   ;Generate background model in 5 keV bins and rebin:
   fine_ebins = findgen(1400)*5.+20.
   edge_products, fine_ebins, mean=fmean, width=fwidth
   bkgfine = barrel_make_model_bkg( fmean, ss.altitude, ss.maglat )
   bkgnormal = brl_rebin(bkgfine,fine_ebins,ss.ebins,flux=1)
   ss.bkgspec = bkgnormal
   ss.bkglive = 1.
   ss.bkgtime = 1.
   ;Take somewhat arbitrary 5% error bars, even though not really uncorrelated:
   ss.bkgspecerr = 0.05*ss.bkgspec
endelse   

end
 
