PRO eva_data_load_mms_fpi, sc=sc

  mms_sitl_get_fpi_basic, sc_id=sc

  tngap = tnames('*_fpi_*')
  tdegap,  tngap, /overwrite

  options, sc+'_fpi_eEnergySpectr_omni',spec=1,ylog=1,zlog=1,$
    ytitle=sc+'!CFPI!Cele',ysubtitle='[eV]',no_interp=1
  ylim, sc+'_fpi_eEnergySpectr_omni', 10,26000

  options,sc+'_fpi_iEnergySpectr_omni',spec=1,ylog=1,zlog=1,$
    ytitle=sc+'!CFPI!Cion',ysubtitle='[eV]',no_interp=1
  ylim, sc+'_fpi_iEnergySpectr_omni', 10,26000

  options,sc+'_fpi_ePitchAngDist_midEn',spec=1,zlog=1,$
    ytitle=sc+'!CFPI!Cele',ysubtitle='(PAD,mid-E)',no_interp=1
  ylim, sc+'_fpi_ePitchAngDist_midEn', 0,180

  options,sc+'_fpi_ePitchAngDist_highEn',spec=1,zlog=1,$
    ytitle=sc+'!CFPI!Cele',ysubtitle='(PAD,high-E)',no_interp=1
  ylim, sc+'_fpi_ePitchAngDist_highEn', 0, 180

  options,sc+'_fpi_DISnumberDensity',ylog=0,$
    ytitle=sc+'!CFPI!CNi',ysubtitle='[cm!U-3!N]'

  options,sc+'_fpi_iBulkV_DSC',$
    ytitle=sc+'!CFPI!CVi',ysubtitle='[km/s]',constant=0,$
    labels=['V!DX!N', 'V!DY!N', 'V!DZ!N'],labflag=-1,colors=[2,4,6]

  options,sc+'_fpi_bentPipeB_DSC',$
    labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CFPI!CbentPipeB',ysubtitle='DSC',$
    colors=[2,4,6],labflag=-1,constant=0
END
