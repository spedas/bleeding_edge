;+
; PROCEDURE:
;         elf_write_data_availability_table
;
; PURPOSE:
;         Write to and update the data availability
;
; KEYWORDS:
;         tdate: time to be used for calculation
;                (format can be time string '2020-03-20'
;                or time double)
;         probe: probe name, probes include 'a' and 'b'
;         instrument: instrument name, insturments include 'epd', 'fgm', 'mrm'
;         data: structure containing the availability data, start times, stop
;               times and science zone 
;
; OUTPUT:
;
; EXAMPLE:
;         elf_write_data_availability_table, filename, data_avail, 'epd', 'a'
;         
;LAST EDITED: lauraiglesias4@gmail.com 05/18/21
;
;-
pro elf_write_data_availability_table, tdate, dt, filename, data_available, instrument, probe

  ; initialize parameters
  if undefined(filename) then begin
    print, 'You must provide a name for the csv file.'
    return
  endif
  if undefined(data_available) then begin
    print, 'You must provide data availability for the csv file.'
    return
  endif
  
  if undefined(dt) then dt=60. else dt=dt
  timespan, time_double(tdate)-dt*86400., dt
  trange=timerange()

  ; define local and remote paths
  local_path=!elf.LOCAL_DATA_DIR+'el'+probe+ '/data_availability/'
  remote_path=!elf.REMOTE_DATA_DIR+'el'+probe+ '/data_availability/'

    zone_names=['sasc','nasc','sdes','ndes', 'eq']  
    for i=0,n_elements(zone_names)-1 do begin
      current = where(data_available.zones eq zone_names[i])
      if current[0] ne -1 then begin
        newdat = {starttimes: data_available.starttimes[current], $
          endtimes: data_available.endtimes[current], dL:data_available.dL[current], medMLT:data_available.medMLT[current]}                
        ;writing the header. the position is added to the header
        if i eq 0 then pos = ' South Ascending'
        if i eq 1 then pos = ' North Ascending'
        if i eq 2 then pos = ' South Descending'
        if i eq 3 then pos = ' North Descending'
        if i eq 4 then pos = ' Equatorial'
        
        ;creating header and file
        header = 'ELFIN ' + strupcase(probe) + ' - '+ strupcase(instrument) + pos 
        this_file = filename + '_' + zone_names[i] +'.csv'
        
        ; Download CSV file
        paths = ''
        
        ; download data as long as no flags are set
        if file_test(local_path,/dir) eq 0 then file_mkdir2, local_path
        dprint, dlevel=1, 'Downloading ' + remote_path + this_file + ' to ' + local_path + this_file
        paths = spd_download(remote_file=this_file, remote_path=remote_path, $
            local_file=this_file, local_path=local_path, ssl_verify_peer=0, ssl_verify_host=0)
        if undefined(paths) or paths EQ '' then $
          dprint, devel=1, 'Unable to download ' + remote_file 
        
        ;making sure the file exists. if not, it will just create one
        existing = FILE_TEST(local_path+this_file)
        
        new_starttimes = newdat.starttimes
        new_endtimes = newdat.endtimes
        new_dL = newdat.dL
        new_medMLT = newdat.medMLT

        if existing GT 0 then begin
          olddat = READ_CSV(local_path+this_file, N_TABLE_HEADER = 2)
          ;finding the start/end index
          idx=where(time_double(olddat.field1) LT trange[0], ncnt)
          if ncnt GT 0 then begin
            starttimes=time_double(olddat.field1[idx])
            endtimes=time_double(olddat.field2[idx])
            dL=olddat.field3[idx]
            medMLT=olddat.field4[idx]
          endif 
        endif 

        append_array, starttimes, new_starttimes
        append_array, endtimes, new_endtimes
        append_array, dl, new_dl
        append_array, medMLT, new_medMLT

        ;sorting
        sorting  = sort(starttimes)
        starttimes = starttimes[sorting]
        endtimes = endtimes[sorting]
        dL = dL[sorting]
        medMLT = medMLT[sorting]
        UNDEFINE, sorting

        ;there shouldn't be any repeating times, but sometimes there are very minute differences in the start times, so we need this
        unique = uniq(time_string(starttimes))
        starttimes = starttimes[unique]
        endtimes = endtimes[unique]
        dL = dL[unique]
        medMLT = medMLT[unique]
        UNDEFINE, unique       
       
        write_csv, local_path+this_file, time_string(starttimes), time_string(endtimes), dL, medMLT, HEADER = ['tstart', 'tend', 'Lstart, Lend', 'median MLT'], TABLE_HEADER=header + ' Science Collections'
          
        ;taking note of the files we write to 
        append_array, data_written, this_file
        
        print, 'Finished Writing to File: ', this_file
        print, 'Last Entry: ', time_string(starttimes[-1])

      endif
      close, /all
      
    endfor
    
    foreach file, data_written do begin
      print, 'Data written to: ', local_path+file
    endforeach
    

end