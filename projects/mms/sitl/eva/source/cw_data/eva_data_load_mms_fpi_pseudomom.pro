PRO eva_data_load_mms_fpi_pseudomom, sc=sc

  mms_sitl_get_fpi_trig, sc = sc

  tngap = tnames('*_fpi_*')
  tdegap,  tngap, /overwrite

    options,sc+'_fpi_iBulkV_DSC',constant=0,$
    ytitle=sc+'!CFPI!CVi',ysubtitle='[km/s]',$
    labels=['V!DX!N', 'V!DY!N', 'V!DZ!N'],labflag=-1,colors=[2,4,6]

  options,sc+'_fpi_bentPipeB_DBCS',constant=0,$
    labels=['B!DX!N', 'B!DY!N', 'B!DZ!N'],labflag=-1,colors=[2,4,6],$
    ytitle=sc+'!Cbent!CpipeB',ysubtitle='[nT]'
  
  options,sc+'_fpi_bentPipeB_Norm',constant=0,$
    labels=['|B|'],labflag=-1,colors=0,$
    ytitle=sc+'!Cbent!CpipeB',ysubtitle='[nT]'
  
  options,sc+'_fpi_pseudodens',constant=0,$
    colors=[0,1],$
    ytitle=sc+'!Ctrig!Cdns',ysubtitle='[cm!U-3!N]'
  
  options,sc+'_fpi_epseudoflux',constant=0,$
    ytitle=sc+'!Ctrig!Cflux(e)'
  
  options,sc+'_fpi_epseudotemp',constant=0,$
    labels='T!Be!N (trig)',$
    ytitle=sc+'!Ctrig!Ctemp',ysubtitle='[eV]'
 
  options,sc+'_fpi_ipseudovz',constant=0,$
    labels='Viz',colors=6,$
    ytitle=sc+'!Ctrig!CVz(i)',ysubtitle='[km/s]'

  options,sc+'_fpi_ipseudovxy',constant=0,$
    labels='Vxy',$$
    ytitle=sc+'!Ctrig!CVxy(i)',ysubtitle='[km/s]'

    
END