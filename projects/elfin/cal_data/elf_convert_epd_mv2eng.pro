;+
;NAME:
; elf_convert_epd_mV2eng
;
;PURPOSE:
; This procedure converts epd engineering units to mV2end
;
;INPUTS:
;  trange:   time range of epd engineering data to be converted
;            Ex:  ['2022-04-15','2022-04-16']
;
;CALLING SEQUENCE:
; elf_convert_epd_mV2eng, trange=trange
;
; $LastChangedBy: 
; $LastChangedDate: 
; $LastChangedRevision: 
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/common/elf_convert_epd_mV2eng.pro $
;-
function elf_convert_epd_mV2eng, trange=trange
  
  ; initial variables and constants
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  offset=0.
  mVperkeV=.240
  nbits=12
  vref=3.893
  epd_ebins = [50., 70., 110., 160., 210., 270., 345., 430., 630., 900., 1300., 1800., 2500., 3000., 3850., 4500.] ;# in keV

  ; convert mV to Eng
  mVtoEng = 2^(nbits/vref)
  energy_bins = epd_ebins*mVperkeV*mVtoEng

  return, energy_bins
end