; NAME: edit_dated_csv
;
; PURPOSE: Function to temporary read csv and remove duplicate times and then write 
;
; INPUT:
;    this_file   name of the csv file to be edited
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-11-28 10:09:38 -0800 (Tue, 28 Nov 2017) $
; $LastChangedRevision: 24352 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/common/elf_config_write.pro $
;

function edit_dated_csv, this_file
  ;reading the data
  olddat = READ_CSV(this_file, RECORD_START = 1)

  ;finding the start/end index
  olddat_doub = {name:'olddat_doub', starttimes: time_double(olddat.field1), endtimes: time_double(olddat.field2)}
  starttimes = [olddat_doub.starttimes, newdat.starttimes]
  endtimes = [olddat_doub.endtimes, newdat.endtimes]
  
  ;sorting
  starttimes = starttimes[uniq(starttimes, sort(starttimes))]
  endtimes = endtimes[uniq(starttimes, sort(starttimes))]

  ;checks
  ;print, 'new', time_string(newdat.starttimes)
  ;print, 'old', time_string(olddat.field1)
  ;print, 'written', time_string(starttimes), time_string(endtimes)

  ;rewriting existing file
  write_csv, this_file, time_string(starttimes), time_string(endtimes), HEADER = header
  print, 'Finished Writing to File:'
  close, /all
  return, n_elements(starttimes) - n_elements(olddat.field1)
END