; It is assumed that the window size and time limits have already been set up prior to running this


pro mvn_sep_gen_ql,trange=trange,load=load,summary=summary,plotformat=plotformat

if keyword_set(load) then begin
   L0_files = mvn_pfp_file_retrieve(/l0,trange=trange)
   mvn_sep_load,files = l0_files
;   mk_files = mvn_spice_kernels(trange=trange)
endif

;source = mvn_file_source()
;dir = source.local_data_dir + 'maven/prelaunch/plots/sep/recent'
;output = dir

if ~keyword_set(plotformat) then plotformat = 'maven/pfp/sep/plots/YYYY/MM/$NDAY$/$PLOT$/mvn_sep_$PLOT$_YYYYMMDD_$NDAY$.png'
trange = timerange(trange)
fname = mvn_pfp_file_retrieve(plotformat,trange=trange[0],no_server=1,valid_only=0,/daily)   ; generate plot file names
ndays = round( (trange[1]-trange[0])/86400 )
str_replace,fname,'$NDAY$',strtrim(ndays,2)+'day'

summary = 1
if keyword_set(summary) then begin
  mvn_sep_tplot,'1a',filename=fname
  mvn_sep_tplot,'1b',filename=fname
  mvn_sep_tplot,'2a',filename=fname
  mvn_sep_tplot,'2b',filename=fname
  mvn_sep_tplot,'TID',filename=fname
  mvn_sep_tplot,'SUM',filename=fname
  mvn_sep_tplot,'HKP',filename=fname
endif

mvn_sep_tplot,'Ql',filename=fname


end


