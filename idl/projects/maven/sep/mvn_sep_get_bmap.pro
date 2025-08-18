
function mvn_sep_get_bmap,mapnum,sensor

common mvn_sep_get_bmap_com, lut,bmap,last_mapnum,last_sensor

if (n_elements(last_mapnum) eq 0) || (mapnum ne last_mapnum) || (sensor ne last_sensor) then begin
    lut = mvn_sep_create_lut(mapname,mapnum=mapnum)

    bmap = mvn_sep_lut2map(lut=lut,  sensor=sensor)
    last_mapnum = mapnum
    last_sensor = sensor
  
endif

return,bmap

end
  
  

