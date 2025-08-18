
;+
;NAME:
; thm_sst_dist3d_16x64
;PURPOSE:
;  This routine returns the appropriate distribution representation struct for 
;  16 Energy and 64 angle SST data.(16 energy by 4 theta by 16 phi)
;  Default and/or constant values will be populated.  At this point,
;  the structure should be considered incomplete. 
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2012-11-01 16:46:42 -0700 (Thu, 01 Nov 2012) $
;$LastChangedRevision: 11152 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_dist3d_16x64_2.pro $
;-


function thm_sst_dist3d_16x64_2,ion=ion,elec=elec,time,probe=prb,index=index

dat = {thm_sst_dist3d_16x64_2}

spin_period = 3.

dim = size(/dimension,dat.data)
nenergy = dim[0]
nbins   = dim[1]

if keyword_set(ion) && keyword_set(elec) then begin
  dprint,level=0,'ERROR: Keywords "ion" and "elec" are mutually exclusive'
  return,0
endif

one = replicate(1.,16)
if keyword_set(ion) then begin
    dat.theta = replicate(1,16) # [52*one,-52*one,25*one,-25*one]
    dat.dtheta = 40
    phi16 = (findgen(16)+.5) * 22.5
    sphi16 = shift(phi16,8)
    dat.phi   = replicate(1,16) # [phi16,sphi16,sphi16,phi16]
    dat.dphi   = 22.5
endif else if keyword_set(elec) then begin
    dat.theta = replicate(1,16) # [-52*one,+52*one,-25*one,+25*one]
    dat.dtheta = 40

    phi16 = (findgen(16)+.5) * 22.5
    sphi16 = shift(phi16,8)
    dat.phi   = replicate(1,16) # [sphi16,phi16,phi16,sphi16]
    dat.dphi   = 22.5
endif

dat.integ_t = dat.dphi / 360 * spin_period

dat.geom_factor = .1

dat.eclipse_dphi = !values.d_nan

dat.nenergy = nenergy
dat.nbins   = nbins
dat.bins = 1

dat.units_procedure = 'thm_sst_convert_units2'

return,dat
end



