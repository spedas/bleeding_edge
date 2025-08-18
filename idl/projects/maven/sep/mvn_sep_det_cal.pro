;BW = [13, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 17, 20, 25, 30, 36, 44, 52, 62, 76, 90, 110, 132, 158, 190, 228, 274, 330, 396, 476, 572, 694]



pro mvn_sep_det_cal,map,sepn,units=units

message,'Still in mods'
cbin59_5 =[[[ 1. , 43.77, 38.49, 41.13,  41.,41.,41. ] ,  $  ;1A     ; O T F
            [ 1. , 41.97, 40.29, 42.28,  41.,41.,41. ]] ,  $  ;1B
           [[ 1. , 40.25, 44.08, 43.90,  41.,41.,41. ] ,  $  ;2A
            [ 1. , 43.22, 43.97, 41.96,  41.,41.,41. ]]]   ;  2B

;map.x = average(map.adc,1)
;map.dx = map.num  ;/2.
;map.y = 1
;map.dy = 1
map.sens = sepn
units =1

if keyword_set(units) then begin
   erange = fltarr(2,256)
   for i=0,255 do   erange[*,i] = 59.5 / cbin59_5[map[i].det,map[i].tid,sepn-1] * map[i].adc
   map.meas_energy    = average(erange,1)
   map.meas_width   = reform(erange[1,*]-erange[0,*])  ;/2
endif
end


