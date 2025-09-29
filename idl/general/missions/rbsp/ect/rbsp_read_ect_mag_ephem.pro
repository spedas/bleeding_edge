;+
; NAME: rbsp_read_ect_mag_ephem
; SYNTAX:
; PURPOSE: Read in RBSP ECT's official magnetic field model predicted quantities
; INPUT: sc -> 'a' or 'b'
;		     date -> '2014-01-01'
;        type -> defaults to OP77Q. Can also have "TS04D" (definitive)
;        or "T89Q" for predicted.
; OUTPUT: tplot variables with prefix 'rbsp'+sc+'_ME_'
;		  Will also return perigeetimes as keyword
; KEYWORDS:
; HISTORY: Written by Aaron W Breneman, UMN
; VERSION:
;   $LastChangedBy: $
;   $LastChangedDate: $
;   $LastChangedRevision: $
;   $URL: $
;-

pro rbsp_read_ect_mag_ephem, sc, perigeetimes, $
  pre = pre, type = type, trange = trange, $
  _extra = extra
  ; fix: should other inits exclusion extras be possible?
  ; if ~tag_exist(extra, 'no_rbsp_efw_init') then rbsp_efw_init
  ; rbsp_spice_init
  ; adding rbsp_ect_init for consistency:
  if ~tag_exist(extra, 'no_rbsp_ect_init') then rbsp_ect_init

  if ~keyword_set(trange) then begin
    trange = timerange() ;
  endif

  ; fix: not rbsp_ect_init local_data_dir?
  local_data_dir = !rbsp_ect.local_data_dir
  local_data_dir += 'ect_definitive_ephem/'

  ; Handle pre keyword:
  if keyword_set(pre) then print, 'Predicted keyword is no longer supported; returning results for definitive ephemeris data...'

  ; initialize type if not declared, check if type is valid if declared
  if ~keyword_set(type) then type = 'op77q'
  case strlowcase(type) of
    'op77q': type_extension = 'def-1min-op77q'
    't89d': type_extension = 'def-1min-t89d'
    't89q': type_extension = 'def-1min-t89q'
    'ts04d': type_extension = 'def-5min-ts04d'
    else: begin
      print, '***Input type ' + type + ' not valid; must be one of: op77q, t89d, t89q, or ts04d***'
      return
    end
  endcase
  remote_data_dir = !rbsp_ect.remote_data_dir + 'rbsp' + sc + '/ephemeris/ect-mag-ephem/cdf/' + type_extension + '/'

  ; declare file name prefix:
  fn = 'rbsp-' + sc + '_mag-ephem_' + type_extension + '_'

  ; call to file_dailynames to generate a list of pathnames to be downloaded
  remote_names = file_dailynames(remote_data_dir,fn,'_v*.cdf',trange=trange,yeardir='YYYY/')
  ; call spd_download to fetch the data files from SPDF
  file_loaded = spd_download(remote_file=remote_names,local_path = local_data_dir,/last_version)
  ; call spd_cdf2tplot to load the CDF data as tplot variables
  spd_cdf2tplot,file=file_loaded,all=all,verbose=verbose,/tt2000
  

  ; store_data, 'rbsp' + sc + '_ME_pfs_gsm', data = {x: unixtime, y: pfs_gsm}
  ; options, 'rbsp' + sc + '_ME_pfs_cd_mlat', 'ytitle', 'Mlat!CSouth!Cfootpoint!Ccentered!Cdipole!Cdeg'

  if keyword_set(perigeetimes) then perigeetimes = time_string(perigeetimes)
end
