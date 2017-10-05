pro load_wilcox,t,data=alldat
files = findfile('/home/davin/dat/solar/wilcox/CR*')
nf = n_elements(files)

par ={T0:time_double('1853-10-27/14:21:42'),T1:2355919.8d}
v = asin(dgen(30,range=[14.5,-14.5]/15))*180/!pi

s = ''
a = fltarr(8)
map = bindgen(256)
map[byte('CT:')] = byte(' ')
dat0 = {time:0.d, CT:0, phi:0, mag:fltarr(30), lat_cur:0.}
for i=0,nf-1 do begin
  openr,lun,files[i],/get_lun
  readf,lun,s
  readf,lun,s
;  print,s
  readf,lun,s
  for j=0,73-1 do begin
    readf,lun,s
    s2 = string(map(byte(s)))
    reads,s2,a
    dat0.ct = round(a[0])
    dat0.phi = round(a[1])
    dat0.mag[0:5] = a[2:7]
    readf,lun,a
    dat0.mag[6:13] = a
    readf,lun,a
    dat0.mag[14:21] = a
    readf,lun,a
    dat0.mag[22:29] = a
    dat0.lat_cur = interp(v,dat0.mag,0.)
    append_array,alldat,dat0,index=ind
  endfor
  free_lun,lun
endfor
append_array,alldat,index=ind,/done
cr = alldat.ct + (360.-alldat.phi)/360. 
dshift = 4.5
alldat.time = par.t0 + cr * par.t1 + dshift * 3600d * 24d
store_data,'lat_cur',data={x:alldat.time, y:alldat.lat_cur},dlim={ytitle:'!19Q!X!DCS!N'}
end
