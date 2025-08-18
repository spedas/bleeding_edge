;+
; PROCEDURE: IUG_LOAD_GMAG_NIPR
;   iug_load_gmag_nipr, site = site, $
;                     datatype=datatype, $
;                     fproton=fproton, $
;                     trange=trange, $
;                     verbose=verbose, $
;                     downloadonly=downloadonly, $
;                     no_download=no_download
;
; PURPOSE:
;   Loads the fluxgate magnetometer data obtained by NIPR.
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_gmag_nipr, site='syo',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['syo', 'hus']
;           or a single string delimited by spaces, e.g., 'syo hus'.
;           Available sites: syo hus tjo aed isa
;   datatype = Time resolution. Please notice that '1sec' means nearly
;           1-sec time resolution. Even if datatype was set to '1sec', 
;           the time resolution corresponds to
;           2sec : syo(1981-1997), hus & tjo(1984-2001/08), isa(1984-1989), 
;                  aed(1989-1999/10)
;           1sec : syo(1997-present)
;           0.5sec  : hus & tjo(2001/09-present), aed(2001/09-2008/08)
;           At present, '1sec' is only available for datatype.
;   fproton = (Optional) if set, then total geomagnetic field intensity 
;           measured by proton magnetometer will be loaded.
;           This option is now available only for syo before 1987/4/14.
;   trange = (Optional) Time range of interest  (2 element array).
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it 
;           into variables.
;   /no_download: use only files which are online locally.
;
; EXAMPLE:
;   iug_load_gmag_nipr, site='syo', $
;                 trange=['2003-11-20/00:00:00','2003-11-21/00:00:00']
;
; NOTE: This load procedure was developed by ERG-Science Center and
;            IUGONET projects.
;            ERG website      http://gemsissc.stelab.nagoya-u.ac.jp/erg/
;            IUGONET website  http://www.iugonet.org/en/
;
; Written by H. Tadokoro, June 1, 2010
; The prototype of this procedure was written by Y. Miyashita, Apr 22, 2010, 
;        ERG-Science Center, STEL, Nagoya Univ.
; Revised by Y.-M. Tanaka, February 17, 2011 (ytanaka at nipr.ac.jp)
; Added new keyword "fproton" by Y.-M. Tanaka, August 22, 2011
; Changed from the alias to the original load procudure, by Y.-M
;         Tanaka, July 24, 2012.
; Added six automated magnetometer network stations to site, by by Y.-M
;         Tanaka, December 25, 2013.
;-

pro iug_load_gmag_nipr, site=site, datatype=datatype, fproton=fproton, $
        trange=trange, verbose=verbose, downloadonly=downloadonly, $
	no_download=no_download

;===== Keyword check =====
;----- default -----;
if ~keyword_set(fproton) then fproton=0
if ~keyword_set(verbose) then verbose=0
if ~keyword_set(downloadonly) then downloadonly=0
if ~keyword_set(no_download) then no_download=0

;----- site -----;
site_code_all = strsplit('syo hus tjo aed isa h57 amb srm ihd skl h68', /extract)
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return

print, site_code

;----- datatype -----;
if(not keyword_set(datatype)) then datatype='1sec'
datatype_all=strsplit('1sec', /extract)
if size(datatype,/type) eq 7 then begin
  datatype=ssl_check_valid_name(datatype,datatype_all, $
                                /ignore_case, /include_all)
  if datatype[0] eq '' then return
endif else begin
  message,'DATATYPE must be of string type.',/info
  return
endelse

datatype=datatype[0]

instr='fmag'

;===== Download files, read data, and create tplot vars at each site =====
;----- Loop -----
for i=0,n_elements(site_code)-1 do begin
  
  ;----- Set sampling time correspoding to input date -----;
  tr=timerange(trange)
  tr0=tr[0]
  if strlowcase(datatype) eq '1sec' then begin
    case site_code[i] of
      'syo': begin
        crttime=time_double('1998-1-1')
        if tr0 lt crttime then tres='2sec' else tres='1sec'
      end
      'hus': begin
        crttime=time_double('2001-09-08')
        if tr0 lt crttime then tres='2sec' else tres='02hz'
      end
      'tjo': begin
        crttime=time_double('2001-9-12')
        if tr0 lt crttime then tres='2sec' else tres='02hz'
      end
      'aed': begin
        crttime=time_double('2001-9-27')
        if tr0 lt crttime then tres='2sec' else tres='02hz'
      end
      'isa': begin
        tres='2sec'
      end
      else: begin
        tres='1sec'
      end
    endcase
  endif else begin
    tres=datatype
  endelse

  ;----- Set parameters for file_retrieve and download data files -----;
  source = file_retrieve(/struct)
  source.verbose = verbose
  source.local_data_dir  = root_data_dir() + 'iugonet/nipr/'
  source.remote_data_dir = 'http://iugonet0.nipr.ac.jp/data/'
  if keyword_set(no_download) then source.no_download = 1
  if keyword_set(downloadonly) then source.downloadonly = 1

  relpathnames1 = file_dailynames(file_format='YYYY', trange=trange)
  relpathnames2 = file_dailynames(file_format='YYYYMMDD', trange=trange)
  relpathnames  = instr+'/'+site_code[i]+'/'+tres+'/'+$
    relpathnames1 + '/nipr_'+tres+'_'+instr+'_'+site_code[i]+'_'+$
    relpathnames2 + '_v??.cdf'

  files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, no_server=no_server, no_download=no_download, _extra=source, /last_version)

  filestest=file_test(files)
  if total(filestest) ge 1 then begin
    files=files(where(filestest eq 1))
  endif

  ;----- Print PI info and rules of the road -----;
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
    print, 'Rules of the Road for NIPR Fluxgate Magnetometer Data:'
    print, ''
    print_str_maxlet, gatt.TEXT
    print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
    print, '**************************************************************************************'
  endif

  ;----- Load data into tplot variables -----;
  if(downloadonly eq 0) then begin
    ;----- Rename tplot variables of hdz_tres -----;
    prefix_tmp='nipr_'
    varformat='hdz_'+tres
    cdf2tplot, file=files, verbose=source.verbose, prefix=prefix_tmp, $
	varformat=varformat

    tplot_name_tmp=prefix_tmp+varformat
    len=strlen(tnames(tplot_name_tmp))

    if  len eq 0 then begin
      ;----- Quit if no data have been loaded -----;
      print, 'No tplot var loaded for '+site_code[i]+'.'
    endif else begin
      ;----- Rename tplot variables -----;
      tplot_name_new='nipr_mag_'+site_code[i]+'_'+tres
      copy_data, tplot_name_tmp, tplot_name_new
      store_data, tplot_name_tmp, /delete

      ;----- Missing data -1.e+31 --> NaN -----;
      tclip, tplot_name_new, -1e+5, 1e+5, /overwrite

      ;----- Labels -----;
      options, /def, tplot_name_new, labels=['H','D','Z'], $
                         ytitle = strupcase(strmid(site_code[i],0,3)), $
                         ysubtitle = '[nT]', labflag=1,colors=[2,4,6]
    endelse

    ;----- If keyword fproton is set, rename tplot variables of f_tres -----;
    if (fproton eq 1) then begin
      if (site_code[i] eq 'syo') and (tres eq '2sec') then begin
        prefix_tmp='nipr_'
        varformat='f_'+tres
        cdf2tplot, file=files, verbose=source.verbose, prefix=prefix_tmp, $
	    varformat=varformat

        tplot_name_tmp=prefix_tmp+varformat
        len=strlen(tnames(tplot_name_tmp))

        if len eq 0 then begin
          ;----- Quit if no data have been loaded -----;
          print, 'No tplot var loaded for '+site_code[i]+'.'
        endif else begin
          ;----- Rename tplot variables -----;
          tplot_name_new='nipr_mag_'+site_code[i]+'_'+tres+'_f'
          copy_data, tplot_name_tmp, tplot_name_new
          store_data, tplot_name_tmp, /delete

          ;----- Missing data -1.e+31 --> NaN -----;
          tclip, tplot_name_new, -1e+5, 1e+5, /overwrite

          ;----- Labels -----;
          options, tplot_name_new, labels=['F'], $
                         ytitle = strupcase(strmid(site_code[i],0,3)), $
                         ysubtitle = '[nT]'
	  ylim, tplot_name_new, 40000, 49000
        endelse
      endif
    endif

  endif

endfor

;---
return
end

