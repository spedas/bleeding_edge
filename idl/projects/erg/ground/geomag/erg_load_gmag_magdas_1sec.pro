;+
; PROCEDURE: erg_load_gmag_magdas_1sec
;
; PURPOSE:
;   To load the MAGDAS geomagnetic data from the STEL ERG-SC site
;
; KEYWORDS:
;   site  = Observatory name, example, erg_load_magdas_1sec, site='asb',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['asb', 'onw']
;           or a single string delimited by spaces, e.g., 'asb onw'.
;           Sites for 1 sec data:
;              asb ...
;           Sites for 1 min/h data:
;              ...
;   datatype = Time resolution. '1sec' for 1 sec', '1min' for 1 min, and '1h' for 1 h.
;              The default is 'all'.  If you need two of them, set to 'all'.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   /verbose
;   trange = (Optional) Time range of interest  (2 element array).
;
; EXAMPLE:
;   erg_load_gmag_magdas_1sec, site='asb onw', datatype='1sec', $
;                        trange=['2010-11-20/00:00:00','2010-11-21/00:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://magdas.serc.kyushu-u.ac.jp/
;
; Written by: T. Segawa, June 30, 2011
; The prototype of this procedure was written by Y. Miyashita, Apr 22, 2010
;             ERG-Science Center, STEL, Nagoya Univ.
;             erg-sc-core at st4a.stelab.nagoya-u.ac.jp
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

pro erg_load_gmag_magdas_1sec, site=site, datatype=datatype, $
  downloadonly=downloadonly, no_server=no_server, $
  verbose=verbose, $
  no_download=no_download, trange=trange, range=range

  ; *** define & init ***
  ergFIX = 'ergsc/'
  ergURL = 'https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/'
  ; *********************

  DEFSYSV, '!ERG', exist=existERG

  if keyword_set(trange) then trng=trange
  if keyword_set(range) then trng=range

  ;*** site codes ***
  ;--- aliases
  if (n_elements(site) ne 0) then begin
    site = strjoin(site, ' ')
    site = strsplit(strlowcase(site), ' ', /extract)
  endif

  ;--- all sites (default)
  site_code_all = strsplit( $
    'ama asb daw her hln hob kuj laq mcq mgd mlb mut onw ptk wad yap ' $
    + ' ' , ' ', /extract)

  ;--- check site codes
  if (n_elements(site) eq 0) then site='all'
  site_code = ssl_check_valid_name(site, site_code_all, $
    /ignore_case, /include_all)

  print, site_code

  ;*** keyword set ***
  if  (n_elements(datatype) eq 0) then datatype='all'
  if  (not keyword_set(downloadonly)) then downloadonly=0
  if  (not keyword_set(no_server)) then no_server=0
  if  (not keyword_set(no_download)) then no_download=0
  IF  (not keyword_set(verbose)) THEN BEGIN
    IF existERG EQ 0 THEN BEGIN
      verbose=0
    ENDIF ELSE BEGIN
      IF keyword_set(!ERG.VERBOSE) THEN verbose = !ERG.VERBOSE ELSE verbose=0
    ENDELSE
  ENDIF

  ;*** time resolution ***
  case strlowcase(strjoin(datatype,' ')) of
    '1sec': begin
      tres=['1sec', '',     '']   & nfloads=0 & nfloade=0
    end
    ;;  '1min': begin
    ;;            tres=['',     '1min', '']   & nfloads=1 & nfloade=1
    ;;          end
    ;;  '1h':   begin
    ;;            tres=['',     '',     '1h'] & nfloads=1 & nfloade=1
    ;;          end
    'all':  begin
      ;;            tres=['1sec', '1min', '1h'] & nfloads=0 & nfloade=1
      tres=['1sec', '', ''] & nfloads=0 & nfloade=0
    end
    else:   begin
      tres=['1sec', '', ''] & nfloads=0 & nfloade=0
      ;;            tres=['1sec', '1min', '1h'] & nfloads=0 & nfloade=1
    end
  endcase

  ;*** load CDF ***
  ;--- Create (and initialize) a data file structure
  source = file_retrieve(/struct)

  ;--- Set parameters for the data file class
  IF (existERG EQ 1) THEN BEGIN
    IF keyword_set(!ERG.LOCAL_DATA_DIR) THEN BEGIN
      LD_DIR =  root_data_dir() + ergFIX
    ENDIF ELSE LD_DIR = !ERG.LOCAL_DATA_DIR
  ENDIF ELSE LD_DIR =  root_data_dir() + ergFIX
  IF (existERG EQ 1) THEN BEGIN
    IF keyword_set(!ERG.REMOTE_DATA_DIR) THEN BEGIN
      RMT_DIR = ergURL
    ENDIF ELSE RMT_DIR = !ERG.REMOTE_DATA_DIR
  ENDIF ELSE RMT_DIR = ergURL
  IF keyword_set(no_download) THEN source.no_download = 1
  IF keyword_set(downloadonly) THEN source.downloadonly = 1

  ;--- Generate the file paths by expanding wilecards of date/time
  ;    (e.g., YYYY, YYYYMMDD) for the time interval set by "timespan"
  relpathnames1 = file_dailynames(file_format='YYYY', trange=trng)
  relpathnames2 = file_dailynames(file_format='YYYYMMDD', trange=trng)

  for i=0, n_elements(site_code)-1 do begin
    for j=nfloads, nfloade do begin
      case j of
        0: fres='1sec'
        1: fres='1min'
      endcase

      ;--- Set the file path which is added to source.local_data_dir/remote_data_dir.
      ;pathformat = 'ground/geomag/mm210/'+fres+'/SSS/YYYY/mm210_'+fres+'_SSS_YYYYMMDD_v??.cdf'

      ;--- Generate the file paths by expanding wilecards of date/time
      ;    (e.g., YYYY, YYYYMMDD) for the time interval set by "timespan"
      ;relpathnames = file_dailynames(file_format=pathformat)
      ;relpathnames  = 'ground/geomag/magdas/' + fres + '/' + site_code[i] $
      ;		+ '/' + relpathnames1 + '/magdas_' + fres + '_' $
      ;		+ site_code[i] + '_' + relpathnames2 + '_v??.cdf'
      relpathnames  = 'ground/geomag/magdas/' + fres + '/' + site_code[i] + '/'
      rp = RMT_DIR + relpathnames
      rf = relpathnames1 + '/magdas_' + fres + '_' + site_code[i] + '_' + relpathnames2 + '_v??.cdf'
      ld = LD_DIR + relpathnames
      ;	*** DEBUG ***
      IF verbose THEN BEGIN
        PRINT, '%%% remote_path : ' + rp
        PRINT, '%%% remote_file : ' + rf
        PRINT, '%%% local_path  : ' + ld
      ENDIF
      ;   *************
      ;--- Download the designated data files from the remote data server
      ;    if the local data files are older or do not exist.
      ;files = file_retrieve(relpathnames, _extra=source, /last_version, $
      ;          no_server=no_server, no_download=no_download)
      files = spd_download(remote_file = rf, $
        remote_path = rp, local_path = ld, /last_version, $
        no_download=no_download, no_update=no_download, _extra=source)

      if (file_test(files[0])) then begin
        ;--- Load data into tplot variables
        if (downloadonly eq 0) then begin
          cdf2tplot, file=files, verbose=source.verbose, $
            prefix='magdas_', suffix='_' + site_code[i], $
            varformat='*_' + tres[where(tres[j:j*2] ne '')+j] + '*'
          ;;		varformat='*hdz_' + tres[where(tres[j:j*2] ne '')+j] + '*'

          for k=j, j*2 do begin
            if (tres[k] ne '') then begin
              ;--- Rename *** HDZ
              copy_data,  'magdas_hdz_' + tres[k] + '_' + site_code[i], $
                'magdas_mag_' + site_code[i] + '_' + tres[k] + '_hdz'
              store_data, 'magdas_hdz_' + tres[k] + '_' + site_code[i], /delete
              ;--- Missing data -1.e+31 --> NaN
              tclip, 'magdas_mag_' + site_code[i] + '_' + tres[k] + '_hdz', $
                -7e+4, 7e+4, /overwrite
              ;;		-1e+31, 1e+31, /overwrite
              ;--- Labels
              options, '*_hdz', labels=['H','D','Z'], labflag=1, colors=[2,4,6]
              ; --- Rename *** F
              copy_data,  'magdas_f_' + tres[k] + '_' + site_code[i], $
                'magdas_mag_' + site_code[i] + '_' + tres[k] + '_f'
              store_data, 'magdas_f_' + tres[k] + '_' + site_code[i], /delete
              ;--- Missing data -1.e+31 --> NaN
              tclip, 'magdas_mag_' + site_code[i] + '_' + tres[k] + '_f', $
                -7e+4, 7e+4, /overwrite
              ;;		-1e+31, 1e+31, /overwrite
              ;--- Labels
              options, '*_f', labels=['F']

              ; --- Delete
              del_data, 'magdas_time_' + tres[k] + '_' + site_code[i]
              del_data, 'magdas_time_cal_' + tres[k] + '_' + site_code[i]
            endif
          endfor
        endif

        ;--- print PI info and rules of the road
        gatt = cdf_var_atts(files[0])

        print, '**************************************************************************************'
        ;print, gatt.project
        print, gatt.Logical_source_description
        print, ''
        print, 'Information about ', gatt.Station_code
        print, 'PI and Host PI(s): ', gatt.PI_name
        ;; print, 'Affiliations: ', gatt.PI_affiliation
        PRINT, 'Affiliations:'
        piaff = STRSPLIT(gatt.PI_affiliation, '\([1-9]\)', /REGEX, /EXTRACT)
        FOR igatt=0, N_ELEMENTS(piaff)-1 DO BEGIN
          piaff[igatt]='('+STRING(igatt+1,FORMAT='(i0)')+')'+piaff[igatt]
          print_str_maxlet, piaff[igatt], 70
        ENDFOR
        print, ''
        print, 'Rules of the Road for MAGDAS Data Use:'
        ;;      print, gatt.text
        FOR l=0, n_elements(gatt.text)-1 DO PRINT, gatt.text(l)
        print, ''
        print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
        print, '**************************************************************************************'

      endif
    endfor   ; end of for loop of j
  endfor   ; end of for loop of i

  ;---
  return
end
