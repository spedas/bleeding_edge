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
  
  tinterpol_mxn,tpB,tpN,newname=tpB+'_interp'; ....... interpolate

  get_data,tpB+'_interp',data=dataB,lim=limB, dl=dlB;........ geta data
  get_data,tpN, data=dataN,lim=limN,dl=dlN
  get_data,tpVi,data=dataVi,lim=limVi,dl=dlVi
  get_data,tpVe,data=dataVe,lim=limVe,dl=dlVe
  dataNi = {X:dataN.X, Y:dataN.Y[*,1]}
  dataNe = {X:dataN.X, Y:dataN.Y[*,0]} 
  Babs     = sqrt(dataB.y[*,0]^2+dataB.y[*,1]^2+dataB.y[*,2]^2); nT
  store_data,sc+'_sw_Ni',data=dataNi
  store_data,sc+'_sw_Ne',data=dataNe
  
  ; Flow speed
  ;-----------------
  Vswi = sqrt(dataVi.y[*,0]^2+dataVi.y[*,1]^2+dataVi.y[*,2]^2); km/s
  Vswe = sqrt(dataVe.y[*,0]^2+dataVe.y[*,1]^2+dataVe.y[*,2]^2); km/s
  store_data,sc+'_sw_Vswi',data={x:dataNi.X, y:Vswi}
  store_data,sc+'_sw_Vswe',data={x:dataNi.X, y:Vswe}
  options,sc+'_sw_Vswi',ytitle=sc+'!CVswi',ysubtitle='[km/s]'
  options,sc+'_sw_Vswe',ytitle=sc+'!CVswe',ysubtitle='[km/s]'
  store_data,sc+'_sw_Vsw',data=sc+'_sw_Vsw'+['i','e']
  options,sc+'_sw_Vsw', ytitle=sc+'!CVsw',ysubtitle='[km/s]',colors=[6,2],labels=['|Vi|','|Ve|'],labflag=-1

  ; Mach number
  ;------------
  nmax     = n_elements(dataNi.Y)
  Ma       = fltarr(nmax)
  Ma_upper = fltarr(nmax)
  Ma_lower = fltarr(nmax)
  Va       = fltarr(nmax)
  Va_upper = fltarr(nmax)
  Va_lower = fltarr(nmax)
  for n=0,nmax-1 do begin
    Vsw_upper = max([Vswi[n],Vswe[n]],/nan)
    Va_lower[n] = 22.0*Babs[n]/sqrt(max([dataNi.y[n],dataNe.y[n]]))
    Ma_upper[n] = Vsw_upper/Va_lower[n]

    Vsw_lower = min([Vswi[n],Vswe[n]],/nan)
    Va_upper[n] = 22.0*Babs[n]/sqrt(min([dataNi.y[n],dataNe.y[n]]))
    Ma_lower[n] = Vsw_lower/Va_upper[n]

    Va[n] = 22.0*Babs[n]/sqrt(dataNe.y[n])
    Ma[n] = Vswi[n]/Va[n]
  endfor
  store_data,sc+'_sw_Ma_upper',data={x:dataNi.X, y:Ma_upper}
  store_data,sc+'_sw_Ma_lower',data={x:dataNi.X, y:Ma_lower}
  store_data,sc+'_sw_Ma_deflt',data={x:dataNi.X, y:Ma}
  store_data,sc+'_sw_Ma',data=sc+'_sw_Ma_'+['upper','lower','deflt']
  options,sc+'_sw_Ma',constant=[1,10,20],ytitle=sc+'!CM!DA!N',colors=[1,3,0],labels=['upper','lower','default'],labflag=-1



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
  options,sc+'_sw_Man',constant=[1,10,20],ytitle=sc+'!CM!DAn!N',colors=[1,3,0],labels=['upper','lower','default'],labflag=-1

  store_data,sc+'_sw_tBn',data={x:dataNi.X, y:tBn}
  ylim,sc+'_sw_tBn',0,90,0
  options,sc+'_sw_tBn', ytitle=sc+'!Ctheta',ysubtitle='Bn'
  options,sc+'_sw_tBn','constant',[20,45,70]

END
