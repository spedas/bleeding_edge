pro phase_delay_wrap_a, pickrange = pickrange, create_all = create_all, reprocess = reprocess, badFlag = badFlag
  
  CD, 'C:\Users\ELFIN\IDLWorkspace\spedas\idl\projects\elfin\idlphasedelays'
  
  ; \pickrange = it will let you pick the range through a prompt. you do not have to edit szstofit in order for it to work.
  ; \create_all = creates el*_epd_all. only run once a day to save time
  ; \reprocess = reprocesses old szs. must edit szstofit in order to work.
  
  if keyword_set(create_all) or keyword_set(pickrange) then begin
    ;start prompt
    probe = ''
    starttime = ''
    endtime = ''
    read, probe, PROMPT='Probe: '
    ;read, dSectr2add, PROMPT='IG, Sector: '
    ;read, dPhAng2add, PROMPT='IG Phase Angle: '
    read, starttime, PROMPT = 'Enter Start Time [YYYY-MM-DD/HH:MM:DD]: '
    read, endtime, PROMPT = 'Enter End Time [YYYY-MM-DD/HH:MM:DD]: '
  endif
  
  
  if keyword_set(create_all) then begin
    days = (time_double(endtime) - time_double(starttime))/(60.*60.*24.)
    elf_update_data_availability_table, endtime, probe=probe, instrument='epd', days = days
  endif
  
  
  if keyword_set(pickrange) then begin
    
    allszs = read_csv('C:\Users\ELFIN\data\elfin\el'+probe+'\data_availability\el'+probe+'_epd_all.csv', n_table_header = 2)
    
    szs_inrange = where(time_double(allszs.field1) ge time_double(starttime) and time_double(allszs.field1) le time_double(endtime))
    
    szs_st = allszs.field1[szs_inrange]
    szs_en = allszs.field2[szs_inrange]
    probes = make_array(n_elements(szs_inrange), /string, VALUE = probe)
    
    ;stop
  endif else if keyword_set(reprocess) then begin

    observed_szs = read_csv('szstofit.csv', n_table_header = 1)
    szs_st = time_string(time_double(observed_szs.field1))
    szs_en = time_string(time_double(observed_szs.field2))
    old_st = time_string(time_double(observed_szs.field3))
    old_en =  time_string(time_double(observed_szs.field4))
    probes = observed_szs.field5
  endif else begin
 
    observed_szs = read_csv('szstofit.csv', n_table_header = 1)
    szs_st = time_string(time_double(observed_szs.field1)-60)
    szs_en = time_string(time_double(observed_szs.field2)+60)
    probes = observed_szs.field3
    
  endelse
  
  
  i = 0
  ;Echannels = [3, 6, 9, 12]
  Echannels = [0, 3, 6, 9]
  while i le n_elements(szs_st)-1 do begin
    tstart = szs_st[i]
    tend = szs_en[i]
    probe = probes[i]
    ;stop
    if keyword_set(reprocess) then begin
      elf_phase_delay_auto_new_a, probe = probe, Echannels = Echannels, sstart = tstart, send = tend, badFlag = badFlag, soldtimes = [old_st[i], old_en[i]]
    endif else begin
      elf_phase_delay_auto_new_a, probe = probe, Echannels = Echannels, sstart = tstart, send = tend, badFlag = badFlag, /pick_times
    endelse
    userin = ' '
    read, userin, PROMPT='Redo: '
    
    if userin ne 'y' then begin
      
      saveplotq = ' '
      read, saveplotq, PROMPT='Would you like to save the most recent fit plot as a png file? [y/n] '
      
      if saveplotq ne 'n' then begin 
        ;save png here of final fit (not being redone)
        if badFlag eq 0 then begin
          filetime=time_string(tstart, format=2, precision=-1)
          filename='el'+probe+'_pdp_'+ filetime
          filepath = !elf.LOCAL_DATA_DIR + 'el' +probe+ '/' +'phasedelayplots' + '/' + strmid(filetime, 0, 4) + '/' + strmid(filetime, 4, 2) + '/'
          xyouts,  .65, .015, 'Created: '+systime(),/normal
          ;xyouts, .45, .95, 'Final Phase Delay Fit, ' + probe
          makepng, filepath + filename
        
        endif else begin
          filetime=time_string(tstart, format=2, precision=-1)
          filename='el'+probe+'_pdp_'+ filetime + '_bad'
          filepath = !elf.LOCAL_DATA_DIR + 'el' +probe+ '/' +'phasedelayplots' + '/' + strmid(filetime, 0, 4) + '/' + strmid(filetime, 4, 2) + '/'
          xyouts,  .65, .015, 'Created: '+systime(),/normal
          makepng, filepath + filename
        endelse
        print, 'Created png of phase delay fit plot: ' +filename
     endif
      
    endif
    
    
    if userin ne 'y' then $
      i = i + 1
    endwhile 
  print, 'Done'
end
