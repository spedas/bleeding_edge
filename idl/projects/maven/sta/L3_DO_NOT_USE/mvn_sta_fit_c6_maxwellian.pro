;;;;; fit a maxwellian to c6 data.
;;; to do this you will need:
;     -- the uncorrected energy beamwidth temperature (second moment)
;     -- the bulk flow velocity (first moment) 
;     -- the height of the peak (zeroth moment x constant) 
;;; caveats: 
;     -- the LPW correction MUST be loaded BEFORE YOU RUN THIS:
;           run "mvn_lpw_load_l0, /notatlasp
;                mac_lpw_load_pot_c6"               
;                IN THAT ORDER before you run this program
;     -- you must load ca data to calculate the ion suppression correction
;     -- the definition of df in c6 is not exactly a regular maxwellian
;         c6 data assumes that the df is measured across the whole FOV 
;         it assumes the counts are measured equally across the FOV 
;         (so weird things were done to calculate the geometric factor)
;         this effectively scales down the df so that when you integrate over it
;         in the manner of nb_4d, you get the right density
;         it is NOT the same df as a "typical" maxwellian 
;         f(v) = n*(m/(2*pi*k*T))^1.5*exp(-m*(v-vb)^2/(2*k*T)) 
;         so, you need to use the peak of the c6 distribution to fit that constant
;         instead of plugging in a real density
;         then integrate at the end in the manner of nb_4d (or nbc_4d) to get the density

;;; i tried to make this as self-contained as possible, so a lot of code is stolen 
;;; from other STATIC functions
;;; i will try to note where it comes from if possible

function mvn_sta_fit_c6_maxwellian, dat1,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,$
  BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt,nne=nne,lpw=lpw;,result=result
  
common stambfit, m_amu, v_fit, df_fit, density_fit, density_time ;; this will be needed later 
if size(density_fit,/type) eq 0 then begin
  density_fit=[]
  density_time=[]
endif
dat2=dat1

;;; start out by shamelessly plundering code from tbc_4d, 
;;; which does all the mass/energy range limiting, 
;;; applies the LPW s/c pot correction,
;;; and calculates the first and second moments

;;; i will indent all the code until we stop plundering from tbc_4d so you can just ignore it

            ;def_ti = [!values.D_NAN, !values.D_NAN, !values.D_NAN, !values.D_NAN]
            ;def_ti = !values.F_NAN
;            result = { fit_vals: make_array(32,value=!values.F_NAN), $
;              data: make_array(32,value=!values.F_NAN) } 

            tmp =  make_array(32,value=!values.F_NAN)
            result = { A: !values.F_NAN, $
              Ti: !values.F_NAN, $
              vb: !values.F_NAN, $
              fit_vals: tmp, $
              lpw_scpot: tmp, $
              data: tmp }
            def_ti = result
            
            if dat2.valid eq 0 then begin
              print,'Invalid Data'
              return, def_ti
            endif
            
            if (dat2.quality_flag and 195) gt 0 then begin
              return, def_ti
            endif
            
            if keyword_set(mi) and keyword_set(en) then begin
              if mi le 5. and max(en) le 200. and dat2.att_ind ge 2 then begin
                return,def_ti
              endif
            endif
            
            common mvn_lpw_pot_c6,mvn_lpw_pot_c6_dat    ; this is used by c6 data to correct for LPW produces scpot changes during a STATIC energy sweep
            
            ; the following can be used to speed up calculations, function should only should be used at low altitudes
            ; if (total(dat2.pos_sc_mso^2) gt (3386+600.)^2) and dat2.data_name eq 'd1e 32e4d16a8m' then return,def_ti
            
            dat = omni4d(dat2,bins=bins) ;;; this doesn't actually do anything if you input c6 data but stops it from breaking if you don't use c6 i think
            dat = conv_units(dat,"df")    ; convert to distribution function
            
            n_e = dat.nenergy
            data = dat.data
            energy = dat.energy
            cnts = dat.cnts 
            
            ; calculate correction for ion suppression
            
            common mvn_sta_kk1,kk1,kk1_trange
            corr = MVN_STA_GET_KK(dat)
            
            ; determine how many energy bins to use around the peak - may want to change this to a better method
            
            if not keyword_set(nne) then begin
              if n_e eq 64 then nne=6
              if n_e eq 32 then begin
                if dat2.mode eq 1 then nne=4
                if dat2.mode ge 2 then nne=6 ;; this is the new part, it used to just be 4
                wide=0
                if keyword_set(wide) then nne = 20
              endif
              if n_e le 16 then nne=2
              if n_e eq 48 then nne=6   ; when does this happen? is this for swia?
              if dat.mode eq 7 then nne=2*nne
            endif
            
            ; limit energy range if explicitly input - for cold thermal ions generally want en=[0,11] so attenuator transitions don't matter
            
            en_min = min(energy)
            en_max = max(energy)
            if keyword_set(en) then begin
              ind = where(energy lt en[0] or energy gt en[1],count)
              if count ne 0 then data[ind]=0.
              if count ne 0 then cnts[ind]=0.
              en_min = en_min > en[0]
              en_max = en_max < en[1]
            endif
            
            ; limit the mass range to a single ion with explicit input - this should be used
            
            if keyword_set(ms) then begin
              ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
              if count ne 0 then data[ind]=0.
              if count ne 0 then cnts[ind]=0.
            endif
            
            ; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements
            
            if dat.nmass eq 1 then begin
              if dat.time lt time_double('14-10-1') then begin
                maxcnt = max(data,mind)
                if n_e eq 64 then nnne=4 else nnne=nne
                data[0:(mind-nnne>0)]=0.
                data[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
                cnts[0:(mind-nnne>0)]=0.
                cnts[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
              endif
            endif
            
            ; limit the energy range to near the peak for nominal Mars data
            
            data2 = data
            cnts2 = cnts
            if ndimen(data) eq 2 then begin
              maxcnt = max(total(cnts,2),mind)
              data[0:(mind-nne>0),*]=0.
              data[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
              cnts[0:(mind-nne>0),*]=0.
              cnts[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
              en_peak=energy[mind,0]
            endif else begin
              maxcnt = max(cnts,mind)
              data[0:(mind-nne>0)]=0.
              data[((mind+nne)<(n_e-1)):(n_e-1)]=0.
              cnts[0:(mind-nne>0)]=0.
              cnts[((mind+nne)<(n_e-1)):(n_e-1)]=0.
              en_peak=energy[mind]
            endelse
            
            ; if the number of counts near the peak is less than 75% of total counts in the energy range, then it is not a beam
            
            if total(cnts) lt .75*total(cnts2) then begin
             ; return,def_ti
            endif
            
            ; treat low energy outliers with only one count as noise
            
            ind = where(cnts le 1.1 and energy lt 0.6*en_peak,count)
            if count gt 0 then data[ind]=0
            
            ; correct for ion suppression
            
            data = data*corr
            
            ; get rid of low count measurements and those whose peak is too close to energy limits
            
            if keyword_set(mincnt) then if total(cnts) lt mincnt then begin
              return,def_ti
            endif
            if en_peak lt 1.5*en_min or en_peak gt en_max/1.5 then begin
              return,def_ti
            endif
            charge=dat.charge
            if keyword_set(q) then charge=q
            if keyword_set(scpot_mult) then dat.sc_pot = scpot_mult*dat.sc_pot
            sc_pot=dat.sc_pot
            
            ; adjust energies for spacecraft potential - note that pot=!values.f_nan will result in a NAN - this routine requires valid sc_pot
            energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.    ; energy/charge analyzer, require positive energy
            
            if size(mvn_lpw_pot_c6_dat,/type) eq 8 and dat.data_name eq 'c6 32e64m' and not keyword_set(lpw) then begin
              minval = min(abs(mvn_lpw_pot_c6_dat.time-dat.time),lpw_ind)
              offset_pot = mvn_lpw_pot_c6_dat.pot[lpw_ind,mind]
              lpw_pot = reform(mvn_lpw_pot_c6_dat.pot[lpw_ind,*]-offset_pot)#replicate(1.,64)
              energy=(dat.energy+charge*(dat.sc_pot-lpw_pot)/abs(charge))>0.
            endif
            
            ; Note - we don't need to divide by mass
            
            u = (2.*dat.energy*charge)^.5     ; use this velocity for corrections to distribution function
            v = (2.*energy*charge)^.5     ; ESA measures energy/charge
            
            
            v = v>0.001
            
            ; Notes f ~ Counts/u^4 = C/u^4
            ; u^2 = v^2 + 2e*pot/m => 2udu = 2vdv => dv = du/u * (u^2/v)
            ;   du/u = constant for logrithmic sweep
            ; dv = d((2E/m)^.5) = (du/u)*(u^2/v)
            ; vd = integral(fv dv)/integral(f dv)
            ; T/m = integral(f(v-vd)^2 dv)/integral(f dv)
            
            data[where(v eq min(v))] = 0. 
            
            if keyword_set(ms) then begin
              vd = total(data*u^2)/(total(data*u^2/v)>1.e-20)
              tm  = total((v-vd)^2*data*u^2/v)/(total(data*u^2/v)>1.e-20)
            endif else begin
              vd = total(data*u^2,1)/(total(data*u^2/v,1)>1.e-20)
              vd = replicate(1.,n_e)#reform(vd,n_elements(vd))
              tm  = total((v-vd)^2*data*u^2/v,1)/(total(data*u^2/v,1)>1.e-20)
            endelse

;;; this concludes our plundering from tbc_4d 
;;; we now have the first moment vd and the second moment tm 
;;; vd is currently in units of sqrt(eV) because we never divided by mass
;;; use the height of the peak to estimate the zeroth moment
;;; NOT the max of the data -- but the actual height of the peak at v=vd 
;;; you can get this easily because f(v) = peak*exp(-m*(v-vd)^2/(2*k*T)) 
;;; you know f(v) and you know the exponential. 

mass = mi*dat.mass ;;eV/(km/s)^2 

vb = vd/sqrt(mass) ;; km/s 

;;; to get the total df, sum the data over the mass direction

;;; this time we DON'T want the data far from the peak set to zero, 
;;only the data where the sc potential should make it invalid.
data = data2 
data[where(v eq min(v))] = 0. 

ind = where(cnts le 1.1 and energy lt 0.6*en_peak,count)
if count gt 0 then data[ind]=0

;; and correct again for ion suppression. 
data = data*corr

df = total(data,2) ;; c6 df units 
vpar = sqrt(2.*energy[*,0]/mass) ;; km/s 
df[where(vpar eq 0)]=0.
z = mass*(vpar - vb)^2 / (2.*tm) ;;unitless + positive 
pk = max(df,pkind)/max(exp(-z))


;;; now we have a guess for the 0th, 1st, 2nd moments and can fit the maxwellian.
;;; it should look like pk*exp(-m*(v-vb)^2/(2*tm))
;;; where pk is in c6 df units, m is eV/(km/s)^2, v and vb are km/s, and tm is eV
;;; use amoeba to do the fit: it will minimize whatever is returned, 
;;; so use a function that returns the difference between the fit and the data in the variable 'df' 
;;; however, only use a certain # bins on either side of the peak
nbins = 2
fit_ind0 = (pkind-nbins)>0
fit_ind1 = (pkind+nbins)<(n_elements(df)-1)

;;; amoeba will vary whatever you give it as parameters, but you also need to pass it
;;; mi, vpar, df so use the common block stambfit to do that 

m_amu = mi
v_fit = vpar[fit_ind0:fit_ind1]
df_fit = df[fit_ind0:fit_ind1]

if n_elements(df_fit) lt 5 then begin
  print, 'out of energy range'

  result = { A: !values.F_NAN, $
    Ti: !values.F_NAN, $
    vb: !values.F_NAN, $
    fit_vals: make_array(32), $
    lpw_scpot: reform(mvn_lpw_pot_c6_dat.pot[lpw_ind,*]-offset_pot), $ ;  correction to scpot calculated from lpw
    data: df }
  return, result
endif

;;; try and eliminate double-peaked distributions
;;; bin 2 of df_fit holds the peak. 
;;; it's double-peaked if df_fit goes to less than 50% of the peak in bins 1 or 3, then back up in bins 0 and 4 

double_peaked = 0

if df_fit[1] lt 0.75*pk then begin
  if df_fit[0] gt df_fit[1] then double_peaked = 1
endif

if df_fit[3] lt 0.75*pk then begin
  if df_fit[4] gt df_fit[3] then double_peaked = 1
endif

if double_peaked then begin
  print, 'double-peaked'
  
  result = { A: !values.F_NAN, $
    Ti: !values.F_NAN, $
    vb: !values.F_NAN, $
    fit_vals: make_array(32), $
    lpw_scpot: reform(mvn_lpw_pot_c6_dat.pot[lpw_ind,*]-offset_pot), $ ;  correction to scpot calculated from lpw
    data: df }
  return, result 
endif


par = amoeba(1d-5, p0=[pk, vb, tm], $
  scale=[2.*pk, 0.1*vb, 1.5*tm], $
  function_name='sta_maxbol_amoeba')
  
  if n_elements(par) eq 1 then begin
    print,'AMOEBA failed to converge'
    return, def_ti
  endif
  
  z2 = mass*(vpar-par[1])^2 / (2.*par[2]) ;; unitless positive

  fit_vals = par[0] * exp(-z2) ;;c6 df units
  
;;; at the end, par should hold the fitted values of [pk, vb, tm] 
;;; and fit_vals should hold the fit
;;; fit_vals should be directly comparable to df.

;window,2,xs=500,ys=500
;plot,vpar,df,xrange=[0,50]
;oplot,vpar,fit_vals,color=250
;wait,0.5

;if par[1] lt 5. then stop

;;; in the interest of having this program be self-contained,
;;; i will now steal code from nbc_4d in order to calculate the density
;;; and make sure this fit isn't insane

            ;density = total(Const*denergy*(energy^(.5))*fit_vals*2.*cos(theta)*sin(dtheta/2.)*dphi,1)
            ;; for c6: theta, dtheta, dphi, denergy, and energy are all the same for every mass channel
            ;; so pull them out from any mass channel.
            
;            const = (mass)^(-1.5)*(2.)^(.5)
;            denergy = dat.denergy[*,0]
;            energy2 = energy[*,0] ;it SHOULD be corrected for sc pot
;            theta = dat.theta[*,0]/!radeg
;            dtheta = dat.dtheta[*,0]/!radeg
;            dphi = dat.dphi[*,0]/!radeg
;            density_core = total(Const*denergy*(energy2^(.5))*fit_vals*2.*cos(theta)*sin(dtheta/2.)*dphi)
;            density_data = total(Const*denergy*(energy2^(.5))*df*2.*cos(theta)*sin(dtheta/2.)*dphi)
;            
;            density_fit = [density_fit, density_core]
;            density_time = [density_time, dat.time]
;            
;            ;; if the difference b/w core and total density is >10% then set a flag?
;            dif = density_data - density_core
;            
;            if dif/density_core gt 0.05 then flag=1 else flag=0 
;                       
;            ;;;; get the eflux similar to je_4d 
;                     
;            scale = energy2^2*2e5/mass^2 ;;; convert from df to eflux
;            eflux_data = total(df*scale*denergy) ;;; integrate 
;            eflux_core = total(fit_vals*scale*denergy)
;            
;            df_tail = (df - fit_vals)>0.
;            eflux_tail = total(df_tail*scale*denergy)
;          
;          ratio = eflux_tail/eflux_core           
          
            
     ;;; the density doesn't seem quite right, which I imagine has to do with ion suppression correction
     ;;; I did not deal with its full glory in this program so don't use it as a check
     
   
   ;result = [par[0], par[1], par[2], ratio]
   ;result = fit_vals 
   result = { A: par[0], $
    Ti: par[2], $
    vb: par[1], $
    fit_vals: fit_vals, $
    lpw_scpot: reform(mvn_lpw_pot_c6_dat.pot[lpw_ind,*]-offset_pot), $ ;  correction to scpot calculated from lpw
    data: df } 

;stop
return, result


end    