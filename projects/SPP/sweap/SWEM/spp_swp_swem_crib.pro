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

datinfo = spp_apdat('343'x)



spp_swp_tplot,'TEMPS'
spp_swp_tplot,'TEMP'







spp_apdat_info,/print




