;+
;
;PROCEDURE:       ESC_EMAG_ANGLE
;
;PURPOSE:         Creates tplot variables of the ESCAPADE/EMAG magnetic field 
;                 angles in the specified coordinate system. 
;
;INPUTS:          Tplot name can be specified.
;
;KEYWORDS:
;
;     LEVEL:      Specifies the MAG level used (currently unused).
;
;  FILL_NAN:      If set, inserts NANs when the Bphi direction wraps from 360 to 0 degrees, 
;                 making the wrap more visually apparent.
;
;      CONE:      If set, calculates the magnetic field cone angle.
;
;     CLOCK:      If set, calculates the magnetic field clock angle.
;
;NOTE:            This procedure was originally written for MAVEN/MAG data.
;                 It has since been copied and simplified for use with ESCAPADE/EMAG data.
;
;CREATED BY:      Takuya Hara on 2015-10-24.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-08-19 13:54:38 -0700 (Wed, 19 Aug 2026) $
; $LastChangedRevision: 34777 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/emag/esc_emag_angle.pro $
;
;-
PRO esc_emag_angle, name, verbose=verbose, level=lvl, fill_nan=fill_nan, cone=cone, clock=clock;, lgeo=lgeo
  IF KEYWORD_SET(fill_nan) THEN nflg = 1 ELSE nflg = 0
  ;IF KEYWORD_SET(lgeo) THEN lflg = 1 ELSE lflg = 0
  IF SIZE(name, /type) EQ 0 THEN name = 'mvn_mag_l*_bmso_1sec'
  tname = (tnames(name))[0]

  get_data, tname, data=b, index=idx
  IF idx EQ 0 THEN BEGIN
     dprint, 'Tplot not found.', dlevel=2, verbose=verbose
     RETURN
  ENDIF 
  ;IF (lflg) THEN mvn_mag_angle_lgeo, tname, data=b, verbose=verbose
  ndat = N_ELEMENTS(b.x)

  IF SIZE(lvl, /type) EQ 0 THEN lvl = ''
  level = ' ' + lvl
  bphi = ATAN(b.y[*, 1], b.y[*, 0])
  w = WHERE(bphi LT 0., nw)
  IF nw GT 0L THEN bphi[w] += 2.*!PI
  undefine, w, nw
  bthe = ASIN(b.y[*, 2] / SQRT(TOTAL(b.y*b.y, 2)))

  tphi = b.x
  IF (nflg) THEN BEGIN
     xsgn = sign(b.y[1:ndat-1, 0]*b.y[0:ndat-2, 0])
     ysgn = sign(b.y[1:ndat-1, 1]*b.y[0:ndat-2, 1])
     w = WHERE(b.y[*, 0] GT 0. AND ysgn LT 0. AND xsgn GT 0., nw)
     IF nw GT 0 THEN BEGIN
        dt = MEAN(b.x[1:ndat-1] - b.x[0:ndat-2])
        dt = dgen(5, dt*[0.d0, 1.d0])        
        tphi = [b.x, b.x[w]+dt[1], b.x[w]+dt[2], b.x[w]+dt[3]]
        iphi = DOUBLE(ROUND(INTERP([0., 1.], [0., 2.*!DPI], bphi[w])))
        bphi = [bphi, 2. * !DPI * iphi, REPLICATE(!values.d_nan, nw), 2. * !DPI * ABS(iphi - 1.d0)]
        bphi = bphi[SORT(tphi)]
        tphi = tphi[SORT(tphi)]

        dprint, verbose=verbose, dlevel=2, 'Number of data points might be different between Bphi and Bthe.'
     ENDIF 
     undefine, w, nw
     psym = 0
  ENDIF ELSE psym = 3

  tplot_options, get_opt=topt
  store_data, tname + '_phi', data={x: tphi, y: bphi*!RADEG}, $
              dlim={psym: psym, ytitle: 'EMAG' + STRUPCASE(level), ysubtitle: 'Bphi [deg]', $
                    yticks: 4, yminor: 3}
  ylim, tname + '_phi', 0., 360., /def
  store_data, tname + '_the', data={x: b.x, y: bthe*!RADEG}, $
              dlim={psym: psym, ytitle: 'EMAG' + STRUPCASE(level), ysubtitle: 'Bthe [deg]', $
                    yticks: 4, yminor: 3, constant: 0.}
  ylim, tname + '_the', -90., 90., /def

  ;aopt = {yaxis: 1, ystyle: 1, yrange: [-90., 90.], ytitle: 'Bthe [deg]', color: 2, yticks: 4, yminor: 3, ysubtitle: ''}
  ;options, tname + '_phi', tname=tname + '_phi'
  ;options, tname + '_phi', tname=tname + '_the'
  ;store_data, tname + '_angle', data=tname + ['_phi', '_the']
  ;options, tname + '_angle', tplot_routine='mplot_merge', colors=[0, 2]
  ;options, tname + '_angle', 'y2axis', aopt
  ;ylim, tname + '_angle', 0., 360., 0.

  IF KEYWORD_SET(cone) THEN BEGIN
     bcone = ACOS(b.y[*, 0] / SQRT(TOTAL(b.y*b.y, 2)))
     store_data, tname + '_cone', data={x: b.x, y: bcone*!RADEG}, $
                 dlim={psym: psym, ytitle: 'EMAG' + level.toupper(), ysubtitle: 'Bcone [deg]', yticks: 4, yminor: 3, constant: 90.}
     ylim, tname + '_cone', 0., 180., /def
  ENDIF 

  IF KEYWORD_SET(clock) THEN BEGIN
     bclk = ATAN(b.y[*, 1], b.y[*, 2])
     w = WHERE(bclk LT 0., nw)
     IF nw GT 0L THEN bclk[w] += 2.*!PI
     w = WHERE(bclk GT 1.75*!PI, nw)
     IF nw GT 0L THEN bclk[w] -= 2.*!PI
     
     undefine, w, nw
     store_data, tname + '_clk', data={x: b.x, y: bclk*!RADEG}, $
                 dlim={psym: psym, ytitle: 'EMAG' + level.toupper(), ysubtitle: 'Bclk [deg]', yticks: 4, yminor: 3, constant: 90.*FINDGEN(4), ytickinterval: 90.}
     ylim, tname + '_clk', 315., -45., /def
     options, tname + '_clk', ytickname=REVERSE(['N', 'E', 'S', 'W'])
  ENDIF 
  
  RETURN
END 
