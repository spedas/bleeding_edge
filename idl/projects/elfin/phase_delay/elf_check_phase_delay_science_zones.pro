pro elf_check_phase_delay_science_zones, probe=probe
; this routine removes duplicates and sorts the time
; it also writes a '_new.csv' file
  if ~keyword_set(probe) then probe = 'a' else probe=probe

  ; download and read the phase delay file
  phase_delays=elf_get_phase_delays(no_download=nodownload, probe=probe, $
    instrument=instrument)
  starttimes=time_double(phase_delays.starttimes)
  endtimes=time_double(phase_delays.endtimes)
  orig_starttimes=time_string(starttimes)
  orig_endtimes=time_string(endtimes)
  ;remove duplicates and sort
  starttimes = starttimes[UNIQ(starttimes, SORT(starttimes))]
  ridx=UNIQ(starttimes, SORT(starttimes))
  starttimes=starttimes[ridx]
  endtimes=endtimes[ridx]
  sect2add=phase_delays.sect2add[ridx]
  phang2add=phase_delays.phang2add[ridx]
  lastestmediansectr=phase_delays.lastestmediansectr[ridx]
  latestmedianphang=phase_delays.latestmedianphang[ridx]
  badflag=phase_delays.badflag[ridx]
  sectnum=phase_delays.sectnum[ridx]
  timeofprocessing=phase_delays.timeofprocessing[ridx]
  newdat={starttimes:starttimes, $
    endtimes:endtimes, $
    sect2add:sect2add, $
    phang2add:phang2add, $
    lastestmediansectr: lastestmediansectr, $
    latestmedianphang:latestmedianphang, $
    badflag:badflag, $
    sectnum:sectnum, $
    timeofprocessing:timeofprocessing }

  ; check for starttimes that are within a minute of previous starttimes
  ; (this might occur in the earlier mission dates when phase delays were
  ; still being developed)
  npts=n_elements(starttimes)
  tdiff=starttimes[1:npts-1]-starttimes[0:npts-2]
  idx = where(tdiff LT 60, ncnt)
  if ncnt GT 0 then begin
    idx=idx+1
    iarr=indgen(n_elements(starttimes))
    iarr_comp=ssl_set_complement(idx, iarr)
    pd_starttimes=time_string(starttimes[iarr_comp])
    pd_endtimes=time_string(endtimes[iarr_comp])
    pd_sect2add=sect2add[iarr_comp]
    pd_phang2add=phang2add[iarr_comp]
    pd_lastestmediansectr=lastestmediansectr[iarr_comp]
    pd_latestmedianphang=latestmedianphang[iarr_comp]
    pd_badflag=badflag[iarr_comp]
    pd_sectnum=sectnum[iarr_comp]
    pd_timeofprocessing=timeofprocessing[iarr_comp]
    pd_newdat={starttimes:pd_starttimes, $
      endtimes:pd_endtimes, $
      sect2add:pd_sect2add, $
      phang2add:pd_phang2add, $
      lastestmediansectr: pd_lastestmediansectr, $
      latestmedianphang:pd_latestmedianphang, $
      badflag:pd_badflag, $
      sectnum:pd_sectnum, $
      timeofprocessing:pd_timeofprocessing }
  endif else begin
    starttimes=time_string(starttimes)
    endimes=time_string(endtimes)
    pd_newdat={starttimes:starttimes, $
      endtimes:endtimes, $
      sect2add:sect2add, $
      phang2add:phang2add, $
      lastestmediansectr: lastestmediansectr, $
      latestmedianphang:latestmedianphang, $
      badflag:badflag, $
      sectnum:sectnum, $
      timeofprocessing:timeofprocessing }
  endelse

  ; re-index phase_delays and write to file
  ; write to manually manipulated file phase_delays[idx] - these are the ones with two entries

  file = 'el'+probe+'_epde_phase_delays.csv'
  print, !elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'+file
  filedata = read_csv(!elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'+file, header = cols, types = ['String', 'String', 'Float', 'Float','Float','Float','Float','Float', 'String'])

  file = 'el'+probe+'_epde_phase_delays_new.csv'
  write_csv, !elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'+file, pd_newdat, header = cols
  stop

end
