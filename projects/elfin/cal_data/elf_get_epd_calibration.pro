;+
; PROCEDURE:
;         elf_get_epd_calibration
;
; PURPOSE:
;         returns epd calibration parameters
;
; OUTPUT:
;         EPD calibration data structure
;         cal_params include: epd_gf
;                             epd_overaccumulation_factors
;                             epd_thresh_factors
;                             epd_ch_efficiencies
;                             epd_cal_ch_factors
;                             epd_ebins
;                             epd_ebins_logmean
;                             epd_ebin_lbls
;
; KEYWORDS:
;         trange:      start/stop time frame ['mmmm-yy-dd/hh:mm:ss','mmmm-yy-dd/hh:mm:ss']
;         probe:       elfin probe name, 'a' or 'b'
;         instrument:  epd instrument name, 'epde' or 'epdi'
;         no_download: set this flag to turn off download and use local files only
;
; EXAMPLES:
;         elf> cal_params = elf_get_epd_calibration(probe='a', instrument='epde', trange=tr)
;
; NOTES:
;     There are still a few hard coded variables. There is also no calibration data for epdi
;
; HISTORY:
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_cal_mrmi.pro $
;-
function elf_get_epd_calibration, probe=probe, instrument=instrument, trange=trange, no_download=no_download

  ;check that parameters are set and initialized
  if ~keyword_set(probe) then probe='a'
  if ~keyword_set(instrument) then instrument='epde'
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, -1
  endif
  if ~keyword_set(trange) then trange=timerange()
  if instrument EQ 'epde' then begin
      ; get calibration values from log file
      epd_cal_log=elf_read_epd_cal_data(probe=probe, instrument='epde', trange=trange, no_download=no_download)
      epde_gf=epd_cal_log.gf
      epde_overaccumulation_factors=epd_cal_log.overaccumulation_factors
      epde_thresh_factors=epd_cal_log.thresh_factors      
      epde_ch_efficiencies=epd_cal_log.ch_efficiencies
      epde_ebins=epd_cal_log.ebins
      epde_cal_ch_factors = 1./epde_gf*(epde_thresh_factors^(-1.))*(epde_ch_efficiencies^(-1.))
      epde_ebins_logmean = epde_ebins
      for j=0,14 do epde_ebins_logmean[j]=10.^((alog10(epde_ebins[j])+alog10(epde_ebins[j+1]))/2)
      epde_ebins_logmean[15]=6500.
      epde_ebin_lbls = ['50-80', '80-120', '120-160', '160-210', '210-270', '270-345', '345-430', '430-630', $
        '630-900', '900-1300', '1300-1800', '1800-2500', '2500-3350', '3350-4150', '4150-5800', '5800+']
      epd_calibration_data = { epd_gf:epde_gf, $
        epd_overaccumulation_factors:epde_overaccumulation_factors, $
        epd_thresh_factors:epde_thresh_factors, $
        epd_ch_efficiencies:epde_ch_efficiencies, $
        epd_cal_ch_factors:epde_cal_ch_factors, $
        epd_ebins:epde_ebins, $
        epd_ebins_logmean:epde_ebins_logmean, $
        epd_ebin_lbls:epde_ebin_lbls }
  endif

  ;************* NEED cal file for epdi *******************
  if instrument EQ 'epdi' then begin
      epdi_gf = 0.01 ; 21deg x 21deg (in SA) by 1 cm^2
      epdi_overaccumulation_factors = indgen(16)*0.+1.
;
; VA changed: 7/7/2022
;      epdi_overaccumulation_factors[15] = 1./2 ; was
;      epdi_thresh_factors = indgen(16)*0.+1.
;      epdi_thresh_factors[0] = 1./5 ; change me to match the threshold curves
;      epdi_thresh_factors[1] = 1.6
;      epdi_thresh_factors[2] = 1.2
; VA changed: 7/7/2022
      epdi_overaccumulation_factors[15] = 1.0
      epdi_thresh_factors = indgen(16)*0.+1.
;
; VA changed: 7/7/2022
;      epdi_ch_efficiencies = [0.74, 0.8, 0.85, 0.86, 0.87, 0.87, 0.87, 0.87, 0.82, 0.8, 0.75, 0.6, 0.5, 0.45, 0.25, 0.05]
      epdi_ch_efficiencies = indgen(16)*0.+1.
;
      epdi_cal_ch_factors = 1./epdi_gf*(epdi_thresh_factors^(-1.))*(epdi_ch_efficiencies^(-1.))
      epdi_ebins = [50., 80., 120., 160., 210., 270., 345., 430., 630., 900., 1300., 1800., 2500., 3350., 4150., 5800.] ; in keV based on Jiang Liu's Geant4 code 2019-3-5
; VA changed: 7/7/2022 (Added offset due to dead-layer and electronic noise)
      epdi_ebins[1:*] = epdi_ebins[1:*] + 10. ; keV based on Colin discussions on 7/7/2022
;
      epdi_ebins_logmean = epdi_ebins
      for j=0,14 do epdi_ebins_logmean[j]=10.^((alog10(epdi_ebins[j])+alog10(epdi_ebins[j+1]))/2)
      epdi_ebins_logmean[15]=6500.
      epdi_ebin_lbls = ['50-90', '90-130', '130-170', '170-220', '220-280', '280-355', '355-440', '440-640', $
        '640-910', '910-1310', '1310-1810', '1810-2510', '2510-3360', '3360-4160', '4160-5810', '5810+']
      epd_calibration_data = { epd_gf:epdi_gf, $
        epd_overaccumulation_factors:epdi_overaccumulation_factors, $
        epd_thresh_factors:epdi_thresh_factors, $
        epd_ch_efficiencies:epdi_ch_efficiencies, $
        epd_cal_ch_factors:epdi_cal_ch_factors, $
        epd_ebins:epdi_ebins, $
        epd_ebins_logmean:epdi_ebins_logmean, $
        epd_ebin_lbls:epdi_ebin_lbls }
    endif

  return, epd_calibration_data

end