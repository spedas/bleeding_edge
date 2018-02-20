;+
;PROCEDURE:   mvn_sta_cio_save
;PURPOSE:
;  Saves STATIC cold ion outflow results in save/restore files.
;  See mvn_sta_coldion.pro for details.
;
;USAGE:
;  mvn_sta_cio_save, trange [, ndays]
;
;INPUTS:
;       trange:        Start time or time range for making save files, in any 
;                      format accepted by time_double().  If only one time is 
;                      specified, it is taken as the start time and NDAYS is 
;                      used to get the end time.  If two or more times are 
;                      specified, then the earliest and latest times are used.
;                      Fractional days (hh:mm:ss) are ignored.
;
;       ndays:         Number of dates to process.  Only used if TRANGE has
;                      only one element.  Default = 1.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-02-19 13:07:50 -0800 (Mon, 19 Feb 2018) $
; $LastChangedRevision: 24747 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_save.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_sta_cio_save.pro
;-
pro mvn_sta_cio_save, trange, ndays

  dpath = root_data_dir() + 'maven/data/sci/sta/l3/cio/'
  froot = 'mvn_sta_cio_'
  version = '_v02'
  dt = 86400D  ; process one day at a time

  case n_elements(trange) of
     0  :  begin
             print,'You must specify a start time or time range.'
             return
           end
     1  :  begin
             tstart = time_double(time_string(trange,prec=-3))
             if (size(ndays,/type) eq 0) then ndays = 1
           end
    else : begin
             tmin = min(time_double(trange), max=tmax)
             tstart = time_double(time_string(tmin,prec=-3))
             tstop = time_double(time_string((tmax + dt - 1D),prec=-3))
             ndays = (tstop - tstart)/dt
           end
  endcase

; Process the data one calendar day at a time

  for i=0L,(ndays - 1L) do begin
    timer_start = systime(/sec)

    time = tstart + double(i)*dt
    timespan, time, 1

    tstring = time_string(time)
    yyyy = strmid(tstring,0,4)
    mm = strmid(tstring,5,2)
    dd = strmid(tstring,8,2)
    opath = dpath + yyyy + '/' + mm + '/'
    file_mkdir2, opath, mode='0774'o  ; create directory structure, if needed
    ofile = opath + froot + yyyy + mm + dd + version + '.sav'

; If the file already exists, then just update it

    finfo = file_info(ofile)
    if (0) then begin
      print,'CIO save file already exists.  Updating.'
      mvn_sta_cio_update, time
    endif else begin
      mvn_swe_load_l0, /spiceinit
      mvn_swe_stat, npkt=npkt, /silent
      if (npkt[2] gt 0L) then begin
        maven_orbit_tplot, /shadow, /loadonly
        mvn_swe_sciplot, padsmo=16, /loadonly
        mvn_scpot
        mvn_sundir, frame='swe', /polar

        mvn_sta_coldion, density=1, temperature=1, velocity=[1,1,1], $
              result_h=cio_h, result_o1=cio_o1, result_o2=cio_o2, /reset, tavg=16, $
              success=ok

        if (ok) then save, cio_h, cio_o1, cio_o2, file=ofile $
                else print,'CIO pipeline failed: ',tstring

        elapsed_min = (systime(/sec) - timer_start)/60D
        print,elapsed_min,format='("Time to process (min): ",f6.2)'

      endif else print,'No SWEA data: ',tstring
    endelse
  endfor

  return

end

