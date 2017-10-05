;+
;PROCEDURE:   mvn_swe_addsep
;PURPOSE:
;  Loads SEP data, sums over the look directions, and stores electron and ion
;  energy spectra in tplot variables.
;
;USAGE:
;  mvn_swe_addsep
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;
;    PANS:          Named variable to hold a space delimited string containing
;                   the tplot variable(s) created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-23 11:11:45 -0800 (Mon, 23 Nov 2015) $
; $LastChangedRevision: 19452 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addsep.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addsep, pans=pans

  mvn_sep_load

  get_data,'mvn_SEP1F_elec_eflux',data=sepe,dl=dlim,index=i
  if (i gt 0) then begin
    j = where(finite(sepe.v[*,0]),count)
    if (count gt 0L) then v = reform(sepe.v[j[0],*]) else v = findgen(15)
    sepe = 0
    sepe_pan = 'mvn_SEP_elec_eflux'
    add_data,'mvn_SEP1F_elec_eflux','mvn_SEP1R_elec_eflux',newname='mvn_SEP1_elec_eflux'
    add_data,'mvn_SEP2F_elec_eflux','mvn_SEP2R_elec_eflux',newname='mvn_SEP2_elec_eflux'
    add_data,'mvn_SEP1_elec_eflux','mvn_SEP2_elec_eflux',newname=sepe_pan
    get_data,sepe_pan,data=sepe,index=i
    if (i gt 0) then begin
      sepe = {x:sepe.x, y:sepe.y/4., v:v}
      store_data,sepe_pan,data=sepe,dl=dlim
      if (count gt 0L) then begin
        ylim,sepe_pan,20,200,1
        options,sepe_pan,'ytitle','SEP elec!ckeV'
      endif else begin
        ylim,sepe_pan,0,14,0
        options,sepe_pan,'ytitle','SEP elec!cchannel'
      endelse
      options,sepe_pan,'panel_size',0.5
    endif else begin
      print,"Missing SEP electron data."
      sepe_pan = ''
    endelse
    store_data,['mvn_SEP1F_elec_eflux','mvn_SEP1R_elec_eflux','mvn_SEP1_elec_eflux', $
                'mvn_SEP2F_elec_eflux','mvn_SEP2R_elec_eflux','mvn_SEP2_elec_eflux'],/delete
    sepe = 0
  endif

  get_data,'mvn_SEP1F_ion_eflux',data=sepi,dl=dlim,index=i
  if (i gt 0) then begin
    j = where(finite(sepi.v[*,0]),count)
    if (count gt 0L) then v = reform(sepi.v[j[0],*]) else v = findgen(28)
    sepi = 0
    sepi_pan = 'mvn_SEP_ion_eflux'
    add_data,'mvn_SEP1F_ion_eflux','mvn_SEP1R_ion_eflux',newname='mvn_SEP1_ion_eflux'
    add_data,'mvn_SEP2F_ion_eflux','mvn_SEP2R_ion_eflux',newname='mvn_SEP2_ion_eflux'
    add_data,'mvn_SEP1_ion_eflux','mvn_SEP2_ion_eflux',newname=sepi_pan
    get_data,sepi_pan,data=sepi,index=i
    if (i gt 0) then begin
      sepi = {x:sepi.x, y:sepi.y/4., v:v}
      store_data,sepi_pan,data=sepi,dl=dlim
      if (count gt 0L) then begin
        ylim,sepi_pan,20,6000,1
        options,sepi_pan,'ytitle','SEP ion!ckeV'
      endif else begin
        ylim,sepi_pan,0,27,0
        options,sepi_pan,'ytitle','SEP ion!cchannel'
      endelse
      options,sepi_pan,'panel_size',0.5
    endif else begin
      print,"Missing SEP ion data."
      sepi_pan = ''
    endelse
    store_data,['mvn_SEP1F_ion_eflux','mvn_SEP1R_ion_eflux','mvn_SEP1_ion_eflux', $
                'mvn_SEP2F_ion_eflux','mvn_SEP2R_ion_eflux','mvn_SEP2_ion_eflux'],/delete
    sepi = 0
  endif

  pans = strtrim(strcompress(sepi_pan + ' ' + sepe_pan),2)

  return
  
end
