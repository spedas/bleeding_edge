function mvn_sta_l3_tailtest,tt
  ;;;; to check for a tail, fit a maxwellian to the data
  ;;;; then calculate the eflux in the maxwellian and compare
  ;;;; to the total eflux

  ;;; use mvn_sta_fit_c6 to fit a maxwellian to the df
  dat1 = mvn_sta_get_c6(tt)
  ;if size(dat1,/type) ne 8 then stop 
  fit_data= mvn_sta_fit_c6_maxwellian(dat1, mass=[24.,40.], m_int=32.);, mincnt=50.);,result=fit_data
;  fit_data = { A: par[0], $
;    Ti: par[1], $
;    vb: par[2], $
;    fit_vals: fit_vals, $
;    lpw_scpot: reform(mvn_lpw_pot_c6_dat.pot[lpw_ind,*]-offset_pot), $
;    data: df }
  
  fit_vals = fit_data.fit_vals
  df = fit_data.data

  energy2 = dat1.energy[*,0]
  energy2 = energy2 + dat1.sc_pot
  mass = 32.*dat1.mass ;;eV/(km/s)^2
  denergy = dat1.denergy

  ;;;; get the eflux similar to je_4d

  scale = energy2^2*2e5/mass^2 ;;; convert from df to eflux
  eflux_data = total(df*scale*denergy) ;;; integrate
  eflux_core = total(fit_vals*scale*denergy)

  df_tail = (df - fit_vals)>0.
  eflux_tail = total(df_tail*scale*denergy)

  ratio = eflux_tail/eflux_core
  
  result = { A: fit_data.A, $
    Ti: fit_data.Ti, $
    vb: fit_data.vb, $
    df: df, $
    ratio: ratio, $ 
    lpw_scpot: fit_data.lpw_scpot, $
    flag: !values.F_NAN }

  ;; if there's eflux in the tail then set a flag
  if ratio ge 0.1 then result.flag = 1 else result.flag = 0
  
  return, result
end