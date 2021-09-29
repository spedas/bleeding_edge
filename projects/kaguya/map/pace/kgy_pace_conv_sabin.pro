;+
; PROCEDURE:
;       kgy_pace_conv_sabin
; PURPOSE:
;       Converts data structure in [nene,ntheta,nphi] to [nene,nbins]
; CALLING SEQUENCE:
;       datnew = kgy_pace_conv_sabin(dat)
; INPUTS:
;       3d data structure created by kgy_*_get3d
; CREATED BY:
;       Yuki Harada on 2018-05-11
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-10 19:25:52 -0700 (Thu, 10 May 2018) $
; $LastChangedRevision: 25196 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_pace_conv_sabin.pro $
;-

function kgy_pace_conv_sabin, dat2

dat = dat2

if size(dat.data,/n_dim) eq 2 then return,dat

nenergy = dat.nenergy
nphi = dat.nphi
ntheta = dat.ntheta
nbins = nphi * ntheta

str_element,dat,/add,'energy',reform(dat.energy,nenergy,nbins)
str_element,dat,/add,'theta',reform(dat.theta,nenergy,nbins)
str_element,dat,/add,'phi',reform(dat.phi,nenergy,nbins)
str_element,dat,/add,'gfactor',reform(dat.gfactor,nenergy,nbins)
str_element,dat,/add,'eff',reform(dat.eff,nenergy,nbins)
str_element,dat,/add,'bins',reform(dat.bins,nenergy,nbins)
str_element,dat,/add,'denergy',reform(dat.denergy,nenergy,nbins)
str_element,dat,/add,'dtheta',reform(dat.dtheta,nenergy,nbins)
str_element,dat,/add,'dphi',reform(dat.dphi,nenergy,nbins)
str_element,dat,/add,'domega',reform(dat.domega,nenergy,nbins)
str_element,dat,/add,'data',reform(dat.data,nenergy,nbins)

return,dat

end
