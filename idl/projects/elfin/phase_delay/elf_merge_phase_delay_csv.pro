pro elf_merge_phase_delay_csv ; starttime, endtime
 
   elf_init
   sc=['a']
   ;tr=time_double(['2019-04-30', '2021-07-01/23:59'])
   tr=time_double(['2021-07-02', '2022-09-12/23:59'])
   ;tr=time_double(['2019-09-01', '2022-09-12/23:59'])
   ;tr=time_double(['2022-01-01', '2022-09-25/23:59'])
   for i=0,n_elements(sc) -1 do begin
    
     probe = sc[i]

     archive_path = !elf.local_data_dir+'el'+sc[i]+'/calibration_files/pdpcsv_archive'
     cd, archive_path
     spawn, 'ls', csv_list
help, csv_list
stop   
     ; check that there are files
     if csv_list[0] EQ '' then continue
     
     ; read main csv     
     csv_file='el'+sc[i]+'_epde_phase_delays.csv
     csv_path=!elf.local_data_dir+'el'+probe+'/calibration_files/'
     dat = read_csv(!elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'+csv_file, $
       header = cols, types = ['String', 'String', 'Float', 'Float','Float','Float','Float','Float'])
     cd, csv_path
     ;fileresult=FILE_SEARCH(csv_file)
     ;if size(fileresult,/dimen) eq 1 then FILE_DELETE,fitsfilename,/RECURSIVE ; delete old folder
     ;file_copy,'Fitplots','Fitplots_'+filename,/OVERWRITE,/RECURSIVE

     tidx=where(time_double(dat.field1) LT tr[0] OR time_double(dat.field1) GE tr[1], ncnt)
     fidx=where(time_double(dat.field1) GE tr[0] AND time_double(dat.field1) LT tr[1], ncnt)
tidx1=indgen(n_elements(dat.field1))
help, dat
help, fidx
help, tidx
print, n_elements(fidx) + n_elements(tidx)
stop
    ; create struct
     if ncnt GT 0 then begin
       tstart=dat.field1[tidx]
       tend=dat.field2[tidx]
       dSectr2add=fix(dat.field3[tidx])
       dPhAng2add=dat.field4[tidx]
       LatestMedianSectr=fix(dat.field5[tidx])
       LatestMedianPhAng=dat.field6[tidx]
       badFlag=fix(dat.field7[tidx])
       SectNum=fix(dat.field8[tidx])
       timeofprocessing=dat.field9[tidx]
     endif else begin
       tstart=dat.field1
       tend=dat.field2
       dSectr2add=fix(dat.field3)
       dPhAng2add=dat.field4
       LatestMedianSectr=fix(dat.field5)
       LatestMedianPhAng=dat.field6
       badFlag=fix(dat.field7)
       SectNum=fix(dat.field8)
       timeofprocessing=dat.field9      
     endelse

     ; LOOP for each time stamped csv file
     for j=0,n_elements(csv_list)-1 do begin
       this_file=archive_path + '/' + csv_list[j]
       if csv_list[j] EQ 'ela_epde_phase_delays_20230806.csv' then continue
       newdat = read_csv(this_file)
       ; append struct
       append_array, tstart, newdat.field1[0]
       append_array, tend, newdat.field1[1]
       append_array, dSectr2add, fix(newdat.field1[2])
       append_array, dPhAng2add, newdat.field1[3]
       append_array, LatestMedianSectr, fix(newdat.field1[4])
       append_array, LatestMedianPhAng, newdat.field1[5]
       append_array, badflag, fix(newdat.field1[6])
       append_array, SectNum, fix(newdat.field1[7])
       append_array, timeofprocessing, newdat.field1[8]
     endfor ; end of file loop

     ; TO DO:
     ; Need to either first remove any entries within the start/end
     ; of this run and then append OR
     ; Order first by timeofprocessing and then uniq/sort     
     ; time order and remove duplicates
     idx=UNIQ(tstart,SORT(tstart))
     newdat= { $
     tstart:tstart[idx],$
     tend:tend[idx],$
     dSectr2add:fix(dSectr2add[idx]),$
     dPhAng2add:dPhAng2add[idx],$
     LatestMedianSectr:fix(LatestMedianSectr[idx]),$
     LatestMedianPhAng:LatestMedianPhAng[idx],$
     badFlag:fix(badFlag[idx]),$
     SectNum:fix(Sectnum[idx]),$
     timeofprocessing:timeofprocessing[idx]}
help, tstart
help, newdat
help, idx
stop

     ; save original file before copying
     csvfile=csv_path+csv_file
     csv_file_save='el'+sc[i]+'_epde_phase_delays_sav.csv
     csvfile_sav=csv_path+csv_file_save
     print, 'Copying '+csvfile+' to '+csvfile_save
stop
     file_copy,csvfile,csvfile_save,/OVERWRITE
     ; write csv file
     print, 'Writing csv: '+newfile
stop
     write_csv, newfile, newdat, header=cols
   
     ; remove files
     for j=0,n_elements(csv_list)-1 do begin
       this_file=archive_path + '/' + csv_list[j]
       cmd = 'rm '+this_file
       spawn, cmd
     endfor 
     print, 'Removed individual csv'

     ; remove tempdirs
     ;temp_dir=!elf.local_data_dir+'el'+sc[i]+'/phasedelayplots/temp_*'
     ;cmd = 'rm -rf '+temp_dir
     ;spawn, cmd
     ;print, 'Removed temp_ directories'
     
   endfor   ; end of s/c loop
print, 'Done'   
end