;+
; PROCEDURE: IUG_LOAD_ASK_NIPR
;   iug_load_ask_nipr, site = site, $
;                     wavelength=wavelength, $
;                     trange=trange, $
;                     verbose=verbose, $
;                     downloadonly=downloadonly, $
;                     no_download=no_download
;
; PURPOSE:
;   Loads the keogram of all-sky imager data obtained by NIPR.
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_ask_nipr, site='syo',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['syo', 'hus']
;           or a single string delimited by spaces, e.g., 'syo hus'.
;           Available sites as of April, 2013 : syo
;   wavelength = Wavelength in Angstrom, i.e., 4278, 5577, 6300, etc.
;           The 0000 means white light images taken without filter.
;           Only 0000 is available as of October, 2014.
;   trange = (Optional) Time range of interest  (2 element array).
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it 
;           into variables.
;   /no_download: use only files which are online locally.
;
; EXAMPLE:
;   iug_load_ask_nipr, site='syo', wavelength=0000, $
;                 trange=['2012-01-22','2012-01-23']
;
; Written by Y.-M. Tanaka, August, 2014 (ytanaka at nipr.ac.jp)
;-

;************************************************
;*** Load procedure for imaging riometer data ***
;***             obtained by NIPR             ***
;************************************************
pro iug_load_ask_nipr, site=site, wavelength=wavelength, $
        trange=trange, verbose=verbose, $
        downloadonly=downloadonly, no_download=no_download

;===== Keyword check =====
;----- default -----;
if ~keyword_set(verbose) then verbose=0
if ~keyword_set(downloadonly) then downloadonly=0
if ~keyword_set(no_download) then no_download=0

;----- site -----;
site_code_all = strsplit('hus tjo tro lyr spa syo mcm', /extract)
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return

print, site_code

;----- wavelength -----;
if(not keyword_set(wavelength)) then begin
    wlenstr='0000'
endif else begin
    wlenstr=wavelength
endelse

wlenstr_all=strsplit('0000 4278 4300 5577 5580 6300', /extract)
wlenstr=ssl_check_valid_name(wlenstr,wlenstr_all, $
                             /ignore_case, /include_all)
if wlenstr[0] eq '' then begin
    print, 'The input value for wavelength is not supported!'
    return
endif

;----- Set parameters for file_retrieve and download data files -----;
source = file_retrieve(/struct)
source.verbose = verbose
source.local_data_dir  = root_data_dir() + 'iugonet/nipr/'
source.remote_data_dir = 'http://iugonet0.nipr.ac.jp/data/'
; source.remote_data_dir = 'http://polaris.nipr.ac.jp/~ytanaka/data/'
if keyword_set(no_download) then source.no_download = 1
if keyword_set(downloadonly) then source.downloadonly = 1
relpathnames1 = file_dailynames(file_format='YYYY', trange=trange)
relpathnames2 = file_dailynames(file_format='YYYYMMDD', trange=trange)

instr='ask'

;===== Download files, read data, and create tplot vars at each site =====
;----- Loop -----
for i=0,n_elements(site_code)-1 do begin
  for j=0,n_elements(wlenstr)-1 do begin
    relpathnames  = instr+'/'+site_code[i]+'/'+relpathnames1+'/'+$
      'nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]+'_'+relpathnames2+$
      '_v??.cdf'
    files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

    filestest=file_test(files)
    if total(filestest) ge 1 then begin
      files=files[where(filestest eq 1)]
    endif

    ;----- Print PI info and rules of the road -----;
    if(file_test(files[0])) then begin
      gatt = cdf_var_atts(files[0])
      print, '**************************************************************************************'
      print, gatt.Logical_source_description
      print, ''
      print, 'Information about ', gatt.Station_code
      print, ''
      print, 'PI: ', gatt.PI_name
      print, ''
      print, 'Affiliations: ', gatt.PI_affiliation
      print, ''
      print, 'Rules of the Road for NIPR All-Sky Imager Data:'
      print_str_maxlet, gatt.TEXT
      print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
      print, '**************************************************************************************'
    endif

    ;----- Load data into tplot variables -----;
    if(downloadonly eq 0) then begin
      ;----- Rename tplot variables of hdz_tres -----;
      prefix_tmp='niprtmp_'
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

          ;----- ylim & degap -----;
          ylim, tplot_name_tmp[k], 0, 480
          tdegap, tplot_name_tmp[k], margin=6, /overwrite

          ;----- options -----;
          case param of
            'keo_raw_ns': begin
              options, tplot_name_tmp[k], ytitle=site_code[i]+' '+wlenstr[j]+'!CNS keogram', $
                ysubtitle = '[pixels]', spec=1, ztitle='[counts]'
              tplot_name_new='nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]+'_ns'
            end
            'keo_raw_ew': begin
              options, tplot_name_tmp[k], ytitle=site_code[i]+' '+wlenstr[j]+'!CEW keogram', $
                ysubtitle = '[pixels]', spec=1, ztitle='[counts]'
              tplot_name_new='nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]+'_ew'
            end
            else: tplot_name_new='nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]+'_'+param
          endcase

          ;----- Rename tplot variables -----;
          copy_data, tplot_name_tmp[k], tplot_name_new
          store_data, tplot_name_tmp[k], /delete
        endfor

      endelse
    endif
  endfor
endfor

;---
return
end
