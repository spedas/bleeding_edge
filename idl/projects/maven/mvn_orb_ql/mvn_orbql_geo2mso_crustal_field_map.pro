;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orbql_geo2mso_crustal_field_map
;
; Routine to determine the MSO x, y, z projection for a given
; GEO map of crustal fields at a particular time.
;
; Requires loaded spice kernels and location of the crustl field file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-

pro mvn_orbql_geo2mso_crustal_field_map, crustal_field_file, trange, mso_crustal_fields

  Rm = 3390.
   ;;; Get the crustal fields in observer cartesian
  ; CD, current=c
  ; restore, c+'/br_360x180_pc.sav'
  restore, crustal_field_file
  ; mapcolor = mvn_orbql_colorscale( br,$
  ;      mindat=-70, maxdat=70, mincol=7, maxcol=255 )

  ; mapcolor_groundtrack = mvn_orbql_colorscale( br,$
  ;      mindat=-70, maxdat=70, mincol=7, maxcol=254 )

  mapcolor_groundtrack = mvn_orbql_colorscale( br,$
       mindat=-70, maxdat=70, mincol=7, maxcol=254 )

  tmp = where(br eq 0, tmpcnt)
  if tmpcnt ne 0 then mapcolor_groundtrack[tmp] = 255

  mapcolor = mapcolor_groundtrack

  nummaplon = n_elements(br[*,0])
  nummaplat = n_elements(br[0,*])
  maplonres = 360./nummaplon
  maplatres = 180./nummaplat
  maplons = findgen(nummaplon) * maplonres + maplonres/2.
  maplats = findgen(nummaplat) * maplatres - 90. + maplonres/2.
  mapx = fltarr(nummaplon,nummaplat)
  mapy = mapx
  mapz = mapx
  periapse_time = mean(trange)
  ut = time_double(periapse_time)
  et = time_ephemeris(ut,/ut2et)
  qrot =  spice_body_att('IAU_MARS','MAVEN_MSO',ut,/quaternion)
  for i = 0, nummaplon-1 do begin
     for j = 0, nummaplat-1 do begin
        xtmp = Rm * cos(maplons[i]*!dtor) * cos(maplats[j]*!dtor)
        ytmp = Rm * sin(maplons[i]*!dtor) * cos(maplats[j]*!dtor)
        ztmp = Rm * sin(maplats[j]*!dtor)
        ans = quaternion_rotation([ xtmp, ytmp, ztmp ],qrot,/last_ind)
        mapx[i,j] = ans[0] / Rm
        mapy[i,j] = ans[1] / Rm
        mapz[i,j] = ans[2] / Rm
     endfor                  
  endfor

   flat_xdat = reform(mapx,nummaplon*nummaplat)
   flat_ydat = reform(mapy,nummaplon*nummaplat)
   flat_zdat = reform(mapz,nummaplon*nummaplat)
   flat_color = reform(mapcolor,nummaplon*nummaplat)

   mso_crustal_fields = {mapx: mapx, mapy: mapz, mapz: mapz, mapcolor: mapcolor,$
                        mapx_flat: flat_xdat, mapy_flat: flat_ydat, mapz_flat: flat_zdat,$
                        mapcolor_flat: flat_color,$
                        mapcolor_groundtrack: mapcolor_groundtrack,$
                        lon: maplons, lat: maplats}


end