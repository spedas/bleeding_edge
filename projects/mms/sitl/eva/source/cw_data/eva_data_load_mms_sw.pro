PRO eva_data_load_mms_sw, sc=sc
  compile_opt idl2

  ; B
  ;------------
  tn = tnames(sc+'_dfg_srvy_dmpa',ct)
  if ct ne 1 then begin
    mms_sitl_get_dfg, sc_id=sc
    options,sc+'_dfg_srvy_gsm_dmpa',$
      labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='GSM [nT]',$
      colors=[2,4,6],labflag=-1,constant=0, cap=1
    options,sc+'_dfg_srvy_dmpa',$
      labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='DMPA [nT]',$
      colors=[2,4,6],labflag=-1,constant=0, cap=1
  endif


  ; V
  ;------------
  tn1 = tnames(sc+'_fpi_ion_vel_dbcs',ct1)
  tn2 = tnames(sc+'_fpi_density',ct2)
  if ct1*ct2 ne 1 then begin
    eva_data_load_mms_fpi, sc=sc
  endif

  ; Get Data
  ;---------------------------
  tpN = sc+'_fpi_density'
  tpB = sc+'_dfg_srvy_gsm_dmpa'
  tpVi= sc+'_fpi_ion_vel_dbcs'
  tpVe= sc+'_fpi_elec_vel_dbcs'
  tppos = sc+'_ql_pos_gse'

  get_data,tpN, data=dataN,lim=limN,dl=dlN
  get_data,tpVi,data=dataVi,lim=limVi,dl=dlVi
  get_data,tpVe,data=dataVe,lim=limVe,dl=dlVe

  ; Check to see if ion and electron moments at same times
  ; If not, there may be data gaps to fill
  IF n_elements(dataVi.X) NE n_elements(dataVe.X) THEN BEGIN
     tdegap, tpVi, /overwrite
     tdegap, tpVe, /overwrite
     get_data, tpVi, data=dataVi_tmp
     szi = n_elements(dataVi_tmp.x)
     get_data, tpVe, data=dataVe_tmp
     sze = n_elements(dataVe_tmp.x)
     IF szi NE sze THEN BEGIN
        IF max(szi, sze) EQ szi THEN tinterpol_mxn, tpVe, tpVi, /overwrite $
        ELSE tinterpol_mxn, tpVe, tpVi, /overwrite      
     ENDIF
     tinterpol_mxn, tpVe, tpN, /overwrite
     tinterpol_mxn, tpVi, tpN, /overwrite 
     get_data,tpVi,data=dataVi,lim=limVi,dl=dlVi
     get_data,tpVe,data=dataVe,lim=limVe,dl=dlVe
  ENDIF
  
  dataNi = {X:dataN.X, Y:dataN.Y[*,1]}
  dataNe = {X:dataN.X, Y:dataN.Y[*,0]}
  store_data,sc+'_sw_Ni',data=dataNi
  store_data,sc+'_sw_Ne',data=dataNe

  tinterpol_mxn,tpB,tpN,newname=tpB+'_interp' ; ....... interpolate
  get_data,tpB+'_interp',data=dataB,lim=limB, dl=dlB ;........ geta data
  Babs = sqrt(dataB.y[*,0]^2+dataB.y[*,1]^2+dataB.y[*,2]^2)
  

  ; Flow speed
  ;-----------------
  Vswi = sqrt(dataVi.y[*,0]^2+dataVi.y[*,1]^2+dataVi.y[*,2]^2); km/s
  Vswe = sqrt(dataVe.y[*,0]^2+dataVe.y[*,1]^2+dataVe.y[*,2]^2); km/s
  store_data,sc+'_sw_Vswi',data={x:dataN.X, y:Vswi}
  store_data,sc+'_sw_Vswe',data={x:dataN.X, y:Vswe}
  options,sc+'_sw_Vswi',ytitle=sc+'!CVswi',ysubtitle='[km/s]'
  options,sc+'_sw_Vswe',ytitle=sc+'!CVswe',ysubtitle='[km/s]'
  store_data,sc+'_sw_Vsw',data=sc+'_sw_Vsw'+['i','e']
  options,sc+'_sw_Vsw', ytitle=sc+'!CVsw',ysubtitle='[km/s]',colors=[6,2],labels=['|Vi|','|Ve|'],labflag=-1

  
  ; Mach number & Dynamic pressure
  ;------------
  nmax     = n_elements(dataNi.Y)  
  Ma       = fltarr(nmax)
  Ma_upper = fltarr(nmax)
  Ma_lower = fltarr(nmax)
  Va       = fltarr(nmax)
  Va_upper = fltarr(nmax)
  Va_lower = fltarr(nmax)
  Pd       = fltarr(nmax)
  Pd_upper = fltarr(nmax)
  Pd_lower = fltarr(nmax)
  for n=0,nmax-1 do begin
     Vsw_upper = max([Vswi[n],Vswe[n]],/nan)     
     Va_lower[n] = 22.0*Babs[n]/sqrt(max([dataNi.y[n],dataNe.y[n]]))
     Ma_upper[n] = Vsw_upper/Va_lower[n]
     Pd_upper[n] = 1.6726e-6*max([dataNi.y[n],dataNe.y[n]])*Vsw_upper^2
     
     Vsw_lower = min([Vswi[n],Vswe[n]],/nan)
     Va_upper[n] = 22.0*Babs[n]/sqrt(min([dataNi.y[n],dataNe.y[n]]))
     Ma_lower[n] = Vsw_lower/Va_upper[n]
     Pd_lower[n] = 1.6726e-6*min([dataNi.y[n],dataNe.y[n]])*Vsw_lower^2
     
     Va[n] = 22.0*Babs[n]/sqrt(dataNe.y[n])
     Ma[n] = Vswi[n]/Va[n]
     Pd[n] = 1.6726e-6*dataNi.y[n]*Vswi[n]^2
  endfor
  store_data,sc+'_sw_Ma_upper',data={x:dataNi.X, y:Ma_upper}
  store_data,sc+'_sw_Ma_lower',data={x:dataNi.X, y:Ma_lower}
  store_data,sc+'_sw_Ma_deflt',data={x:dataNi.X, y:Ma}
  store_data,sc+'_sw_Ma',data=sc+'_sw_Ma_'+['upper','lower','deflt']
  options,sc+'_sw_Ma',constant=[1,10,20],ytitle=sc+'!CM!DA!N',colors=[1,3,0],labels=['upper','lower','default'],labflag=-1

  store_data,sc+'_sw_Pdyn_upper',data={x:dataNi.X, y:Pd_upper}
  store_data,sc+'_sw_Pdyn_lower',data={x:dataNi.X, y:Pd_lower}
  store_data,sc+'_sw_Pdyn_deflt',data={x:dataNi.X, y:Pd}
  store_data,sc+'_sw_Pdyn',data=sc+'_sw_Pdyn_'+['upper','lower','deflt']
  options,sc+'_sw_Pdyn',constant=[1,10,20],ytitle=sc+'!CP!Ddyn!N',colors=[1,3,0],$
    labels=['upper','lower','default'],labflag=-1,ysubtitle='[nPa]'


  ; Shock Angle
  ;--------------------
  Re = 6378.137
  dr = !dpi/180.
  rd = 1/dr
  tinterpol_mxn,tpPos,tpN,newname=tppos+'_interp'; ....... interpolate
  get_data,tpPos+'_interp',data=D
  if nmax ne n_elements(D.x) then stop; Something is wrong
  Vupi= fltarr(3)
  Vupe= fltarr(3)
  Bup = fltarr(3)
  Man       = fltarr(nmax)
  Man_upper = fltarr(nmax)
  Man_lower = fltarr(nmax)
  tBn       = fltarr(nmax)
  for n=0,nmax-1 do begin
    xgse = D.y[n,0]/Re
    ygse = D.y[n,1]/Re
    zgse = D.y[n,2]/Re
    tgse = D.x[n]

    Vupi= [dataVi.y[n,0],dataVi.y[n,1],dataVi.y[n,2]]
    Vupe= [dataVe.y[n,0],dataVe.y[n,1],dataVe.y[n,2]]
    Bup = [dataB.y[n,0],dataB.y[n,1],dataB.y[n,2]]
    Babs = sqrt(Bup[0]^2+Bup[1]^2+Bup[2]^2)

    a0 = atan((Vupi[1]+29.78)/(-Vupi[0]))
    a0 *= rd
    result = model_boundary_normal(xgse, ygse, zgse, a0=a0)
    nrm = [result.nx[0],result.ny[0], result.nz[0]]

    thetaBnp = acos((Bup[0]*nrm[0]+Bup[1]*nrm[1]+Bup[2]*nrm[2])/Babs)
    thetaBnm = acos(-(Bup[0]*nrm[0]+Bup[1]*nrm[1]+Bup[2]*nrm[2])/Babs)
    thetaBn = thetaBnp*rd
    if thetaBn gt 90. then thetaBn = thetaBnm*rd
    tBn[n] = thetaBn
    
    Vupni = abs(Vupi[0]*nrm[0]+Vupi[1]*nrm[1]+Vupi[2]*nrm[2])
    Vupne = abs(Vupe[0]*nrm[0]+Vupe[1]*nrm[1]+Vupe[2]*nrm[2])

    Vsw_upper = max([Vupni, Vupne],/nan)
    Man_upper[n] = Vsw_upper/Va_lower[n]

    Vsw_lower = min([Vupni, Vupne],/nan)
    Man_lower[n] = Vsw_lower/Va_upper[n]

    Man[n] = Vupni/Va[n]
  endfor
  
  store_data,sc+'_sw_Man_deflt',data={x:dataNi.X, y:Man}
  store_data,sc+'_sw_Man_lower',data={x:dataNi.X, y:Man_lower}
  store_data,sc+'_sw_Man_upper',data={x:dataNi.X, y:Man_upper}
  store_data,sc+'_sw_Man',data=sc+'_sw_Man_'+['upper','lower','deflt']
  options,sc+'_sw_Man',constant=[1,10,20],ytitle=sc+'!CM!DAn!N',colors=[1,3,0],$
    labels=['upper','lower','default'],labflag=-1,yrange=[0,20],ystyle=1

  store_data,sc+'_sw_tBn',data={x:dataNi.X, y:tBn}
  ylim,sc+'_sw_tBn',0,90,0
  options,sc+'_sw_tBn', ytitle=sc+'!Ctheta',ysubtitle='Bn'
  options,sc+'_sw_tBn',constant=[15, 45, 75],ytickinterval=15

END
