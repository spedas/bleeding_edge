; $LastChangedBy: ali $
; $LastChangedDate: 2019-08-20 18:35:15 -0700 (Tue, 20 Aug 2019) $
; $LastChangedRevision: 27627 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/cdf/mvn_sep_makefile.pro $
; $ID: $

pro mvn_sep_make_cdf_wrap,cal=cal,raw=raw,sepnum=sepnum,source_files=source_files,trange=trange,prereq_files=prereq_files,add_link=add_link,sw_version=sw_version
  @mvn_sep_handler_commonblock.pro
  sn = strtrim(sepnum,2)
  sepstr = 's'+sn
  sepname = 'SEP'+sn
  if keyword_set(cal) then data_type = sepstr+'-cal-svy-full'
  if keyword_set(raw) then data_type = sepstr+'-raw-svy-full'
  ver = sw_version.sw_version
  L2_fileformat ='maven/data/sci/sep/l2/YYYY/MM/mvn_sep_l2_'+data_type+'_YYYYMMDD_'+ver+'_r??.cdf'
  lastrev_fname = mvn_pfp_file_retrieve(l2_fileformat,/daily_name,trange=trange[0],verbose=verbose,/last_version)
  lri = file_info(lastrev_fname)
  source_fi = file_info([source_files,prereq_files])
  if lri.mtime lt max([source_fi.mtime,source_fi.ctime]) then begin
    mvn_sep_load,/use_cache,files=source_files,trange=trange,/L1
    nextrev_fname = mvn_pfp_file_next_revision(lastrev_fname)
    dprint,dlevel=1,'Generating L2 file: '+nextrev_fname
    sepdata = sepnum eq 1 ? *sep1_svy.x : *sep2_svy.x
    if keyword_set(cal) then begin
      ;if keyword_set(bkgfile) and file_test(/regular,bkgfile) then restore,file=bkgfile,/verb
      ; mvn_sep_spectra_plot,bkg2
      sepdata = mvn_sep_get_cal_units(sepdata,background = bkg2)
    endif
    if size(/type,sepdata) ne 8 then begin
      dprint,'sepdata is not a structure.  No Data?'
      printdat,sepdata
      return
    endif
    if keyword_set(cal) then global={ filename:file_basename(nextrev_fname),  data_type:data_type+'>Survey Calibrated Particle Flux',   logical_source:'SEP'+sn+'.cal.spec_svy',  sensor: sepname}
    if keyword_set(raw) then global={ filename:file_basename(nextrev_fname),  data_type:data_type+'>Survey Raw Particle Counts',   logical_source:'SEP'+sn+'.raw.spec_svy',  sensor: sepname}
    if keyword_set(raw) then begin
      mapid = round(median(sepdata.mapid))
      bmaps = mvn_sep_get_bmap(mapid,sepnum)
    endif else bmaps=0
    dependencies = [source_files,spice_test('*')]
    mvn_sep_make_cdf,sepdata,bmaps,filename = nextrev_fname,global=global,dependencies=dependencies,add_link=add_link,raw=raw,cal=cal
    ;    print_cdf_info,nextrev_fname
    if 0 then begin
      src = mvn_file_source()
      arcdir = src.local_data_dir+'maven/data/sci/sep/archive/'
      file_archive,lastrev_fname,archive_ext='.arc',archive_dir = arcdir
    endif
  endif
end


pro mvn_sep_makefile,init=init,trange=trange0

  if keyword_set(init) then begin
    ;  trange0 = [time_double('2014-9-20'), systime(1) ]
    trange0 = [time_double('2014-3-18'), systime(1) ] ;now can handle Flight2 energy map (MAPID=8)
    if init lt 0 then trange0 = systime(1) + [init,0 ]*24L*3600
  endif else trange0 = timerange(trange0)

  ;if ~keyword_set(plotformat) then plotformat = 'maven/data/sci/sep/plots/YYYY/MM/$NDAY/$PLOT/mvn_sep_$PLOT_YYYYMMDD_$NDAY.png'
  L1_fileformat =  'maven/data/sci/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_$NDAY.sav'


  ndaysload =1
  L1fmt = str_sub(L1_fileformat, '$NDAY', strtrim(ndaysload,2)+'day')

  res = 86400L
  daynum = round( timerange(trange0) /res )
  nd = daynum[1]-daynum[0]
  trange = res* double( daynum  )         ; round to days
  ;nd = round( (trange[1]-trange[0]) /res)

  ;if n_elements(load) eq 0 then load =1

  for i=0L,nd-1 do begin
    tr = trange[0] + [i,i+1] * res

    sw_version = mvn_sep_sw_version()
    prereq_files = sw_version.sw_time_stamp_file
    sw_info = file_info(prereq_files)

    L0_files = mvn_pfp_file_retrieve(/l0,trange=tr)   ; should be scalar

    if tr[0] gt time_double('2014-07-17') and tr[0] lt time_double('2014-9-21') then begin
      dprint,dlevel=3,'Cruise to Mars, Spacecraft hybernation, No L0 file: '+l0_files
      continue
    endif

    if total(file_test(/regular,l0_files)) eq 0 then begin
      dprint,dlevel=2,'File not found: '+l0_files
      continue
    endif

    if tr[0] eq time_double('2014-11-26') then begin
      dprint,dlevel=2,'File contains no SEP data: '+l0_files
      continue
    endif

    append_array,prereq_files,L0_files

    if 0 then begin
      mk_files = mvn_spice_kernels(trange=tr)
      cspice_kclear
      spice_kernel_load,mk_files
      append_array, prereq_files, mk_files
    endif

    L1_filename = mvn_pfp_file_retrieve(L1fmt,/daily,trange=tr[0],source=source,verbose=verbose,create_dir=1)

    L0_info = file_info(L0_files)
    prereq_timestamp = max([sw_info.mtime, L0_info.mtime, L0_info.ctime])

    target_info = file_info(l1_filename)
    target_timestamp = target_info.mtime

    if prereq_timestamp gt target_timestamp then begin    ; skip if L1 does not need to be regenerated
      mvn_sep_load,/l0,files = l0_files
      dprint,dlevel=1,'Generating L1 file: '+L1_filename
      prereq_info = file_checksum(prereq_files,/add_mtime)
      mvn_sep_var_save,l1_filename,prereq_info=prereq_info,description=description
      ;    mvn_mag_var_save
    endif  ; else begin
    ;    mvn_sep_var_restore,trange=tr ,prereq=prereq_info  ;,filename=l1_filename
    ;    printdat,prereq_info
    ;  endelse

    add_link = (mvn_pfp_file_retrieve('maven/pfp/.secure/.htaccess'))[0]

    mvn_sep_make_cdf_wrap,/cal,sepnum=1,trange=tr,source_files=l0_files,prereq_files=prereq_files,add_link=add_link,sw_version=sw_version
    mvn_sep_make_cdf_wrap,/cal,sepnum=2,trange=tr,source_files=l0_files,prereq_files=prereq_files,add_link=add_link,sw_version=sw_version
    mvn_sep_make_cdf_wrap,/raw,sepnum=1,trange=tr,source_files=l0_files,prereq_files=prereq_files,add_link=add_link,sw_version=sw_version
    mvn_sep_make_cdf_wrap,/raw,sepnum=2,trange=tr,source_files=l0_files,prereq_files=prereq_files,add_link=add_link,sw_version=sw_version


    if keyword_set(plotformat) then begin
      pf = str_sub(plotformat,'$NDAY',strtrim(ndaysload,2)+'day')
      fname = mvn_pfp_file_retrieve(pf,trange=tr[0],no_server=1,create_dir=1,valid_only=0,/daily_names)   ; generate plot file names - (doesn't matter if they exist)
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


end

