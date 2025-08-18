;swem crib
;
;Real time example

if 0 then begin
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

printdat,spp_file_source(user_pass='davin:password',/set)

trange = ['2018-03-06/00:00:00','2018-03-09/00:00:00']  ; goddard testing
ptpfiles = spp_file_retrieve('spp/data/sci/sweap/prelaunch/',/hourly,TRANGE=TRANGE)

path='psp/data/sci/sweap/sao/s#sr_telemetry/YYYY/DOY/*_EA'
ff=time_string(met,tformat=path)
str_replace,ff,'s#s','ss'


ff = 'psp/data/sci/sweap/sao/ssr_telemetry/2020/191/*_EA'
SSRfiles = spp_file_retrieve(ff)


ssrfiles = spp_file_retrieve('spp/data/sci/sweap/sao/ssr_telemetry/2018/245/*_EA')                 ;MSIM4:
spp_ssr_file_read,ssrfiles

ssrfiles = spp_file_retrieve('spp/data/sci/sweap/prelaunch/moc/MOPS_DATA/20180515_MSIM4/ssr_telemetry/2018/245/*_EA')  ;MSIM4:
spp_ssr_file_read,ssrfiles

prefix = 'spp/data/sci/MOC/SPP_IT/data_products/ssr_telemetry/'

trange = '2020-1-'+['200','202']
;trange = '2018-1-'+['245','247']
ssrfiles = spp_file_retrieve( prefix='spp/data/sci/MOC/SPP_IT/data_products/ssr_telemetry/' ,'YYYY/DOY/*_EA',/daily_names,trange=trange)


;;----SPAN-E TVAC TESTING @ GODDARD (2018)----;;
; Use the following:
; files = spp_file_retrieve(/swem, /goddard, trange = trange)
trange = '2018 03 ' + ['07/16','08/01'] ; fields wpc testing with electron gun
trange = '2018 03 ' + ['08/00','08/04'] ; threshold tests @ each anode w/electron gun stimuli
trange = '2018 03 ' + ['08/03','08/06'] ; threshold tests @ MCP values, spoiler test, and energy sweep (also powerdown)  MET = '2020-1-201'

ptp1files = spp_file_retrieve('spp/data/sci/MOC/SPP_IT/data_products/level_zero_telemetry/YYYY/DOY/sweap_spp_YYYYDOY_??.ptp.gz',/daily_names,trange=trange,/valid_only)
ptp2files = spp_file_retrieve('spp/data/sci/MOC/SPP_IT/data_products/level_zero_telemetry/YYYY/DOY/sweap_spp_YYYYDOY_??.ptp.gz',/daily_names,trange=trange,/valid_only)



trange = '2018-05-08/03:27:02'   ; racksat memory dump

trange='2018-3-8/'+['1','2']
trange=['2018-3-7','2018-3-9']  ; goddard testing
path = 'spp/data/sci/sweap/prelaunch/gsedata/realtime/hires1/swem/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
ptpfiles = spp_file_retrieve(path,trange=trange,/hourly_names)
spp_ptp_file_read, ptpfiles

trange = ['2018-04-30/18:18', '2018-04-30/22:14']  ; compression testing
;trange = ['2018-4-3

path =  'spp/data/sci/sweap/prelaunch/gsedata/realtime/hires1/swem/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
spp_init_realtime,/swem,/hires1,/exec

path =  'spp/data/sci/sweap/prelaunch/gsedata/realtime/cal/swem/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
spp_init_realtime,/swem,/cal,/exec


spp_apdat_info,/print
spp_apdat_info,'7c0'x,dlevel=1
spp_apdat_info,'344'x,dlevel=1
spp_apdat_info,'7c1'x,dlevel=1



endif

if 1 then begin
if n_elements(racksat) eq 0 then racksat = 1

if keyword_set(racksat) then begin
  path =  'spp/data/sci/sweap/prelaunch/gsedata/realtime/cal/swem/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
  spp_init_realtime,/swem,/cal,/exec
endif else begin
  path =  'spp/data/sci/sweap/prelaunch/gsedata/realtime/hires1/swem/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
  spp_init_realtime,/swem,/hires1,/exec
  
endelse

dprint,setd=4

trange = systime(1) + [-1,0] * 3600.
timespan,trange
ptpfiles = spp_file_retrieve(path,trange= trange,/hourly_names)

if not keyword_set(log) then begin
  file_open,'w','log/spp_swp_log.txt',unit=log
  spp_apdat_info,'*log*',output_lun = log
endif


if 0 then begin
  spi_memdump = spp_apdat('spi_memdump')
  spi_memdump.display, win = window(name='spi_memdump')
  swem_memdump = spp_apdat('swem_memdump')
  swem_memdump.display, win = window(name='swem_memdump')
endif

dprint,setd=2
spp_ptp_file_read, ptpfiles

spp_swp_tplot,/setlim   ,'swem2'

if 0 then begin
ap = spp_apdat('swem_dig_hkp')
ap.cdf_pathname = time_string(tformat='psp/data/sci/sweap/swem/YYYY/MM/DD/swem_test_YYYYMMDD.cdf',trange[0])
ap.cdf_create_file,trange=trange
endif

if 0 then begin
  options,'*SPEC',spec=1
  zlim,'spp_sp[ab]_SF1_NRG_SPEC', 1,10000,1
endif

endif


end
