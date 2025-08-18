;+
;PROCEDURE:   mvn_exo_bar
;PURPOSE:
;  Creates a colored bar indicating when the spacecraft is below
;  the exobase.  Assumes that you have run maven_orbit_tplot first.
;
;USAGE:
;  mvn_sun_bar
;
;INPUTS:
;
;KEYWORDS:
;        ALT : Altitude of the exobase.  Default = 180 km.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-11-13 11:12:51 -0800 (Wed, 13 Nov 2024) $
; $LastChangedRevision: 32951 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mvn_exo_bar.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_exo_bar, alt=exo, pans=bname

  bname = 'mvn_exo_bar'
  
  get_data,'alt',data=alt,index=i
  if (i eq 0) then begin
    print,'You must run maven_orbit_tplot first.'
    return
  endif

  exo = (size(exo,/type) gt 0) ? float(exo[0]) : 180.

  y = replicate(!values.f_nan,n_elements(alt.x),2)
  indx = where(alt.y le exo, count)
  if (count gt 0L) then y[indx,*] = 206.

  store_data,bname,data={x:alt.x, y:y, v:[0,1]}
  ylim,bname,0,1,0
  zlim,bname,0,(255-7),0
  options,bname,'spec',1
  options,bname,'panel_size',0.05
  options,bname,'ytitle',''
  options,bname,'yticks',1
  options,bname,'yminor',1
  options,bname,'no_interp',1
  options,bname,'xstyle',4
  options,bname,'ystyle',4
  options,bname,'no_color_scale',1
  options,bname,'color_table',43
  
  return

end
