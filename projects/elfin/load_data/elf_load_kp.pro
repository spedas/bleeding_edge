;+
; PROCEDURE:
;         elf_load_kp
;
; PURPOSE:
;         Wrapper for noaa_load_kp routine to download kp data
;            ftp://ftp.gfz-potsdam.de/pub/home/obs/kp-nowcast-archive/wdc/
;
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         extend_time:  set this flag to return the two adjacent values - this is useful for very
;                       small time frames
;
; NOTES:
;         The kp values downloaded from potsdam are at 3 hour intervals. 01:30, 04:30, 07:30, ... 22:30.
;         If you time range is less than 3 hours it's possible no values will be found. Use the extend_time
;         keyword to return the prevoius and next values.
;
;-
pro elf_load_kp, trange=trange, extend_time=extend_time

  if undefined(trange) then begin
    dprint, dlevel = 0, 'Error, trange must be defined: [starttime, endtime]'
    return
  endif else begin
    trange=time_double(trange)
    trange=[trange[0]-21600.,trange[1]+21600.]
  endelse

  noaa_load_kp, trange=trange, datatype='kp'
  dt=5400.    ; kp values are every 3 hours dt/2 is 1.5 hrs
  copy_data, 'Kp', 'elf_kp'
  get_data, 'elf_kp', data=d
  kp={x:d.x-dt, y:round(d.y)}
  store_data, 'elf_kp', data=kp
  options, 'elf_kp', colors=65
  options, 'elf_kp', psym=10
  options, 'elf_kp', labels=['kp']
  max_kp=max(kp.y)
  if max_kp GT 4.3 then begin
    max_kp_range=max_kp + (max_kp*.1)
    options, 'elf_kp', yrange=[-0.5,max_kp_range]
  endif else begin
    options, 'elf_kp', yrange=[-0.5,4.5]
  endelse
  options, 'elf_kp', ystyle=1

end