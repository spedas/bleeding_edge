;+
;PROCEDURE:   mvn_sta_cio_update
;PURPOSE:
;  Updates STATIC cold ion outflow results in save/restore files.
;
;USAGE:
;  mvn_sta_cio_update, trange [, ndays]
;
;INPUTS:
;       trange:        Start time or time range for making save files, in any 
;                      format accepted by time_double().  If only one time is 
;                      specified, it is taken as the start time and NDAYS is 
;                      used to get the end time.  If two or more times are 
;                      specified, then the earliest and latest times are used.
;                      Fractional days (hh:mm:ss) are ignored.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-02-27 18:37:52 -0800 (Tue, 27 Feb 2018) $
; $LastChangedRevision: 24801 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_update.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_sta_cio_update.pro
;-
pro mvn_sta_cio_update, trange, ndays

  dpath = root_data_dir() + 'maven/data/sci/sta/l3/cio/'
  froot = 'mvn_sta_cio_'
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
    ofile = opath + froot + yyyy + mm + dd + '_v02.sav'

    finfo = file_info(ofile)
    if (finfo.exists) then begin
      mvn_swe_spice_init, /force, /list
      maven_orbit_tplot, /load
      restore, filename=ofile

; Elevation angle of the Sun in the APP frame
;   0 deg = i-j plane ; +90 deg = +k
;   cold-ion configuration is ~0 deg

      mvn_sundir, frame='app', /polar
      get_data,'Sun_APP_The',data=sthe_app,index=j
      if (j gt 0) then begin
        cio_h.sthe_app = spline(sthe_app.x, sthe_app.y, cio_h.time)
        cio_o1.sthe_app = cio_h.sthe_app
        cio_o2.sthe_app = cio_h.sthe_app
      endif else print,'MVN_STA_CIO_UPDATE: Failed to get Sun (APP) direction!'

; Elevation angle of MSO RAM in the APP frame
;   0 deg = i-j plane ; +90 deg = +k
;   cold-ion configuration is ~0 deg

      mvn_ramdir, /mso, frame='app', /polar
      get_data,'V_sc_APP_The',data=rthe_app,index=j
      if (j gt 0) then begin
        cio_h.rthe_app = spline(rthe_app.x, rthe_app.y, cio_h.time)
        cio_o1.rthe_app = cio_h.rthe_app
        cio_o2.rthe_app = cio_h.rthe_app
      endif else print,'MVN_STA_CIO_UPDATE: Failed to get MSO RAM direction!'

; Save the updated structures

      save, cio_h, cio_o1, cio_o2, file=ofile

    endif else print,'Save file does not exist: ',ofile

    delta_t = (systime(/sec) - timer_start)/60D
    print, delta_t, format='("Elapsed time: ",f7.2," min")'

  endfor

  return

end

