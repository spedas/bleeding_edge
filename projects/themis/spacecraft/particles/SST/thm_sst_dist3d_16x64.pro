


function thm_sst_dist3d_16x64,ion=ion,elec=elec,time,probe=prb,index=index

dat = {thm_sst_dist3d_16x64}

spin_period = 3.

dim = size(/dimension,dat.data)
nenergy = dim[0]
nbins   = dim[1]


;bins_64 = [[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15],  $
;           [[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15]+16], $
;           [[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15]+32], $
;           [[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15]+48] ]


one = replicate(1.,16)
if keyword_set(ion) then begin
    dat.theta = replicate(1,16) # [52*one,-52*one,25*one,-25*one]
    dat.dtheta = 40

    phi16 = (findgen(16)+.5) * 22.5
    sphi16 = shift(phi16,8)
    dat.phi   = replicate(1,16) # [phi16,sphi16,sphi16,phi16]
    dat.dphi   = 22.5
endif

if keyword_set(elec) then begin
    dat.theta = replicate(1,16) # [-52*one,+52*one,-25*one,+25*one]
    dat.dtheta = 40

    phi16 = (findgen(16)+.5) * 22.5
    sphi16 = shift(phi16,8)
    dat.phi   = replicate(1,16) # [sphi16,phi16,phi16,sphi16]
    dat.dphi   = 22.5
endif

dat.integ_t = dat.dphi / 360 * spin_period


if 0 then begin
  ; Warning: not final cals!
  idap_start = [12,19,26,34,44,69,103,150,215,306,506,906,2000,3000,4000,5000]  * 1.5 * 1000
  idap_width = [ 7, 7, 8,10,25,34, 47, 65, 91,200,400,3060,1000,1000,1000,1000] * 1.5 * 1000
  
  edap_start = [12,19,26,34,44,69,103,150,215,306,506,906,2000,3000,4000,5000]  * 1.5 * 1000
  edap_width = [ 7, 7, 8,10,25,34, 47, 65, 91,200,400,2000,1000,1000,1000,1000] * 1.5 * 1000
  
  energy = (2*idap_start + idap_width)/2   + 5000.       ; midpoint energy
  dat.energy = energy # replicate(1,nbins)       ; total energy width
  denergy = (idap_width)
  dat.denergy = denergy # replicate(1,nbins)
endif else begin
   thm_sst_energy_cal,energy=energy,denerg=denergy,inst = keyword_set(ion),probe=prb
   detector = [[replicate(0,16)],[replicate(1,16)],[replicate(2,16)],[replicate(3,16)]]
   dat.energy  =  energy[*,detector[*]]
   dat.denergy = denergy[*,detector[*]]
endelse


;weights = calc_omega_flt2(dat.theta,dat.phi,dat.dtheta,dat.dphi, 1.)
;dat.domega = weights[0,*,*]

dat.nenergy = nenergy
dat.nbins   = nbins
dat.bins = 1
dat.gf = 1

dat.units_procedure = 'thm_sst_convert_units'

dat.geom_factor = .1

dat.eclipse_dphi = !values.d_nan

return,dat
end



