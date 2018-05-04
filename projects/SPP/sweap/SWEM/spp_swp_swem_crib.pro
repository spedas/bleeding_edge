;swem crib
;
;Real time example
spp_init_realtime,/swem,/cal,/exec





path ='spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires5/20161025_160613_SWEMSPC/PTP_data.dat'
path ='spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires5/20161025_160613_SWEMSPC/PTP_data.dat'
path ='spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires5/20160824_143328_swem_int/20160824_143328_PTP_data.dat'
path ='spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires5/20161025_152727_SWEM-SPCtest/PTP_data.dat'

path = 'spp/data/sci/sweap/prelaunch/gsedata/realtime/cal/swem/2017/11/30/spp_socket_20171130_19.dat.gz'

file = spp_file_retrieve(path)
spp_ptp_file_read, file


trange='2017 11 30 '+['14','23']

path = 'spp/data/sci/sweap/prelaunch/gsedata/realtime/cal/swem/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
files = spp_file_retrieve(path,trange=trange,/hourly_names)
spp_ptp_file_read, files

;retrieving files
;example 1
path = 'psp/data/sci/sweap/prelaunch/moc/20171218_TIMEJUMP/data_products/ssr_telemetry/2024/348/*_?_E?
SSRfiles = spp_file_retrieve(path)

;example 2
trange='2017 11 30 '+['14','23']
path = 'psp/data/sci/sweap/prelaunch/moc/20171218_TIMEJUMP/data_products/SSR_telemetry/YYYY/DOY/*_?_E?
SSRfiles = spp_file_retrieve(path,trange=trange,/hourly)

;reading files
spp_SSR_file_read, SSRfiles


spp_apdat_info,/print

f='/Users/davin/Downloads/0271373172_2_EA'
fs = '/Users/davin/Downloads/??????????_?_EA'
ssrfiles = file_search(fs)

datinfo = spp_apdat('343'x)



spp_swp_tplot,'TEMPS'
spp_swp_tplot,'TEMP'

spp_swp_tplot,'si_hv'
spp_swp_tplot,'si_rate1',/add
spp_swp_tplot,'sa_hv'
spp_swp_tplot,'sb_hv'

tplot,'*SF1_ANODE_SPEC'


spp_apdat_info,/print

; TVAC CPT
rtime = '2018-3-7'


path = 'psp/data/sci/sweap/prelaunch/moc/20171218_TIMEJUMP/data_products/SSR_telemetry/YYYY/DOY/*_?_E?
SSRfiles = spp_file_retrieve(path,trange=trange,/hourly)

met= '2020-7-21'



path='psp/data/sci/sweap/sao/s#sr_telemetry/YYYY/DOY/*_EA'
ff=time_string(met,tformat=path)
str_replace,ff,'s#s','ss'


ff = 'psp/data/sci/sweap/sao/ssr_telemetry/2020/191/*_EA'
SSRfiles = spp_file_retrieve(ff)

spp_ssr_file_read,ssrfiles


trange='2018-3-8/'+['0','24']
trange=['2018-3-7','2018-3-9']
path = 'spp/data/sci/sweap/prelaunch/gsedata/realtime/hires1/swem/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
ptpfiles = spp_file_retrieve(path,trange=trange,/hourly_names)
spp_ptp_file_read, ptpfiles

trange = ['2018-04-30/18:19:15', '2018-04-30/19:16:50']  ; compression testing

trange = systime(1) + [-10,0] * 3600.
dprint,setd=2
path =  'spp/data/sci/sweap/prelaunch/gsedata/realtime/cal/swem/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
ptpfiles = spp_file_retrieve(path,trange= trange,/hourly_names)
spp_ptp_file_read, ptpfiles

dprint,setd=4

spp_init_realtime,/swem,/cal,/exec

spp_swp_tplot,/setlim,'swem'


