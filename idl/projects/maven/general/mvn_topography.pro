;+
;PROCEDURE:   mvn_topography
;PURPOSE:
;  Calculates topographic profiles along the orbit track based on laser 
;  altimeter measurements by MGS-MOLA.  Topography is relative to the
;  areoid (same as published maps).
;
;  The result is stored in a TPLOT variable.
;
;USAGE:
;  mvn_topography
;
;INPUTS:
;       None:     Gets all necessary inputs from tplot.
;
;KEYWORDS:
;       PANS:     Named variable to hold the tplot variable created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-05-31 11:09:39 -0700 (Wed, 31 May 2017) $
; $LastChangedRevision: 23376 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_topography.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_topography, pans=pans

  get_data, 'mvn_alt_sur', data=sdat, index=i
  if (i eq 0) then begin
    mvn_altitude, datum='surface'
    get_data, 'mvn_alt_sur', data=sdat, index=i
    if (i eq 0) then begin
      print,"Can't get topography."
      return
    endif
  endif

  get_data, 'mvn_alt_are', data=adat, index=i
  if (i eq 0) then begin
    mvn_altitude, datum='areoid'
    get_data, 'mvn_alt_are', data=adat, index=i
    if (i eq 0) then begin
      print,"Can't get areoid."
      return
    endif
  endif

  pans = 'mvn_topo_are'
  store_data, pans, data={x:sdat.x, y:(adat.y - sdat.y), datum:'areoid'}
  options,pans,'ytitle','Topo (km)!careoid'
  options,pans,'constant',0

  return

end
