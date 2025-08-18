;+
; PROCEDURE:  AKB_LOAD_PWS
;
; :Description:
;    This procedure reads Akebono/PWS spectrum data to generate tplot variables
;    containing them. Data files are automatically downloaded via the net if needed.
;
;    IDL and TDAS/SPEDAS should be installed properly to run this procedure.
;
; :Keywords:
;   trange:   two-element array of a time range for which data are loaded.
;   downloadonly:   Set to only download data files and suppress generating tplot variables.
;   no_download:  Set to suppress downloading data files via the net, and read them locally.
;   verbose:  Set an integer from 0 to 9 to get verbose error messages.
;                    More detailed logs show up with increasing number.

; :Examples:
;   IDL> timespan, '1990-02-02'
;   IDL> akb_load_pws
;
; :History:
;   2014-04-04: Initial release
;
; :Author:
;   Tomo Hori (horit at stelab.nagoya-u.ac.jp)
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-07-05 16:33:37 -0700 (Sat, 05 Jul 2025) $
; $LastChangedRevision: 33429 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/akebono/pws/akb_load_pws.pro $
;-
PRO akb_load_pws, $
  trange=trange, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  verbose=verbose
  
  ;Initialize the TDAS environment
  thm_init
  
  ;Set up the structure including the local/remote data directories.
  source = file_retrieve( /struct )
  source.local_data_dir = root_data_dir()+'akebono/pws/NPW-DS/'
  source.remote_data_dir = 'https://data.darts.isas.jaxa.jp/pub/akebono/pws//NPW-DS/'
  
  if keyword_set(downloadonly) then source.downloadonly=1
  if keyword_set(no_download) then source.no_download=1
  if keyword_set(verbose) then source.verbose =verbose
  if keyword_set(trange) and n_elements(trange) eq 2 then timespan, time_double(trange)
  
  ;Relative path with wildcards for data files
  pathformat = 'YYYY/ak_h1_pws_YYYYMMDD_v01.cdf'
  
  ;Expand the wildcards in the relative file paths for designated
  ;time range, which is set by "timespan".
  relpathnames = file_dailynames(file_format=pathformat)
  
  ;Check the time stamps of data files and download  if they are newer
  files = spd_download(remote_file=relpathnames, _extra=source, /last_version)
  if keyword_set(downloadonly) then return
  
  ;Exit unless data files are downloaded or found locally.
  idx = where( file_test(files) )
  if idx[0] eq -1 then begin
    message, /cont, 'No data file is found in the local repository for the designated time range!'
    return
  endif
  ;Get the list of locally exisiting data files
  fpaths = files[idx]
  
  prefix = 'akb_pws_' ;Prefix for tplot variable name
  ; Read CDF files and load data as tplot variables
  cdf2tplot,file=fpaths,verbose=source.verbose,prefix=prefix
  
  ;Set labels, plot ranges, and so forth
  ylim, prefix+'RX?',2.0e4,5.1e6, 1  ;log scale for Y-axis
  options, prefix+'RX?', 'ztitle', '[dB]'
  options, prefix+'RX?', 'ysubtitle', '[Hz]'
  options, prefix+'RX1', 'ytitle', 'akb!Cpws!CE-field RX1'
  
  return
end
