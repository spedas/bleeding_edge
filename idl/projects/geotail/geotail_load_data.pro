;+
; PROCEDURE:
;         geotail_load_data
;
; PURPOSE:
;         Load GEOTAIL data
;
; KEYWORDS:
;         trange: time range of interest
;         datatype: type of GEOTAIL data to load, options include: 'lep', 'mgf', 'orbit'
;
; EXAMPLE:
;         geotail_load_data, trange=['2016-01-10', '2016-01-11']
;
; NOTES:
;        Problems? report them to egrimes@igpp.ucla.edu
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-08-06 11:37:46 -0700 (Thu, 06 Aug 2020) $
;$LastChangedRevision: 29001 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/geotail/geotail_load_data.pro $
;-

pro geotail_load_data, trange=trange, datatype=datatype, no_color_setup=no_color_setup

  geotail_init, no_color_setup=no_color_setup
  
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
  
  if not keyword_set(remote_data_dir) then remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/geotail/'
    
  if not keyword_set(datatype) then datatype = ['lep', 'mgf', 'orbit']
  
  path_count = 0l
  
  for datatype_idx = 0, n_elements(datatype)-1 do begin
    case strlowcase(datatype[datatype_idx]) of
      'lep': begin
        ; LEP
        append_array, pathformat, 'lep/edb12sec_lep/YYYY/ge_edb12sec_lep_YYYYMMDD_v??.cdf'
        path_count += 1
      end
      'mgf': begin
      ;  append_array, pathformat, 'mgf/mgf_k0/YYYY/ge_k0_mgf_YYYYMMDD_v??.cdf'
        append_array, pathformat, 'mgf/edb3sec_mgf/YYYY/ge_edb3sec_mgf_YYYYMMDD_v??.cdf'
        path_count += 1
      end
      'orbit': begin
        append_array, pathformat, 'orbit/def_or/YYYY/ge_or_def_YYYYMMDD_v??.cdf'
        path_count += 1
      end
    endcase
  endfor

  for path_idx = 0, n_elements(pathformat)-1 do begin
    relpathnames = file_dailynames(file_format=pathformat[path_idx], trange=tr, /unique, resolution=24l*3600)
 
    files = spd_download(remote_file=relpathnames, remote_path=remote_data_dir, local_path = local_data_dir, ssl_verify_peer=0, ssl_verify_host=0)
  
    cdf2tplot, files, /all
  endfor

end
