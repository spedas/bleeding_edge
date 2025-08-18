;+
; PRO  erg_load_xep
;
; :Description:
;    The data read script for ERG/XEP data.
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   datatype: Data type to be loaded. Currently "omniflux" and "2dflux" are acceptable.
;   trange: If a time range is set, timespan is executed with it at the end of this program
;   /get_support_data, load support_data variables as well as data variables into tplot variables.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   verbose:  Set to make some commands in this program verbose.
;   varformat: If set a string with wildcards, only variables with
;              matching names are extracted as tplot variables.
;   localdir: Set a local directory path to save data files in the
;             designated directory.
;   remotedir: Set a remote directory in the URL form where the
;              program will look for data files to download.
;   datafpath: If set a full file path of CDF file(s), then the
;              program loads data from the designated CDF file(s), ignoring any
;              other options specifying local/remote data paths.
;   uname: user ID to be passed to the remote server for
;          authentication.
;   passwd: password to be passed to the remote server for
;           authentication.
;   get_filever:  If set, file version infromation is stored as a tplot variable
;
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_xep
;   IDL> erg_load_xep, datatype='omniflux'
;   IDL> erg_load_xep, datatype='2dflux'
;
; :History:
; 2016/02/01: first protetype
; 2018/08/01: modified to load omni-directional XEP L2 data
; 2019/01/22: modified to load spin-phase XEP L2 data
; 2020/04/21: modified to display RoR
; 2020/12/09: add get_filever keyword
;
; :Author:
;   Y. Miyashita, ERG Science Center, ISEE, Nagoya Univ. (erg-sc-core at isee.nagoya-u.ac.jp)
;   M. Teramoto, ERG Science Center, ISEE, Nagoya Univ.
;   S. Imajo, ERG Science Center, ISEE, Nagoya Univ.
;
; $LastChangedDate: 2024-05-28 12:15:53 -0700 (Tue, 28 May 2024) $
; $LastChangedRevision: 32652 $
;-
pro erg_load_xep, $
  debug=debug, $
  level=level, $
  datatype=datatype, $
  trange=trange, $
  get_support_data=get_support_data, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  verbose=verbose, $
  varformat=varformat,$
  localdir=localdir, $
  remotedir=remotedir, $
  datafpath=datafpath, $
  get_filever=get_filever, $
  uname=uname, $
  passwd=passwd

  ;Initialize the system variable for ERG
  erg_init

  ;Arguments and keywords
  if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
  if ~keyword_set(level) then lvl = 'l2'
  if ~keyword_set(datatype) then datatype = 'omniflux'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0
  if ~keyword_set(varformat) then varformat='*'
  if undefined( azch_for_spinph ) then azch_for_spinph = -1
  if azch_for_spinph lt 0 or azch_for_spinph gt 14 then azch_for_spinph = -1
  ;Local and remote data file paths

  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
    localdir =    !erg.local_data_dir      + 'satellite/erg/xep/'+lvl+'/' +datatype+'/'
  endif
  if ~keyword_set(remotedir) then begin
    remotedir = !erg.remote_data_dir + 'satellite/erg/xep/'+lvl+'/'+datatype+'/'
  endif

  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir

  ;Relative file path
  relfpathfmt = 'YYYY/MM/erg_xep_' + lvl + '_' +datatype + '_' + 'YYYYMMDD_v??_??.cdf'

  ;Expand the wildcards for the designated time range
  relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
  if debug then print, 'RELFPATHS: ', relfpaths

  ;Download data files
  if keyword_set(datafpath) then datfiles = datafpath else begin
    datfiles = $
      spd_download( remote_file = relfpaths, $
      remote_path = remotedir, local_path = localdir, /last_version,$
      url_username=uname, url_password=passwd,no_download=no_download)
  endelse
  idx = where( file_test(datfiles), nfile )
  if nfile eq 0 then begin
    print, 'Cannot find any data file. Exit!'
    return
  endif
  datfiles = datfiles[idx] ;;Clip empty strings and non-existing files
  if keyword_set(downloadonly) then return ;;Stop here if downloadonly is set

  ;Read CDF files and generate tplot variables
  prefix = 'erg_xep_'+lvl+'_'
  cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
    verbose = verbose, varformat=varformat

  for i=0, 1 do begin
    case (i) of
      0: begin
        suf = 'SSD'
      end
      1: begin
        suf = 'GSO'
      end
    endcase

    if datatype eq 'omniflux' then begin
      if tnames(prefix+'FEDO_SSD') eq '' then begin
        dprint, prefix+'Failed loading FEDO_SSD data! Exit.'
        return
      endif
      get_data,prefix+'FEDO_'+suf,data=fedo,dl=dl,lim=lim
      new_v=fltarr(n_elements(fedo.v(0,*)))
      for ik=0, n_elements(fedo.v(0,*))-1 do $
        new_v[ik]=sqrt(fedo.v(0,ik)*fedo.v(1,ik))
      store_data,prefix+'FEDO_'+suf,data={x:fedo.x,y:fedo.y,v:new_v},$
        dl=dl,lim=lim
      tclip,prefix+'FEDO_'+suf,0.05,2.0e5,/over
      options,prefix+'FEDO_'+suf,labels=strcompress(string(new_v,format='(I4.4)')+' keV'),$
        labflag=-1,ylog=1,zlog=1, ztickformat='pwr10tick',ytitle='ERG XEP!CFEDO_'+suf,ysubtitle='Energy [keV]',$
        ztitle='[/cm!U2!N-str-s-keV]'
      ylim,prefix+'FEDO_'+suf,450,5000
    endif

    ;; Skip the following part unless 2-D flux data are loaded.
    if strcmp(datatype, '2dflux')  then begin
      get_data, prefix+'FEDU_'+suf, data=fedu, dl=dl, lim=lim
     get_data, prefix+'rawcnt_'+suf, data=rwcnt, dl=dl_rwcnt, lim=lim_rwcnt
     new_v=fltarr(n_elements(fedu.v(*,0)))
      for ik=0, n_elements(fedu.v(*,0))-1 do $
        new_v[ik]=sqrt(fedu.v(ik,0)*fedu.v(ik,1))
      store_data,prefix+'FEDU_'+suf,data={x:fedu.x,y:fedu.y,v:new_v},$
        dl=dl,lim=lim
      store_data,prefix+'rawcnt_'+suf,data={x:rwcnt.x,y:rwcnt.y,v:new_v},$
        dl=dl_rwcnt,lim=lim_rwcnt
      ;Split into each azimuthal channel
     options,prefix+'FEDU_'+suf,labels=strcompress(string(new_v,format='(I4.4)')+' keV'),spec=1,$
        labflag=-1,ylog=1,zlog=1, ztickformat='pwr10tick',ytitle='ERG XEP!CFEDU_'+suf,ysubtitle='Energy [keV]',$
        ztitle='[/cm!U2!N-str-s-keV]'
     options,prefix+'rawcnt_'+suf,labels=strcompress(string(new_v,format='(I4.4)')+' keV'),spec=1,$
        labflag=-1,ylog=1,zlog=1, ztickformat='pwr10tick',ytitle='ERG XEP!Crawcnt'+suf,ysubtitle='Energy [keV]',$
        ztitle='[count/sample]'
      ylim,prefix+'FEDU_*'+suf,450,5000
      ylim,prefix+'rawcnt_*'+suf,450,5000
    endif

  endfor

  ; storing data information
  if KEYWORD_SET(get_filever) then erg_export_filever, datfiles

  ;--- print PI info and rules of the road
  gatt=dl.cdf.gatt


  print_str_maxlet, ' '
  print, '**************************************************************************'
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
  print, ''
  print, 'Information about ERG XEP'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
  print, ''
  print, 'RoR of ERG project common: https://ergsc.isee.nagoya-u.ac.jp/data_info/rules_of_the_road.shtml.en'
  print, 'RoR of XEP: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Xep'
  print, 'Contact: erg_xep_info at isee.nagoya-u.ac.jp'
  print, '**************************************************************************'
  print, ''

  return
end
