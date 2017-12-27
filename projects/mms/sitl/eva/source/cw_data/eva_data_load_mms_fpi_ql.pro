PRO eva_data_load_mms_fpi_ql, sc=sc

  mms_sitl_fpi_moments, sc = sc, /clean
  
  tngap = tnames('*_fpi_*')
  tdegap,  tngap, /overwrite
  
  options,sc+'_fpi_density',ytitle=sc+'!CFPI!Cdns',ysubtitle='[cm!U-3!N]',labels=['Ne','Ni'],$
    labflag=-1,ylog=0,constant=0
  options,sc+'_fpi_temp',ytitle=sc+'!CFPI!Ctemp',ysubtitle='[eV]',ylog=1,constant=0
  options,sc+'_fpi_ion_vel_dbcs',ytitle=sc+'!CFPIi!Cvel',constant=0
  options,sc+'_fpi_elec_vel_dbcs',ytitle=sc+'!CFPIe!Cvel',constant=0
  options,sc+'_fpi_ions',ytitle=sc+'!CFPIi';,ysubtitle='[Hz]',ztitle='[(V/m)!U2!N/Hz]'
  options,sc+'_fpi_electrons',ytitle=sc+'!CFPIe'
  options,sc+'_fpi_epad_lowen_fast',ytitle=sc+'!CFPIe!Clow'
  options,sc+'_fpi_epad_miden_fast',ytitle=sc+'!CFPIe!Cmid'
  options,sc+'_fpi_epad_highen_fast',ytitle=sc+'!CFPIe!Chigh'

  thres = -10.; Density lower limit
  tn = tnames(sc+'*'); sc+'_fpi_density'
  tp = sc+'_fpi_density'
  idx = where(strmatch(tn,tp),ct)
  if ct eq 1 then begin
    get_data,tp,data=D,dl=dl,lim=lim
    jdx = where(D.y lt thres,ct)
    if ct gt 0 then D.y[jdx] = thres
    store_data,tp,data={x:D.x, y:D.y, v:D.v},dl=dl,lim=lim
  endif
END
