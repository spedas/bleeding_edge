function mvn_sta_c8temp_staterr, errdat, tp
  ;; calculates random uncertainty from counting statistics for c8 temperature measurement.
  ;; at periapsis the error is typically ~5-10%
  
;  vth2 = 2.*(total((v*sth - v0#replicate(1.,nth))^2*data2)/(total(data2)>1.e-20))       ; vth^2 = 2*sigma^2
;  tp = .5*m*vth2

energy = errdat.energy ; known and NOT dependent on scpot
theta = errdat.theta ; known
cnts = errdat.cnts
data = errdat.data 
nth = errdat.ndef
dead = errdat.dead
gf = errdat.gf 
bkg = errdat.bkg
lookatme=0
nrg = errdat.nenergy
nbins= errdat.nbins 
cnts[where(data eq 0.)] = 0. 

;data = ((data-bkg)>0.)*dead/gf

m=1.
v = (2*energy/m)^.5
sth = sin(theta/!radeg) ; known

;; first we need the statistical uncertainty from the data 


;    The error associated w/ the data is the usual poisson error
;    however, the error isn't just the sqrt(N) for each bin, where N is the counts in the bin:
;    sqrt(N) is based on the assumption of a large number of measurements of the same distribution
;    and N is the average number of counts in each bin over the large number of measurements.
;    but we only measure each distribution once, which includes statistical fluctuations;
;    so taking sqrt(N_measured) will over- or under-estimate the error.
;    to correctly calculate the statistical uncertainty associated with this particular measurement
;    simulate measuring an ensemble of distributions just like this one,
;    but with random noise added to the counts.
;    if you add up all the counts and divide by # of iterations, you will see what
;    the parent distribution looks like in the absence of statistical fluctuations.

seed=systime(/seconds) ; this is the seed for the random number generator
datashape = size(cnts)
na = datashape[1]
nb = datashape[2]
if not keyword_set(nn) then nn = 200
dcntsavg=make_array(na,nb)
i=0

;  for i=0,nn-1 do begin
; set up the first loop: find the peak, add random noise to the counts,
; find the peak in the new counts, find the fractional difference b/w the peaks
pk = max(cnts, pind)
tmp = cnts

;tmp = cnts + abs(cnts)^.5*randomn(abc,na,nb,/double)
for jj=0,n_elements(cnts)-1 do begin
  tmp(jj) = randomn(seed,1,poisson=float(tmp(jj)>1.e-35))
endfor
tmp=1.*(tmp+tmp^.5*randomn(seed,nrg,nbins,1) > 0)
dcntsavg = dcntsavg + tmp
tmp_pk = dcntsavg[pind]/(i+1)
dpk = abs((tmp_pk - pk)/tmp_pk)

;; plot as you go so you can see the distribution converge toward the parent
if lookatme then begin
  ; figure out which angle channels are relevant
  ;cnts_plot = total(cnts,2)/6
  colz=get_colors()

  cols=[colz.black,colz.red,200,colz.green,colz.cyan,colz.blue,colz.magenta]

  window,1
  plot,energy[*,7],cnts[*,7],xrange=[0.01,10],yrange=[0,1.1*max(cnts)],thick=2,color=cols[0]
  bins=[41,42,43,44,45,46,47]
  for pp=1,n_elements(bins)-1 do begin
    oplot,energy[*,bins[pp]],cnts[*,bins[pp]],thick=2,color=cols[pp]
  endfor
endif

; this loop is the actual iteration of the counts array
while dpk gt 1d-2 do begin ; stop iterating when the change b/w iterations is <1d-2
  pk = tmp_pk ; update the baseline to compare against
  tmp = cnts
  
  for jj=0,n_elements(cnts)-1 do begin
    tmp(jj) = randomn(seed,1,poisson=float(tmp(jj)>1.e-35)) ;populate or unpopulate edge bins with only 1 count
  endfor
  tmp=1.*(tmp+tmp^.5*randomn(seed,nrg,nbins,1) > 0) ; add poisson noise to each bin
  dcntsavg = dcntsavg + tmp
  
  tmp_pk = dcntsavg[pind]/(i+1) ;find the new peak
  dpk = abs((tmp_pk - pk)/tmp_pk) ;what's the change from the last iteration to this iteration?
  ; don't forget to count iterations!
  i ++

  if lookatme then begin
    for pp=0,n_elements(bins)-1 do begin
      oplot,energy[*,bins[pp]],dcntsavg[*,bins[pp]]/(i+1),linestyle=2,thick=2,color=cols[pp]
    endfor
  endif
endwhile

nn=i+1
; endfor
var_cnts = dcntsavg/nn
;; we need the variance in df units though so now convert to df units
;; from mvn_sta_convert_units, the conversion is scale = 1.d/(dt * gf * energy^2 * 2./mass/mass*1e5 )
;; where gf = data.geom_factor*data.gf*data.eff
;; dt = data.integ_t
;; mass = data.mass*data.mass_arr
;; dead = data.dead            ; dead time array usec for STATIC

var_cnts_raw = sqrt(cnts)

gf = errdat.geom_factor*errdat.gf*errdat.eff
integ_dt = errdat.integ_t
mass = errdat.mass*errdat.mass_arr
dead = errdat.dead

;scale = 1.d/(integ_dt * gf * energy^2 * 2./mass/mass*1e5 )
;; wait we actually do this in some weird units 
gf = errdat.gf 
scale = dead/gf 

var_data = var_cnts*scale*scale
sig_data = sqrt(var_data)

var_data_raw = var_cnts_raw*scale*scale

;; now that the uncertainty in the data is known, propagate it through 
;sth0 = total(sth*data)/(total(data)>1.e-20)
;v0=v[*,0]*sth0
term_i = sth*data
top = total(term_i)
 
dtopdd = sth 

var_i = dtopdd^2*var_data 
var_top = total(var_i) 

var_i_raw = dtopdd^2*var_data_raw
var_top_raw = total(var_i_raw)

;; the bottom is easy!
term_i = data
bottom = total(data)>1.e-20
var_bottom = total(var_data)
var_bottom_raw = total(var_data_raw)

v0 = v[*,0]*top/bottom

var_v0 = v0^2*(var_top/top^2 + var_bottom/bottom^2)
var_v0_raw =  v0^2*(var_top_raw/top^2 + var_bottom_raw/bottom^2)


;; vth2,tp have uncertainty from v0 and from the counts
;vth2 = 2.*(total((v*sth - v0#replicate(1.,nth))^2*data)/(total(data)>1.e-20))       ; vth^2 = 2*sigma^2
;tp = .5*m*vth2

term_i = (v*sth - v0#replicate(1.,nth))^2*data
top = total(term_i) 

dtopdd = (v*sth - v0#replicate(1.,nth))^2
dtopdv0 = -2.*(v*sth - v0#replicate(1.,nth))*data

var_i = dtopdd^2*var_data + dtopdv0^2*(var_v0#replicate(1.,nth))
var_i_raw = dtopdd^2*var_data_raw + dtopdv0^2*(var_v0_raw#replicate(1.,nth))

var_top = total(var_i)
var_top_raw = total(var_i_raw)

tk = tp/8.617d-5 ; temp in kelvin
var_tk = tk^2*(var_top/top^2 + var_bottom/bottom^2) ;- 2.*cov_tb/(top*bottom))
var_tk_raw = tk^2*(var_top_raw/top^2 + var_bottom_raw/bottom^2) 
var_t = var_tk * (8.617d-5)^2
var_t_raw = var_tk_raw * (8.617d-5)^2
;if (errdat.mode ne 1 and tp lt 0.05 and sqrt(var_t) gt 0.05) then stop 

;if tp lt 0.03 then print, (sqrt(var_t_raw)-sqrt(var_t))/sqrt(var_t)

return, sqrt(var_t)

end