;+
;
; PROCEDURE:
;     mms_mp_lmn
; 
; NOTES:
;     For more info, see: 
;     Determining L‐M‐N Current Sheet Coordinates at the Magnetopause From Magnetospheric Multiscale Data by Denton et al.
;     
;     http://dx.doi.org/10.1002/2017JA024619
;     
; HISTORY:
;     Originally provided by Jef Broll; added to SPEDAS by egrimes, April 2019
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-04-29 12:07:53 -0700 (Mon, 29 Apr 2019) $
; $LastChangedRevision: 27132 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/mms_mp_lmn.pro $
;-

pro mms_mp_lmn, t1=t1, t2=t2, threshold=threshold
	compile_opt idl2
  trange=timerange([t1,t2])
  data_rate='brst'
  
  if ~keyword_set(threshold) then begin
    threshold=0.5
  endif
  
  
  
  mms_load_fgm, probe=['1','2','3','4'], trange=trange, data_rate=data_rate, /time_clip
  
  ;for i=1,4 do time_clip, 'mms'+strtrim(string(i),1)+'_fgm_b_gse_'+data_rate+'_l2_bvec', trange[0],trange[1], newname='mms'+strtrim(string(i),1)+'_fgm_b_gse_'+data_rate+'_l2_bvec_cl'
  
  
  get_data, 'mms1_fgm_b_gse_'+data_rate+'_l2_bvec', data=mms1_b
  mms1_tfld = mms1_b.X
  mms1_b = mms1_b.Y

  get_data, 'mms2_fgm_b_gse_'+data_rate+'_l2_bvec', data=mms2_b
  mms2_tfld = mms2_b.X
  mms2_b = mms2_b.Y

  get_data, 'mms3_fgm_b_gse_'+data_rate+'_l2_bvec', data=mms3_b
  mms3_tfld = mms3_b.X
  mms3_b = mms3_b.Y

  get_data, 'mms4_fgm_b_gse_'+data_rate+'_l2_bvec', data=mms4_b
  mms4_tfld = mms4_b.X
  mms4_b = mms4_b.Y

  mms_load_fgm, probe=['1','2','3','4'], trange=trange, data_rate=data_rate, /get_fgm_ephemeris

  get_data, 'mms1_fgm_r_gse_'+data_rate+'_l2_vec', data=mms1_r
  mms1_tstate = mms1_r.X
  mms1_r = mms1_r.Y 

  get_data, 'mms2_fgm_r_gse_'+data_rate+'_l2_vec', data=mms2_r 
  mms2_tstate = mms2_r.X
  mms2_r = mms2_r.Y 

  get_data, 'mms3_fgm_r_gse_'+data_rate+'_l2_vec', data=mms3_r 
  mms3_tstate = mms3_r.X
  mms3_r = mms3_r.Y 

  get_data, 'mms4_fgm_r_gse_'+data_rate+'_l2_vec', data=mms4_r 
  mms4_tstate = mms4_r.X
  mms4_r = mms4_r.Y 


; Interpolate everything to mms1 FGM time.
  r1 = reform([interpol(mms1_r[*,0],mms1_tstate,mms1_tfld),interpol(mms1_r[*,1],mms1_tstate,mms1_tfld),interpol(mms1_r[*,2],mms1_tstate,mms1_tfld)],mms1_tfld.LENGTH,3)
  r2 = reform([interpol(mms2_r[*,0],mms2_tstate,mms1_tfld),interpol(mms2_r[*,1],mms2_tstate,mms1_tfld),interpol(mms2_r[*,2],mms2_tstate,mms1_tfld)],mms1_tfld.LENGTH,3)
  r3 = reform([interpol(mms3_r[*,0],mms3_tstate,mms1_tfld),interpol(mms3_r[*,1],mms3_tstate,mms1_tfld),interpol(mms3_r[*,2],mms3_tstate,mms1_tfld)],mms1_tfld.LENGTH,3)
  r4 = reform([interpol(mms4_r[*,0],mms4_tstate,mms1_tfld),interpol(mms4_r[*,1],mms4_tstate,mms1_tfld),interpol(mms4_r[*,2],mms4_tstate,mms1_tfld)],mms1_tfld.LENGTH,3)

  b1 = mms1_b
  b2 = reform([interpol(mms2_b[*,0],mms2_tfld,mms1_tfld),interpol(mms2_b[*,1],mms2_tfld,mms1_tfld),interpol(mms2_b[*,2],mms2_tfld,mms1_tfld)],mms1_tfld.LENGTH,3)
  b3 = reform([interpol(mms3_b[*,0],mms3_tfld,mms1_tfld),interpol(mms3_b[*,1],mms3_tfld,mms1_tfld),interpol(mms3_b[*,2],mms3_tfld,mms1_tfld)],mms1_tfld.LENGTH,3)
  b4 = reform([interpol(mms4_b[*,0],mms4_tfld,mms1_tfld),interpol(mms4_b[*,1],mms4_tfld,mms1_tfld),interpol(mms4_b[*,2],mms4_tfld,mms1_tfld)],mms1_tfld.LENGTH,3)
  ;b2 = mms2_b
  ;b3 = mms3_b
  ;b4 = mms4_b
  
	j = make_array(3,mms1_tfld.length)

	jtot = make_array(mms1_tfld.length)

  ddb = make_array(3,3,mms1_tfld.length)

	L = make_array(3,3,mms1_tfld.length)

	magvar = make_array(3,3,mms1_tfld.length)
	
	bc = make_array(3,mms1_tfld.length)

  ; Find centre rc and separation r_i.  Naming is admittedly unfortunate.
  rc = .25*(r1 + r2 + r3 + r4)
  dr1 = rc - r1
  dr2 = rc - r2
  dr3 = rc - r3
  dr4 = rc - r4

  r12 = r2 - r1
  r13 = r3 - r1
  r14 = r4 - r1
  r23 = r3 - r2
  r24 = r4 - r2
  r34 = r4 - r3
		
  for i=0,mms1_tfld.length-1 do begin

    k1 = crossp(r23[i,*],r24[i,*])
    k1 = -k1/dotp(r12[i,*],k1)
    k2 = -crossp(r34[i,*],r13[i,*])
    k2 = -k2/dotp(r23[i,*],k2)
    k3 = crossp(r14[i,*],r24[i,*])
    k3 = -k3/dotp(r34[i,*],k3)
    k4 = crossp(r12[i,*],r13[i,*])
    k4 = k4/dotp(r14[i,*],k4)

		j[*,i] = .7958 * (crossp(k1,b1[i,*]) + crossp(k2,b2[i,*]) + crossp(k3,b3[i,*]) + crossp(k4,b4[i,*]))

		jtot[i] = sqrt(dotp(j[*,i],j[*,i]))

		;graddbx = k1*b1[i,0] + k2*b2[i,0] + k3*b3[i,0] + k4*b4[i,0]
		;graddby = k1*b1[i,1] + k2*b2[i,1] + k3*b3[i,1] + k4*b4[i,1]
		;graddbz = k1*b1[i,2] + k2*b2[i,2] + k3*b3[i,2] + k4*b4[i,2]

		;ddb[*,*,i] = k1#b1[i,*] + k2#b2[i,*] + k3#b3[i,*] + k4#b4[i,*]
		
		ddb[0,0,i] = k1[0]*b1[i,0] + k2[0]*b2[i,0] + k3[0]*b3[i,0] + k4[0]*b4[i,0]
		ddb[0,1,i] = k1[0]*b1[i,1] + k2[0]*b2[i,1] + k3[0]*b3[i,1] + k4[0]*b4[i,1]
		ddb[0,2,i] = k1[0]*b1[i,2] + k2[0]*b2[i,2] + k3[0]*b3[i,2] + k4[0]*b4[i,2]
		
		ddb[1,0,i] = k1[1]*b1[i,0] + k2[1]*b2[i,0] + k3[1]*b3[i,0] + k4[1]*b4[i,0]
		ddb[1,1,i] = k1[1]*b1[i,1] + k2[1]*b2[i,1] + k3[1]*b3[i,1] + k4[1]*b4[i,1]
		ddb[1,2,i] = k1[1]*b1[i,2] + k2[1]*b2[i,2] + k3[1]*b3[i,2] + k4[1]*b4[i,2]

		ddb[2,0,i] = k1[2]*b1[i,0] + k2[2]*b2[i,0] + k3[2]*b3[i,0] + k4[2]*b4[i,0]
		ddb[2,1,i] = k1[2]*b1[i,1] + k2[2]*b2[i,1] + k3[2]*b3[i,1] + k4[2]*b4[i,1]
		ddb[2,2,i] = k1[2]*b1[i,2] + k2[2]*b2[i,2] + k3[2]*b3[i,2] + k4[2]*b4[i,2]
   
		
		L[*,*,i] = ddb[*,*,i] # transpose(ddb[*,*,i])

		mu1 = 1. + dotp(k1,dr1[i,*])
		mu2 = 1. + dotp(k2,dr2[i,*])
		mu3 = 1. + dotp(k3,dr3[i,*])
		mu4 = 1. + dotp(k4,dr4[i,*])

		Bxc = mu1 * b1[i,0] +  mu2 * b2[i,0] + mu3 * b3[i,0] + mu4 * b4[i,0] 
		Byc = mu1 * b1[i,1] +  mu2 * b2[i,1] + mu3 * b3[i,1] + mu4 * b4[i,1] 
		Bzc = mu1 * b1[i,2] +  mu2 * b2[i,2] + mu3 * b3[i,2] + mu4 * b4[i,2] 

		magvar[*,*,i] = [ [Bxc * Bxc, Bxc * Byc, Bxc * Bzc],[Byc * Bxc, Byc * Byc, Byc * Bzc], [Bzc * Bxc, Bzc * Byc, Bzc * Bzc] ] 

    bc[*,i] = [Bxc,Byc,Bzc]
    
  endfor
  
	top_tenth = cgPercentiles(jtot,Percentiles=[threshold])
	top_indcs = where(jtot GT top_tenth[0],num10)
	h_m_indcs = where(jtot GT .5*max(jtot),halfmax)
  
  if ((halfmax GT 64) and (num10 LT 64)) then top_indcs=h_m_indcs
  
  ;If enough points have J > .5 Jmax then use those, else just take top 10th percentile

	L_filt = L[*,*,top_indcs]
	magvar_filt = magvar[*,*,top_indcs]
	bc_filt = bc[*,top_indcs]
	
	bc_avg = avg(bc_filt,1)
	L_mtx = avg(L_filt,2)
	varmtx = avg(magvar_filt,2) -[ [bc_avg[0] * bc_avg[0], bc_avg[0] * bc_avg[1], bc_avg[0] * bc_avg[2]],[bc_avg[1] * bc_avg[0], bc_avg[1] * bc_avg[1], bc_avg[1] * bc_avg[2]], [bc_avg[2] * bc_avg[0], bc_avg[2] * bc_avg[1], bc_avg[2] * bc_avg[2]] ] 

	mddb_eval = EIGENQL(L_mtx, EIGENVECTORS=mddb_evec,/double)
	mvab_eval = EIGENQL(varmtx,EIGENVECTORS=mvab_evec,/double)
	
  Lmva = reform(mvab_evec[*,0])
  Lmva = Lmva*sign(Lmva[2])
  ;Mmva = reform(mvab_evec[*,1])*determ(mvab_evec)
  Nmva = reform(mvab_evec[*,2])

	Nmdd = reform(mddb_evec[*,0])
	Nmdd = Nmdd*sign(Nmdd[0])
  ;Mmdd = reform(mddb_evec[1,*])
  ;Nmdd = reform(mddb_evec[2,*])

	la_mdd = mddb_eval[0]/mddb_eval[1]
	la_mva = mvab_eval[0]/mvab_eval[1]

	elp = Lmva
	enp = Nmdd

	em = crossp(enp,elp)
	
	em = em/sqrt(dotp(em,em))
	
	theta_vd = acos(dotp(enp,elp) / sqrt( dotp(elp,elp)*dotp(enp,enp)))
	dtheta = theta_vd - !DPI/2

	elpp = crossp(em,enp)
  
  elpp = elpp/sqrt(dotp(elpp,elpp))
  
	dthn = dtheta * la_mva / (la_mva + la_mdd)

	en = cos(dthn)#enp + sin(dthn)#elpp
	
	en = en/sqrt(dotp(en,en))

	el = crossp(em,en)
	
	el = el/sqrt(dotp(el,el))

  el = transpose(el)
  
  em = transpose(em)

	evecs = [el,em,en]

  evec_mtx = reform(evecs,[1,3,3])
  
  lmn_data = {x:[mms1_tfld[0],mms1_tfld[-1]],y:[evec_mtx,evec_mtx]}

  lmn_dl_att = {coord_sys:'gse',units:'none',source_sys:'gse'}
  lmn_dl = {data_att:lmn_dl_att,labflag:0,labels:make_array(3,/string,value='')}
	store_data, 'hybrid_lmn', data=lmn_data, dlimits=lmn_dl
  
  eval_data = {x:[mms1_tfld[0],mms1_tfld[-1]],y:[la_mva,la_mdd]}
  eval_dl_att = {coord_sys:'gse',units:'none',source_sys:'gse'}
  eval_dl = {data_att:eval_dl_att,labflag:0,labels:make_array(3,/string,value='')}
  
  store_data, 'hybrid_lmn_evals', data=eval_data, dlimits=eval_dl
  
end
