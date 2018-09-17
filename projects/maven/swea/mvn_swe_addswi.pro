;+
;PROCEDURE:   mvn_swe_addswi
;PURPOSE:
;  Loads SWIA data and calculates moments based on coarse survey.  All calculations
;  are performed with the SWIA code, which stores the results as tplot variables.
;
;USAGE:
;  mvn_swe_addswi
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;
;    FINE:          Calculate moments with fine survey.  This provides better values
;                   in the upstream solar wind.
;
;    PANS:          Named variable to hold an array of
;                   the tplot variable(s) created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-09-12 17:09:38 -0700 (Wed, 12 Sep 2018) $
; $LastChangedRevision: 25783 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addswi.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addswi, fine=fine, pans=pans

  if keyword_set(fine) then begin
    type = 'fs'
    dname = 'mvn_swifs_density'
    vname = 'mvn_swifs_velocity'
  endif else begin
    type = 'cs'
    dname = 'mvn_swics_density'
    vname = 'mvn_swics_velocity'
  endelse

  mvn_swia_load_l2_data, /loadall, /tplot
  mvn_swia_part_moments, type=[type]

  pans = ['']

  swi_pan = dname
  get_data,swi_pan,index=i
  if (i gt 0) then begin
    options,swi_pan,'ynozero',1
    pans = [pans, swi_pan]
  endif

  get_data,vname,data=swi_v,index=i
  if (i gt 0) then begin
    vsw = sqrt(total(swi_v.y^2.,2))
    swi_pan = 'mvn_swi_vsw'
    store_data,swi_pan,data={x:swi_v.x, y:vsw}
    options,swi_pan,'ytitle','SWIA Vsw!c(km/s)'
    pans = [pans, swi_pan]
  endif

  if (n_elements(pans) gt 1) then pans = pans[1:*]

  return
  
end
