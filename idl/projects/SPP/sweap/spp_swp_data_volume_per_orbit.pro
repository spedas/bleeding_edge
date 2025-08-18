;Ali: June 2020
;$LastChangedBy: ali $
;$LastChangedDate: 2022-07-06 12:44:38 -0700 (Wed, 06 Jul 2022) $
;$LastChangedRevision: 30905 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/spp_swp_data_volume_per_orbit.pro $

pro spp_swp_data_volume_per_orbit,load=load

  if keyword_set(load) then begin
    spp_swp_spice,/pos,/merge,/recons
    spp_swp_wrp_stat,/cdf,/load
  endif
  tn='SPP_POS_(Sun-ECLIPJ2000)_mag'
  deriv_data,tn
  get_data,tn,dat=pos
  get_data,tn+'_ddt',dat=dpos
  pos20=pos.y-20
  shdpos=dpos.y*shift(dpos.y,1)
  shpos20=pos20*shift(pos20,1)
  w=where((shdpos le 0) and (pos.y gt 100))
  w20=where(shpos20 le 0)
  timebar,pos.x[w]
  timebar,pos.x[w20]
  t=pos.x[w20]
  spp_swp_wrp_stat,/cdf,/orig,tr=t[0:1]

end