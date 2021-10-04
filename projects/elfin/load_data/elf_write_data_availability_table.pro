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
pro elf_write_data_availability_table, filename, data_available, instrument, probe

  ; initialize parameters
  if undefined(filename) then begin
    print, 'You must provide a name for the csv file.'
    return
  endif
  if undefined(data_available) then begin
    print, 'You must provide data availability for the csv file.'
    return
  endif

  ; get authorization information
;  if undefined(user) OR undefined(pw) then authorization = elf_get_authorization()
;  user=authorization.user_name
;  pw=authorization.password
;  ; only query user if authorization file not found
;  If user EQ '' OR pw EQ '' then begin
;    print, 'Please enter your ELFIN user name and password'
;    read,user,prompt='User Name: '
;    read,pw,prompt='Password: '
;  endif

  ; define local and remote paths
  local_path=!elf.LOCAL_DATA_DIR+'el'+probe+ '/data_availability/'
  remote_path=!elf.REMOTE_DATA_DIR+'el'+probe+ '/data_availability/'

    zone_names=['sasc','nasc','sdes','ndes', 'eq']  
    for i=0,n_elements(zone_names)-1 do begin
      current = where(data_available.zones eq zone_names[i])
      if current[0] ne -1 then begin
        
        newdat = {name:'newdat', starttimes: data_available.starttimes[current], $
          endtimes: data_available.endtimes[current], dL:data_available.dL[current], medMLT:data_available.medMLT[current]}
                
        ;writing the header. the position is added to the header
        if i eq 0 then pos = ' South Ascending'
        if i eq 1 then pos = ' North Ascending'
        if i eq 2 then pos = ' South Descending'
        if i eq 3 then pos = ' North Descending'
        if i eq 4 then pos = ' Equatorial'

        ;checking that equatorial collections are only found in mrm 
        ;if strmid(filename, 4, 3) ne 'mrm' and i eq 4 then print, 'WARNING, EQUATORIAL CROSSINGS FOUND IN ', strmid(filename, 4, 3)
        
        ;creating header and file
        header = 'ELFIN ' + strupcase(probe) + ' - '+ strupcase(instrument) + pos 
        this_file = filename + '_' + zone_names[i] +'.csv'
        
        ; Download CSV file
        paths = ''
        
        ; download data as long as no flags are set
        if file_test(local_path,/dir) eq 0 then file_mkdir2, local_path
        dprint, dlevel=1, 'Downloading ' + remote_path + this_file + ' to ' + local_path + this_file
        paths = spd_download(remote_file=this_file, remote_path=remote_path, $
            local_file=this_file, local_path=local_path, ssl_verify_peer=1, ssl_verify_host=1)
        if undefined(paths) or paths EQ '' then $
          dprint, devel=1, 'Unable to download ' + remote_file 
        
        ;making sure the file exists. if not, it will just create one
        existing = FILE_TEST(local_path+this_file)
        
        if existing eq 0 then begin
          starttimes = newdat.starttimes
          endtimes = newdat.endtimes
          dL = newdat.dL
          medMLT = newdat.medMLT
          
        endif else begin 
          olddat = READ_CSV(local_path+this_file, N_TABLE_HEADER = 2)
          ;finding the start/end index
          olddat_doub = {name:'olddat_doub', starttimes: time_double(olddat.field1), $
             endtimes: time_double(olddat.field2), dL:olddat.field3, medMLT:olddat.field4}
          ;UNDEFINE, olddat
          
          if n_elements(time_double(olddat.field1)) ne n_elements(time_double(olddat.field3)) AND n_elements(time_double(olddat.field1)) ne n_elements(time_double(olddat.field4)) then stop
          

          no_overlap = where(olddat_doub.starttimes lt floor(newdat.starttimes[0]) or olddat_doub.starttimes gt floor(newdat.starttimes[-1]))

          starttimes = [olddat_doub.starttimes[no_overlap], newdat.starttimes]
          endtimes = [olddat_doub.endtimes[no_overlap], newdat.endtimes]
          dL = [olddat_doub.dL[no_overlap], newdat.dL]
          medMLT = [olddat_doub.medMLT[no_overlap], newdat.medMLT]
        
         
        endelse 
  
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