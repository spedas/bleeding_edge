;+  return a background x-ray model
;
; INPUT: energylist is a list of energies (keV)
;        alt is altitude in km (20<alt<40)
;        mlat is magnetic latitude in degrees (50<|mlat|<90)
;
; OUTPUT: returns a list of counts/s/kev corresponding to energylist
;         returns -1 for input out of range
;
; METHOD: based on an empirical model derived from previous flights
;         model is ok between 20 and 7000 keV
;         background is primarily two power law components
;            these turn over at low energy
;            the 511 line contributes several features
;         prevent underflows by avoiding exp(-huge number)
;
; CALLS: none
;
; EXAMPLE: result = brl_makebkgd([10,20,50,100],63,33.2)
;            calculates bkgd differential count rate at the
;            4 specified energies for a detector at mag lat
;            63 degrees and altitude 33.2 km.
;
; FUTURE WORK:
;        needs to be compared with BARREL test flights
;
; REVISION HISTORY:
;        works, tested mm/18 Dec 2012
;-

function barrel_make_model_bkg, energylist, alt, mlat

  n=n_elements(energylist)

  if min(energylist) lt 0 then return, -1
  mlat = abs(mlat) < 65.
  if (alt lt 20 or alt gt 40) then return, -1
  altfactor = exp(-alt/7.3099)

  c1 = altfactor + 1.237e-3*mlat - 3.475e-3
  c2 = altfactor + 1.537e-3*mlat - 5.714e-2
  c3 = 6.78*altfactor +8.427e-3*mlat - 3.034e-1

  powerlaw1 = c1*(energylist/618.2)^(-2.802)
  powerlaw2 = c2*(energylist/957.1)^(-0.9529)

  turnover1 = fltarr(n)+1.
  good = where(energylist lt 900,cnt)
  if cnt gt 0 then $
    turnover1[good] = (1 + exp(-(energylist[good]-125.93)/40.23))

  turnover2 = fltarr(n)+1.
  good = where(energylist lt 250,cnt)
  if cnt gt 0 then $
    turnover2[good] = (1 + exp(-(energylist[good]-53.2)/10.42))

  area511=fltarr(n)
  good = where(400 lt energylist and energylist lt 600,cnt)
  if cnt gt 0 then $
    area511[good] += exp(-((energylist[good]-511)/15)^2/2)
  good = where(energylist lt 850,cnt)
  if cnt gt 0 then $
    area511[good] += 0.18 * exp(-((energylist[good]-445.47)/60.)^2/2)
  good = where(200 lt energylist and energylist lt 400,cnt)
  if cnt gt 0 then $
    area511[good] += 0.13 * exp(-((energylist[good]-312.)/15.)^2/2)

  return,(powerlaw1+powerlaw2)/(turnover1*turnover2) + c3*area511

end
