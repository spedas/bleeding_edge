;+
; PROCEDURE: IUG_LOAD_IRIO_NIPR
;   iug_load_irio_nipr, site = site, $
;                     datatype=datatype, $
;                     trange=trange, $
;                     verbose=verbose, $
;                     downloadonly=downloadonly, $
;                     no_download=no_download
;
; PURPOSE:
;   Loads the imaging riometer data obtained by NIPR.
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_irio_nipr, site='syo',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['syo', 'hus']
;           or a single string delimited by spaces, e.g., 'syo hus'.
;           Available sites as of April, 2013 : syo
;   datatype = observation frequency in MHz for imaging riometer
;           At present, '30' or '38' is only available for datatype.
;   trange = (Optional) Time range of interest  (2 element array).
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it 
;           into variables.
;   /no_download: use only files which are online locally.
;
; EXAMPLE:
;   iug_load_irio_nipr, site='syo', $
;                 trange=['2003-11-20/00:00:00','2003-11-21/00:00:00']
;
; Written by Y.-M. Tanaka, December, 2012 (ytanaka at nipr.ac.jp)
;-

;===== Make kegorams from IRIO data =====;
pro get_keogram_irio, tvar

  npar = n_params()
  if npar lt 1 then begin
    message,'No input tplot variables.',/info
    return
  endif
  if strlen(tnames(tvar[0])) eq 0 then return

  beam_no=findgen(8)
  for ins=0, 7 do begin
    get_data, tvar, data=d, lim=lim, dlim=dlim
    dns = reform( d.y[*, ins, *] )
    tvar_new=tvar+'_N'+string(ins, format='(i1.1)')+'E0-7'
    store_data, tvar_new, data={x:d.x, y:dns, v:beam_no}, dlim=dlim
    options, tvar_new, spec=1, $
             ztitle = '[dB]', ysubtitle=''
  endfor
  for iew=0, 7 do begin
    get_data, tvar, data=d, lim=lim, dlim=dlim
    dew = reform( d.y[*, *, iew] )
    tvar_new=tvar+'_N0-7E'+string(iew, format='(i1.1)')
    store_data, tvar_new, data={x:d.x, y:dew, v:beam_no}, dlim=dlim
    options, tvar_new, spec=1, $
             ztitle = '[dB]', ysubtitle=''
  endfor

end


;************************************************
;*** Load procedure for imaging riometer data ***
;***             obtained by NIPR             ***
;************************************************
pro iug_load_irio_nipr, site=site, datatype=datatype, keogram=keogram, $
        trange=trange, verbose=verbose, downloadonly=downloadonly, $
	no_download=no_download

;===== Keyword check =====
;----- default -----;
if ~keyword_set(verbose) then verbose=0
if ~keyword_set(downloadonly) then downloadonly=0
if ~keyword_set(no_download) then no_download=0

;----- site -----;
site_code_all = strsplit('syo hus tjo zho', /extract)
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return

print, site_code

;----- datatype -----;
datatype_all=strsplit('30 38', /extract)
if(not keyword_set(datatype)) then datatype='all'
if size(datatype,/type) eq 7 then begin
  datatype=ssl_check_valid_name(datatype,datatype_all, $
                                /ignore_case, /include_all)
  if datatype[0] eq '' then return
endif else begin
  message,'DATATYPE must be of string type.',/info
  return
endelse

instr='irio'

;===== Download files, read data, and create tplot vars at each site =====
;----- Loop -----
for i=0,n_elements(site_code)-1 do begin
  ;----- Check datatype -----;
  tr=timerange(trange)
  tr0=tr[0]
  if(not keyword_set(datatype)) then datatype='all'
  case site_code[i] of
    'hus': datatype_all='38'
    'tjo': datatype_all='30'
    'zho': datatype_all='30'
    'syo': begin
      crttime=time_double('2007-1-1')
      if tr0 lt crttime then datatype_all='30' else $
	datatype_all=strsplit('30 38', /extract)
    end
  endcase
  if size(datatype,/type) eq 7 then begin
    datatype=ssl_check_valid_name(datatype,datatype_all, $
                                  /ignore_case, /include_all)
    if datatype[0] eq '' then return
  endif else begin
    message,'DATATYPE must be of string type.',/info
    return
  endelse

;  print, datatype
  
  for j=0,n_elements(datatype)-1 do begin

    ;----- Set parameters for file_retrieve and download data files -----;
    source = file_retrieve(/struct)
    source.verbose = verbose
    source.local_data_dir  = root_data_dir() + 'iugonet/nipr/'
    source.remote_data_dir = 'http://iugonet0.nipr.ac.jp/data/'
    if keyword_set(no_download) then source.no_download = 1
    if keyword_set(downloadonly) then source.downloadonly = 1

    relpathnames1 = file_dailynames(file_format='YYYY', trange=trange)
    relpathnames2 = file_dailynames(file_format='YYYYMMDD', trange=trange)
    relpathnames  = instr+'/'+site_code[i]+'/'+$
      relpathnames1 + '/nipr_h0_'+instr+datatype[j]+'_'+site_code[i]+'_'+$
      relpathnames2 + '_v??.cdf'

    files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

    filestest=file_test(files)
      if total(filestest) ge 1 then begin
      files=files(where(filestest eq 1))
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
      print, 'Rules of the Road for NIPR Imaging Riometer Data:'
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

          ;----- Rename tplot variables -----;
          tplot_name_new='nipr_irio'+datatype[j]+'_'+site_code[i]+'_'+param
          copy_data, tplot_name_tmp[k], tplot_name_new
          store_data, tplot_name_tmp[k], /delete

          ;----- Missing data -1.e+31 --> NaN -----;
          tclip, tplot_name_new, -1e+5, 1e+5, /overwrite

          ;----- Set options -----;
          case param of
	    'cna' : begin
	      options, tplot_name_new, $
		ytitle = strupcase(strmid(site_code[i],0,3)), $
                ysubtitle = '[dB]', spec=0, ztitle='[dB]'

              ;----- Make keogram -----;
              if keyword_set(keogram) then begin
                get_keogram_irio, tplot_name_new
              endif
	    end
	    'qdc' : begin
	      options, tplot_name_new,$
	        ytitle='QDC', spec=0
            end
          endcase
        endfor

        ;----- Load positions -----;
        cdfi = cdf_load_vars(files[0], varformat='*')
        tmvn = (strfilter(cdfi.vars.name, 'epoch_1sec'))[0]
        azvn = (strfilter(cdfi.vars.name, 'azimuth_angle'))[0]
        zevn = (strfilter(cdfi.vars.name, 'zenith_angle'))[0]
        tmvnidx = (where(strcmp(cdfi.vars.name, tmvn) , cnt))[0]
        azvnidx = (where(strcmp(cdfi.vars.name, azvn) , cnt))[0]
        zevnidx = (where(strcmp(cdfi.vars.name, zevn) , cnt))[0]
        timetmp = *cdfi.vars[tmvnidx].dataptr
        aztmp  = *cdfi.vars[azvnidx].dataptr
        zetmp  = *cdfi.vars[zevnidx].dataptr

        sbeam=size(aztmp)
        az=fltarr(sbeam[1], sbeam[2], 2) & ze=fltarr(sbeam[1], sbeam[2], 2)
        time=[timetmp[0], timetmp[n_elements(timetmp)-1]]
        az[*,*,0]=aztmp & az[*,*,1]=aztmp
        ze[*,*,0]=zetmp & ze[*,*,1]=zetmp
        store_data, 'nipr_irio'+datatype[j]+'_'+site_code[i]+'_az', $
                    data={x:time_double(time,/epoch), y:az}
        store_data, 'nipr_irio'+datatype[j]+'_'+site_code[i]+'_ze', $
                    data={x:time_double(time,/epoch), y:ze}
      endelse
    endif
  endfor
endfor

;---
return
end
