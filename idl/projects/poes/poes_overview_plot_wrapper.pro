;+
;
;NAME:
;         poes_overview_plot_wrapper
;
;PURPOSE:
;         Generates daily overview plots for POES data - wrapper for poes_overview_plot
;
;KEYWORDS:
;         probes: array of poes probe numbers, if probe='' then probe=['15','16','17','18','19']
;         date_start: begin processing at this date (eg. '2013-12-19')
;         date_end: end processing at this date (eg. '2013-12-29')
;         base_dir: root dir for output plots (eg. /disks/themisdata/overplots/)
;         makepng: generate png files
;         server_run: for a cron job this has to be set to '1' to avoid downloading files
;         themis_dir: server directory for themis (eg. '/disks/themisdata/')
;         poes_dir: server directory for poes (eg. '/disks/data/goes/poes/qa/')
;         date_mod: date modification keyword
;                 date_mod='daysNNN' produces plots from today to NNN days back (days001 is today only)
;                 date_mod='startdateNNN' produces plots from datestart to NNN days after that
;                 date_mod='enddateNNN' produces plots from dateend to NNN days before that
;                 date_mod='continue' continue from last date of
;                           processing (text file: base_dir + 'poeslastdate.txt')
;                 reprocess=if set, ignore last date file, so as to
;                           avoid issues with the regular cronjob
;OUTPUT:
;         png files in base_dir
;
;
;EXAMPLE USAGE:
;          poes_overview_plot_wrapper, date_end = '2012-03-01', date_mod='enddate002', base_dir='c:\temp\'
;          poes_overview_plot_wrapper, date_start = '2012-03-21', date_end = '2012-03-31', probes='18', base_dir='c:\temp\'
;          poes_overview_plot_wrapper, date_start = '2012-01-01', date_end = '2013-12-31', base_dir='/disks/themisdata/overplots/', $
;                             server_run = '1', themis_dir ='/disks/themisdata/', poes_dir = '/disks/data/poes/qa/'
;          poes_overview_plot_wrapper, date_mod = 'days004', base_dir='/disks/themisdata/overplots/', $
;                             server_run = '1', themis_dir ='/disks/themisdata/', poes_dir = '/disks/data/poes/qa/'
;
;NOTES: 
;  Years of operation:
;  1998 noaa15
;  1999 15
;  2000 15
;  2001 15,16
;  2002 15,16,17
;  2003 15,16,17
;  2004 15,16,17
;  2005 15,16,17,18
;  2006 15,16,17,18
;  2007 15,16,17,18
;  2008 15,16,17,18
;  2009 15,16,17,18,19
;  2010 15,16,17,18,19
;  2011 15,16,17,18,19
;  2012 15,16,17,18,19
;  2013 15,16,17,18,19
;  2014 15,16,18,19
;  2015 15,16,18,19
;  2021 15,18,19
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2022-03-18 12:52:44 -0700 (Fri, 18 Mar 2022) $
;$LastChangedRevision: 30691 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_overview_plot_wrapper.pro $
;----------

function poes_url_callback, status, progress, data
  ; print the info msgs from the url object
  PRINT, status
  
  ; return 1 to continue, return 0 to cancel
  RETURN, 1
end

function check_poes_noaa_dir, base_dir, remote_http_dir
  ; If the url object throws an error it will be caught here
  CATCH, errorStatus
  IF (errorStatus NE 0) THEN BEGIN
    CATCH, /CANCEL
    
    ; Display the error msg in a dialog and in the IDL output log
    ;r = DIALOG_MESSAGE(!ERROR_STATE.msg, TITLE='URL Error',   /ERROR)
    PRINT, !ERROR_STATE.msg
    
    ; Get the properties that will tell us more about the error.
    oUrl->GetProperty, RESPONSE_CODE=rspCode, $
      RESPONSE_HEADER=rspHdr, RESPONSE_FILENAME=rspFn
    PRINT, 'rspCode = ', rspCode
    PRINT, 'rspHdr= ', rspHdr
    PRINT, 'rspFn= ', rspFn
    
    ; Destroy the url object
    OBJ_DESTROY, oUrl
    RETURN, 0
  ENDIF
  
  oUrl = OBJ_NEW('IDLnetUrl', ssl_verify_host=0, ssl_verify_peer=0)
  oUrl->SetProperty, VERBOSE = 1
  oUrl->SetProperty, url_scheme = 'https'
  ;cd, base_dir
  oUrl->SetProperty, CALLBACK_function ='poes_url_callback'
  oUrl->SetProperty, URL_HOST = remote_http_dir
  FILE_DELETE, base_dir + 'poestestfile.txt',  /ALLOW_NONEXISTENT
  fn = oUrl->Get(FILENAME = base_dir + 'poestestfile.txt' )
  return, 1
end

function poes_read_lastdate, fname
  lastdate = ''
  openr, lun, fname, /get_lun
  readf, lun, lastdate
  free_lun, lun
  return, lastdate
end

pro poes_write_lastdate, fname, lastdate
  openw, lun, fname, /get_lun
  printf, lun, lastdate
  free_lun, lun
end

function poes_generate_datearray, date_start, date_end
  if date_start eq '' then begin
    dprint, dlevel = 1, 'Invalid date_start.'
    return, ['0']
  endif
  year01 = STRMID(date_start, 0, 4)
  month01 = STRMID(date_start, 5, 2)
  day01 = STRMID(date_start, 8, 2)
  if date_end eq '' then begin ;if date_end is empty, use today
    CALDAT, systime(/julian), month02, day02, year02
  endif else begin
    year02 = STRMID(date_end, 0, 4)
    month02 = STRMID(date_end, 5, 2)
    day02 = STRMID(date_end, 8, 2)
  endelse
  date_array = TIMEGEN( START=JULDAY(month01,day01,year01), FINAL=JULDAY(month02,day02,year02))
  return, date_array
end

pro poes_overview_plot_wrapper, date_start = date_start, date_end = date_end, $
  date_mod = date_mod, probes = probes, base_dir = base_dir, makepng=makepng,$
  server_run = server_run, themis_dir = themis_dir, poes_dir = poes_dir, $
  reprocess = reprocess
  compile_opt idl2
  
  dprint, dlevel = 2, 'START POES overview plot. Date: ' + SYSTIME()
  
  ; for server cron job set the directories to server directories
  ; so that files will not have to be downloaded every time
  device = 'z'
  thm_init, /reset
  poes_init, /reset
  if keyword_set(server_run) then begin
    if FILE_TEST(themis_dir, /DIRECTORY) then !themis.local_data_dir = themis_dir
    if FILE_TEST(poes_dir, /DIRECTORY) then !poes.local_data_dir = poes_dir
  endif
  if ~keyword_set(base_dir) then base_dir='/disks/themisdata/overplots/'
  lastdate_file = base_dir + 'poeslastdate.txt' ;this file holds the last day processed
  if ~keyword_set(probes) then probes=['15','16','17','18','19']
  if ~keyword_set(date_start) then date_start = ''
  if strlen(date_start) ne 10 then date_start = ''
  if ~keyword_set(date_end) then date_end = ''
  if strlen(date_end) ne 10 then date_end = ''
  if date_end eq '' then begin ;if there is no date_end specified, then date_end = today
    CALDAT, systime(/julian), Month1, Day1, Year1
    date_end=STRTRIM(string(Year1),2)+'-'+STRTRIM(string(Month1, format='(I02)'),2)+'-'+STRTRIM(string(Day1, format='(I02)'),2)
  endif
  
  if keyword_set(date_mod) then begin
    if  STRCMP(date_mod, 'continue', 8, /FOLD_CASE) then begin
      date_start = poes_read_lastdate(lastdate_file)
      date_array = poes_generate_datearray(date_start, date_end)
    endif else if STRCMP(date_mod, 'daysNNN', 4, /FOLD_CASE) then begin
      len = STRMID(date_mod, 4, 3)
      date_array = TIMEGEN(len, START=SYSTIME(/JULIAN)-len)
    endif else if STRCMP(date_mod, 'startdateNNN', 9, /FOLD_CASE) then begin
      if  strlen(date_mod) ne 12 then begin
        dprint, dlevel = 1, 'Invalid date_mod. Please use date_mod=startdateNNN'
        return
      endif
      if date_start ne ''   then begin
        year0 = STRMID(date_start, 0, 4)
        month0 = STRMID(date_start, 5, 2)
        day0 = STRMID(date_start, 8, 2)
        len = STRMID(date_mod, 9, 3)
        date_array = TIMEGEN(len, START=JULDAY(month0,day0,year0))
      endif else begin
        dprint, dlevel = 1, 'Invalid date_mod. Please use date_mod=daysNNN and a valid date_start'
        return
      endelse
    endif else if STRCMP(date_mod, 'enddateNNN', 7, /FOLD_CASE) then begin
      if  strlen(date_mod) ne 10 then begin
        dprint, dlevel = 1, 'Invalid date_mod. Please use date_mod=enddateNNN'
        return
      endif
      if date_end ne ''   then begin
        year0 = STRMID(date_end, 0, 4)
        month0 = STRMID(date_end, 5, 2)
        day0 = STRMID(date_end, 8, 2)
        len = STRMID(date_mod, 7, 3)
        if len ge 1 then len = len - 1
        date_array = TIMEGEN(STEP_SIZE=1, FINAL=JULDAY(month0,day0,year0), START=JULDAY(month0,day0,year0)-len)
      endif else begin
        dprint, dlevel = 1, 'Invalid date_mod. Please use date_mod=enddateNNN and a valid date_end'
        return
      endelse
    endif else begin
      dprint, dlevel = 1, 'Invalid date_mod.'
      return
    endelse
  endif else begin
    date_array = poes_generate_datearray(date_start, date_end)
  endelse
  
  if date_array[0] eq '0' then return
  
  CALDAT, date_array, Month1, Day1, Year1
  daten=STRTRIM(string(Year1),2)+'-'+STRTRIM(string(Month1, format='(I02)'),2)+'-'+STRTRIM(string(Day1, format='(I02)'),2)
  
  for i=0, n_elements(daten)-1 do begin
    date = daten[i]
    year03 = STRMID(date, 0, 4)
    month03 = STRMID(date, 5, 2)
    day03 = STRMID(date, 8, 2)
    directory = base_dir + year03 + path_sep() + month03 + path_sep() + day03 + path_sep()
    remote_dir = 'cdaweb.gsfc.nasa.gov/istp_public/data/noaa/'  
   ; remote directory: http://satdat.ngdc.noaa.gov/sem/poes/data/avg/cdf/2014/noaa18/ 
    for j=0, n_elements(probes)-1 do begin
      probe = probes[j]
      ; check if dir exists, eg: http://satdat.ngdc.noaa.gov/sem/poes/data/new_avg/2011/08/poes13/netcdf/
      remote_http_dir = remote_dir + 'noaa' + probe + '/sem2_fluxes-2sec/' + year03
      if check_poes_noaa_dir(base_dir, remote_http_dir) then begin
        dprint, dlevel=1, "====================================================="
        msgstr = "POES OVERVIEW PLOT: Probe= " + string(probe) + ", date= " + date
        dprint, dlevel = 1, msgstr
        heap_gc
        poes_overview_plot, date = date, probe = probe, directory = directory, $
                            device = device , duration = 1, makepng=makepng
        if ~keyword_set(reprocess) then poes_write_lastdate, lastdate_file, date ;jmm, 2019-12-12
      endif
    endfor
  endfor
  
  dprint, dlevel = 2, 'END POES overview plot. Date: ' + SYSTIME()
end
