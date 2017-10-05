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
;    PANS:          Named variable to hold a space delimited string containing
;                   the tplot variable(s) created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-23 11:11:45 -0800 (Mon, 23 Nov 2015) $
; $LastChangedRevision: 19452 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addswi.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addswi, pans=pans

    mvn_swia_load_l2_data, /loadall, /tplot
    mvn_swia_part_moments, type=['cs']

    swi_pan = 'mvn_swics_density'
    get_data,swi_pan,index=i
    if (i eq 0) then swi_pan = '' else options,swi_pan,'ynozero',1

    get_data,'mvn_swics_velocity',data=swi_v,index=i
    if (i gt 0) then begin
      vsw = sqrt(total(swi_v.y^2.,2))
      swi_pan2 = 'mvn_swi_vsw'
      store_data,swi_pan2,data={x:swi_v.x, y:vsw}
      options,swi_pan2,'ytitle','SWIA Vsw!c(km/s)'
      swi_pan = swi_pan + ' ' + swi_pan2
    endif

    pans = strtrim(strcompress(swi_pan),2)

  return
  
end
