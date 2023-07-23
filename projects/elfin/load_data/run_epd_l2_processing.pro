;+
;
; PROCEDURE:
;         run_epd_l2_processing
;
; PURPOSE:
;         This is a wrapper routine for processing epd l2 cdf
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probe:        letter of the elfin spacecraft - 'a' or 'b'
;         species:      letter of the type of data - e: electron or i: ion
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;-
pro run_epd_l2_processing, date, ndays=ndays, probe=probe, species=species

  if undefined(species) then species='e'
  if undefined(probe) then probe='a'
  if undefined(probe) then ndays=30
  
  for i=0, ndays-1 do begin
     starttime=time_double(date) + i*86400.0 
     endtime=starttime + 86400.0
     trange=[starttime,endtime]
     file_out=''
     elf_create_l2_epd_cdf, probe=probe, trange=trange, species=species, file_out=file_out
     if file_out eq '' then stop
     stop
  endfor

end
