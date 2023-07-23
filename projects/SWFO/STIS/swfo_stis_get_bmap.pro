
function swfo_stis_get_bmap,mapnum,sensor

common swfo_stis_get_bmap_com, lut,bmap,last_mapnum,last_sensor

if 1 || (n_elements(last_mapnum) eq 0) || (mapnum ne last_mapnum) || (sensor ne last_sensor) then begin
    lut = swfo_stis_create_lut(mapname,mapnum=mapnum)

    bmap = swfo_stis_lut2map(lut=lut,  sensor=sensor)
    last_mapnum = mapnum
    last_sensor = sensor
  
endif

return,bmap

end
  
  

