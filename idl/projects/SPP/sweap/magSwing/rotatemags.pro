; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-05-10 11:57:37 -0700 (Thu, 10 May 2018) $
; $LastChangedRevision: 25194 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/magSwing/rotatemags.pro $
; For now this is a crib sheet.

pro rotateMags

  ;if ~keyword_set(scalefactor) then scalefactor = 1.
  mag1height = (7 * 12 *2.54)/100.
  height1 = 64.0 * 2.54 / 100
  height2 = 52. * 2.54 / 100
  magdistance = ((7. * 12 + 10.) *2.54)/100
  circleRange = indgen(10000)
  angleRange = circleRange * 1. / max(circleRange) * 2 * !dpi
  scalefactor = 1.2
  ;assume inboard mag is 1m from mounting structure
  xvalsHeight1mag1inboard = (magDistance - 1.)* scalefactor * sin(angleRange)
  yvalsHeight1mag1inboard = (magDistance - 1.)* scalefactor * cos(angleRange)
  zvalsHeight1mag1inboard = fltarr(10000) + mag1height - height1
  
  magValuesHeight1mag1inboard = []

  for i = 0, n_elements(circleRange)-1 do begin
    ;print, magValuesHeight1mag1inboard
    magValuesHeight1mag1inboard = [magValuesHeight1mag1inboard, pspmags([xvalsHeight1mag1inboard[i], yvalsHeight1mag1inboard[i], zvalsHeight1mag1inboard[i]])]
  endfor
  
  magValuesHeight1mag1inboard = magValuesHeight1mag1inboard / 1E-9
  
  wi, 1
  
  plot, magValuesHeight1mag1inboard[0:-1:3], yrange = [-300., 200.], title = 'Distance = ' + string((magDistance - 1.)* scalefactor)
  oplot, magValuesHeight1mag1inboard[2:-1:3], color = 6
  oplot, magValuesHeight1mag1inboard[1:-1:3], color = 4
  oplot, magValuesHeight1mag1inboard[0:-1:3], color = 2
  
  ;; Kludge for Round 2
;  mag1height = (7 * 12 *2.54)/1000.
;  height1 = 64.0 * 2.54 / 1000
;  height2 = 52. * 2.54 / 1000
;  magdistance = ((7. * 12 + 10.) *2.54)/1000
;  circleRange = indgen(10000)
;  angleRange = circleRange * 1. / max(circleRange) * 2 * !dpi
  scalefactor = 1.
  ;assume inboard mag is 1m from mounting structure
  xvalsHeight1mag1inboard = (magDistance - 1.)* scalefactor * sin(angleRange)
  yvalsHeight1mag1inboard = (magDistance - 1.)* scalefactor * cos(angleRange)
  zvalsHeight1mag1inboard = fltarr(10000) + mag1height - height1

  magValuesHeight1mag1inboard = []

  for i = 0, n_elements(circleRange)-1 do begin
    ;print, magValuesHeight1mag1inboard
    magValuesHeight1mag1inboard = [magValuesHeight1mag1inboard, pspmags([xvalsHeight1mag1inboard[i], yvalsHeight1mag1inboard[i], zvalsHeight1mag1inboard[i]])]
  endfor

  magValuesHeight1mag1inboard = magValuesHeight1mag1inboard / 1E-9
  
  wi, 2

  plot, magValuesHeight1mag1inboard[0:-1:3], yrange = [-800., 300.], title = 'Distance = ' + string(((magDistance - 1.)* scalefactor))
  oplot, magValuesHeight1mag1inboard[2:-1:3], color = 6
  oplot, magValuesHeight1mag1inboard[1:-1:3], color = 4
  oplot, magValuesHeight1mag1inboard[0:-1:3], color = 2
  
  print, 'pause'
  
end