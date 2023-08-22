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

  exec_start=systime()
  
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
  
;****************************
;
; MAIN LOOP for SPACECRAFT
; 
;****************************
  sc=['a','b']
  for isc=0,n_elements(sc)-1 do begin
    probe = sc[isc]
    if probe EQ 'a' AND starttime GT time_double('2022-09-12/00:00:00') then begin
      dprint, 'There is no valid orbit or EPD data past 2022-09-11.'
      return
    endif

; *** data availability shouldn't be updated here. it should be a daily cronjob ***
; *** it's end of mission so the data availability shouldn't need an update
;    if keyword_set(create_avai) then begin
;      days = (time_double(endtime) - time_double(starttime))/(60.*60.*24.)
;      elf_update_data_availability_table, endtime, probe=probe, instrument='epd', days = days
;    endif
;    if update_avai eq 1 then begin
;      this_remote_path=!elf.remote_data_dir+'el'+probe+'/data_availability/'
;      this_remote_file=['el'+probe+'_epd_all.csv','el'+probe+'_epd_nasc.csv','el'+probe+'_epd_ndes.csv','el'+probe+'_epd_sasc.csv','el'+probe+'_epd_sdes.csv']
;      this_local_path=!elf.local_data_dir+'el'+probe+'/data_availability/'
;      for file_idx = 0,n_elements(this_remote_file)-1 do begin
;        ;stop
;        paths = ''
;        paths = spd_download(remote_file=this_remote_file[file_idx], remote_path=this_remote_path, $
;                              local_file=this_remote_file[file_idx], local_path=this_local_path)
;      endfor    
;    endif
    
;    if update_phasedelay eq 1 then begin
;      this_remote_path=!elf.remote_data_dir+'el'+probe+'/calibration_files/'
;      this_remote_file='el'+probe+'_epde_phase_delays.csv'      
;      this_local_path=!elf.local_data_dir+'el'+probe+'/calibration_files/'      
;      paths = spd_download(remote_file=this_remote_file, remote_path=this_remote_path, $
;          local_file=this_remote_file, local_path=this_local_path)
;    endif
       
; ***** once data availability is correct and updated then this section of code can be re-instated *****  
;    allszs = read_csv(!elf.LOCAL_DATA_DIR + 'el' +probe+ '/data_availability/el'+probe+'_epd_data_availability.csv', n_table_header = 1)
;    szs_inrange = where(time_double(allszs.field1) ge time_double(starttime) and time_double(allszs.field1) le time_double(endtime), count)

;    if count eq 0 then begin
;      print, probe+' Sci zone not found, try another one'
;      ; jwu when ela doesn't have sci zone but elb has, return has issue 
;      continue
;    endif

    ;-----------------------------
    ; DETERMINE Science Zones
    ;------------------------------
    thistr=[starttime,endtime]
    elf_load_epd, probes=probe, trange=thistr, datatype='pef', level='l1', type='nflux', no_download=no_downlaod
    get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
    if (size(pef_nflux, /type)) NE 8 then begin
      undefine, pef_nflux
      del_data, '*.*'
      return
    endif
    ; figure out science zones
    if n_elements(pef_nflux.x) GT 2 then begin
      tdiff = pef_nflux.x[1:n_elements(pef_nflux.x)-1] - pef_nflux.x[0:n_elements(pef_nflux.x)-2]
      idx = where(tdiff GT 270., ncnt)
      append_array, idx, n_elements(pef_nflux.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone
    endif else begin
      ; ********* TO DO: might need to account for n_elements(pef_nflux.x) EQ 2
      ncnt=0
    endelse
    if ncnt EQ 0 then begin
      ; if ncnt is zero then there is only one science zone for this time frame
      sz_starttimes=[pef_nflux.x[0]]
      sz_endtimes=pef_nflux.x[n_elements(pef_nflux.x)-1]
      ts=time_struct(sz_starttimes[0])
      te=time_struct(sz_endtimes[0])
    endif else begin
      for sz=0,ncnt do begin ;changed from ncnt-1
        if sz EQ 0 then begin
          this_s = pef_nflux.x[0]
          sidx = 0
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
        endif else begin
          this_s = pef_nflux.x[idx[sz-1]+1]
          sidx = idx[sz-1]+1
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
        endelse
        if (this_e-this_s) lt 15. then continue ; ignore if lt 3 spins
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
      endfor ; end of sz determination zone loop
    endelse
    if undefined(sz_starttimes) then begin
      print, 'No science zones'
      return
    endif
    num_szs=n_elements(sz_starttimes)

    szs_st = sz_starttimes
    szs_en = sz_endtimes

    elf_load_state, probes=probe, trange = [szs_st[0], szs_en[n_elements(szs_en)-1]]
    get_data, 'el'+probe+'_pos_gei', data=dat_gei
    cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
    cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
    cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM
    elf_mlt_l_lat,'el'+probe+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0 ;;subroutine to calculate mlt,l,mlat under dipole configuration
    get_data, 'el'+probe+'_pos_sm', data=elfin_pos
    get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
    store_data,'el'+probe+'_MLAT_dip',data={x:elfin_pos.x,y:lat0*180./!pi}

    ; ***************************************
    ; 
    ; MAIN LOOP for PHASE DELAY calculations
    ; 
    ;****************************************
    Echannels = [0, 3, 6, 9]
    for i =0, n_elements(szs_st)-1 do begin
      tstart = szs_st[i]
      tend = szs_en[i]

      ; setup working area
      tstart_str=time_string(tstart, format=6)
      tempfolder= !elf.LOCAL_DATA_DIR + 'el' +probe+ '/phasedelayplots/temp_' + tstart_str
      fileresult=FILE_SEARCH(tempfolder)
      if size(fileresult,/dimen) eq 0 then FILE_MKDIR,tempfolder
      cd, tempfolder
;      stop
      elf_phase_delay_AUTO, probe = probe, Echannels = Echannels, sstart = tstart, send = tend, badflag = badflag
      if badflag eq -99 then continue
      elf_mlt_l_lat,'el'+probe+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0
      get_data, 'el'+probe+'_pos_sm', data=elfin_pos
      get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
      store_data,'el'+probe+'_MLAT_dip',data={x:elfin_pos.x,y:lat0*180./!pi}
      get_data,'el'+probe+'_MLAT_dip',data=this_lat

      ; based on latitude and whether s/c is ascending or descending
      ; determine zone name
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

      ; find out what 1.5 hour interval this time fits into
      ; this will either be 1 or 2 (2 if the science zone is in the last 30 minutes of the 1.5 hr interval
      idx=where(time_double(tstart) GE tstarts AND time_double(tstart) LE tends, ncnt)
      print, ncnt

      ; ******************************************************
      ; LOOP for each 1.5 hour interval for each science zone
      ;*******************************************************
      if ncnt GT 0 then begin
        for k=0, ncnt-1 do begin
          ; this is the first png file in the 1.5 hr 
          filename='el'+probe+'_pdp_'+ filetime + '_' + file_lbl[idx[k]] + sz_name
          file_path = !elf.LOCAL_DATA_DIR + 'el' +probe+ '/phasedelayplots' + '/' + strmid(filetime, 0, 4) + '/' + strmid(filetime, 4, 2) + '/' + strmid(filetime, 6, 2) + '/'
          fileresult=FILE_SEARCH(file_path)
          if size(fileresult,/dimen) eq 0 then FILE_MKDIR,file_path
          ;file_mkdir, file_path
          fullfilename=file_path + filename 
          temp_path = !elf.LOCAL_DATA_DIR + 'el' +probe+ '/phasedelayplots/temp_' + tstart_str 
          fileresult=FILE_SEARCH(temp_path)
          if size(fileresult,/dimen) eq 0 then FILE_MKDIR,temp_path
          ;cd, tempfolder

          ;file_mkdir, temp_path
          fits_path = temp_path + '/Fitplots'
          fileresult=FILE_SEARCH(fits_path)
          if size(fileresult,/dimen) eq 0 then FILE_MKDIR,fits_path

          ;file_mkdir, fits_path
          fitsfilename = fits_path + '/bestfit.png'
          ;cd, fits_path
          dprint,fitsfilename
          dprint,fullfilename
          spawn,'pwd',pwdname
          dprint,pwdname
          file_copy,fitsfilename,fullfilename+'.png',/OVERWRITE
          
          ; if this zone rolls into next hour create 2nd png file
          sthr=strmid(tstart, 11, 2)
          enhr=strmid(tend, 11, 2)
          if sthr NE enhr then begin
            if idx[k] LT 23 then begin
              filename2='el'+probe+'_pdp_'+ filetime + '_' + file_lbl[idx[k]+1] + sz_name
              fullfilename2=file_path + filename2
              file_copy,fitsfilename,fullfilename2+'.png',/OVERWRITE
              ;file_copy,'Fitplots/bestfit.png',fullfilename2+'.png',/OVERWRITE
            endif
          endif
          if verbosefig eq 1 then begin
            ;fileresult=FILE_SEARCH('Fitplots_'+filename)
            ;if size(fileresult,/dimen) eq 1 then FILE_DELETE,'Fitplots_'+filename,/RECURSIVE ; delete old folder
            fileresult=FILE_SEARCH(fitsfilename)
            if size(fileresult,/dimen) eq 1 then FILE_DELETE,fitsfilename,/RECURSIVE ; delete old folder
            ;file_copy,'Fitplots','Fitplots_'+filename,/OVERWRITE,/RECURSIVE
            file_copy,fitsfilename,fullfilename+'.png',/OVERWRITE
            if ~undefined(filename2) then begin              
              ;fileresult2=FILE_SEARCH(fitsfilename)
              ;if size(fileresult,/dimen) eq 1 then FILE_DELETE,fitsfilename,/RECURSIVE ; delete old folder
              ;fileresult2=FILE_SEARCH('Fitplots_'+filename)
              ;if size(fileresult2,/dimen) eq 1 then FILE_DELETE,'Fitplots_'+filename2,/RECURSIVE ; delete old folder
              ;file_copy,'Fitplots','Fitplots_'+filename2,/OVERWRITE,/RECURSIVE
            endif
          endif

          print, 'Created: ' + fullfilename + '.png'
          if ~undefined(filename2) then print, 'Created: ' + fullfilename2 + '.png'

          ;temp_path = !elf.LOCAL_DATA_DIR + 'el' +probe+ '/phasedelayplots/temp_' + tstart_str
          ;cd, !elf.LOCAL_DATA_DIR + 'el' +probe+ '/phasedelayplots
          ;cmd = 'rm -rf '+temp_path
          ;spawn, cmd
 
        endfor  ;  end of 1.5 hour loop
        
      endif

    endfor    ; end of science zone loop

    del_data,'*'
    undefine, pef_nflux
    undefine, sz_starrtimes
    undefine, sz_endtimes
    
  endfor ; end of probe loop
  
  exec_end=systime()
  print, num_szs
  print, exec_start
  print, exec_end
  ;FILE_DELETE,'Fitplots',/RECURSIVE ; delete old folder
  print, 'Done'
 
end
