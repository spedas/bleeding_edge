function edit_dated_csv, this_file, header, newdat, instrument
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