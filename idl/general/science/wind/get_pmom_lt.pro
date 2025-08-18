pro get_pmom_lt,trange;,index = index, $
;on_ioerror,error

dir = '/disks/aeolus/home/wind/scratch/long_term/'
openr,fp,dir+'pmom_binary',/get_lun
dat = {time:0.d, dtime:0.d, quality:0, nsamp:0, counter:0l, dummy:0l,$
   dens:0., vel:fltarr(3), temp:0. }
filedata = assoc(fp,dat)


;foo = filedata(0)
;startsstftime = foo.time

;if n_elements(trange) ne 2 then trange = [str_to_time('94-11-20'),systime(1)]

;tr = gettime(trange)

;if not keyword_set(index) then index = long((tr-startsstftime)/(128*3.))
;index(0) = index(0) > 0
;index(1) = index(1) < 50000l+index(0)


if not keyword_set(index) then begin
   file_status = fstat(fp)
   rec_len=n_tags(dat,/length)
;   help,dat,file_status,/st
;   stop
   num_records = file_status.size / rec_len
   index = [0l,num_records -1]
endif

np =index(1)-index(0)+1

time = fltarr(np)
dens = fltarr(np)
vel = fltarr(np,3)
temp = fltarr(np)

n = 0l
for i=0l,np-1 do begin
    foo = filedata(i+index(0))
    if(foo.time) > 7.5738240e+08 then begin
       time(n)   = foo.time
       dens(n)  = foo.dens
       vel(n,*) = foo.vel
       temp(n)  = foo.temp
       n=n+1
    endif
endfor
error:
print,n

time = time(0:n-1)
dens = dens(0:n-1)
vel =  vel(0:n-1,*)
temp = temp(0:n-1)

store_data,"Np_lt",data={ytitle:'Np_lt', x:time, y:dens}
store_data,"Vp_lt",data={ytitle:'Vp_lt', x:time, y:vel}
store_data,"Tp_lt",data={ytitle:'Tp_lt', x:time, y:temp}
free_lun,fp

end
