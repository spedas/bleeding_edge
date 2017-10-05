;+
; NAME: rbsp_load_maneuver_file
; SYNTAX: x = rbsp_load_maneuver_file(probe,date)
; PURPOSE: Returns a structure with start and end times of maneuvers
; from the MOC data product "maneuver_sequence" files. 
; INPUT: probe = 'a' or 'b'
;        date = '2012-10-13' format
;
; http://themis.ssl.berkeley.edu/data/rbsp/MOC_data_products
;
; NOTES: uses the MAXARMTIME variable to determine the extent of the
; maneuver. This may be the maximum upper limit maneuver time and not
; the actual maneuver time. Unfortunately the final maneuver log files are
; Word documents. 
;
; HISTORY: Written by Aaron W Breneman - University of Minnesota 2014-10-26
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-10-26 10:14:47 -0700 (Sun, 26 Oct 2014) $
;   $LastChangedRevision: 16037 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_maneuver_file.pro $
;-


function rbsp_load_maneuver_file,probe,date,remote_data_dir=remote_data_dir,local_data_dir=local_data_dir


  rbsp_spice_init

;URL stuff...

  if ~keyword_set(remote_data_dir) then $
     remote_data_dir = !rbsp_spice.remote_data_dir
  if ~keyword_set(local_data_dir) then $
     local_data_dir = !rbsp_spice.local_data_dir

  dirpath='MOC_data_products/RBSP'+strupcase(probe)+'/maneuver_sequence/'

;Find out what files are online
  FILE_HTTP_COPY,dirpath,url_info=ui,links=links,localdir=local_data_dir,$
                 serverdir=remote_data_dir


;Modify date/time strings

  date2 = time_string(time_double(date),tformat='YYYYMMDD')
  year = time_string(time_double(date),tformat='YYYY')
  doy = time_string(time_double(date),tformat='DOY')


  months = replicate(0.,n_elements(links))
  days = replicate(0.,n_elements(links))
  test = replicate(0B,n_elements(links))

  doys = strmid(links,7,3)
  years = strmid(links,2,4)

  doy_to_month_date,years,doys,months,days

  months = strtrim(floor(months),2)
  days = strtrim(floor(days),2)

  uts = years + '-' + months + '-' + days

                                ;fix string format
  uts = time_string(time_double(uts))


;uts holds the unix times of all the files available online to download


  test = (time_double(date) - time_double(uts))/86400.   
  goo = where(test eq 0)



  if goo[0] ne -1 then begin

     burnstart = dblarr(n_elements(goo))
     burnend = dblarr(n_elements(goo))


     for b=0,n_elements(goo)-1 do begin
        file = links[goo[b]]

        relpathnames = dirpath + file

                                ;download the file
        file_loaded = file_retrieve(relpathnames,remote_data_dir=remote_data_dir,$
                                    local_data_dir=local_data_dir,/last_version)

        openr,lun,local_data_dir + dirpath + file,/get_lun
        

        jnk = ''
        for i=0,2 do readf,lun,jnk
        tmp = strsplit(jnk,' ',/extract)
        tmp = tmp[1]

        boo = strsplit(tmp,':',/extract)
        burnstart[b] = time_double(date + '/' + boo[2] + ':' + boo[3] + ':' + boo[4])


        for i=0,16 do readf,lun,jnk

        tmp = strsplit(jnk,' ',/extract)
        burntime = float(tmp[1])
        burnend[b] = burnstart[b] + burntime

     endfor

     maneuver_times = {m0:burnstart,m1:burnend}
  
  endif else maneuver_times = !values.f_nan



  return,maneuver_times


end






