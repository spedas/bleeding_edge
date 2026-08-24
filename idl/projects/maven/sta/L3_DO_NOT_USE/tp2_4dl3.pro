;+
;FUNCTION:	tp2_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
;INPUT:	
;	dat:	structure,	4d data structure filled by themis routines mvn_sta_c8.pro
;KEYWORDS
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2,2),	optional, angle range for integration
;				theta min,max (0,0),(1,0) -90<theta<90 
;				phi   min,max (0,1),(1,1)   0<phi<360 
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;					0,1=exclude,include
;
;PURPOSE:
;	Returns the perp temperature of a beam from APID C8 in units of eV 
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;	Modified to use tplot structure 'mvn_sta_o2+_c6_ec'
;	Only valid <500 km altitude
; Designed to be called in mvn_sta_ti_an, so references some common blocks 
; that might cause other codes to break. 
;
;CREATED BY:
;	J.McFadden	2014-03-12
;LAST MODIFICATION:
;	J.McFadden	2018-06-29
;-
function tp2_4dl3,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt,avg=avg,plot=plot,th_plot=th_plot

def_ti = 0.
def_ti = !values.f_nan
common mvn_sta_temp_error, sta_c6_errtime, sta_c6error, sta_c8_errtime, sta_c8error


if dat2.valid eq 0 then begin
	print,'Invalid Data'
	sta_c8error = [sta_c8error, def_ti]
	sta_c8_errtime = [sta_c8_errtime, dat2.time]
	return, def_ti
endif

if (dat2.quality_flag and 195) gt 0 then begin
  sta_c8error = [sta_c8error, def_ti]
  sta_c8_errtime = [sta_c8_errtime, dat2.time]
  return, def_ti
endif

if dat2.apid ne 'c8' then begin
	print,'Invalid Data: Data must be Maven APID C8'
	sta_c8error = [sta_c8error, def_ti]
	sta_c8_errtime = [sta_c8_errtime, dat2.time]
	return,  def_ti
endif

; the following attempts to restrict use of this program to below 500 km

orb_rad = total(dat2.pos_sc_mso^2)^.5
if orb_rad gt (3386.+500.) then begin
  sta_c8error = [sta_c8error, def_ti]
  sta_c8_errtime = [sta_c8_errtime, dat2.time]
  return, def_ti
endif
alt=orb_rad-3386.
if orb_rad eq 0. then begin
	get_data,'alt',data=tmp95
	if size(tmp95,/type) eq 8 then begin
		alt = interp(tmp95.y,tmp95.x,dat2.time+2.)
		if alt gt 500. then begin
		  sta_c8error = [sta_c8error, def_ti]
		  sta_c8_errtime = [sta_c8_errtime, dat2.time]
		  return,def_ti
		endif
	endif
endif

datg = dat2

dat = conv_units(dat2,"counts")		; initially use counts
nth = dat.ndef
n_e = dat.nenergy
dth = dat.dtheta[31,7]			; this is only good at energies <4keV
att = dat.att_ind

; get rid of the mass array index
data = reform(dat.cnts) 
bkg = reform(dat.bkg)
energy = reform(dat.energy)
dead = reform(dat.dead)
gf = reform(dat.gf)

; restrict the energy range if the energy keyword is set
if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=1.e-20
	if count ne 0 then bkg[ind]=0.
endif

if keyword_set(mincnt) then if total(data-bkg) lt mincnt then begin
  sta_c8error = [sta_c8error, def_ti]
  sta_c8_errtime = [sta_c8_errtime, dat2.time]
  return,  def_ti
endif
if total(data-bkg) lt 1 then begin
  sta_c8error = [sta_c8error, def_ti]
  sta_c8_errtime = [sta_c8_errtime, dat2.time]
  return,def_ti
endif

data = ((data-bkg)>0.)*dead/gf		; include gf to account for decreasing sensitivity at large deflections, include dead to account for deadtime and MCP droop

data2 = fltarr(n_e,nth)

; get energy with peak counts - ignore scattered peak for att=2,3

	if att le 1 then begin
		max_en = max(total(data,2),eind)
	endif else begin
		if dth gt 5 then max_en = max(total(data[*,5:10],2),eind) else max_en = max(total(data[*,2:13],2),eind)
	endelse

; the following was inserted to assure the O2+ peak is used if 'mvn_sta_o2+_c6_ec' exists

	get_data,'mvn_sta_o2+_c6_ec',data=tmp97
	if size(tmp97,/type) eq 8 then begin
;		peak = interp(tmp97.y,tmp97.x,dat2.time+2.)
		min_tim = min(abs(tmp97.x-dat2.time-2.),ind97)
		peak = tmp97.y[ind97]
		if keyword_set(en) then peak2 = en[0] > peak < en[1]
		closest = min(abs(reform(dat2.energy[*,0])-peak2),ind2)
		eind=ind2
	endif

	nne=1
	if dat.mode eq 7 then nne=nne*2				; this may not be needed - but should reduce statistical errors
	ind0=(eind-nne)>0
	ind1=(eind+nne)<(n_e-1)

	max_th = max(dat.theta)
	if att le 1 then begin
		ith0=0
		ith1=15
	endif else begin	
		if max_th gt 30. then begin
			max_data=max(data[eind,0:10],ind) 		; exclude reflection ion peak
			ith1=10
;			ith0=5 
			ith0=(0>(2*ind-ith1)<5) 
		endif else begin
			max_data=max(data[eind,*],ind)
			nind=5
			ith0=(0>(ind-nind))
			ith1= ((ind+nind)<(nth-1))
		endelse
	endelse
 
for i=ind0,ind1 do data2[i,ith0:ith1]=data[i,ith0:ith1]		; use 7 angle bins for 6deg resolution, 11 angle bins for 3 deg resolution 

charge=dat.charge
if keyword_set(q) then charge=q
energy=dat.energy						; we should ignore s/c potential for this calculation

; the mass, m=1., was left in to explicitly check for any mass dependence
m=1. 
v = (2*energy/m)^.5
sth = sin(dat.theta/!radeg)

; this version of the v0 calculation allows sth0 to vary with energy, which should not happen unless there are time variations in the winds
; with this version of v0, statistical fluctuations result in a slightly lower temperature 
; 	v0 = total(v*sth*data2,2)/(total(data2,2)>1.e-20)

; this version of the v0 calculation assumes a fixed angle for the beam
	sth0 = total(sth*data2)/(total(data2)>1.e-20)
	v0=v[*,0]*sth0

; the following was incorrect - missing a factor of 2 seen in this equation:  vth^2 = 2*sigma^2, where sigma is the satandard deviation
;	vth2 = total((v*sth - v0#replicate(1.,nth))^2*data2)/(total(data2)>1.e-20)
; this is the correct version
	vth2 = 2.*(total((v*sth - v0#replicate(1.,nth))^2*data2)/(total(data2)>1.e-20))   		; vth^2 = 2*sigma^2
	tp = .5*m*vth2
	
	plot=0

if keyword_set(plot) then begin
;if alt lt 200. then begin
	cols=get_colors()
	sth0 = total(sth*data2)/(total(data2)>1.e-20)
	vperp = v[eind,0]*sin(dat.theta[eind,*]/!radeg)
	tmp = max(data2[eind,*],ind) 
if keyword_set(th_plot) then begin
	plot,!radeg*asin(vperp/v[eind,0]),data2[eind,*],xtitle='theta',ytitle='(Counts-bkg)*dead/gf',psym=-1,yrange=[0,1.5*max(data2[eind,*])],xrange=[-20,20]
	scale=total(data2[eind,*])/total(data2[eind,ind]*exp(-(vperp-v0[eind])^2/(2.*tp/m)))
	oplot,!radeg*asin(vperp/v[eind,0]),scale*data2[eind,ind]*exp(-(vperp-v0[eind])^2/(2.*tp/m)),color=cols.red,psym=2
	tmp = (findgen(1000.)-500.)/50.
	tmpx = !radeg*asin(tmp/v[eind,0])
	oplot,tmpx,scale*data2[eind,ind]*exp(-(tmp-v0[eind])^2/(2.*tp/m)),color=cols.green
endif else begin
	plot,vperp,data2[eind,*],xtitle='V perp',ytitle='(Counts-bkg)*dead/gf',psym=-1,yrange=[0,1.5*max(data2[eind,*])],xrange=[-1,1]
	scale=total(data2[eind,*])/total(data2[eind,ind]*exp(-(vperp-v0[eind])^2/(2.*tp/m)))
	oplot,vperp,scale*data2[eind,ind]*exp(-(vperp-v0[eind])^2/(2.*tp/m)),color=cols.red,psym=2
	tmpx = (findgen(1000.)-500.)/50.
	oplot,tmpx,scale*data2[eind,ind]*exp(-(tmpx-v0[eind])^2/(2.*tp/m)),color=cols.green
endelse
;	print,scale*total(data2[eind,ind]*exp(-(vperp-v0[eind])^2/(2.*tp/m)))
;	print,total(data2[eind,*])
endif

;if alt lt 200. then stop

;;;;;;;;;;;;;;;; end of tp2_4d, begin gwen's code

errdat = dat2
errdat.data = data2
tp_unc = mvn_sta_c8temp_staterr(errdat,tp)
sta_c8error = [sta_c8error, tp_unc]
sta_c8_errtime = [sta_c8_errtime, dat2.time]


;mvn_sta_convert_units, datg, 'df'
;jev = 1.6d-19 ;; j/ev
;m2 = 32. * 938.28d6 / (3d8)^2 ;* jev ;; eV / c^2 = eV s^2 / m^2 *jev = kg 
;
;e_corr = energy ;+ dat2.sc_pot ;;; dont do this!!!!
;
;;;; convert deflector angle to a perpendicular velocity
;;; only use the 3 energy channels
;
;;vg = sqrt(2*e_corr*jev / (32 * 1.67d-27)) *1d-3  ;km/s
;;vp_all_en = vg*sin(reform(dat.theta) / !radeg)
;;vp_peak = vp_all_en[ind0:ind1,*]
;v2 = sqrt(2*energy/m2) * 1d-3 ;km/s 
;vp_arr = v2*sth 
;vp_peak = vp_arr[ind0:ind1,*]
;
;;df_all = (datg.data - datg.bkg)*datg.dead/datg.gf
;;df_all = datg.data
;df_all = data
;
;;;; now loop through each energy channel, fit them individually, and keep track of the temps
;
;tpg_tmp = []
;goodind = []
;goodi = []
;
;for i=0,(ind1-ind0) do begin
;
;  tmp = datg.cnts
;  
;;  cnts = reform(tmp[*,ind0+i])
;;  df = reform(df_all[*, ind0+i])
;;  v_perp = reform(vp_arr[*,ind0+i])
;
;  cnts = tmp[ind0+i,*]
;  df = reform(df_all[ind0+i,*])
;  v_perp = reform(vp_peak[i,*])
;
;
;  ;;; crop the data to where counts > 50
;
;  keep = where(cnts gt 25)
;  cntsfit = cnts[keep]
;  dffit = df[keep]
;  vfit = v_perp[keep]
;  cfm = max(cntsfit, cfm_ind) ;; cnts_fit max
;  dfm = max(dffit, dfm_ind)
;
;  ;; add in something to make u not do the fit if there's not enough points cuz it wastes time
;
;  ;;; now fit to a maxwellian
;
;  ;; now set up the initial guesses.
;  ;; for T, use jim's guess
;  ;; for n, use a scale factor that you compute by making an unscaled fit match the data at the peak
;  ;; for vb, use the velocity associated with the deflector angle with the highest counts
;  
;  params = sta_maxbol()
;  params.T = tp
;  params.vb = vfit[cfm_ind]
; ;params.vb = v0[ind0+i]
; ;params.vb = v0[eind]
;;stop
;  
;  const = sqrt( m2 / (2*!pi) )
;
; ; f_noscale = const / sqrt(params.T) * exp( - m*(vfit-params.vb)^2 / (2*params.T*(3d5)^2) )
; ;f_noscale = const / (sqrt(params.T))^3 * exp( - m*(vfit-params.vb)^2 / (2*params.T*(3d5)^2) )
; f_noscale = exp( - m2*(1d3*(vfit-params.vb))^2 / (2*params.T) )
;;stop
; ; params.n = dfm / (1/sqrt(tp)*f_noscale[dfm_ind] )
; 
; ;params.n = total(df) / total(exp( - m*(v_perp-params.vb)^2 / (2*params.T*(3d5)^2) )) 
; ;params.n = scale*data2[eind,ind]
; params.n = dfm * sqrt(params.T)
;
; ; f = params.n * const / sqrt(params.T) * exp( - m*((v_perp-params.vb))^2 / (2*params.T*(3d5)^2) )
; ;f = params.n * const / (sqrt(params.T))^3 * exp( - m*((v_perp-params.vb))^2 / (2*params.T*(3d5)^2) )
;  f = params.n / sqrt(params.T) * exp( - (m2*(1d3*(v_perp-params.vb))^2) / (2*params.T) )
; 
;  params_w = params
;  
;  if (tp ne 0 and finite(tp) and n_elements(vfit) gt 2) then begin
;  
;   
;  
;  ; fit, vfit, dffit, func='sta_maxbol', param=params, fit=f2
;  fit, vfit, dffit, func='sta_maxbol', param=params_w, weight=1/dffit,fit=f_weight
;
;  ;f3 = dfm / f_noscale[cfm_ind] * const / sqrt(tp) * exp( - m2*(1d3*(vfit-params.vb))^2 / (2*tp) )
;  f4 = params_w.n / sqrt(params_w.T) * exp(- 32.*938.28d6/(3d5)^2*(v_perp-params_w.vb)^2 / (2*params_w.T) )
;
;;  if (alt lt 200. and n_elements(vfit) gt 1 and eind eq (ind0+i)) then begin
;;    p1 = plot(v_perp, df, $
;;      symbol= 'o', name='alldata', $
;;      xtitle='v_perp (km/s)', ytitle='df',$
;;      thick=2, sym_filled=1, xrange=[-1,1])
;;   p2 = plot(vfit, dffit, /overplot, color='blue', name='data to fit')
;;  if n_elements(f) gt 1 then p3 = plot(v_perp, f, /overplot, color='red', symbol='o', thick=2,name = 'initial')
;;  ;pp = plot(v_
;;  if n_elements(f4) gt 1 then p4 = plot(v_perp, f4, /overplot, color='green', symbol='o', name = 'final')
;; ; p5 = plot(vfit, f_weight, /overplot, color='orange', sym='o', name='weighted fit', linestyle=6,sym_filled=1)
;;  ;p6 = plot(vfit, f3, /overplot, color='orange', sym='o', name= 'jim temp+fitted offset')
;;  l = legend()
;  ;p7 = plot(v_perp, f4, /overplot, color='orange', thick=2)
;; endif
;
;endif
;
;  
;  if params_w.T le 0 then begin
;    params_w.T = !values.D_NAN
;  endif else begin
;    goodind = [goodind, ind0+i]
;    goodi = [goodi, i]
;  endelse
;
;
;  tpg_tmp = [tpg_tmp, params_w.T]
;endfor
;
;;; at the end do a weighted average by % of counts in that channel
;
;wtmp=total(df_all,2)
;
;if n_elements(goodind) ne 0 then begin
;  weights=wtmp[goodind] / total(wtmp[goodind])
;  tpg = total(tpg_tmp[goodi]*weights)
;endif else begin
;  tpg = 0
;endelse
;
;
;
;if ~finite(tpg) then tpg = 0
;
;
;;print, 'Jim: ', tp
;;print, 'Gwen: ', tpg
;;print, '% difference: ', abs((tp - tpg) / tp)*100.,'%'
;;print, 'alt:', orb_rad-3386,' km'
;;print, time_string(dat2.time)
;
;print, [tp, tpg, tpg/tp]
;if alt lt 200. then stop
 
return, tp            ; eV


end