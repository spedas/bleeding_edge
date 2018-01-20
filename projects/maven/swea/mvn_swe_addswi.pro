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
;    PANS:          Named variable to hold an array of
;                   the tplot variable(s) created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-01-19 14:47:21 -0800 (Fri, 19 Jan 2018) $
; $LastChangedRevision: 24551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addswi.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addswi, pans=pans

  mvn_swia_load_l2_data, /loadall, /tplot
  mvn_swia_part_moments, type=['cs']

  pans = ['']

  swi_pan = 'mvn_swics_density'
  get_data,swi_pan,index=i
  if (i gt 0) then begin
    options,swi_pan,'ynozero',1
    pans = [pans, swi_pan]
  endif

  get_data,'mvn_swics_velocity',data=swi_v,index=i
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
