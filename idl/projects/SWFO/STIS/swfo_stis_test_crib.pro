;  sample crib sheet
;
;

;Loading data
;


pro swfo_stis_nse_metric
  get_data,'swfo_stis_nse_SIGMA',ptr=dd,dlim=lim
  dat = dd.ddata.array
  ndat = n_elements(dat.time)
  raw_hist = reform(dat.histogram,10,6,ndat)
  metric = fltarr(6,ndat)
  for det=0,5 do begin
    h = reform( raw_hist[*,det,*] )
    metric[det,*] = ( h[0,*] + h[9,*] ) / total(h, 1)
  endfor
  store_data,'swfo_stis_nse_METRIC' ,dat.time,transpose(metric),dlim = lim
  metric_max = max(metric,dimen=1)
  store_data,'swfo_stis_nse_METRIC_max' ,dat.time,metric_max,dlim = lim
end

if ~keyword_set(rdr) then begin

  trange = ['2024 9 9 23','2024 9 21 6']
  trange = ['2024 9 20 8','2024 9 21 6']  ; 1 atmos test after TVAC
  ;

  ; retrieving files:
  ; Files can be found at the following website:   (replace YYYY MM DD and hh with the proper time of interest
  ; https://sprg.ssl.berkeley.edu/data/swfo/data/sci/stis/prelaunch/realtime/Ball2/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz

  no_download = 0    ;set to 1 to prevent download from the web
  no_update = 1      ; set to 1 to prevent checking for updates

  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
    master_file: 'swfo/.master', $
    no_update : no_update ,$
    no_download :no_download ,$
    resolution: 3600L  }

  pathname = 'swfo/data/sci/stis/prelaunch/realtime/Ball2/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
  files = file_retrieve(pathname,_extra=source,trange=trange)
  w=where(file_test(files),/null)
  files = files[w]


  ; Initialize the code to evaluate data

  swfo_stis_apdat_init,/save
  
  
  ;  Get reader object for raw CCSDS packets
  ccsds_rdr = ccsds_reader(name='Raw CCSDS stream from TOC' , sync_pattern = ['2b'xb,  'ad'xb ,'ca'xb, 'fe'xb], sync_mask= [0xef,0xff,0xff,0xff], /no_widget )


  ;  The data is stored in common block files for more info on this format see:  
  ;  https://docs.google.com/presentation/d/1b5ooHfuHJsavys-BOUOOZohXeCzJC1M0MNaUlxM1tEg/edit#slide=id.p
  rdr = cmblk_reader(name='Common Block stream from STIS GSE',/no_widget)
  rdr.add_handler, 'raw_ball', ccsds_rdr


  ; Read filess

  rdr.file_read, files


  defsysv,/test,'!stis',dictionary()
  init = 1


  ; Plotting data
 
  swfo_apdat_info,/create_tplot_vars


  swfo_apdat_info,/sort
  
  swfo_stis_tplot,/set
  swfo_stis_tplot,'wheels'
  tlimit,trange
  swfo_stis_tplot,'noise2',add=99
  swfo_stis_nse_metric
  tplot,'swfo_stis_nse_METRIC',add=1

endif




!stis.pngname = root_data_dir() + 'swfo/data/sci/stis/prelaunch/realtime/plot'


if 0 then begin
  get_data,'swfo_sc_xxx_IRU_BITS'

  ntimes = dimen2(ttimes)
  for i=0,ntimes-1 do begin
    tt = ttimes[*,i]
    ;      get_data,'swfo_sc_xxx_IRU_BITS',data = iru
    iru = tsample('swfo_sc_110xxx_IRU_BITS',tt)

    wheelspeed = tsample('swfo_sc_ WHEEL_RPM',tt,/average)
    wheeltemp  = tsample('swfo_sc_ TEMP',tt,/average)
    stis_metric = tsample('swfo_stis_nse_metric',tt,/average)
  endfor

endif


end
