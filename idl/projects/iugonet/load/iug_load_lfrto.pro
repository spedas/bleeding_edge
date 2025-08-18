;+
; PROCEDURE: iug_load_lfrto
;
; PURPOSE:
;   To load the Low Frequency Radio Transmitter Observation data from the Tohoku University site 
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_lfrto, site='ath',
;           the default is 'ath', athabasca station.
;           This can be an array of strings, e.g., ['ath', 'nal']
;           or a single string delimited by spaces, e.g., 'ath nal'.
;           Sites:  ath nal
;   trans = Transmitter code, example, iug_load_lfrto, trans='wwvb',
;           the default is 'all', i.e., load all available transmitter.
;           This can be an array of strings, e.g., ['wwvb', 'ndk']
;           or a single string delimited by spaces, e.g., 'wwvb ndk'.
;           Transmitter:  wwvb ndk nlk npm nau nrk nwc msf dcf
;   parameter = Parameter name.
;               'power' or 'pow' for amplitude.
;               'phase' or 'pha' for phase.
;   datatype  = Time resolution. '30sec' or '30s' for 30 sec.
;               The default is '30sec'.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_download: use only files which are online locally.
;   /verbose : set to output some useful info
;   trange = (Optional) Time range of interest  (2 element array).
;
; EXAMPLE:
;   iug_load_lfrto, site='ath', datatype='30sec', $
;                        trange=['2011-05-29/00:00:00','2011-05-30/00:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://iprt.gp.tohoku.ac.jp/
;
; NAMING CONVENTIONS:
;       lfrto_[site]_[trans]_[parameter+datatype]
;       ex. lfrto_ath_wwvb_pow30s
;
; Written by: M.Yagi, Oct 2, 2012
;             PPARC, Tohoku Univ.
;
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
;   $URL:
;-
pro iug_load_lfrto, site=site, trans=trans, parameter=parameter, datatype=datatype,$
         downloadonly=downloadonly, no_download=no_download, verbose=verbose, trange=trange

;--- reciever (site)
site_code_all = strsplit('ath nal', /extract)
if(n_elements(site) eq 0) then site='all'
site_code=ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if(site_code[0] eq '') then return
print, site_code

;--- transmitter (trans)
trans_code_ath_all = strsplit('wwvb ndk nlk npm nau nrk nwc', /extract)
trans_code_nal_all = strsplit('msf dcf nrk gbz', /extract)
if(n_elements(trans) eq 0) then trans='all'
trans_code_ath = ssl_check_valid_name(trans, trans_code_ath_all, /ignore_case, /include_all, /no_warning)
trans_code_nal = ssl_check_valid_name(trans, trans_code_nal_all, /ignore_case, /include_all, /no_warning)
if(trans_code_ath[0] eq '' and trans_code_nal[0] eq '') then begin
  dprint,'!!! Trans code error !!!'
  dprint,'Valid Trans codes:'
  dprint,'wwvb ndk nlk npm nau nrk nwc (for site "ath")'
  dprint,'msf dcf nrk gbz (for site "nal")'
  return
endif

;--- time resolution (datatype)
tres_all = ['30sec']
if(n_elements(datatype) eq 0) then datatype='all'

datatype=strjoin(datatype, ' ')
datatype=strsplit(strlowcase(datatype), ' ', /extract)
if(where(datatype eq '30s')  ne -1) then datatype[where(datatype eq '30s')]='30sec'
tres = ssl_check_valid_name(datatype, tres_all, /ignore_case, /include_all)
if (tres[0] eq '') then return

;--- power & phase (parameter)
param_all = strsplit('power phase', /extract)
if(n_elements(parameter) eq 0) then parameter='all'

parameter=strjoin(parameter, ' ')
parameter=strsplit(strlowcase(parameter), ' ', /extract)
if(where(parameter eq 'pow')  ne -1) then parameter[where(parameter eq 'pow')]='power'
if(where(parameter eq 'pha')  ne -1) then parameter[where(parameter eq 'pha')]='phase'
param = ssl_check_valid_name(parameter, param_all, /ignore_case, /include_all)
if (param[0] eq '') then return

;--- other options
if (not keyword_set(verbose)) then verbose=0
if (not keyword_set(downloadonly)) then downloadonly=0
if (not keyword_set(no_download)) then no_download=0

;--- data file structure
source = file_retrieve(/struct)
source.verbose = verbose
filedate  = file_dailynames(file_format='YYYYMMDD', trange=trange)
filemonth = strmid(filedate,0,6)
if keyword_set(no_download) then source.no_download = 1

show_text=0
for i=0,n_elements(site_code)-1 do begin
  ;--- Set the file path
  source.local_data_dir = root_data_dir() + 'iugonet/TohokuU/radio_obs/'+site_code[i]+'/lf/'
  source.remote_data_dir = 'http://iprt.gp.tohoku.ac.jp/lf/cdf/'+site_code[i]+'/'
  case site_code[i] of
    'ath': trans_code=trans_code_ath
    'nal': trans_code=trans_code_nal
  endcase

  for j=0,n_elements(trans_code)-1 do begin
    for k=0,n_elements(tres)-1 do begin

      ;--- Download file
      relfnames = filemonth+'/'+'lfrto'+'_'+tres[k]+'_'+site_code[i]+'_'+trans_code[j]+'_'+filedate+'_v01.cdf'
      datfiles  = file_retrieve(relfnames, _extra=source)

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

        for l=0,n_elements(param)-1 do begin
          cdf2tplot, file=source.local_data_dir+relfnames,varformat='lf_'+param[l]+'_'+tres[k]
          ;--- shorten tplot variable name
          if (param[l] eq 'power' and tres[k] eq '30sec') then ptr = 'pow30s'
          if (param[l] eq 'phase' and tres[k] eq '30sec') then ptr = 'pha30s'
          ;--- Rename
          copy_data,  'lf_'+param[l]+'_'+tres[k], 'lfrto_'+site_code[i]+'_'+trans_code[j]+'_'+ptr
          store_data,  'lf_'+param[l]+'_'+tres[k], /delete
        endfor
      endif

    endfor
  endfor

endfor


;--- Acknowledgement
datfile = source.local_data_dir+relfnames[0]
if (show_text eq 1) then begin
  gatt = cdf_var_atts(datfile)
  dprint, '**********************************************************************'
  dprint, gatt.project
  dprint, ''
  dprint, 'PI and Host PI(s): ', gatt.PI_name
  dprint, 'Affiliations: ', 'PPARC, Tohoku University'
  dprint, ''
  dprint, 'Rules of the Road for LFRTO Data Use:'
  for igatt=0, n_elements(gatt.text)-1 do print_str_maxlet, gatt.text[igatt], 70
  dprint, ''
  dprint, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
  dprint, '**********************************************************************'
  dprint, ''
endif else begin
  dprint, 'No data is loaded'
  dprint, ''
endelse

return
end
