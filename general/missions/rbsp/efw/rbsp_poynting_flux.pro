;+
;  PROCEDURE :  rbsp_poynting_flux
;
;  PURPOSE  : calculates Poynting flux (ergs/s/cm^2). Separates into field-aligned and perp components
;			  Returns results as tplot variables. Includes
;			  values with and w/o spinaxis component
;
;
;  REQUIRES:  tplot library
;
;  KEYWORDS:              Bw -> tplot name of the [n,3] magnetic field
;                               waveform (nT) in MGSE
;			  Ew -> tplot name of the [n,3] electric field
;			        waveform (mV/m) in MGSE
;			  Tshort, Tlong -> short and long period of waveform to use.
;			  Bo -> (optional keyword) array of DC
;			  magnetic field directions in MGSE.
;					Use, for example, if Bw is
;					from AC-coupled data.
;                               If not included then Bw is downsampled
;                               and used as background field
;             method2 -> The waveform data are first downsampled to 1/Tshort to avoid the wasted
;			 computation of having to run program with data at unnecessarily high
;			 sample rate. The waveform is then run through
;			 bandpass_filter to the frequency range flow=1/Tlong...fhigh=1/Tshort
;             method1 (default) -> uses smoothing instead of a
;                        bandpass_filter which results in a sharper freq rolloff than
;                        smoothing method. Both methods give very similar results for test chorus waves
;
;   NOTES:     DO NOT INPUT DATA WITH SIGNIFICANT GAPS
;
;********************************************************************
;             Tested on Van Allen Probes chorus from EFW's B1
;             data on 2014-08-27 at ~07:42 on probe A. A is at +20
;             mlat and the Pflux indicates propagation away from eq
;             with magnitude values consistent with those in Li et
;             al., 2013 and Santolik et al., 2010
;********************************************************************
;			 Poynting flux coord system
;   		 	P1mgse = Bmgse x xhat_mgse  (xhat_mgse is spin axis component)
;				P2mgse = Bmgse x P1mgse
;  		   		P3mgse = Bmgse
;
;
;
;			 The output tplot variables are:
;
;			 	These three output variables contain a mix of spin axis and spin plane components:
;		 		        pflux_perp1  -> Poynting flux in perp1 direction
;			 		pflux_perp2  -> Poynting flux in perp2 direction
; 			 		pflux_para   -> Poynting flux along Bo
;
;			 	These partial Poynting flux calculations contain only spin plane Ew.
;			 		pflux_nospinaxis_perp
;			 		pflux_nospinaxis_para
;
;                               All of the above variables projected
;                               to the ionosphere
;
;
;   CREATED:  11/28/2012
;   CREATED BY:  Aaron W. Breneman
;    LAST MODIFIED:  MM/DD/YYYY   v1.0.0
;    MODIFIED BY:
;
;-


pro rbsp_poynting_flux,Bw,Ew,Tshort,Tlong,Bo=Bo,method2=method2


  get_data,Bw,data=Bw_test
  get_data,Ew,data=Ew_test

  if ~is_struct(Bw_test) or ~is_struct(Ew_test) then begin
    print,'**************************************************'
    print,'ONE OR BOTH OF THE TPLOT VARIABLES CONTAIN NO DATA'
    print,'....RETURNING....'
    print,'**************************************************'
    return
  endif

  if is_struct(Bw_test) then begin

  ;Get DC magnetic field and use to define P1,P2,P3 directions
  if ~keyword_set(Bo) then begin
    rbsp_downsample,Bw,suffix='_DC',1/40.
    Bdc = Bw + '_DC'
  endif else begin
    tinterpol_mxn,Bo,Bw,newname='Mag_mgse_DC'
    Bdc = 'Mag_mgse_DC'
  endelse


  ;Interpolate to get MagDC and Ew data to be on the same times as the Bw data
  get_data,Bw,data=goo
  times = goo.x
  tinterpol_mxn,Ew,times
  Ew = Ew + '_interp'
  tinterpol_mxn,Bdc,times
  Bdc = Bdc + '_interp'


  ;Define new coordinate system
  nelem = n_elements(times)

  ;P1 unit vector
  p1mgse = double([[replicate(0,nelem)],$
  [replicate(0,nelem)],$
  [replicate(0,nelem)]])
  get_data,Bdc,data=Bmgse_dc
  for i=0L,nelem-1 do p1mgse[i,*] = crossp(Bmgse_dc.y[i,*],[1.,0.,0.])
  ;normalize p1gse
  p1mag = fltarr(nelem)
  for i=0L,nelem-1 do p1mag[i] = sqrt(p1mgse[i,0]^2 + p1mgse[i,1]^2 + p1mgse[i,2]^2)
  for i=0L,nelem-1 do p1mgse[i,*] = p1mgse[i,*]/p1mag[i]


  ;P2 unit vector
  p2mgse = p1mgse
  for i=0L,nelem-1 do p2mgse[i,*] = crossp(Bmgse_dc.y[i,*],p1mgse[i,*])
  ;normalize p2mgse
  p2mag = fltarr(nelem)
  for i=0L,nelem-1 do p2mag[i] = sqrt(p2mgse[i,0]^2 + p2mgse[i,1]^2 + p2mgse[i,2]^2)
  for i=0L,nelem-1 do p2mgse[i,*] = p2mgse[i,*]/p2mag[i]



;*********************************************
;Test to make sure unit vectors are orthogonal
;*********************************************

;for i=0,3000 do print,acos(total(p1mgse[i,*]*p2mgse[i,*])/(p1mag[i]*p2mag[i]))/!dtor   ;perp!
;for i=0,3000 do print,acos(total(p1mgse[i,*]*Bmgse.y[i,*])/(p1mag[i]*Bmag[i]))/!dtor   ;perp!
;for i=0,3000 do print,acos(total(p2mgse[i,*]*Bmgse.y[i,*])/(p2mag[i]*Bmag[i]))/!dtor   ;perp!

;**************************************************
;**************************************************


  ;----------------------------------------------------------------------------
  ;Now we've defined our Poynting flux unit vectors as P1mgse,P2mgse,
  ;P3mgse=Bmgse_uvec. Project the Ew, Bw and Bo data into these three directions
  ;----------------------------------------------------------------------------

  ;Background magnetic field in Pflux coord
  Bmag_dc = sqrt(Bmgse_dc.y[*,0]^2 + Bmgse_dc.y[*,1]^2 + Bmgse_dc.y[*,2]^2)
  Bmgse_dc_uvec = Bmgse_dc.y
  Bmgse_dc_uvec[*,0] = Bmgse_dc.y[*,0]/Bmag_dc
  Bmgse_dc_uvec[*,1] = Bmgse_dc.y[*,1]/Bmag_dc
  Bmgse_dc_uvec[*,2] = Bmgse_dc.y[*,2]/Bmag_dc


  get_data,Ew,data=Emgse
  get_data,Bw,data=Bmgse

  Emgse = Emgse.y
  Bmgse = Bmgse.y


  Ep1 = fltarr(nelem) & Ep2 = Ep1 & Ep3 = Ep1
  for i=0L,nelem-1 do Ep1[i] = total(reform(Emgse[i,*])*reform(P1mgse[i,*]))
  for i=0L,nelem-1 do Ep2[i] = total(reform(Emgse[i,*])*reform(P2mgse[i,*]))
  for i=0L,nelem-1 do Ep3[i] = total(reform(Emgse[i,*])*reform(Bmgse_dc_uvec[i,*]))
  Ep = [[Ep1],[Ep2],[Ep3]]


  Bp1 = fltarr(nelem) & Bp2 = Bp1 & Bp3 = Bp1
  for i=0L,nelem-1 do Bp1[i] = total(reform(Bmgse[i,*])*reform(P1mgse[i,*]))
  for i=0L,nelem-1 do Bp2[i] = total(reform(Bmgse[i,*])*reform(P2mgse[i,*]))
  for i=0L,nelem-1 do Bp3[i] = total(reform(Bmgse[i,*])*reform(Bmgse_dc_uvec[i,*]))
  Bp = [[Bp1],[Bp2],[Bp3]]



;--------------------------------------------------
;Method 1 - use IDL's smooth function (default method)
;--------------------------------------------------

  if ~keyword_set(method2) then begin

    goo = rbsp_sample_rate(times,out_med_avg=medavg)
    rate = medavg[0]

    ;Find lower and upper periods for smoothing
    detren = floor(Tlong * rate)
    smoo = floor(Tshort * rate)

    dE1=Ep1-smooth(Ep1,detren,/nan)
    dE2=Ep2-smooth(Ep2,detren,/nan)
    dE3=Ep3-smooth(Ep3,detren,/nan)
    dB1=Bp1-smooth(Bp1,detren,/nan)
    dB2=Bp2-smooth(Bp2,detren,/nan)
    dB3=Bp3-smooth(Bp3,detren,/nan)

    fE1=smooth(dE1,smoo,/nan)
    fE2=smooth(dE2,smoo,/nan)
    fE3=smooth(dE3,smoo,/nan)
    fB1=smooth(dB1,smoo,/nan)
    fB2=smooth(dB2,smoo,/nan)
    fB3=smooth(dB3,smoo,/nan)

    B1bg=smooth((Bmgse_dc_uvec[*,0]),smoo,/nan)
    B2bg=smooth((Bmgse_dc_uvec[*,1]),smoo,/nan)
    B3bg=smooth((Bmgse_dc_uvec[*,2]),smoo,/nan)

    fE1 = fE1/1000. & fE2 = fE2/1000. & fE3 = fE3/1000.
    fB1 = fB1/1d9 & fB2 = fB2/1d9 & fB3 = fB3/1d9


  endif else begin

  ;--------------------------------------------------
  ;Method 2 - use bandpass filter
  ;--------------------------------------------------

    ;----------------------------------------------------
    ;Downsample both the Bw and Ew based on Tshort.
    ;No need to have the cadence at a higher rate than 1/Tshort
    ;----------------------------------------------------

    sr = 2/Tshort
    nyquist = sr/2.

    rbsp_downsample,[Bw,Ew],suffix='_DS_tmp',sr

    Bw = Bw +  '_DS_tmp'
    Ew = Ew +  '_DS_tmp'


    ;--------------------------------------------------
    ;At this point Ep, Bp and Bdc have a sample rate of
    ;2/Tshort and are sampled at the same times.
    ;We want to bandpass so that the lowest possible
    ;frequency is 1/Tlong Samples/sec
    ;--------------------------------------------------


    ;Define frequencies as a fraction of Nyquist
    flow = (1/Tlong)/nyquist
    fhigh = (1/Tshort)/nyquist


    ;Zero-pad these arrays to speed up FFT
    fac = 1
    nelem = n_elements(Ep[*,0])
    while 2L^fac lt n_elements(Ep[*,0]) do fac++

    addarr = fltarr(2L^fac - nelem) ;array of zeros
    Ep2 = [Ep,[[addarr],[addarr],[addarr]]]
    Bp2 = [Bp,[[addarr],[addarr],[addarr]]]

    Epf = BANDPASS_FILTER(Ep2,flow,fhigh) ;,/gaussian)
    Bpf = BANDPASS_FILTER(Bp2,flow,fhigh) ;,/gaussian)


    ;Remove the padded zeros
    fE = Epf[0:nelem-1,*]/1000.   ;V/m
    fB = Bpf[0:nelem-1,*]/1d9     ;Tesla

    fE1 = fE[*,0] & fE2 = fE[*,1] & fE3 = fE[*,2]
    fB1 = fB[*,0] & fB2 = fB[*,1] & fB3 = fB[*,2]

  endelse



;--------------------------------------------------
;Calculate Poynting flux
;--------------------------------------------------

  muo = 4d0*!DPI*1d-7        ; -Permeability of free space (N/A^2)

  ;J/m^2/s
  S1=(fE2*fB3-fE3*fB2)/muo
  S2=(fE3*fB1-fE1*fB3)/muo
  S3=(fE1*fB2-fE2*fB1)/muo
  Sp1 = (fE1*fB3)/muo        ;nospinaxis perp
  Sp2 = (fE1*fB2)/muo        ;nospinaxis parallel

  ;erg/s/cm2
  S1 = S1*(1d7/1d4) & S2 = S2*(1d7/1d4) & S3 = S3*(1d7/1d4)
  Sp1 = Sp1*(1d7/1d4) & Sp2 = Sp2*(1d7/1d4)

;--------------------------------------------------
;Find angle b/t Poynting flux and Bo
;--------------------------------------------------

  Bbkgnd = [[B1bg],[B2bg],[B3bg]]

  ;Bmgse_dc_uvec[*,0]
  S_mag = sqrt(S1^2 + S2^2 + S3^2)

  ;Bo defined to be along the third component
  angle_SB = acos((S3*Bbkgnd[*,2])/S_mag)/!dtor
  store_data,'angle_pflux_Bo',data={x:times,y:angle_SB}


  ;Smooth the wave normal angle calculation
  stime = 100.*(1/rate)
  if stime lt (times[n_elements(times)-1]-times[0]) then rbsp_detrend,'angle_pflux_Bo',stime

  tplot,[Bw,Ew,'pflux_para','pflux_perp1','pflux_perp2','pflux_Ew','pflux_Bw',$
  'angle_pflux_Bo','angle_pflux_Bo_smoothed','Mag_mgse_DC_interp']




;Define the P unit vectors in terms of MGSE(xhat,yhat,zhat)
;P1M = -By*zhat + Bz*yhat =  [0,B3bg,-B2bg]
;P2M = Bx*By*yhat + Bx*Bz*zhat - By^2*xhat - Bz^2*xhat = [-B2bg^2 - B3bg^2,B1bg*B2bg,B1bg*B3bg]
;P3M = Bx*xhat + By*yhat + Bz*zhat = [B1bg,B2bg,B3bg]


;;Normally our Poynting flux vector is defined as
;Svec = [S1,S2,S3] = S1*P1 + S2*P2 + S3*P3
;;Poynting flux defined in terms of P[MGSE]
;Svec = S1*P1M + S2*P2M + S3*P3M

  Svecx = -1*S2*B2bg^2 - 1*S2*B3bg^2 + S3
  Svecy = S1*B3bg + S2*B1bg*B2bg + S3*B2bg
  Svecz = -1*S1*B2bg + S2*B1bg*B3bg + S3*B3bg


  ;This should be the Poynting flux vector in terms of MGSE
  ;coord....need to test!!!
  Svec_MGSE = [[Svecx],[Svecy],[Svecz]]




;------------------------------------
;Estimate mapped Poynting flux
;From flux tube conservation B1*A1 = B2*A2  (A=cross sectional area of flux tube)
;B2/B1 = A1/A2
;P = EB/A ~ 1/A
;P2/P1 = A1/A2 = B2/B1
;Assume an ionospheric magnetic field of 45000 nT at 100km. This value shouldn't change too much
;and is good enough for a rough mapping estimate.
;------------------------------------


  S1_ion = 45000d * S1/Bmag_dc
  S2_ion = 45000d * S2/Bmag_dc
  S3_ion = 45000d * S3/Bmag_dc
  Sp1_ion = 45000d * Sp1/Bmag_dc
  Sp2_ion = 45000d * Sp2/Bmag_dc


;--------------------------------------------------
;Store all as tplot variables
;--------------------------------------------------

  store_data,'pflux_para',data={x:times,y:S3}
  store_data,'pflux_perp1',data={x:times,y:S1}
  store_data,'pflux_perp2',data={x:times,y:S2}
  store_data,'pflux_nospinaxis_para',data={x:times,y:Sp2}
  store_data,'pflux_nospinaxis_perp',data={x:times,y:Sp1}
  store_data,'pflux_Ew',data={x:times,y:1000.*[[fE1],[fE2],[fE3]]} ;change back to mV/m
  store_data,'pflux_Bw',data={x:times,y:1d9*[[fB1],[fB2],[fB3]]}   ;change back to nT
  store_data,'pflux_para_iono',data={x:times,y:S3_ion}
  store_data,'pflux_perp1_iono',data={x:times,y:S1_ion}
  store_data,'pflux_perp2_iono',data={x:times,y:S2_ion}
  store_data,'pflux_nospinaxis_para_iono',data={x:times,y:Sp2_ion}
  store_data,'pflux_nospinaxis_perp_iono',data={x:times,y:Sp1_ion}
  store_data,'angle_pflux_Bo',data={x:times,y:angle_SB}
  ;store_data,'pflux_para_mgse',data={x:times,y:pflux_para_mgse}
  ;store_data,'pflux_perp1_mgse',data={x:times,y:pflux_perp1_mgse}
  ;store_data,'pflux_perp2_mgse',data={x:times,y:pflux_perp2_mgse}
  store_data,'pflux_mgse',data={x:times,y:Svec_mgse}



  options,'pflux_Ew','ytitle','Ew!Cpflux coord!C[mV/m]'
  options,'pflux_Bw','ytitle','Bw!Cpflux coord!C[nT]'
  options,'pflux_Ew','ytitle','Ew!Cpflux!C[mV/m]'
  options,'pflux_Bw','ytitle','Bw!Cpflux!C[nT]'
  options,'pflux_nospinaxis_perp','ytitle','pflux!Ccomponent!Cperp to Bo!C[erg/cm^2/s]'
  options,'pflux_nospinaxis_para','ytitle','pflux!Ccomponent!Cpara to Bo!C[erg/cm^2/s]'
  options,'pflux_perp1','ytitle','pflux!Cperp1 to Bo!C[erg/cm^2/s]'
  options,'pflux_perp2','ytitle','pflux!Cperp2 to Bo!C[erg/cm^2/s]'
  options,'pflux_para','ytitle','pflux!Cparallel to Bo!C[erg/cm^2/s]'
  options,'pflux_nospinaxis_perp_iono','ytitle','pflux!Cmapped!Cto ionosphere!Cperp to Bo!C[erg/cm^2/s]'
  options,'pflux_nospinaxis_para_iono','ytitle','pflux!Cmapped!Cto ionosphere!Cpara to Bo!C[erg/cm^2/s]'
  options,'pflux_perp1_iono','ytitle','pflux!Cmapped!Cperp1 to Bo!C[erg/cm^2/s]'
  options,'pflux_perp2_iono','ytitle','pflux!Cmapped!Cperp2 to Bo!C[erg/cm^2/s]'
  options,'pflux_para_iono','ytitle','pflux!Cmapped!Cparallel to Bo!C[erg/cm^2/s]'
  options,'angle_pflux_Bo','ytitle','Angle (deg) b/t!CBo and Pflux'
  options,'pflux_mgse','ytitle','Pflux in MGSE coord'
  options,'pflux_nospinaxis_perp','labels','No spin axis!C comp'
  options,'pflux_nospinaxis_para','labels','No spin axis!C comp!C+ along Bo'
  options,'pflux_nospinaxis_perp_iono','labels','No spin axis!C comp'
  options,'pflux_nospinaxis_para_iono','labels','No spin axis!C comp!C+ along Bo'
  options,'pflux_Ew','labels','Red=parallel!C  to Bo'
  options,'pflux_Bw','labels','Red=parallel!C  to Bo'
  options,'pflux_nospinaxis_para','colors',2
  options,'pflux_nospinaxis_perp','colors',1
  options,'pflux_nospinaxis_para_iono','colors',2
  options,'pflux_nospinaxis_perp_iono','colors',1

  ylim,['pflux_perp1','pflux_perp2','pflux_para'],-0.2,0.2
  ylim,['pflux_nospinaxis_perp','pflux_nospinaxis_para'],-0.2,0.2
  ylim,['pflux_nospinaxis_perp_iono','pflux_nospinaxis_para_iono'],-10,10
  ylim,['pflux_perp1_iono','pflux_perp2_iono','pflux_para_iono'],0,0



;;Define the Poynting flux perp and parallel values in terms of MGSE coord
;get_data,'pflux_para',data=ppara
;get_data,'pflux_perp1',data=pperp1
;get_data,'pflux_perp2',data=pperp2
;pflux_para_mgse = [[ppara.y * Bmgse_dc.y[*,0]],[ppara.y * Bmgse_dc.y[*,1]],[ppara.y * Bmgse_dc.y[*,2]]]
;pflux_perp1_mgse = [[pperp1.y * p1mgse[*,0]],[pperp1.y * p1mgse[*,1]],[pperp1.y * p1mgse[*,2]]]
;pflux_perp2_mgse = [[pperp2.y * p2mgse[*,0]],[pperp2.y * p2mgse[*,1]],[pperp2.y * p2mgse[*,2]]]

;pf1mag = sqrt(pflux_para_mgse[*,0]^2 + pflux_para_mgse[*,1]^2 + pflux_para_mgse[*,2]^2)
;pf2mag = sqrt(pflux_perp1_mgse[*,0]^2 + pflux_perp1_mgse[*,1]^2 + pflux_perp1_mgse[*,2]^2)
;pf3mag = sqrt(pflux_perp2_mgse[*,0]^2 + pflux_perp2_mgse[*,1]^2 + pflux_perp2_mgse[*,2]^2)

;for i=0,300 do print,acos(total(pflux_para_mgse[i,*]*pflux_perp1_mgse[i,*])/(pf1mag[i]*pf2mag[i]))/!dtor   ;perp!
;for i=0,300 do print,acos(total(pflux_para_mgse[i,*]*pflux_perp2_mgse[i,*])/(pf1mag[i]*pf3mag[i]))/!dtor   ;perp!
;for i=0,300 do print,acos(total(pflux_perp1_mgse[i,*]*pflux_perp2_mgse[i,*])/(pf2mag[i]*pf3mag[i]))/!dtor   ;perp!


;options,'pflux_para_mgse','ytitle','pflux para!Cin MGSE'
;options,'pflux_perp1_mgse','ytitle','pflux perp1!Cin MGSE'
;options,'pflux_perp2_mgse','ytitle','pflux perp2!Cin MGSE'


;ylim,['pflux_para','pflux_nospinaxis_para','pflux_perp1','pflux_nospinaxis_perp1','pflux_perp2','pflux_nospinaxis_perp2'],-2d-5,1.5d-4
;ylim,['pflux_perp1','pflux_nospinaxis_perp1','pflux_perp2','pflux_nospinaxis_perp2'],-1d-4,1d-4
;tplot,['pflux_para','pflux_nospinaxis_para','pflux_Ew','pflux_Bw']
;tplot,['pflux_perp1','pflux_nospinaxis_perp1','pflux_perp2','pflux_nospinaxis_perp2']
;tplot,['pflux_para','pflux_perp1','pflux_perp2']
;tplot,['pflux_para','pflux_perp1','pflux_perp2']+'_iono'


  endif
end
