;+
; PROCEDURE:
;         elf_update_data_availability_table
;
; PURPOSE:
;         Update the data availability page
;
; KEYWORDS:
;         tdate: time to be used for calculation
;                (format can be time string '2020-03-20'
;                or time double)
;         probe: probe name, probes include 'a' and 'b'
;         instrument: instrument name, insturments include 'epd', 'fgm', 'mrm'
;
; OUTPUT:
;
; EXAMPLE:
;         elf_update_data_availability_table, '2020-03-20', probe='a', instrument='mrm'
;         
;LAST EDITED: lauraiglesias4@gmail.com 05/18/21
;
;-
pro elf_update_data_availability_table, trange=trange, probe=probe, instrument=instrument, days = days

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, no_color_setup = no_color_setup

  if keyword_set(probe) then probes = probe else probes = ['a', 'b']

  if keyword_set(instrument) then instruments = instrument else instruments = ['epde', 'epdi', 'fgm'] ;, 'mrm']
  
  foreach probe, probes do begin
    foreach instrument, instruments do begin 
      ; initialize parameters
      if undefined(trange) then begin
        print, 'You must provide a date. Example: 2020-01-01'
        return
      endif
      
      dt=time_double(trange[1])-time_double(trange[0])
      timespan, trange[0], dt, /sec
      tr=timerange(trange)
; print, time_string(tr)
; stop
      if undefined(instrument) then instrument='epde' else instrument=strlowcase(instrument)
       
      if undefined(probe) then probe='a' else probe=strlowcase(probe)
      if probe ne 'a' and probe ne 'b' then begin
        print, probe+' is not a valid probe name.'
        print, 'Valid probe names are a or b.'
        return
      endif
      sc='el'+probe
    
      ; Determine what data is available
    
      data_avail=elf_get_data_availability(trange=tr, probe=probe, instrument=instrument)
;      print, instrument
;      stop
      ; Update the csv file
      if ~undefined(data_avail) && size(data_avail, /type) EQ 8 then begin
        print, 'Data available'
        filename='el'+probe+'_'+instrument  
;print, filename
;dt=time_double(trange[1])-time_double(trange[0])
;timespan, trange[0], dt, /sec
print, time_string(tr)
;        stop  
        elf_write_data_availability_table, tr, dt, filename, data_avail, instrument, probe
      endif else begin
        print, 'There is no data for probe '+probe+' , instrument '+instrument+' from '+ time_string(trange[0]) + ' to ' + time_string(trange[1])     
      endelse
      
        ;VERY IMPORTANT! Update needs to be zero and nodownload needs to be 1, otherwise you'll go in an infinite loop.
 ;       elf_create_instrument_all, probe = probe, instrument = instrument, nodownload = 1, update = 0 
        ; elf_create_epd_all
    endforeach 
  endforeach
  
 
end