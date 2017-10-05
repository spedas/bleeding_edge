; this file will be run once per day

; 'day' must be in either string or double format

pro mvn_sep_make_ancillary_data, day, cdf_file_name = cdf_file_name,sav_file_name = sav_file_name,version  = version, revision = revision
  
  If not keyword_set(version) then version = 0
  if not keyword_set (revision) then revision = 0
  
  trange = [time_double (day), time_double (day) +86400]
  maven_kernels = mvn_spice_kernels(trange = trange,/load, /all) 

  year_string = time_string(day, tformat = 'YYYY')
  month_string = time_string(day,tformat = 'MM')
  date_string = time_string(day,tformat = 'DD')
  out_path_stem = '/disks/data/maven/data/sci/sep/anc/'
  
  version_string = numbered_filestring(version, digits = 2)
  revision_string = numbered_filestring(revision, digits = 2)
  
  if not keyword_set (sav_file_name) then sav_file_name = 'sav/'+year_string+'/'+ month_string +'/'+'mvn_sep_anc_' + year_string+ month_string + date_string + $
    '_v'+version_string +'_r'+revision_string +'.sav'
  if not keyword_set (cdf_file_name) then cdf_file_name ='cdf/'+year_string+'/'+ month_string +'/'+'mvn_sep_anc_' + year_string+ month_string + date_string + $
    '_v'+version_string +'_r'+revision_string +'.cdf'
  
; create the ancillary data structure
  print, 'making IDL save file: ',sav_file_name
  sep_ancillary = mvn_sep_anc_data(tr=trange,/load)
  if size(sep_ancillary,/type) ne 8 then return
  
  save, sep_ancillary, file = out_path_stem + sav_file_name

; make the CDF file
  print, 'making CDF file: ', cdf_file_name
  mvn_sep_anc_make_cdf, sep_ancillary,dependencies=dependencies, file = out_path_stem +cdf_file_name, data_version = data_version

end
  