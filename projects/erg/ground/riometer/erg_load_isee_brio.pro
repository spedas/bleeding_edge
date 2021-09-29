;+
; PROCEDURE: ERG_LOAD_ISEE_BRIO
;
; PURPOSE:
;   Loads the broadbeam riometer data obtained from ISEE riometer network.
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_brio_nipr, site='syo',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['ath', 'hus']
;           or a single string delimited by spaces, e.g., 'ath hus'.
;           Available sites as of July, 2017 : ath, kap, gak, hus
;   datatype = observation frequency in MHz for imaging riometer
;           At present, '30' is only available for datatype.
;   trange = (Optional) Time range of interest  (2 element array).
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it
;           into variables.
;   /no_download: use only files which are online locally.
;
; EXAMPLE:
;   erg_load_isee_brio, site='ath', $
;                 trange=['2017-03-20/00:00:00','2017-03-21/00:00:00']
;
; HISTORY:
; 2017-07-06: Initial release by Satoshi Kurita, ISEE, Nagoya U.(kurita at isee.nagoya-u.ac.jp)
;             with support from Yoshimasa Tanaka (NIPR)
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;
;-

pro erg_load_isee_brio, site=site, trange=trange, $
      verbose=verbose, downloadonly=downloadonly, $
	    no_download=no_download

;===== Keyword check =====
;----- default -----;
if ~keyword_set(verbose) then verbose=0
if ~keyword_set(downloadonly) then downloadonly=0
if ~keyword_set(no_download) then no_download=0

;----- site -----;
site_code_all = strsplit('ath kap gak hus zgn ist', /extract)
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return

;----- datatype -----;
datatype='64hz'
instr='brio'
freq='30'

;===== Download files, read data, and create tplot vars at each site =====
;----- Loop -----
for i=0,n_elements(site_code)-1 do begin
  tres=datatype

  ;----- Set parameters for spd_download and download data files -----;
  source = file_retrieve(/struct)
  source.verbose = verbose
  source.local_data_dir  = root_data_dir() + 'ergsc/'
  source.remote_data_dir = 'https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/'
  if keyword_set(no_download) then source.no_download = 1
  if keyword_set(downloadonly) then source.downloadonly = 1

  file_format  = 'ground/riometer/'+site_code[i]+'/'+$
                  'YYYY/isee_'+tres+'_'+instr+freq+'_'+site_code[i]+'_'+$
                  'YYYYMMDD_v??.cdf'

  relpathnames=file_dailynames(file_format=file_format,trange=trange)

  files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

  filestest=file_test(files)
  if total(filestest) ge 1 then begin
    files=files(where(filestest eq 1))

  ;----- Load data into tplot variables -----;
    if(downloadonly eq 0) then begin
    ;----- Rename tplot variables of hdz_tres -----;
      prefix_tmp='iseetmp_'
      cdf2tplot, file=files, verbose=source.verbose, prefix=prefix_tmp

      tplot_name_tmp=tnames(prefix_tmp+'*')
      len=strlen(tplot_name_tmp[0])

      if len eq 0 then begin
        ;----- Quit if no data have been loaded -----;
        print, 'No tplot var loaded for '+site_code[i]+'.'
      endif else begin
      ;----- Loop for params -----;
        for k=0, n_elements(tplot_name_tmp)-1 do begin
        ;----- Find param -----;
          len=strlen(tplot_name_tmp[k])
          pos=strpos(tplot_name_tmp[k],'_')
          param=strmid(tplot_name_tmp[k],pos+1,len-pos-1)

        ;----- Rename tplot variables -----;
          tplot_name_new='isee_brio'+freq+'_'+site_code[i]+'_'+tres+'_'+param
          copy_data, tplot_name_tmp[k], tplot_name_new
          store_data, tplot_name_tmp[k], /delete

        ;----- Missing data -1.e+31 --> NaN -----;
          tclip, tplot_name_new, -1e+5, 1e+5, /overwrite

        ;----- Set options -----;
          case param of
        	  'cna' : begin
        	    options, tplot_name_new, $
       	      ytitle = strupcase(strmid(site_code[i],0,3)), $
              ysubtitle = '[dB]', labels='CNA'
            end
      	   'qdc' : begin
  	          options, tplot_name_new,$
 	            ytitle = strupcase(strmid(site_code[i],0,3)), $
              ysubtitle = '[V]', labels='QDC'
            end
            'raw' : begin
    	         options, tplot_name_new,$
   	           ytitle = strupcase(strmid(site_code[i],0,3)), $
               ysubtitle = '[V]', labels='Raw data'
            end
          endcase
        endfor
      endelse
    endif

    if(file_test(files[0])) then begin
      gatt = cdf_var_atts(files[0])
      print, '**************************************************************************************'
      ;print, gatt.project
      print, gatt.Logical_source_description
      print, ''
      print, 'Information about ', gatt.Station_code
      print, 'PI: ', gatt.PI_name
      print, 'Affiliations: ', gatt.PI_affiliation
      print, ''
      print, 'Rules of the Road for ISEE Riometer Data:'
      print, ''
      print_str_maxlet, gatt.TEXT
      print, gatt.LINK_TEXT
      print, '**************************************************************************************'
    endif
  endif
endfor
;---
return
end
