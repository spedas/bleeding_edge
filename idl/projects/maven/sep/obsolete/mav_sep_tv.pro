pro mav_sep_tv

source = mav_file_source()
source.preserve_mtime=0
source.min_age_limit=30
pathname = 'maven/sep/prelaunch_tests/TV/*_SEP_??_HTR.txt'
file = file_retrieve(pathname,_extra=source,last_version=0)
nf = n_elements(file)
;file = file[nf-2:nf-1]
printdat,file

format = {time:0d,SEP1A_TEMP:0.,SEP1B_TEMP:0.,sep2A_TEMP:0.,sep2B_TEMP:0.,SEP1A_THRESH:0.,SEP1B_THRESH:0.,sep2A_Thresh:0.,sep2b_thresh:0.,heater_flag:0}
tvdat = read_asc(file,format = format)
delta_t = time_double('2078') - time_double('2012')
n = n_elements(tvdat)
print,time_string(tvdat[n-1].time-delta_t)
tvdat.time -= delta_t


store_data,'HTR_*',/clear
mav_gse_structure_append,0,/realtime,tvdat,tname='HTR'

times = tvdat.time
tvdat[n-1].heater_flag = 0 

dcf = (tvdat.heater_flag and 1) ne 0
w_on = where(dcf eq 0 and shift(dcf,1) eq 1 ,nw1)
w_off = where(dcf eq 1 and shift(dcf,1) eq 0, nw0)
if nw1 gt 2 then begin
  t_on = times[w_on]
  t_off= times[w_off]
  tperiod = t_on - shift(t_on,1)
  dc = abs((t_off - t_on)/tperiod)
  store_data,'HTR_SEP1A_DC',t_on,dc
endif

dcf = (tvdat.heater_flag and 2) ne 0
w_on = where(dcf eq 0 and shift(dcf,1) eq 1 ,nw1)
w_off = where(dcf eq 1 and shift(dcf,1) eq 0, nw0)
if nw1 gt 2 then begin
  t_on = times[w_on]
  t_off= times[w_off]
  tperiod = t_on - shift(t_on,1)
  dc = abs((t_off - t_on)/tperiod)
  store_data,'HTR_SEP1B_DC',t_on,dc
endif

dcf = (tvdat.heater_flag and 4) ne 0
w_on = where(dcf eq 0 and shift(dcf,1) eq 1 ,nw1)
w_off = where(dcf eq 1 and shift(dcf,1) eq 0, nw0)
if nw1 gt 2 then begin
  t_on = times[w_on]
  t_off= times[w_off]
  tperiod = t_on - shift(t_on,1)
  dc = abs((t_off - t_on)/tperiod)
  store_data,'HTR_SEP2A_DC',t_on,dc
endif

dcf = (tvdat.heater_flag and 8) ne 0
w_on = where(dcf eq 0 and shift(dcf,1) eq 1 ,nw1)
w_off = where(dcf eq 1 and shift(dcf,1) eq 0, nw0)
if nw1 gt 2 then begin
  t_on = times[w_on]
  t_off= times[w_off]
  tperiod = t_on - shift(t_on,1)
  dc = abs((t_off - t_on)/tperiod)
  store_data,'HTR_SEP2B_DC',t_on,dc
endif

options,'HTR_SEP1?_*',colors='b'
options,'HTR_SEP2?_*',colors='r'
store_data,'HTR_TEMP',data='HTR_SEP??_TEMP'
store_data,'HTR_DC',data='HTR_SEP??_DC'



;tplot,trange=minmax(tvdat.time)
end


;http://sprg.ssl.berkeley.edu/data/maven/sep/preflight/maven/sep/prelaunch_tests/TV/20120913_162754_SEP_TB.txt