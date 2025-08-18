pro mav_sep_ig

source = mav_file_source()
source.preserve_mtime=0
source.min_age_limit=30
pathname = 'maven/sep/prelaunch_tests/IonGun/*_iongun.txt'
file = file_retrieve(pathname,_extra=source,last_version=2)
nf = n_elements(file)
ln = 1
file = file[nf-ln:nf-1]
printdat,file

format = {time:0d,Steer:0.,EXB:0.,Lens:0.,HDEF:0.}
tvdat = read_asc(file,format = format)
delta_t = time_double('2078') - time_double('2012')
n = n_elements(tvdat)
;print,time_string(tvdat[n-1].time-delta_t)
tvdat.time -= delta_t
;n = n_elements(tvdat)
ldat = tvdat[n-1]

fmt = '(a,"  Hdef=",f5.3,"  Lens=",f5.3,"  ExB=",f5.3,"  Steer=",f5.3)'
print,time_string(ldat.time),ldat.hdef,ldat.lens,ldat.exb,ldat.steer,format=fmt
;print,time_string(ldat.time),'   Hdef=',ldat.hdef,'   Lens=',ldat.lens,'   ExB=',ldat.exb,'    Steer=',ldat.steer


store_data,'IG_*',/clear
mav_gse_structure_append,0,/realtime,tvdat,tname='IG'

store_data,'IG',data=tnames('IG_*')
options,'IG_STEER',colors='m'
options,'IG_EXB',colors='b'
options,'IG_LENS',colors='g'
options,'IG_HDEF',colors='r'


;tplot,trange=minmax(tvdat.time)
end


;http://sprg.ssl.berkeley.edu/data/maven/sep/preflight/maven/sep/prelaunch_tests/TV/20120913_162754_SEP_TB.txt