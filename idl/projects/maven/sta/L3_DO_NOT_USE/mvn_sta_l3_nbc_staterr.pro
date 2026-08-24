function mvn_sta_l3_nbc_staterr,errdat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt
  ;; calculates random uncertainty from counting statistics for c6 beam density measurement.
  ;; you should set mass and m_int!!! 
  
  ;density = total(total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi,1),1)
  ;; const,denergy,energy are known exactly
  ;; theta, dtheta, and dphi are assumed to cover the FOV for c6 data, so
  ;; there's some additional uncertainty introduced because of this
  ;; ignore it for now an dtreat theta, dtheta, and dphi as fixed as well 
  
  ;; in that case the only uncertainty comes from the data, which is in df units.
  ;; Poisson uncertainty must be calculated in units of counts and it must include background counts
  ;; Normally, error=sqrt(N counts) 
  ;; but that assumes you have measured N many times and know it exactly. 
  ;; We have measured N only ONCE for each bin, so it's subject to statistical fluctuations
  ;; If you just use N_measured you will over- or under-estimate the uncertainty
  ;; Instead, simulate adding poisson noise to the measured distribution 
  ;; so that you can guess what the ideal parent distribution looks like and 
  ;; get a better constraint on the real value of N WITHOUT the statistical fluctuations
  
  ;; after you know the uncertainty from the data in units of counts, 
  ;; you have to convert it to df units, and then plug that into the density formula
  ;; to get the uncertainty in units of density. 
  ;
  
 ;;;;;; first steal code from nbc_4d to apply the energy and mass ranges and check that you have enough counts
  dat2 = errdat
  
  def_den = 0.

  if dat2.valid eq 0 then begin
    print,'Invalid Data'
    return, def_den
  endif

  if (dat2.quality_flag and 195) gt 0 then return, def_den

  dat = conv_units(dat2,"counts")   ; initially use counts
  n_e = dat.nenergy
  nb = dat.nbins
  nm = dat.nmass

  ; this is included for low energy beams because the GF is larger because the ESA exit posts and TOF entrance posts do not attenuate the beam
  dat.geom_factor = dat.geom_factor * 1.235

  data = dat.cnts
  
  bkg = dat.bkg
  energy = dat.energy
  denergy = dat.denergy
  theta = dat.theta/!radeg
  phi = dat.phi/!radeg
  dtheta = dat.dtheta/!radeg
  dphi = dat.dphi/!radeg
  domega = dat.domega
  
  ; determine how many energy bins to use around the peak count rate
  if n_e eq 64 then nne=8
  if n_e eq 32 then nne=4
  if n_e le 16 then nne=2
  if n_e eq 48 then nne=6   ; when does this happen? is this for swia?
  if dat.mode eq 7 then nne=nne*2

  
  cnts=errdat.cnts
  
  datashape = size(cnts)
  na = datashape[1]
  nb = datashape[2]
  
  
  
  ; remove energy sectors if "energy" keyword is set
  en_min = min(energy)
  en_max = max(energy)
  if keyword_set(en) then begin
    ind = where(energy lt en[0] or energy gt en[1],count)
    if count ne 0 then data[ind]=0.
    if count ne 0 then bkg[ind]=0.
    en_min = en_min > en[0]
    en_max = en_max < en[1]
  endif

  ; remove mass sectors if "mass" keyword is set
  if keyword_set(ms) then begin
    ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
    if count ne 0 then data[ind]=0.
    if count ne 0 then bkg[ind]=0.
  endif

data2 = data

  ; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements of apid c0
  ; only acts on data before mars injection orbit
  if dat.nmass eq 1 then begin
    if dat.time lt time_double('14-10-1') then begin
      maxcnt = max(data,mind)
      if n_e eq 64 then nnne=4 else nnne=nne
      data[0:(mind-nnne>0)]=0.
      data[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
      bkg[0:(mind-nnne>0)]=0.
      bkg[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
    endif
  endif

    maxcnt = max(total(data,2),mind)
    ;print,mind,mind2,energy[mind],energy[mind2]
    if 0 then mind = (mind2 < (mind+nne/2))   ; this doesn't seem to be needed
    ;print,mind
    data[0:(mind-nne>0),*]=0.
    data[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
    bkg[0:(mind-nne>0),*]=0.
    bkg[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
    en_peak=energy[mind,0]
    
    ; if the number of counts near the peak is less than 75% of total counts in the energy range, then it is not a beam
   ; if total(data) lt .75*total(data2) then return,def_den  ;CMF commented out****

    if dat.nmass gt 1 then begin
      if keyword_set(mi) then begin
        dat.mass_arr[*]=mi & mass=dat.mass*dat.mass_arr
      endif else begin
        dat.mass_arr[*]=round(dat.mass_arr-.1)>1. & mass=dat.mass*dat.mass_arr  ; the minus 0.1 helps account for straggling at low mass
      endelse
    endif else mass = dat.mass

    ;if keyword_set(mincnt) then if total(data) lt mincnt then return,0
    if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, !Values.F_NAN
    if total(data-bkg) lt 1 then return, !Values.F_NAN

;; skip ion suppression correction.

dat.cnts=data
dat.bkg=bkg
cnts = dat.cnts 

dcntsavg=make_array(na,nb)
i=0

;If this routine is run in a loop, it can go too quick such that systime() doesn't change by enough, and the output is identical for 
;each iteration of this routine. Multiply systime() so that subseconds become integers, to move the seed along each time.
seed0 = time_double('2014-01-01')*1E5
seed = (systime(/seconds)*1E5) - seed0   ;CMF added this


;;;;; now start the error calculation on just the relevant mass channels. 
  
  ; set up the first loop: find the peak, add random noise to the counts,
  ; find the peak in the new counts, find the fractional difference b/w the peaks
  pk = max(cnts, pind)
  tmp=cnts
  ;; the following loop decides whether the bins at the edges,
  ;; which might get 0, 1, or 2 counts, are populated on this iteration
  ;; it uses a poisson distribution to decide.
  for jj=0,n_elements(cnts)-1 do begin
    tmp(jj) = randomn(seed,1,poisson=float(tmp(jj)>1.e-35)) 
  endfor
  tmp=1.*(tmp+tmp^.5*randomn(seed,na,nb) > 0)
  dcntsavg = dcntsavg + tmp

  tmp_pk = dcntsavg[pind]/(i+1)
  dpk = abs((tmp_pk - pk)/tmp_pk)

  ; this loop is the actual iteration of the counts array to make it resemble the parent distribution
  while dpk gt 1d-1 do begin ; stop iterating when the change b/w iterations is <1d-2
    pk = tmp_pk ; update the baseline to compare against
    
    for jj=0,n_elements(cnts)-1 do begin
      tmp(jj) = randomn(seed,1,poisson=float(tmp(jj)>1.e-35))
    endfor
    tmp=1.*(tmp+tmp^.5*randomn(seed,na,nb) > 0)
    dcntsavg = dcntsavg + tmp

    tmp_pk = dcntsavg[pind]/(i+1) ;find the new peak
    dpk = abs((tmp_pk - pk)/tmp_pk) ;what's the change from the last iteration to this iteration?
    ; don't forget to count iterations!
    i ++
   endwhile
  
    nn=i+1
    var_cnts = dcntsavg/nn
    ;;; var_cnts is the variance (sigma^2) in the counts.
    ;; sigma = sqrt(var_cnts)
    ; 
    ;; we need the variance in df units though so now convert to df units
    ;; from mvn_sta_convert_units, the conversion is scale = 1.d/(dt * gf * energy^2 * 2./mass/mass*1e5 )
    ;; where gf = data.geom_factor*data.gf*data.eff
    ;; dt = data.integ_t
    ;; mass = data.mass*data.mass_arr
    ;; dead = data.dead            ; dead time array usec for STATIC
    
    gf = errdat.geom_factor*errdat.gf*errdat.eff
    integ_dt = errdat.integ_t
    mass = errdat.mass*errdat.mass_arr
    dead = errdat.dead
    energy=errdat.energy 

    scale = 1.d/(integ_dt * gf * energy^2 * 2./mass/mass*1e5 )
    var_data = var_cnts*scale*scale ;;Poisson variance in df units.
    
    ;;;;;;; If calculating an error associated with the uncertainty in direction, do that here.
    
   
    ;; the density formula is a sum for c6 data since nbins=1.
    ;; the uncertainty of a sum is: var_(aA+bB) = a^2*var_A + b^2*var_B 
    ;; density = total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi,1)
    ;; in this case A and B are the value of df in each channel
    ;; and a and b are the coefficient for the channel 
    ;; Const*denergy*(energy^(.5))*2.*cos(theta)*sin(dtheta/2.)*dphi
    
    denergy = dat.denergy
    theta = dat.theta/!radeg
    phi = dat.phi/!radeg
    dtheta = dat.dtheta/!radeg
    dphi = dat.dphi/!radeg
    
    Const = (mass)^(-1.5)*(2.)^(.5)
    
    ;;; this still has mass channel resolution
    var_dens = total((Const*denergy*(energy^(.5))*2.*cos(theta)*sin(dtheta/2.)*dphi)^2*var_data,1)
   
    ;;; sum over all the mass channels 
    var_density = total(var_dens)
    
    return,sqrt(var_density)

end