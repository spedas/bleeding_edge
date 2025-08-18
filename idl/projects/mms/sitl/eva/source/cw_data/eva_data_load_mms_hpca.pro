PRO eva_data_load_mms_hpca, prb=prb, level=level
  sc = 'mms'+prb
  ;mms_sitl_get_hpca_moments, sc_id=sc, level=level
  mms_sitl_get_hpca, probes=prb, level=level, datatype='moments'
  
  sh='(H!U+!N)'
  so='(O!U+!N)'
  
  options, sc+'_hpca_hplus_number_density',ytitle=sc+'!CHPCA!CN '+sh,ysubtitle='[cm!U-3!N]',/ylog,$
    colors=1,labels=['N '+sh]
  options, sc+'_hpca_oplus_number_density',ytitle=sc+'!CHPCA!CN '+so,ysubtitle='[cm!U-3!N]',/ylog,$
    colors=3,labels=['N '+so]
  options, sc+'_hpca_hplus_ion_bulk_velocity',ytitle=sc+'!CHPCA!CV '+sh,ysubtitle='[km/s]',ylog=0,$
    colors=[2,4,6],labels=['V!DX!N '+sh, 'V!DY!N '+sh, 'V!DZ!N '+sh],labflag=-1,constant=0
  options, sc+'_hpca_oplus_ion_bulk_velocity',ytitle=sc+'!CHPCA!CV '+so,ysubtitle='[km/s]',ylog=0,$
    colors=[2,4,6],labels=['V!DX!N '+so, 'V!DY!N '+so, 'V!DZ!N '+so],labflag=-1,constant=0
  options, sc+'_hpca_hplus_scalar_temperature',ytitle=sc+'!CHPCA!CT '+sh,ysubtitle='[eV]',/ylog,$
    colors=1,labels=['T '+sh]
  options, sc+'_hpca_oplus_scalar_temperature',ytitle=sc+'!CHPCA!CT '+so,ysubtitle='[eV]',/ylog,$
    colors=3,labels=['T '+so]

  options, sc+'_hpca_hplusoplus_number_densities',ytitle=sc+'!CHPCA!CDensity',ysubtitle='[cm!U-3!N]',/ylog,$
    colors=[1,3],labels=['N '+sh, 'N '+so],labflag=-1
  options, sc+'_hpca_hplusoplus_scalar_temperatures',ytitle=sc+'!CHPCA!CTemp',ysubtitle='[eV]',$
    colors=[1,3],labels=['T '+sh, 'T '+so],labflag=-1

END