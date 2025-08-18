pro fa_esa_init

  fa_init
  common fa_information,info_struct
  if info_struct.setup.esa EQ 1 then return

  print,'Loading FAST ESA information...'
  file=fa_pathnames('byteto14_map',dir='information')
  byteto14_map=fltarr(10,26)
  openr,unit,file,/get_lun
  readf,unit,byteto14_map
  close,unit
  free_lun,unit
  byteto14_map=(reform(byteto14_map,260))[0:255]

  file=fa_pathnames('byteto16_map',dir='information') 
  byteto16_map=fltarr(10,26)
  openr,unit,file,/get_lun
  readf,unit,byteto16_map
  close,unit
  free_lun,unit
  byteto16_map=(reform(byteto16_map,260))[0:255]

  fourteen_to_byte_map=bytarr(16384)
  sixteen_to_byte_map=bytarr(65536)
  file=fa_pathnames('fourteen_to_byte_map',dir='information')
  openr,unit,file,/get_lun
  readf,unit,fourteen_to_byte_map
  close,unit
  free_lun,unit
  file=fa_pathnames('sixteen_to_byte_map',dir='information')
  openr,unit,file,/get_lun
  readf,unit,sixteen_to_byte_map
  close,unit
  free_lun,unit

  shiftvalues=fltarr(514,48)
  sebshift={ 	sebshift1:fltarr(514,48), $
                sebshift2:fltarr(514,48), $
                sebshift3:fltarr(514,48), $
                sebshift4:fltarr(514,48), $
                sebshift5:fltarr(514,48), $
                sebshift6:fltarr(514,48)  }
  openr,unit,fa_pathnames('sebshift1.dat',directory='calibration'),/get_lun
  readf,unit,shiftvalues
  sebshift.sebshift1=shiftvalues
  close,unit
  free_lun,unit
  openr,unit,fa_pathnames('sebshift3.dat',directory='calibration'),/get_lun
  readf,unit,shiftvalues
  sebshift.sebshift3=shiftvalues
  close,unit
  free_lun,unit
  openr,unit,fa_pathnames('sebshift5.dat',directory='calibration'),/get_lun
  readf,unit,shiftvalues
  sebshift.sebshift5=shiftvalues
  close,unit
  free_lun,unit

  energy_struct={ElectronEnergy_48_32:fltarr(48,32), $
                 ElectronEnergy_48_64:fltarr(48,64), $
                 ElectronEnergy_96_32:fltarr(96,32), $
                 ElectronDEnergy_48_32:fltarr(48,32), $
                 ElectronDEnergy_48_64:fltarr(48,64), $
                 ElectronDEnergy_96_32:fltarr(96,32), $
                 ElectronEFF_48_32:fltarr(48,32), $
                 ElectronEFF_48_64:fltarr(48,64), $
                 ElectronEFF_96_32:fltarr(96,32), $
                 IonEnergy_48_32:fltarr(48,32), $
                 IonEnergy_48_64:fltarr(48,64), $
                 IonDEnergy_48_32:fltarr(48,32), $
                 IonDEnergy_48_64:fltarr(48,64), $
                 IonEFF_48_32:fltarr(48,32), $
                 IonEFF_48_64:fltarr(48,64), $
                 Theta00:fltarr(48,32), $
                 Theta11:fltarr(48,64), $
                 Theta10:fltarr(96,32)}
  openr,unit,fa_pathnames('fa_esa_info.dat',directory='information'),/get_lun
  readf,unit,energy_struct
  close,unit
  free_lun,unit

  yesa_ascii=read_ascii(fa_pathnames('esarecord',directory='calibration'),comment_symbol='#')
  sesa_ascii=read_ascii(fa_pathnames('sesrecord',directory='calibration'),comment_symbol='#')
  yesarecords=n_elements(yesa_ascii.field1)/6
  sesarecords=n_elements(sesa_ascii.field1)/14
  yesa_retrace=reform(yesa_ascii.field1,6,yesarecords)
  sesa_retrace=reform(sesa_ascii.field1,14,sesarecords)

  id=cdf_open(fa_pathnames('electroncalibration.cdf',directory='calibration'))
  cdf_varget,id,'ElectronCalib',electron_gf
  cdf_close,id
  id=cdf_open(fa_pathnames('ioncalibration.cdf',directory='calibration'))
  cdf_varget,id,'IonCalib',ion_gf
  cdf_close,id

  datatype={ees:'EESA SURVEY', $
            ies:'IESA SURVEY', $
            eeb:'EESA BURST', $
            ieb:'IESA BURST', $
            ses:'SESA SURVEY', $
            seb:'SESA BURST COMBINED', $
            seb1:'SESA 1 BURST', $
            seb2:'SESA 2 BURST', $
            seb3:'SESA 3 BURST', $
            seb4:'SESA 4 BURST', $
            seb5:'SESA 5 BURST', $
            seb6:'SESA 6 BURST' }

  calibration_structure={sebshift:sebshift, $
                         yesa_retrace:yesa_retrace, $
                         sesa_retrace:sesa_retrace, $
                         electron_gf:electron_gf, $
                         ion_gf:ion_gf }

  str_element,info_struct,'byteto14_map',byteto14_map,/add
  str_element,info_struct,'byteto16_map',byteto16_map,/add
  str_element,info_struct,'fourteen_to_byte_map',fourteen_to_byte_map,/add
  str_element,info_struct,'sixteen_to_byte_map',sixteen_to_byte_map,/add
  str_element,info_struct,'test',{energy:energy_struct},/add
  str_element,info_struct,'calibrate',calibration_structure,/add
  str_element,info_struct,'esa',{datatype:datatype},/add

  info_struct.setup.esa=1
  info_struct.setup.test=1
  info_struct.setup.calibrate=1

  return
end
