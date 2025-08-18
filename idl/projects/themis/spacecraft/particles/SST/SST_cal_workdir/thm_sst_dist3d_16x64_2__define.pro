
;+
;NAME:
; thm_sst_dist3d_16x64
;PURPOSE:
;  This routine defines the appropriate distribution representation struct for 
;  16 Energy and 64 angle SST data.
;  
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-09-10 16:17:02 -0700 (Tue, 10 Sep 2013) $
;$LastChangedRevision: 13014 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_dist3d_16x64_2__define.pro $
;-


pro thm_sst_dist3d_16x64_2__define,structdef=dat

nenergy = 16
nbins = 64
nthetas=4
dims = [nenergy,nbins]

dat = {thm_sst_dist3d_16x64_2, inherits dist3d, $
       apid: 0, $
       mode:                 0    , $
       cnfg:    0   ,$
       nspins:               0    ,  $
       data:    fltarr(dims)      , $  ;the actual data is stored here
       energy:  fltarr(dims)    , $    ;the energy value midpoints at which each data bin is measured are stored here
       theta:   fltarr(dims)    , $    ;the theta angle midpoints at which each data bin is measured are stored here(theta is elevation out of the spacecraft spin plane)
       phi:     fltarr(dims)    , $    ;the phi angle midpoints at which each data bin is measured are stored here (phi is rotation within the spacecraft spin plane)
       denergy: fltarr(dims)      , $  ;the change in energy across each bin.  (ie bin start/stop are energy +- denergy/2)
       dtheta:  fltarr(dims)    , $    ;the change in theta across each bin.  (ie bin start/stop are theta +- dtheta/2)
       dphi:    fltarr(dims)    , $    ;the change in phi across each bin.  (ie bin start/stop are phi +- dphi/2)
 ;      domega:  fltarr(dims)     ,$
       bins:    intarr(dims)     ,$
       gf:      fltarr(dims)     ,$  ;the geometric factor correction for each bin
       integ_t: fltarr(dims)    , $  ;the intergration time for each bin(in seconds)
       deadtime:fltarr(dims)    , $  ;the deadtime correction factor for each bin
       geom_factor: !values.f_nan  ,  $ ;the nominal(theoretical) geometric factor for all bins
       eclipse_dphi: !values.d_nan  ,  $ ;deviation (degrees) between the IDPU's spin model and the sunpulse+fgm spin model
       atten:   -1,   $                 ;whether the attenuator is on or off 
       att:fltarr(dims), $              ;attenuator scaling factors, applied when attenuator is on 
       eff:fltarr(dims),$            ;efficiencies for each energy bin
       en_low:fltarr(nenergy), $  ;lower energy boundaries for each bin in this anode
       en_high:fltarr(nenergy), $ ;upper energy boundaries for each bin in this anode
       dead_layer_offsets:fltarr(nthetas), $ ;dead layer offsets for each look direction
       channel:'' $ ;does this represent 'f','o','t','ft','ot','fto', or 'f_ft'(f & ft merged)
       }

dat.nenergy = nenergy
dat.nbins = nbins

end

