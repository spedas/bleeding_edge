function mvn_sta_c6temp_staterr,errdat,vd,tm,corr,valid=valid
;; calculates random uncertainty from counting statistics for c6 temperature measurement. 
;; at periapsis the error is typically ~5-10%. 

  ;tm  = total((v-vd)^2*data*u^2/v)/(total(data*u^2/v)>1.e-20)
  ;tm is a function of v, vd, data/counts, and u...
  common mvn_sta_vd_cmn
  if size(do_vd,/type) eq 0 then do_vd=0

 
  energy=errdat.energy 
  sc_pot=errdat.sc_pot
  data=errdat.data
  nrg=errdat.nenergy
  nbins=errdat.nbins
  ;; the data includes the background, which will contribute to the noise
  ;; so don't remove it. 
  cnts=errdat.cnts; - errdat.bkg)
  charge=1.
  mi=32.
  
  energy2=(errdat.energy+charge*sc_pot/abs(charge))>0. 
  
  u = (2.*energy*charge)^.5     ; use this velocity for corrections to distribution function
  v = (2.*energy2*charge)^.5     ; ESA measures energy/charge

  v = v>0.001
  
  if tm lt 0.03 then lookatme=1 else lookatme=0
   lookatme=0
  
  ; v = sqrt(2*E) is the measured ion velocity.
  ;     if v has error associated with it from the width of the energy bins, dE/E = 0.16
  ;     var_v = E*(0.16)^2/2 = 0.0128*E
  ;     but we actually know the center of the bin very well, so just set this to zero
  ;var_v = 0.0128*energy
  var_v = 0.


  ; u = sqrt(2(E+q*scpot)) is the ion velocity corrected for sc potential.
  ;     u has error associated with it from the spacecraft potential and from dE.
  ;     I'm not sure what the uncertainty in the spacecraft potential is at any given time.
  ;     If you assume it's the same as the STATIC dE/E then: 
  q = 1.
  var_u = (0.16/u)^2*(energy^2 + q^2*sc_pot^2)
  ;     But actually set the dE/E uncertainty to zero so that the only uncertainty 
  ;     in u is in the spacecraft potential. And a better way to do this estimation is to
  ;     just plug in different values of the sc potential and see how much the temperature changes.
  ;     We try to correct for this, so actually just ignore var_u for now also.
  var_u = 0.  
       
  
  ; vd = total(data*u^2)/(total(data*u^2/v)>1.e-20) is the bulk velocity
  ;    vd has error associated with the data, u, and v. du and dv given above.
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
    

  datashape = size(cnts)
  na = datashape[1]
  nb = datashape[2]
  if not keyword_set(nn) then nn = 200
  dcntsavg=make_array(na,nb)
  i=0
  seed=systime(/seconds) 
  
;  for i=0,nn-1 do begin  
  ; set up the first loop: find the peak, add random noise to the counts, 
  ; find the peak in the new counts, find the fractional difference b/w the peaks 
    pk = max(cnts, pind)
  ;  tmp = cnts + abs(cnts)^.5*randomn(abc,na,nb,/double) 
  tmp=cnts
      for jj=0,n_elements(cnts)-1 do begin
        tmp(jj) = randomn(seed,1,poisson=float(tmp(jj)>1.e-35))
      endfor
      tmp=1.*(tmp+tmp^.5*randomn(seed,na,nb) > 0)
      dcntsavg = dcntsavg + tmp
  
    tmp_pk = dcntsavg[pind]/(i+1)
    dpk = abs((tmp_pk - pk)/tmp_pk)
    
    ;; plot as you go so you can see the distribution converge toward the parent
    if lookatme then begin
    ; we have 6 mass channels 
       ;cnts_plot = total(cnts,2)/6
       cnts_plot=cnts[*,41];this is usually the farthest from peak channel 
       colz=get_colors()
        
       cols=[colz.black,colz.red,200,colz.green,colz.cyan,colz.blue,colz.magenta]
      
        window,1
        plot,energy[*,41],cnts[*,41],xrange=[0.01,10],yrange=[0,1.1*max(cnts)],thick=2,color=cols[0]
          bins=[41,42,43,44,45,46,47]
        for pp=1,n_elements(bins)-1 do begin
          oplot,energy[*,bins[pp]],cnts[*,bins[pp]],thick=2,color=cols[pp]
        endfor
    endif
    
    ; this loop is the actual iteration of the counts array
    while dpk gt 1d-2 do begin ; stop iterating when the change b/w iterations is <1d-2
      pk = tmp_pk ; update the baseline to compare against 
;      abc = total(tmp,/NaN)/!pi ; reset the random number generator
;      tmp = cnts + abs(cnts)^.5*randomn(abc,na,nb,/double) ; remake the noisy array 

      for jj=0,n_elements(cnts)-1 do begin
        tmp(jj) = randomn(seed,1,poisson=float(tmp(jj)>1.e-35))
      endfor
      tmp=1.*(tmp+tmp^.5*randomn(seed,na,nb) > 0)
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
 
 ;;this _raw stuff is just for comparison
 var_cnts_raw = sqrt(cnts)
 
 gf = errdat.geom_factor*errdat.gf*errdat.eff
 integ_dt = errdat.integ_t 
 mass = errdat.mass*errdat.mass_arr
 dead = errdat.dead 
 
 scale = 1.d/(integ_dt * gf * energy^2 * 2./mass/mass*1e5 )
 
 var_data = var_cnts*scale*scale 
 var_data_raw = var_cnts_raw*scale*scale
 sig_data = sqrt(var_data)
 nz=where(cnts ne 0)
 ;print,(data[nz]-var_data[nz])/data[nz]
 
 if lookatme then begin
     window,2
     plot,energy[*,41],data[*,41],xrange=[0.01,10],yrange=[0,1.1*max(data)],thick=2,color=cols[0]
     
     for pp=1,n_elements(bins)-1 do begin
       oplot,energy[*,bins[pp]],data[*,bins[pp]],thick=2,color=cols[pp]
     endfor
    
     for pp=0,n_elements(bins)-1 do begin
       oplot,energy[*,bins[pp]],sig_data[*,bins[pp]],linestyle=2,thick=2,color=cols[pp]
     endfor
 endif
 
 ;;;; At this point we know var_data, var_u, var_v 
 ;;; Now begin claculating var_vd and var_t.
 
 ;;; var_vd 
 ;   if tm le 0.03 then stop
  data=double(data)
  u=double(u)
  v=double(v)
   
  term_i = data*u^2 ; each individual term in the sum, indexed by i (it doesn't matter that it's 2D) 
  top = total(term_i)
  ;       var_top = (d(top)/du)^2 * var_u + (d(top)/d(data))^2 * var_data
  ;
  dtopdu = 2*u*data
  dtopdd = u^2
    
  ;; the entire top is a sum: a*A + b*B + c*C +.... 
  ;; where the lowercase letters are constants representing u^2 for each bin,
  ;; and the uppercase letters are the number of counts in each bin
  ;; the variance for the sum is
  ;; a^2*var(A^2) + b^2*var(B^2) +... + 2ab cov_ab 
  ;; so I guess you need a covariance for each pair of terms.
  ;;cov_AB = exval((A-exval(A))(B-exval(B)))
  
  ; this array contains the variance of each term in the sum, indexed by i 
  var_i = dtopdu^2*var_u + dtopdd^2*var_data
  var_i_raw = dtopdu^2*var_u + dtopdd^2*var_data_raw
  
  tmp_ij = 0d
  nz = where(term_i ne 0)
  ; loop through the nonzero terms
;  for ii=0,n_elements(nz)-2 do begin 
;    ci=dtopdd[nz[ii]]
;    term_ii = term_i[nz[ii]]
;    exval_ii = ci*var_data[nz[ii]]
;      
;    foreach jj,nz[(ii+1):-1] do begin ; for each nonzero value, loop through the following nonzero values      
;      cj=dtopdd[jj]
;      term_jj = term_i[jj]    
;      exval_jj = cj*var_data[jj]
;      
;      ;term_iijj =  
;      
;      ;cov_ij = (term_ii-exval_ii)*(term_jj-exval_jj)
;     ; cov_ij = exval(xy) - exval(x)exval(y)
;     
;      
;      tmp_ij = tmp_ij + 2.*ci*cj*cov_ij
;      if tm le 0.03 and tmp_ij gt 1. then stop
;    endforeach
;  endfor

  var_top = total(var_i) + tmp_ij 
  var_top_raw = total(var_i_raw,/NaN) + tmp_ij

;;; now repeat everything for the bottom. 

  term_i = data*u^2/v
  bottom = (total(term_i)>1.e-20)
  ;       var_bottom = (d(bottom)/du)^2 * var_u + (d(bottom))/dv)^2 * var_v + (d(bottom)/d(data))^2 * var_data

  dbottomdu = 2*u*data/v
  dbottomdd = u^2/v
  dbottomdv = -data*u^2/v^2
  
  dbottomdd[where(dbottomdd gt 1000)] = 0. ;;; remove low energy bins with 1 or 2 counts when the s/c potential is high -- if you don't, the error will be overestimated by ~1000x

  var_i = dbottomdu^2*var_u + dbottomdd^2*var_data + dbottomdv^2*var_v
  var_i_raw = dbottomdu^2*var_u + dbottomdd^2*var_data_raw + dbottomdv^2*var_v
  
  tmp_ij = 0.
  nz = where(term_i ne 0)
  ; loop through the nonzero terms
;  for ii=0,n_elements(nz)-2 do begin
;    foreach jj,nz[(ii+1):-1] do begin ; for each nonzero value, loop through the following nonzero values
;      ci=dbottomdd[nz[ii]]
;      cj=dbottomdd[jj]
;
;      term_ii = term_i[nz[ii]]
;      term_jj = term_i[jj]
;
;      exval_ii = ci*var_data[nz[ii]]
;      exval_jj = cj*var_data[jj]
;
;      cov_ij = (term_ii-exval_ii)*(term_jj-exval_jj)
;
;      tmp_ij = tmp_ij + 2.*term_ii*term_jj*cov_ij
;    endforeach
;  endfor
  
  
  var_bottom = total(var_i) + tmp_ij 
  var_bottom_raw = total(var_i_raw,/NaN) + tmp_ij 
  
  ; now the covariance b/w the top and bottom
  ; 
  ; we need the expectation values of the top and bottom. 
  ; to get those, do the expectation values of each term in the sums
  ; for the top since u is known, the only variable is the expectation value of the data
  ; the expectation value of the data is equal to the variance. 
  ; same for the bottom since u^2/v is known.
  exval_top = total(var_data*u^2)
  exval_bottom = (total(var_data*u^2/v)>1.e-20)
  exval_vd = exval_top/exval_bottom
  
  
  
  ; for us A = top and B = bottom, we only have 1 measurement of each. 
  ; So the exval of the product of the differences is just the product of the differences.
  ; that is:
  cov_tb = (top-exval_top)*(bottom-exval_bottom)
  ; is just one number.
  cov_tb=0
    
  var_vd = vd^2*(var_top/top^2 + var_bottom/bottom^2 - 2.*cov_tb/(top*bottom))
  if do_vd then sta_c6_vd_error=[sta_c6_vd_error, sqrt(var_vd/(mi*986d6/(3d5)^2))] & if do_vd then sta_c6_vd_errtime = [sta_c6_vd_errtime, errdat.time]
  var_vd_raw =  vd^2*(var_top_raw/top^2 + var_bottom_raw/bottom^2 - 2.*cov_tb/(top*bottom))
;  if var_vd gt 1 then begin
;    vd_var_top = var_top
;    vd_top = top
;    vd_var_bottom = var_bottom
;    vd_bottom = bottom 
;  endif
;  
 ; if tm lt 0.03 then print, vd, sqrt(var_vd)

  ; Now calculate var_t
  ; the bottom is the same as for vd but now the top is
  term_i = (v-vd)^2*data*u^2/v
  top = total(term_i)

  ; var_top = (dtop/dv)^2*var_v + (dtop/dvd)^2*var_vd + (dtop/dd)^2*var_d + (dtop/du)^2*var_u
  dtopdv = data*u^2 - vd^2*data*u^2/v^2
  dtopdvd = -2*(v-vd)*data*u^2/v
  dtopdd = (v-vd)^2*u^2/v
  dtopdu = 2*(v-vd)^2*data*u/v
  
  dtopdvd[where(v lt 0.002)] = 0. ;;; remove low energy bins with 1 or 2 counts when the s/c potential is high -- if you don't, the error will be overestimated by ~1000x
  dtopdd[where(v lt 0.002)] = 0. ;;; remove low energy bins with 1 or 2 counts when the s/c potential is high -- if you don't, the error will be overestimated by ~1000x

  
  
  
  tmp_ij = 0.
  nz = where(term_i ne 0)
  ; loop through the nonzero terms
;  for ii=0,n_elements(nz)-2 do begin
;    foreach jj,nz[(ii+1):-1] do begin ; for each nonzero value, loop through the following nonzero values
;      ci=dtopdd[nz[ii]]
;      cj=dtopdd[jj]
;
;      term_ii = term_i[nz[ii]]
;      term_jj = term_i[jj]
;
;      exval_ii = ci*var_data[nz[ii]]
;      exval_jj = cj*var_data[jj]
;
;      cov_ij = (term_ii-exval_ii)*(term_jj-exval_jj)
;
;      tmp_ij = tmp_ij + 2.*term_ii*term_jj*cov_ij
;    endforeach
;  endfor

  var_i = dtopdv^2*var_v + dtopdvd^2*var_vd + dtopdd^2*var_data + dtopdu^2*var_u
  var_top = total(var_i,/NaN) + tmp_ij 
  
  var_i_raw = dtopdv^2*var_v + dtopdvd^2*var_vd + dtopdd^2*var_data_raw + dtopdu^2*var_u
  var_top_raw = total(var_i_raw,/NaN) + tmp_ij
  
  exval_top = total((v-exval_vd)^2*var_data*u^2/v)
  
  cov_tb = (top-exval_top)*(bottom-exval_bottom)
  cov_tb = 0 

  tk = tm/8.617d-5 ; temp in kelvin 
  var_tk = tk^2*(var_top/top^2 + var_bottom/bottom^2 - 2.*cov_tb/(top*bottom))
  var_t = var_tk * (8.617d-5)^2 
  
  var_tk_raw = tk^2*(var_top_raw/top^2 + var_bottom_raw/bottom^2 - 2.*cov_tb/(top*bottom))
  var_t_raw = var_tk_raw * (8.617d-5)^2
 
  ;; now compare this to the result using the algorithm found in dn_4d
  ;; which adds random noise onto the measurement, repeats the measurement, 
  ;; and keeps track of the discrepancies, instead of formally propagating 
  ;; the error in the counts through to the error in the temperature.
  
;  tmpdat = errdat
;  cnt=total(errdat.cnts)/!pi
;  if not keyword_set(nn) then nn = 100
;  dtavg=0
; ; tt = tbc_4dg3(tmpdat,ENERGY=[0.,30.],MASS=[24.,40.],m_int=32.,mincnt=100.,no_error=1)
;  tt=tm
;  for i=0,nn-1 do begin
;    tmpdat = errdat
;    tmpdat.cnts = errdat.cnts + errdat.cnts^.5*randomn(cnt,na,nb)
;    dtavg = dtavg + abs(tt - tbc_4dg3(tmpdat,ENERGY=[0.,30.],MASS=[24.,40.],m_int=32.,mincnt=100.,no_error=1))
;    cnt = total(tmpdat.cnts)/!pi
;  endfor
;  sig_t = dtavg/nn
;  
 ; if tm lt 0.03 then print,sig_t/8.617d-5,sqrt(var_tk),sqrt(var_tk)/tk
; if tm lt 0.03 then begin
;  print, (sqrt(var_tk_raw)-sqrt(var_tk))/sqrt(var_tk)
; endif

;if (sqrt(var_t) gt 0.5 and tk le 600.) then stop 

 ; stop 
  return,sqrt(var_t)
end