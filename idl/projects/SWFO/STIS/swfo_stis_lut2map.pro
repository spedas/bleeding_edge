;This routine will take an energy LUT and create a bin map


;
;function swfo_stis_adc_calibration,sensornum
;  ;message,'obsolete.  Contained within swfo_stis_lut2map.pro'
;  adc_scale =  [[[ 43.77, 38.49, 41.13 ] ,  $  ;1A          O T F
;    [ 41.97, 40.29, 42.28 ]] ,  $  ;1B
;    [[ 40.25, 44.08, 43.90 ] ,  $  ;2A
;    [ 43.22, 43.97, 41.96 ]]]   ;  2B
;  adc_scale = adc_scale[*,*,sensornum] / 59.5
;  return,adc_scale
;end
;
;




function swfo_stis_lut2map,mapname=mapname,lut=lut ,mapnum=mapnum ,  sensor=sensor

  nbins = max(lut)+1   ; don't use this now
  if nbins gt 256 then message,"Don't use this code"

  if keyword_set(mapname) or not keyword_set(lut) then lut = swfo_stis_create_lut(mapname,mapnum=mapnum)
  mapsize = (max(lut)+1) > 256
  if mapsize gt 256  then dprint,'Default MAP in use'

  psym = [7,4]
  colors = [0,2,4,6,3,1,5]
  colors = [0,2,4,6,3,1,0,6]
  nan = !values.f_nan
  bmap =  {sens:0, bin:0b, name:'', fto:0, det:0 , tid:0, ADC:[0,0],  num:0,  ok:0, $
    color:0 ,psym:0, type:0 , $
    ;                    x:0., y:0., dx:0. ,dy:0., $
    FACE:0,  overflow:0b,  $
    nw:0,  $
    adcm: 0, $
    adc_avg:nan         ,  adc_delta:nan  , $
    nrg_meas_avg:nan    , nrg_meas_delta:nan, $
    nrg_proton_avg:nan  , nrg_proton_delta:nan, $
    nrg_electron_avg:nan, nrg_electron_delta:nan }
  bmaps = replicate(bmap,nbins)
  remap = indgen(16)
  ;remap[[0,1,10,11]] = 0    ; allow
  remap[[0,1]] = 0                  ; Non events  'x'
  det =    [0,1,2,4,3,5,6,7,0]                                 ; det number
  adcm =   [0,1,1,1,2,2,2,4,0]    ; multiplier
  ;names = strsplit('X O T OT F FO FT FTO Mixed',/extract)
  ;names = strsplit('X 1 2 1-2 3 1-3 2-3 1-2-3 Total',/extract)
  names = strsplit('X 1 2 12 3 13 23 123 Mixed',/extract)

  ;names = reform( transpose( [['A-'+names],['B-'+names]]))
  names = reform( transpose( [['O-'+names],['F-'+names]]))
  realfto = remap[lindgen(2L^16) / 2L^12]
  for b=0,mapsize-1 do begin
    w = where((lut eq b) and (realfto ne 0),nw)
    if nw eq 0 then w = 0
    fto = minmax(remap[  w / 2L^12 ] )
    if fto[0] eq fto[1] then fto = fto[0] else fto = 8   ;  the value of 8 signifies a bin with mixed types
    bmap.name = names[fto]
    bmap.fto = fto / 2
    bmap.bin = b
    bmap.det = det[fto / 2]
    bmap.color = colors[bmap.det]
    bmap.tid = fto mod 2
    bmap.psym = psym[bmap.tid]
    adc = minmax( w mod 2L^12  )+ [0,1]
    bmap.adc = adc
    bmap.num = adc[1] - adc[0]
    bmap.nw = nw
    bmap.ok = (bmap.num eq nw) and bmap.fto ne 8
    bmap.adcm = adcm[bmap.det]
    bmap.adc *= adcm[bmap.det]    ; OT and FT are doubled,  FTO is quadrupled
    bmap.num = bmap.adc[1] - bmap.adc[0]
    bmap.overflow = max(adc) ge 4096
    bmap.face = (fix((bmap.fto and 1) ne 0) - fix((bmap.fto and 4) ne 0)) * (bmap.tid ? 1 : -1)
    bmaps[b] = bmap
  endfor

  ;bmaps.x = (bmaps.adc[1] + bmaps.adc[0])/2.
  ;bmaps.dx = bmaps.adc[1] - bmaps.adc[0]

  bmaps.adc_avg = (bmaps.adc[1] + bmaps.adc[0])/2.
  bmaps.adc_delta = bmaps.adc[1] - bmaps.adc[0]

  dprint,'Warnng this section of code should be calling: swfo_stis_adc_calibration'

  ;The following cal data should be modified to originate from mvn_sep_det_cal
  cbin59_5 =[[[ 1. , 43.77, 38.49, 41.13,  41.,41.,41.] ,  $  ;1A     ; O T F
    [ 1. , 41.97, 40.29, 42.28,  41.,41.,41. ]] ,  $  ;1B
    [[ 1. , 40.25, 44.08, 43.90,  41.,41.,41. ] ,  $  ;2A
    [ 1. , 43.22, 43.97, 41.96,  41.,41.,41. ]]]   ;  2B

  ;  Default calibration for STIS
  cbin59_5 =[[[ 1. , 43.77, 38.49, 41.13,  41.,41.,41., 41. ] ,  $  ;1  - Open side     ; O T F   ;  1 3 2
    [ 1. , 41.97, 40.29, 42.28,  41.,41.,41. , 41.]] ,  $  ;1  - Foil side
    [[ 1. , 40.25, 44.08, 43.90,  41.,41.,41., 41. ] ,  $  ;2A
    [ 1. , 43.22, 43.97, 41.96,  41.,41.,41., 41. ]]]   ;  2B


  if keyword_set(sensor) then begin
    bmaps.sens = sensor
    erange = fltarr(2,nbins)
    for i=0,nbins-1 do   erange[*,i] = 59.5 / cbin59_5[bmaps[i].det,bmaps[i].tid,sensor-1] * bmaps[i].adc
    bmaps.nrg_meas_avg    = average(erange,1)

    bmaps.nrg_meas_delta   = reform(erange[1,*]-erange[0,*])  ;/2
    w = where(bmaps.overflow)
    overflow_fudge = .3  ;   This value is arbitrary - but at least better than the default
    bmaps[w].nrg_meas_delta = bmaps[w].nrg_meas_avg * overflow_fudge
    bmaps[w].nrg_meas_avg += bmaps[w].nrg_meas_delta / 2
  endif else dprint,'Please supply sensor number'

  return,bmaps
end
