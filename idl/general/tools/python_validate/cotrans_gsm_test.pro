pro cotrans_gsm_test

; Set up timestamps
; 

tstart='2010-01-01'
tend='2015-01-01'
tstart_unix= time_double(tstart)
tend_unix=time_double(tend)

days = (tend_unix - tstart_unix)/86400

times = dblarr(days)
times = tstart_unix + dindgen(days)*86400.0D


zdata = dblarr(days,3)
zdata[*,0] = 0.0D
zdata[*,1] = 0.0D
zdata[*,2] = 1.0D

store_data,'zgeo',data={x:times, y:zdata}
get_data,'zgeo',data=d,dl=dl
cotrans_set_coord,dl,'GEO'
store_data,'zgeo',data=d, dl=dl
spd_cotrans,'zgeo',out_coord='GSM', out_suff='_gsm'
tdotp,'zgeo','zgeo_gsm',newname='zgeo_gsm_dot'
get_data,'zgeo_gsm_dot',data=d
ang_deg = acos(d.y)*180.0D/!dpi

store_data,'ang_deg',data={x: times, y:ang_deg}
tplot,'ang_deg'

; Now do the same GEO to GSM cotrans in geopack

zdata_gp = dblarr(days,3)
for i = 0, n_elements(times)-1 do begin
  ts = time_struct(times[i])
  geopack_recalc,ts.year, ts.doy, ts.hour, ts.min, ts.sec
  geopack_conv_coord,/from_geo, /to_gsm,0.0,0.0,1.0D,xgsm,ygsm,zgsm
  
  zdata_gp[i,0] = xgsm
  zdata_gp[i,1] = ygsm
  zdata_gp[i,2] = zgsm
endfor
store_data,'zgeo_gsm_gp',data={x: times, y:zdata_gp}
tdotp,'zgeo','zgeo_gsm_gp',newname='zgeo_gsm_gp_dot'
get_data,'zgeo_gsm_gp_dot',data=d
ang_deg_gp = acos(d.y)*180.0D/!dpi
store_data,'ang_deg_gp',data={x: times, y:ang_deg_gp}


tplot,'ang_deg ang_deg_gp'

; And compute the difference
; 
ang_diff = ang_deg_gp - ang_deg
store_data,'ang_diff',data={x:times, y: ang_diff}
tplot, 'ang_deg ang_deg_gp ang_diff'
testvars = ['zgeo','zgeo_gsm', 'zgeo_gsm_gp']
tplot_save,testvars, filename='/tmp/geogsm_gp_test'
end


