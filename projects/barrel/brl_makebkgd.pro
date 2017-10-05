;+  return a background x-ray model
;
; INPUT: energylist is a list of energies (keV)
;        alt is altitude in km (25<alt<40)
;        mlat is magnetic latitude in degrees (55<|mlat|<90)
;
; OUTPUT: returns a list of counts/s/kev corresponding to energylist
;         returns -1 for input out of range
;
; METHOD: based on an empirical model derived from BARREL flights
;         model is ok between 30 and 8000 keV
;         background is primarily two power law components
;            these turn over at low energy
;            the 511 line contributes several features
;         prevent underflows by avoiding exp(-huge number)
;
; CALLS: none
;
; EXAMPLE: result = brl_makebkgd([10,20,50,100],33.2,63)
;            calculates bkgd differential count rate at the
;            4 specified energies for a detector at mag lat
;            63 degrees and altitude 33.2 km.
;
; FUTURE WORK:
;
;COMMENT
; model ignores solar cycle changes of cosmic ray and associated background X-ray intensity
; the estimation for < 60keV is to some extent affected by detector temperature effect.
; REVISION HISTORY:
; works, tested mm/18 Dec 2012
; version 2, updated LZ/ May 28th, 2013 .
;- better constants values and latitude function than previous version

function brl_makebkgd, energylist, alt, mlat

  if min(energylist) lt 0 then return, -1
 mlat = abs(mlat)
 if (mlat lt 55) then return, -1
mlat_adj=mlat - 65;
  if (alt lt 25 or alt gt 40) then return, -1
  altfactor = exp(-alt/8.5)

  c1 = 4.926e7*(altfactor + 0.03/(1+exp(-4-mlat_adj/10)))
  c2 = 511.7*(altfactor + 0.037/(1+exp(-4-mlat_adj/2.58)))
  c3 = 5.37*(altfactor +0.02/(1+exp(-4-mlat_adj/5.67)))

  powerlaw1 = c1*(energylist)^(-2.75)
  powerlaw2 = c2*(energylist)^(-0.92)

  turnover1 = fltarr(256)+1.
  good = where(energylist lt 900,cnt)
  if cnt gt 0 then $
    turnover1[good] = (1 + exp(-(energylist[good]-113.3)/44.4))

  turnover2 = fltarr(256)+1.
  good = where(energylist lt 250,cnt)
  if cnt gt 0 then $
    turnover2[good] = (1 + exp(-(energylist[good]-48.6)/10))

  area511=fltarr(256)
  good = where(400 lt energylist and energylist lt 600,cnt)
  if cnt gt 0 then $
    area511[good] += exp(-((energylist[good]-511)/20)^2/2)
  good = where(energylist lt 850,cnt)
  if cnt gt 0 then $
    area511[good] += 0.18 * exp(-((energylist[good]-445.47)/60.)^2/2)
  good = where(200 lt energylist and energylist lt 400,cnt)
  if cnt gt 0 then $
    area511[good] += 0.13 * exp(-((energylist[good]-312.)/20.)^2/2)

  return,(powerlaw1+powerlaw2)/(turnover1*turnover2) + c3*area511

end