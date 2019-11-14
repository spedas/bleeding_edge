;+
; PROCEDURE: iug_load_hf_tohokuu
;
; PURPOSE:
;   To load the Jupiter's/solar wide band spectral data in HF-band 
;
; KEYWORDS:
;   site  = Observatory name. Only 'iit' is allowed.
;   parameter = The polarization of the radiowave.
;               'RH' for right handed, and 'LH' for left handed.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_download: use only files which are online locally.
;   trange = (Optional) Time range of interest  (2 element array).
;
; EXAMPLE:
;   iug_load_hf_tohokuU, parameter='RH', $
;                        trange=['2004-01-09/22:00:00','2004-01-09/23:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://ariel.gp.tohoku.ac.jp/~jupiter/
;
; Written by: M.Yagi, Oct 2, 2012
;             PPARC, Tohoku Univ.
;
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2019-11-13 11:33:21 -0800 (Wed, 13 Nov 2019) $
;   $URL:
;-

pro iug_load_hf_tohokuu, site=site, parameter=parameter,$
         downloadonly=downloadonly, no_download=no_download,$
         trange=trange

;--- site
site_code_all = strsplit('iit', /extract)
if(n_elements(site) eq 0) then site='iit'
site_code=ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if(site_code[0] eq '') then return
print, site_code

;--- parameter
param_all = strsplit('RH LH', /extract)
if(n_elements(parameter) eq 0) then parameter='all'
param = ssl_check_valid_name(parameter, param_all, /ignore_case, /include_all)
if(param[0] eq '') then return
print, param

;--- data file structure
source = file_retrieve(/struct)

;--- Download options
if keyword_set(downloadonly) then source.downloadonly=1
if keyword_set(no_download)  then source.no_download=1
if(not keyword_set(downloadonly)) then downloadonly=0

show_text=0
for i=0,n_elements(site_code)-1 do begin
  ;--- Set filedate(YYYYMMDD) and filehour(YYYYMMDDhh)
  filehour = file_dailynames(file_format='YYYYMMDDhh',trange=trange,/hour_res)
  filedate = strmid(filehour,0,8)

  ;--- Set the file path
  source.local_data_dir = root_data_dir() + 'iugonet/tohokuu/radio_obs/iit/hfspec/'
;  source.remote_data_dir = 'http://ariel.gp.tohoku.ac.jp/~jupiter/it_hf/cdf2/'
  source.remote_data_dir = 'http://adrastea.gp.tohoku.ac.jp/~jupiter/it_hf/cdf2/'

  ;--- Download file
  relfnames = filedate+'/'+'it_h1_hf_'+filehour+'_v0?.cdf'
  datfiles = spd_download(remote_file=relfnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

  ;--- Skip load where no data
  filenum=n_elements(datfiles)
  file_exist=intarr(filenum)
  for it=0,filenum-1 do begin
    file_exist[it] = file_test(datfiles[it])
  endfor

  ;--- Load data into tplot variables
  if(downloadonly eq 0 and (where(file_exist eq 1))[0] ne -1) then begin
    datfiles  = datfiles[where(file_exist eq 1)]
    show_text = 1

    for j=0,n_elements(param)-1 do begin
      ;--- load data
      cdf2tplot, file=datfiles, varformat=strupcase(param[j])
      get_data, strupcase(param[j]), data=data, dlimit=dlimit
      store_data, strupcase(param[j]), /delete

      ;--- add metadata
      gatt={Project:dlimit.cdf.gatt.project, Logical_source_description:"Jupiter's/solar wide band spectral data in HF-band", PI_name:"Atsushi Kumamoto", PI_affiliation:"Tohoku University", TEXT:"When the data is used in or contributes to a presentation or publication, you should let us know and make acknowledgement to the Planetary Plasma and Atmospheric Research Center, Tohoku University.", LINK_TEXT:"For more information, see", HTTP_LINK:"http://ariel.gp.tohoku.ac.jp/~jupiter/"}
      cdf = {filename:dlimit.cdf.filename, gatt:gatt, vname:dlimit.cdf.vname, vatt:dlimit.cdf.vatt}
      dl =  {cdf:cdf, spec:dlimit.spec, ylog:dlimit.ylog, ysubtitle:dlimit.ysubtitle}

      ;--- restore data
      if param[j] eq 'rh' then store_data, 'iug_iit_hf_R', data=data, dlimit=dl
      if param[j] eq 'lh' then store_data, 'iug_iit_hf_L', data=data, dlimit=dl
    endfor
  endif
endfor

;--- Acknowledgement
datfile = source.local_data_dir+relfnames[0]
if (show_text eq 1) then begin
  dprint, ''
  dprint, '**********************************************************************'
  dprint, "Jupiter's/solar wide band spectral data in HF-band"
  dprint, ''
  dprint, 'PI and Host PI(s): ', 'Atsushi Kumamoto'
  dprint, 'Affiliations: ', 'PPARC, Tohoku University'
  dprint, ''
  dprint, 'Rules of the Road for HF Data Use:'
  dprint, 'When the data is used in or contributes to a presentation or publication, you should let us know and make acknowledgement to the Planetary Plasma and Atmospheric Research Center, Tohoku University.'
  dprint, '**********************************************************************'
  dprint, ''
endif else begin
  dprint, '**********************************************************************'
  dprint, 'No data is loaded'
  dprint, '**********************************************************************'
endelse

return
end
