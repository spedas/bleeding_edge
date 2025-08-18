;swx_text_crib
;
swx_apdat_init
swx_apdat_info,rt_flag=0, save_flag=1;, /clear
;files = FILE_SEARCH('/disks/data/swx/sst/prelaunch/realtime/cleantent/ptp_reader/2023/12/27/*.dat')
source = { remote_data_dir: 'http://sprg.ssl.berkeley.edu/data/',resolution:3600d,master_file:'swx/sst/prelaunch/.master'}
trange = ['2023-12-27 5','2023-12-27 / 8']
trange = ['2023-12 22', '2023-12-31']
trange = ['2023-12 27 22', '2023-12-28 2']
trange = ['2023 12 22 ','2024 1 6']
trange = ['2024 3 25', '2024 3 28' ]
trange = ['2024 1 2 16:20' ,'2024/1/4 16:31']
files = file_retrieve('swx/s\st/prelaunch/realtime/cleantent/ptp_reader/YYYY/MM/DD/ptp_reader_YYYYMMDD_hh.dat',_extra=source,trange=trange)
if 1 then begin
  rdr = ptp_reader(/no_widget,mission='SWX'  )  
  rdr.file_read,files
endif else begin
  swfo_ptp_file_read, files,file_type =  'ptp_file'  
endelse


swfo_apdat_info,/print,/all  ,  /make_ncdf,trange=trange,file_resolution=3600d*24
end