pro mpause_t96,PD,XMGNP=XMGNP,YMGNP=YMGNP,ZMGNP=ZMGNP,$
  XGSM=XGSM,YGSM=YGSM,ZGSM=ZGSM,ID=ID,DISTAN=DISTAN
  ;
  ;  THE PRESSURE-DEPENDENT MAGNETOPAUSE IS THAT USED IN THE T96_01 MODEL
  ;  (TSYGANENKO, JGR, V.100, P.5599, 1995; ESA SP-389, P.181, O;T. 1996)
  ;   AUTHOR:  N.A. TSYGANENKO
  ;   DATE:    AUG.1, 1995, REVISED APRIL 3, 2003.
  ;   
  ;   JWU translate T96_MGNP in geopack_2005.f
  ;   
  ;   INPUT:  PD -  THE SOLAR WIND RAM PRESSURE IN NANOPAS
  ;           XGSM, YGSM, ZGSM  - position of points in re for flagging             
  ;
  ;   OUTPUT: XMGNP, YMGNP, ZMGNP - location of magnetopause in re
  ;           ID - flag, whether XGSM, YGSM, ZGSM are inside or outside mp
  ;           DISTAN - distance between XGSM, YGSM, ZGSM and Xmp0, Ymp0, Zmp0 in re
  ;                    Xmp0, Ymp0, Zmp0 is the boundary point, having the same value of TAU
  ;
  ;  RATIO OF PD TO THE AVERAGE PRESSURE, ASSUMED EQUAL TO 2 nPa:
  ;
  RAT=PD/2.0
  RAT16=RAT^0.14
  A0=70.
  S00=1.08
  X00=5.48
  ;
  ; VALUES OF THE MAGNETOPAUSE PARAMETERS, SCALED BY THE ACTUAL PRESSURE:
  ;
  A=A0/RAT16
  S0=S00
  X0=X00/RAT16
  XM=X0-A
  
  ;-----------------------------------------------------
  ;                  get mp boundary
  ;-----------------------------------------------------
  n=dindgen(45,start=1.,increment=1)
  TAU=1-10.d^(-5)*n^3
  XMGNP_half=X0-A*(1.-S0*TAU)
  ARG=(S0^2-1.)*(1.-TAU^2)
  RHOMGNP=A*SQRT(ARG)
  YMGNP_half=RHOMGNP
  XMGNP=[reverse(XMGNP_half),XMGNP_half]
  YMGNP=[-reverse(RHOMGNP),RHOMGNP]
  ZMGNP=[-reverse(RHOMGNP),RHOMGNP]
  
  ;-----------------------------------------------------
  ;                   flagging 
  ;-----------------------------------------------------
  id=make_array(n_elements(xgsm),value=!VALUES.F_NAN)
  phi=make_array(n_elements(xgsm),value=0.)
  Xmp0=make_array(n_elements(xgsm),value=!VALUES.F_NAN)
  Ymp0=make_array(n_elements(xgsm),value=!VALUES.F_NAN)
  Zmp0=make_array(n_elements(xgsm),value=!VALUES.F_NAN)
  distan=make_array(n_elements(xgsm),value=!VALUES.F_NAN)
  
  
  if keyword_set(XGSM) and keyword_set(YGSM) and keyword_set(ZGSM) then begin
    if n_elements(XGSM) ne n_elements(YGSM) or n_elements(YGSM) ne n_elements(ZGSM) then begin
      print,'mpause_t96: Input XGSM, YGSM, ZGSM not the same length!'
      stop
      return
    endif
    
    index0=where(ygsm ne 0. or zgsm ne 0., count0)
    if count0 gt 0 then phi[index0]=atan2(ygsm[index0],zgsm[index0])

    RHO=SQRT(YGSM^2+ZGSM^2)
    index=where(xgsm lt xm, count)
    if count gt 0 then begin
      rhomgnp=a*sqrt(s0^2-1)
      index1=where(rhomgnp ge rho[index], count1)
      if count1 gt 0 then id[index[index1]]=1
      index1=where(rhomgnp lt rho[index], count1)
      if count1 gt 0 then id[index[index1]]=-1
      
      Xmp0[index]=xgsm[index]
      Ymp0[index]=rhomgnp*sin(phi[index])
      Zmp0[index]=rhomgnp*cos(phi[index])
      distan[index]=sqrt((xgsm[index]-Xmp0[index])^2+(ygsm[index]-Ymp0[index])^2+(zgsm[index]-Zmp0[index])^2)
    endif
    index=where(xgsm ge xm, count)
    if count gt 0 then begin
      XKSI=(XGSM[index]-X0)/A+1.
      XDZT=RHO/A
      SQ1=SQRT((1.+XKSI)^2+XDZT^2)
      SQ2=SQRT((1.-XKSI)^2+XDZT^2)
      SIGMA=0.5*(SQ1+SQ2)
      TAU=0.5*(SQ1-SQ2)
      ARG=(S0^2-1.)*(1.-TAU^2)
      index2=where(arg lt 0., count2)
      if count2 gt 0 then arg[index2]=0
      RHOMGNP=A*SQRT(ARG)
      index3=where(sigma ge s0, count3)
      if count3 gt 0 then id[index[index3]]=-1
      index3=where(sigma lt s0, count3)
      if count3 gt 0 then id[index[index3]]=1  
      
      Xmp0[index]=X0-A*(1.-S0*TAU)
      Ymp0[index]=RHOMGNP*SIN(PHI[index])
      Zmp0[index]=RHOMGNP*COS(PHI[index])
      ;
      ;  NOW CALCULATE THE DISTANCE BETWEEN THE POINTS {XGSM,YGSM,ZGSM} AND {XMGNP,YMGNP,ZMGNP}:
      ;   (IN GENERAL, THIS IS NOT THE SHORTEST DISTANCE D_MIN, BUT DIST ASYMPTOTICALLY TENDS
      ;    TO D_MIN, AS WE ARE GETTING CLOSER TO THE MAGNETOPAUSE):
      ;
      DISTAN[index]=SQRT((XGSM[index]-Xmp0[index])^2+(YGSM[index]-Ymp0[index])^2+(ZGSM[index]-Zmp0[index])^2)
    endif
  endif 

end