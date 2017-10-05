
pro mvn_sep_gen_plots,trange=trange0,load=load,summary=summary,plotformat=plotformat,init=init,timestamp=timestamp,verbose=verbose

if keyword_set(init) then begin
  trange0 = [time_double('2013-12-5'), systime(1) ]
  if init lt 0 then trange0 = [time_double('2013-12-5'), systime(1) ]
endif else trange0 = timerange(trange0)

if ~keyword_set(plotformat) then plotformat = 'maven/data/sci/sep/plots/YYYY/MM/$NDAY/$PLOT/mvn_sep_$PLOT_YYYYMMDD_$NDAY.png'
L1_fileformat =  'maven/data/sci/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_$NDAY.sav' 

ndaysload =1
L1fmt = str_sub(L1_fileformat, '$NDAY', strtrim(ndaysload,2)+'day')


wi,0,wsize=[1000,800]
res = 86400L
trange = res* double(round( (timerange((trange0+ [ 0,res-1]) /res)) ))         ; round to days
nd = round( (trange[1]-trange[0]) /res) 

if n_elements(load) eq 0 then load =1

for i=0L,nd-1 do begin
  tr = trange[0] + [i,i+1] * res

  sw_version = mvn_sep_sw_version()  
  prereq_files = sw_version.sw_time_stamp_file

  L0_files = mvn_pfp_file_retrieve(/l0,trange=tr)

  append_array,prereq_files,L0_files

  if 0 then begin
       mk_files = mvn_spice_kernels(trange=tr)
       cspice_kclear
       spice_kernel_load,mk_files
       append_array, prereq_files, mk_files
  endif

  L1_filename = mvn_pfp_file_retrieve(L1fmt,/daily,trange=tr[0],source=source,verbose=verbose,create_dir=1)


  prereq_info = file_info(prereq_files)
  prereq_timestamp = max([prereq_info.mtime, prereq_info.ctime])
  
  target_info = file_info(l1_filename)
  target_timestamp =  target_info.mtime 

  if prereq_timestamp lt target_timestamp then continue    ; skip if L1 does not need to be regenerated
  dprint,dlevel=1,'Generating L1 file: '+L1_filename
  timestamp= systime(1)    ; trigger regeneration of long term plots
  mvn_sep_load,/l0,files = l0_files
  
  prereq_info = file_checksum(prereq_files,/add_mtime)
  mvn_sep_var_save,l1_filename,prereq_info=prereq_info,description=description
  mvn_mag_var_save

;  mvn_sep_gen_l2_cdf,prereq=prereq_info


;  ndays = round( (tr[1]-tr[0])/res )
  pf = str_sub(plotformat,'$NDAY',strtrim(ndaysload,2)+'day')
  fname = mvn_pfp_file_retrieve(pf,trange=tr[0],no_server=1,create_dir=1,valid_only=0,/daily_names)   ; generate plot file names - (doesn't matter if they exist)

  if 1 then begin
    tplot,trange=tr  ;tlimit,tr   ; cluge to set time - there should be an option in tlimit to not make a plot
    summary = 1
    if keyword_set(summary) then begin
      mvn_sep_tplot,'1a' ,filename=fname
      mvn_sep_tplot,'1b' ,filename=fname
      mvn_sep_tplot,'2a' ,filename=fname
      mvn_sep_tplot,'2b' ,filename=fname
      mvn_sep_tplot,'TID',filename=fname
      mvn_sep_tplot,'SUM',filename=fname
      mvn_sep_tplot,'HKP',filename=fname
    endif
    mvn_sep_tplot,'Ql',filename=fname
  endif
  endfor
  
  timestamp = 0  ; temporarily disable
  if  keyword_set(timestamp) then begin  ; should only be run if there is at least one new daily file
     trange = systime(1) + 86400d *[-28,0]          ; last 28 days
     mvn_sep_var_restore,trange=trange
     tlimit,trange
     fname = mvn_pfp_file_retrieve('maven/pfp/sep/plots/recent/28day/mvn_sep_$PLOT_28day.png',/create_dir)
     mvn_sep_tplot,'1a',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'1b',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'2a',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'2b',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'TID',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'sum',filename=fname,if_older_than=timestamp

     trange = systime(1) + 86400d *[-7,0]          ; last 7 days
     mvn_sep_var_restore,trange=trange
     tlimit,trange
     fname = mvn_pfp_file_retrieve('maven/pfp/sep/plots/recent/7day/mvn_sep_$PLOT_7day.png',/create_dir)
     mvn_sep_tplot,'1a',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'1b',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'2a',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'2b',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'TID',filename=fname,if_older_than=timestamp
     mvn_sep_tplot,'sum',filename=fname,if_older_than=timestamp
  endif
  
  if 0 then begin
  
  ;28 day plots...
  res28 = 28d * 24* 3600
  btl =  floor(trange/res28)
  nd = btl[1]-btl[0]+1
  for b=btl[0],btl[1] do begin
     tr = res28 * [b,b+1]  
     plot_info = file_info( mvn_pfp_file_retrieve( 'maven/pfp/sep/plots/28day/mvn_sep_SUM_YYYYMMDD_28day.png',trange=tr[0],/daily_name)  )
     L1_info   = file_info( mvn_pfp_file_retrieve(L1fmt,trange=tr,/daily_name) )
     if plot_info.mtime le max(L1_info.mtime) then begin
        dprint,'Make new plot: ' ,plot_info.name
     endif
   endfor
   
  endif

end


