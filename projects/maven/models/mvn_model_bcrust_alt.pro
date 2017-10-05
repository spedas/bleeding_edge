;+
;
;PROCEDURE:       MVN_MODEL_BCRUST_ALT
;
;PURPOSE:         Computes the Martian crustal magnetic field 
;                 2D (longitude - latitude) data at the same altitude level.
;                 The computed result is returned by the "result" keyword.
;
;INPUTS:          Altitude level from the surface. Default is 400 km.
;
;KEYWORDS:
;
;   RESOLUTION:   Lon-Lat grid resolution. Default is 1 deg.
;
;       RESULT:   Returns the computed result.
;                 If the computed data structure is supplied,
;                 the Martian crustal field geographic map will be plotted. 
;
;       ARKANI:   Uses Arkani-Hamed's 62-deg and order spherical harmonic model.
;
;    CAIN_2003:   Uses Cain's 2003 90-deg and order spherical harmonic model.
;
;    CAIN_2011:   Uses Cain's 2011 90-deg and order spherical harmonic model.
;
;     PURUCKER:   Uses Purucker's spherical harmonic model.
;
; MORSCHHAUSER:   Uses Morschhauser's 2014 110-deg and order spherical harmonic model.
;                 (It is the default model to be calculated).
;
;CREATED BY:      Takuya Hara on 2015-11-04.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2015-11-04 12:00:06 -0800 (Wed, 04 Nov 2015) $
; $LastChangedRevision: 19236 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/models/mvn_model_bcrust_alt.pro $
;
;-
PRO mvn_model_bcrust_alt, alt, result=result, verbose=verbose, resolution=resolution, $
                          arkani=arkani, purucker=purucker, $
                          cain_2003=cain_2003, cain_2011=cain_2011, $
                          morschhauser=morschhauser, plot=plot, window=window

  IF SIZE(result, /type) EQ 8 THEN BEGIN
     IF tag_exist(result, 'lat') AND tag_exist(result, 'lon') AND $
        tag_exist(result, 'br') AND tag_exist(result, 'bt') AND tag_exist(result, 'bp') THEN BEGIN
        lat = result.lat
        lon = result.lon
        br = result.br
        bt = result.bt
        bp = result.bp
        GOTO, plot_map
     ENDIF ELSE BEGIN
        dprint, 'Invalid data structure is supplied.', dlevel=2, verbose=verbose
        RETURN
     ENDELSE 
  ENDIF 

  IF SIZE(alt, /type) EQ 0 THEN alt = 400. ELSE alt = FLOAT(alt)
  IF SIZE(resolution, /type) EQ 0 THEN res = 1 ELSE res = resolution
  rm = 3389.5d

  lat = FLOAT(dgen(res=res, range=[-1., 1.] * (90. - 0.5*FLOAT(res))))
  lon = FLOAT(dgen(res=res, range=[0., 360.] + (0.5*FLOAT(res)) * [1., -1.]))
  nlat = N_ELEMENTS(lat)
  nlon = N_ELEMENTS(lon)
  
  the = REFORM(REBIN(lat, nlat, nlon, /sample), LONG64(nlat)*LONG64(nlon))
  phi = REFORM(TRANSPOSE(REBIN(lon, nlon, nlat, /sample)), LONG64(nlat)*LONG64(nlon))

  xpc = (alt + rm) * SIN(!DTOR*(90.- the)) * COS(!DTOR*phi)
  ypc = (alt + rm) * SIN(!DTOR*(90.- the)) * SIN(!DTOR*phi)
  zpc = (alt + rm) * COS(!DTOR*(90.- the))

  ;FOR i=0, 359 DO FOR j=0, 179 DO BEGIN
  ;   append_array, xpc, (alt + rm) * SIN(!DTOR*(90.-lat[j])) * COS(!DTOR*lon[i])
  ;   append_array, ypc, (alt + rm) * SIN(!DTOR*(90.-lat[j])) * SIN(!DTOR*lon[i])
  ;   append_array, zpc, (alt + rm) * COS(!DTOR*(90.-lat[j]))
  ;ENDFOR 

  pos = [ [xpc], [ypc], [zpc] ]
  mvn_model_bcrust, pos=pos, data=data, $ 
                    arkani=arkani, purucker=purucker, $
                    cain_2003=cain_2003, cain_2011=cain_2011, $
                    morschhauser=morschhauser

  br = TRANSPOSE(REFORM(REFORM(data.lg[0, *]), [180, 360]))
  bt = TRANSPOSE(REFORM(REFORM(data.lg[1, *]), [180, 360]))
  bp = TRANSPOSE(REFORM(REFORM(data.lg[2, *]), [180, 360]))

  IF keyword_set(arkani) THEN modeler = 'Arkani'
  IF keyword_set(cain_2003) THEN modeler = 'Cain_2003'
  IF keyword_set(cain_2011) THEN modeler = 'Cain_2011'
  IF keyword_set(purucker) THEN modeler = 'Purucker'
  IF keyword_set(morschhauser) THEN modeler = 'Morschhauser'
  IF SIZE(modeler, /type) EQ 0 THEN modeler = 'Morschhauser'

  result = {name: modeler, alt: FLOAT(alt), lon: lon, lat: lat, br: br, bt: bt, bp: bp}

  IF keyword_set(plot) THEN BEGIN
     plot_map:
     tplot_options, get_opt=topt
     ochsz = !p.charsize
     dsize = GET_SCREEN_SIZE()
     IF SIZE(window, /type) EQ 0 THEN BEGIN
        IF tag_exist(topt, 'window') THEN wnum = topt.window + 1 ELSE wnum = 0
     ENDIF ELSE wnum = window
     
     wstat = EXECUTE("wset, wnum")
     IF wstat EQ 0 THEN wi, wnum, wsize=[dsize[0]*0.4, dsize[1]*0.98]
     undefine, wstat

     wset, wnum
     IF !d.name EQ 'X' THEN !p.charsize = 1.3
     title = result.name + ' at ' + STRING(result.alt, '(F0.1)') + ' km'
     plotxyz, lon, lat, br, zrange=[-20., 20.], xtitle='Lon [deg]', ytitle='Lat [deg]', ztitle='Br [nT]', ymargin=[.2, .075], $
              xticks=4, xminor=3, yticks=4, yminor=3, xrange=[0., 360.], yrange=[-90., 90.], multi='1,3', title=title
     plotxyz, lon, lat, bt, zrange=[-20., 20.], xtitle='Lon [deg]', ytitle='Lat [deg]', ztitle='Bt [nT]', ymargin=[.2, .075], $
              xticks=4, xminor=3, yticks=4, yminor=3, xrange=[0., 360.], yrange=[-90., 90.], /add
     plotxyz, lon, lat, bp, zrange=[-20., 20.], xtitle='Lon [deg]', ytitle='Lat [deg]', ztitle='Bp [nT]', ymargin=[.2, .075], $
              xticks=4, xminor=3, yticks=4, yminor=3, xrange=[0., 360.], yrange=[-90., 90.], /add

     !p.charsize = ochsz
  ENDIF 
  RETURN
END
