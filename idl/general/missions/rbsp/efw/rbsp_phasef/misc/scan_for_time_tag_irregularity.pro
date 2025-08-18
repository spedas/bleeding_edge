;+
; Scan L2 esvy data for irregular time tags.
;-

time_range = time_double(['2013-01-01','2018-12-31'])
probe = 'b'


secofday = 86400d
days = make_bins(time_range+[-1,0]*secofday, secofday)
nday = n_elements(days)-1
prefix = 'rbsp'+probe+'_'
rbspx = 'rbsp'+probe
dt = 1d/32

day_list = dblarr(nday)
dtime_list = dblarr(nday)

local_root = join_path([default_local_root(),'rbsp'])
version = 'v*'

file_time_ranges = dblarr(nday+1,2)

foreach day, days, day_id do begin   
    base_name = rbspx+'_l1_esvy_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'l1','esvy','%Y']
    remote_path = ['http://themis.ssl.berkeley.edu/data/rbsp', $
        rbspx,'l1','esvy','%Y']
    local_file = apply_time_to_pattern(join_path([local_path,base_name]), day)
    files = file_search(local_file)
    file = files[-1]
    epochs = cdf_read_var('epoch', filename=file)
    times = convert_time(epochs,from='epoch16',to='unix')
    the_time_range = minmax(times)
    file_time_ranges[day_id,*] = the_time_range

    tid = day_id-1
    if day_id eq 0 then begin
        pre_time_range = the_time_range
        continue
    endif else begin
        day_list[tid] = day
        dtime_list[tid] = the_time_range[0]-pre_time_range[1]
        pre_time_range = the_time_range
    endelse
    
    dtime = dtime_list[tid]
    if abs(dtime-dt) lt 2*dt then continue
    print, time_string(day_list[tid],tformat='YYYY-MM-DD')
    print, dtime
endforeach

dtimes = file_time_ranges[1:nday-1,0]-file_time_ranges[0:nday-2,1]
plot, dtimes
index = where(dtimes le 0, count)
if count ne 0 then begin
    print, 'Negative jump: '
    for ii=0,count-1 do begin
        print, time_string(day_list[index[ii]],tformat='YYYY-MM-DD')
        print, dtimes[index[ii]]
    endfor
endif

index = where(abs(dtimes-dt) ge 2*dt, count)
if count ne 0 then begin
    print, 'Full list: '
    for ii=0,count-1 do begin
        print, time_string(day_list[index[ii]],tformat='YYYY-MM-DD')
        print, dtimes[index[ii]]
    endfor
endif
stop

end
