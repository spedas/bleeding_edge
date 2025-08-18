function mvn_sep_lut2map,mapname=mapname,lut=lut ,mapnum=mapnum ,  sensor=sensor


if keyword_set(mapname) or not keyword_set(lut) then lut = mvn_sep_create_lut(mapname,mapnum=mapnum)

psym = [7,4]
adcm = [0,1,1,1,2,2,4,0]
colors = [0,2,4,6,3,1,5]
colors = [0,2,4,6,3,1,0]
nan = !values.f_nan
bmap =  {sens:0, bin:0b, name:'', fto:0, det:0 , tid:0, ADC:[0,0],  num:0,  ok:0, $
                    color:0 ,psym:0, type:0 , $
;                    x:0., y:0., dx:0. ,dy:0., $
                    FACE:0,  overflow:0b,  $
                    adc_avg:nan         ,  adc_delta:nan  , $
                    nrg_meas_avg:nan    , nrg_meas_delta:nan, $
                    nrg_proton_avg:nan  , nrg_proton_delta:nan, $
                    nrg_electron_avg:nan, nrg_electron_delta:nan }
bmaps = replicate(bmap,256)                                                                
remap = indgen(16)
remap[[0,1,10,11]] = 0
det = [0,1,2,4,3,0,5,6,0]
names = strsplit('X O T OT F FO FT FTO Mixed',/extract)
names = reform( transpose( [['A-'+names],['B-'+names]]))
realfto = remap[lindgen(2L^16) / 2L^12]
for b=0,255 do begin
   w = where((lut eq b) and (realfto ne 0),nw)
   if nw eq 0 then w = 0
   fto = minmax(remap[  w / 2L^12 ] )
   if fto[0] eq fto[1] then fto = fto[0] else fto = 8
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
   bmap.ok = (bmap.num eq nw) and bmap.fto ne 8
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

;The following cal data should be modified to originate from mvn_sep_det_cal
cbin59_5 =[[[ 1. , 43.77, 38.49, 41.13,  41.,41.,41. ] ,  $  ;1A     ; O T F
            [ 1. , 41.97, 40.29, 42.28,  41.,41.,41. ]] ,  $  ;1B
           [[ 1. , 40.25, 44.08, 43.90,  41.,41.,41. ] ,  $  ;2A
            [ 1. , 43.22, 43.97, 41.96,  41.,41.,41. ]]]   ;  2B

if keyword_set(sensor) then begin
  bmaps.sens = sensor
  erange = fltarr(2,256)
  for i=0,255 do   erange[*,i] = 59.5 / cbin59_5[bmaps[i].det,bmaps[i].tid,sensor-1] * bmaps[i].adc
  bmaps.nrg_meas_avg    = average(erange,1)
  
  bmaps.nrg_meas_delta   = reform(erange[1,*]-erange[0,*])  ;/2
  w = where(bmaps.overflow)
  overflow_fudge = .3  ;   This value is arbitrary - but at least better than the default
  bmaps[w].nrg_meas_delta = bmaps[w].nrg_meas_avg * overflow_fudge  
  bmaps[w].nrg_meas_avg += bmaps[w].nrg_meas_delta / 2
endif else dprint,'Please supply sensor number'

return,bmaps
end
