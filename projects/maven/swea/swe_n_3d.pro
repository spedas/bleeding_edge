;+
;FUNCTION:	swe_n_3d(dat,EBINS=ebins,ABINS=abins,DBINS=dbins)
;INPUT:	
;	dat:	structure,	2d data structure filled mvn_swe_get3d
;KEYWORDS
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include, na = dat.nenergy
;	ABINS:	bytarr(16),	optional, anode bins array for integration
;					0,1=exclude,include
;	DBINS:	bytarr(6),	optional, deflector bins array for integration
;					0,1=exclude,include
;
;   OBINS:  bytarr(96), optional, solid angle bins for integration
;                   0,1=exclude,include
;PURPOSE:
;	Returns the density, n, 1/cm^3
;
;CREATED BY:
;	J.McFadden	95-7-27	
;LAST MODIFICATION:
;	96-7-6		J.McFadden	added more keywords
;   14-7-6      D.Mitchell  redefined keywords, 
;                           added correction for spacecraft potential
;-
function swe_n_3d, dat2, EBINS=ebins, ABINS=abins, DBINS=dbins, OBINS=obins

  density = 0.

  if dat2.valid eq 0 then begin
    dprint, 'Invalid Data'
    return, density
  endif

  dat = conv_units(dat2,"eflux")    ; Use Energy Flux (eV/cm2-sec-ster-eV)
  data = dat.data
  na = dat.nenergy
  nb = dat.nbins
  pot = dat.sc_pot                  ; Spacecraft potential (V)

  ebins2 = replicate(1B,na)
  if (n_elements(ebins) eq na) then ebins2 = ebins

  abins2 = replicate(1B,16)
  if (n_elements(abins) eq 16) then abins2 = abins

  dbins2 = replicate(1B,6)
  if (n_elements(dbins) eq 6) then dbins2 = dbins

  if (n_elements(obins) eq 96) then obins2 = obins $
                               else obins2 = reform(abins2 # dbins2, nb)

  bins2 = ebins2 # obins2

; Calculate energy steps for integral

  energy = dat.energy[*,0]
  denergy = energy
  denergy[0] = abs(energy[1] - energy[0])
  for i=1,(na-2) do denergy[i] = abs(energy[i+1] - energy[i-1])/2.
  denergy[na-1] = abs(energy[na-1] - energy[na-2])

; Calculate phi steps for integral

  phi = dat.phi*!dtor
  dphi = phi
  i0 = 16*indgen(6)
  dphi[*,i0] = abs(phi[*,i0+1] - phi[*,i0])
  for i=1,14 do dphi[*,i0+i] = abs(phi[*,i0+i+1] - phi[*,i0+i-1])/2.
  dphi[*,i0+15] = abs(phi[*,i0+15] - phi[*,i0+14])

; Calculate theta steps for integral

  the = dat.theta*!dtor
  dthe = the
  i0 = indgen(16)
  dthe[*,i0] = abs(the[*,i0+16] - the[*,i0])
  for i=1,4 do dthe[*,i0 + i*16] = abs(the[*,i0 + (i+1)*16] - the[*,i0 + (i-1)*16])/2.
  dthe[*,i0 + 5*16] = abs(the[*,i0 + 5*16] - the[*,i0 + 4*16])

; Calculate solid angles for integral
;   Theta is latitude, from -90 to +90 degrees.

  domega = 2.*dphi*cos(the)*sin(dthe/2.)

  sumdata = total(data*domega*bins2,2)
  fovcorr = total(domega*(replicate(1.,na)#obins2),2)/(4.*!pi)
  prat = (pot/energy) < 1.

; Calculate the moment [cm-3]

  mass = 5.6856297d-06           ; electron mass [eV/(km/s)^2]
  Const = 1d-5 * sqrt(mass/2D)
  
  density = Const*total(denergy*sqrt(1. - prat)*(energy^(-1.5))*sumdata/fovcorr)

  return, density

end

