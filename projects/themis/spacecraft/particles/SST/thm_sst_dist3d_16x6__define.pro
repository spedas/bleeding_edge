pro thm_sst_dist3d_16x6__define,structdef=dat

nenergy = 16
nbins = 6
dims = [nenergy,nbins]

dat = {thm_sst_dist3d_16x6, inherits dist3d, $
       apid:                 0    , $
       mode:                 0    , $
       cnfg:                 0    , $
       nspins:               0    ,  $
       data:    fltarr(dims)      , $
       energy:  fltarr(dims)    , $
       theta:   fltarr(dims)    , $
       phi:     fltarr(dims)    , $
       denergy: fltarr(dims)      , $
       dtheta:  fltarr(dims)    , $
       dphi:    fltarr(dims)    , $
 ;      domega:  fltarr(dims)     ,$
       bins:    fltarr(dims)     ,$
       gf:      fltarr(dims)     ,$
       integ_t: fltarr(dims)    , $
       deadtime:fltarr(dims)    , $
       geom_factor: !values.f_nan  ,  $
       atten:   -1                 ,  $
       eclipse_dphi: !values.d_nan    $
       }
dat.nenergy = nenergy
dat.nbins = nbins

end

