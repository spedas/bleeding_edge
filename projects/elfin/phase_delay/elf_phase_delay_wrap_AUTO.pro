;+
; FUNCTION:
;         phase_delay_wrap_AUTO
;
; PURPOSE:
;         A difference in attitude creates a delay in the pitch angles collected in the ascending vs
;         descending parts of the satellites spin. Correcting the difference in angles reverses distortion
;         in the summary plots.
;         
;         This code serves as the wrapper for elf_phase_delay_AUTO.
;         Elf_phase_delay_AUTO obtains corrected phase delay values (both sectors and phase angles)
;         for either a singular science zone or range of science zones over multiple days, as well as
;         note with a flag whether the values are reasonable enough to be used (flag = 0) or should be
;         replaced with the mean value of the few previous science zones (bad flag = any nonzero value).
;         The values and flag are written to the elx_epde_phase_delays.csv, which is then updated on the
;         server to be used in summary plots and relevant science aims.
;         NAMING CONVENTION
;
; KEYWORDS:
;         \pickrange = it will let you pick the range through a prompt. you do not have to edit szstofit in order for it to work.
;         \update_avai = grab epd availablity file from server
;         \update_phasedelay = grab phase delay file from server
;         \verbosefig  - 0: (default) only save bestfit figure
;                        1: (default) save all figures in Fitplots
;
; OUTPUT:
;         PHASE DELAY PLOT AND CSV UPDATE.
;
; EXAMPLE:
;         elf_phase_delay_wrap_AUTO,'2022-05-05'
;         elf_phase_delay_wrap_AUTO,/pickrange
;         2022-01-15/12:04:58
;         2022-01-15/12:24:56
;         2022-03-16/08:39:38
;         2022-03-16/08:42:38
;
;
;VERSION LAST EDITED: akroosnovo@gmail.com, jwu@epss.ucla.edu 02/27/2022

pro elf_phase_delay_wrap_AUTO, date, verbosefig = myverbosefig, create_avai = mycreate_avai, update_avai = myupdate_avai, pickrange = mypickrange, update_phasedelay = myupdate_phasedelay

  if ~keyword_set(myverbosefig) then verbosefig=0 else verbosefig=myverbosefig
  if ~keyword_set(myupdate_avai) then update_avai=0 else update_avai=myupdate_avai
  if ~keyword_set(mypickrange) then pickrange=0 else pickrange=mypickrange 
  if ~keyword_set(myupdate_phasedelay) then update_phasedelay=0 else update_phasedelay=myupdate_phasedelay
  if ~keyword_set(mycreate_avai) then create_avai=0 else create_avai=mycreate_avai

  elf_init
  askprompt:
  if undefined(date) or pickrange eq 1 then begin
    ;start prompt
    userprobe = ''
    starttime = ''
    endtime = ''
    read, userprobe, PROMPT='Probe: '
    read, starttime, PROMPT = 'Enter Start Time [YYYY-MM-DD/HH:MM:DD]: '
    read, endtime, PROMPT = 'Enter End Time [YYYY-MM-DD/HH:MM:DD]: '
    timeduration=time_double(endtime)-time_double(starttime)
    timespan,starttime,timeduration,/seconds ; set the analysis time interval
  endif else begin
    starttime = time_string(time_double(date))
    timespan,starttime,1,/day
    endtime=time_string(time_double(starttime)+86400.0d0)
  endelse
  
  sc=['a','b']
  for isc=0,1 do begin
    probe = sc[isc]
    if ~undefined(userprobe) then begin
      if probe ne userprobe then continue ; if userprobe defined 
    endif 
    if probe EQ 'a' AND starttime GT time_double('2022-09-12/00:00:00') then begin
      dprint, 'There is no valid orbit or EPD data past 2022-09-11.'
      return
    endif

    if keyword_set(create_avai) then begin
      days = (time_double(endtime) - time_double(starttime))/(60.*60.*24.)
      elf_update_data_availability_table, endtime, probe=probe, instrument='epd', days = days
    endif


    if update_avai eq 1 then begin
      this_remote_path=!elf.remote_data_dir+'el'+probe+'/data_availability/'
      this_remote_file=['el'+probe+'_epd_all.csv','el'+probe+'_epd_nasc.csv','el'+probe+'_epd_ndes.csv','el'+probe+'_epd_sasc.csv','el'+probe+'_epd_sdes.csv']
      this_local_path=!elf.local_data_dir+'el'+probe+'/data_availability/'
      for file_idx = 0,n_elements(this_remote_file)-1 do begin
        ;stop
        paths = ''
        paths = spd_download(remote_file=this_remote_file[file_idx], remote_path=this_remote_path, $
                              local_file=this_remote_file[file_idx], local_path=this_local_path)
      endfor    
    endif
    
    
    if update_phasedelay eq 1 then begin
      this_remote_path=!elf.remote_data_dir+'el'+probe+'/calibration_files/'
      this_remote_file='el'+probe+'_epde_phase_delays.csv'
      this_local_path=!elf.local_data_dir+'el'+probe+'/calibration_files/'      
      paths = spd_download(remote_file=this_remote_file, remote_path=this_remote_path, $
          local_file=this_remote_file, local_path=this_local_path)
    endif
      
    cwdirname=!elf.LOCAL_DATA_DIR + 'el' +probe+ '/phasedelayplots'
    cd,cwdirname
    foldername= 'temp'
    fileresult=FILE_SEARCH(foldername)
    if size(fileresult,/dimen) eq 0 then FILE_MKDIR,foldername
    cd,cwdirname+'/'+foldername
   
    allszs = read_csv(!elf.LOCAL_DATA_DIR + 'el' +probe+ '/data_availability/el'+probe+'_epd_data_availability.csv', n_table_header = 1)
    szs_inrange = where(time_double(allszs.field1) ge time_double(starttime) and time_double(allszs.field1) le time_double(endtime), count)

    if count eq 0 then begin
      print, probe+' Sci zone not found, try another one'
      ; jwu when ela doesn't have sci zone but elb has, return has issue 
      continue
    endif
    szs_st = allszs.field1[szs_inrange]
    szs_en = allszs.field2[szs_inrange]
    probes = make_array(n_elements(szs_inrange), /string, VALUE = probe)

    elf_load_state, probes=probe, trange = [szs_st[0], szs_en[n_elements(szs_en)-1]]
    get_data, 'el'+probe+'_pos_gei', data=dat_gei
    cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
    cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
    cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM
    elf_mlt_l_lat,'el'+probe+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0 ;;subroutine to calculate mlt,l,mlat under dipole configuration
    get_data, 'el'+probe+'_pos_sm', data=elfin_pos
    get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
    store_data,'el'+probe+'_MLAT_dip',data={x:elfin_pos.x,y:lat0*180./!pi}

    i = 0
    Echannels = [0, 3, 6, 9]
    for i =0, n_elements(szs_st)-1 do begin
      tstart = szs_st[i]
      tend = szs_en[i]
      probe = probes[i]
      elf_phase_delay_AUTO, probe = probe, Echannels = Echannels, sstart = tstart, send = tend, badflag = badflag
      if badflag eq -99 then continue
      elf_mlt_l_lat,'el'+probe+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0
      get_data, 'el'+probe+'_pos_sm', data=elfin_pos
      get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
      store_data,'el'+probe+'_MLAT_dip',data={x:elfin_pos.x,y:lat0*180./!pi}
      get_data,'el'+probe+'_MLAT_dip',data=this_lat
      ;lat_idx=where(this_lat.x GE tstart AND this_lat.x LE tend, ncnt)

      sz_name=''
      if size(this_lat, /type) EQ 8 then begin ;change to num_scz?
        sz_tstart=time_string(tstart)
        sz_lat=this_lat.y
        median_lat=median(sz_lat)
        dlat = sz_lat[1:n_elements(sz_lat)-1] - sz_lat[0:n_elements(sz_lat)-2]
        if median_lat GT 0 then begin
          if median(dlat) GT 0 then sz_plot_lbl = ', North Ascending' else $
            sz_plot_lbl = ', North Descending'
          if median(dlat) GT 0 then sz_name = '_nasc' else $
            sz_name = '_ndes'
        endif else begin
          if median(dlat) GT 0 then sz_plot_lbl = ', South Ascending' else $
            sz_plot_lbl = ', South Descending'
          if median(dlat) GT 0 then sz_name = '_sasc' else $
            sz_name =  '_sdes'
        endelse
        print, sz_name
      endif

      ;create 1.5 hr web page time start and stop times
      filetime=time_string(tstart, format=2, precision=-3)
      print, filetime     

      tstarts=[]
      tends=[]
      for j=0,23,1 do append_array, tstarts,time_double(filetime)+j*3600.
      tends=tstarts+5400.
      ; fix final tend from 24:30 to be 24:00
      tends[23]=tstarts[0]+86400.

      ;create array of file labels
      file_lbl=strmid(time_string(tstarts),11,2)

      ; first find out what 1.5 hour interval this time fits into
      idx=where(time_double(tstart) GE tstarts AND time_double(tstart) LE tends, ncnt)
      ;idx=where(time_double(tstart) GE tstarts[j] AND time_double(tstart) LE tends[j], ncnt)
      print, ncnt

      if ncnt GT 0 then begin
        for k=0, ncnt-1 do begin

          filename='el'+probe+'_pdp_'+ filetime + '_' + file_lbl[idx[k]] + sz_name

          file_path = !elf.LOCAL_DATA_DIR + 'el' +probe+ '/phasedelayplots' + '/' + strmid(filetime, 0, 4) + '/' + strmid(filetime, 4, 2) + '/' + strmid(filetime, 6, 2) + '/'
          file_mkdir, file_path

          file_copy,'Fitplots/bestfit.png',filename+'.png',/OVERWRITE

          sthr=strmid(tstart, 11, 2)
          enhr=strmid(tend, 11, 2)
          if sthr NE enhr then begin
            if idx[k] LT 23 then begin
              filename2='el'+probe+'_pdp_'+ filetime + '_' + file_lbl[idx[k]+1] + sz_name
              file_copy,'Fitplots/bestfit.png',filename2+'.png',/OVERWRITE
            endif
          endif
          if verbosefig eq 1 then begin
            fileresult=FILE_SEARCH('Fitplots_'+filename)
            if size(fileresult,/dimen) eq 1 then FILE_DELETE,'Fitplots_'+filename,/RECURSIVE ; delete old folder
            file_copy,'Fitplots','Fitplots_'+filename,/OVERWRITE,/RECURSIVE

            if ~undefined(filename2) then begin              
              fileresult2=FILE_SEARCH('Fitplots_'+filename2)
              if size(fileresult2,/dimen) eq 1 then FILE_DELETE,'Fitplots_'+filename2,/RECURSIVE ; delete old folder
              file_copy,'Fitplots','Fitplots_'+filename2,/OVERWRITE,/RECURSIVE
            endif

          endif

          print, filename + '.png'
          if ~undefined(filename2) then print, filename2 + '.png'

        endfor
      endif

    endfor

  endfor ; end of probe loop
  ;FILE_DELETE,'Fitplots',/RECURSIVE ; delete old folder
  print, 'Done'
 
end
