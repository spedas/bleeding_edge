pro elf_run_verify_phase_delays, probe=probe

  elf_init
; this routine is a wrapper for checking science zones against phase delays
  probe='b'
  startrun=time_double('2019-09-01')
  endrun=time_double('2021-07-01/23:59')
  ;ndays=253
  ndays=(endrun-startrun)/86400.
  ; Read missing phase delay file and store data
  file = 'el'+probe+'_epde_missing_phase_delays.csv'
  file=!elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'+file
print, file

stop
  if file_test(file) NE 1 then begin
    dprint,'No missing file exists yet'
  endif else begin
    orig_dat = read_csv(file, types = ['String'])
    orig_sz_date=time_double(orig_dat.field1)
  endelse
help, orig_sz_date
stop
  ; run routine that will return science zones that don't have phase delays
  for i=0,ndays-1 do begin 
     startdate=startrun + i*86400. 
     mz_struct=elf_verify_phase_delay_science_zones(startdate=startdate, probe=probe)
     if size(mz_struct, /type) ne 8 then continue
     append_array, mzs, mz_struct.zone
;     append_array, dfs, mz_struct.diff
  endfor
print, probe
stop
  ; kluge to remove unnecessary elements
  idx=where(mzs ne '', ncnt)
  if ncnt GT 0 then begin
    newmzs=time_double(mzs[idx])
;    newdfs=dfs[idx]
  endif

  ; combine the new missing science zones with the current contents of the missing csv file
  if ~undefined(orig_sz_date) then begin
    if ~undefined(newmzs) then begin
      append_array, orig_sz_date, newmzs
;      append_array, orig_sz_diff, newdfs
    endif 
  endif else begin
    if ~undefined(newmzs) then begin
      orig_sz_date=newmzs
;      orig_sz_diff=newdfs
    endif    
  endelse

  ; remove duplicate entries and sort by date
  ridx=UNIQ(orig_sz_date, SORT(orig_sz_date))
  new_sz_date=orig_sz_date[ridx]
;  new_sz_diff=orig_sz_diff[ridx]
;help, newmzs
help, new_sz_date
stop  
  ; write missing zones to missing csv file
  file = 'el'+probe+'_epde_missing_phase_delays.csv'
  missing_scizone=time_string(new_sz_date)
  write_csv, !elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'+file, missing_scizone, header = cols
  print, 'Wrote file '+file
end