pro mvn_sep_fov_xray_crib

timespan,'2019-12-18',1 ;skimming the transition altitude
bx=[.6,6]
mvn_sep_fov,/spice,/load,/calc,/tplot
mvn_sep_fov_xray_model,bx=bx
mvn_sep_fov_xray,/occ,sep=1,sld=1,mvnalt=100.,tanalt=[40,120],/ylog,bx=bx ;sep2_A-O

timespan,'2016-03-12',2 ;11 consecutive orbits
mvn_sep_fov,/spice,/load,/calc,/tplot
mvn_sep_fov_xray_model
mvn_sep_fov_xray,/occ,sep=1,sld=1,mvnalt=1000.,tanalt=[-50,200],bx=[.67,2.],det=5 ;sep2_B-F

end