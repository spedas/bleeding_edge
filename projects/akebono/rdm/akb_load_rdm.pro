;+
; PROCEDURE: AKB_LOAD_RDM
;
; :Description:
;    This procedure reads Akebono/RDM data to generate tplot variables
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
;   IDL> timespan, '2012-10-01'
;   IDL> akb_load_rdm
;
; :History:
;   2014-04-04: Initial release
;   2014-07-16: Revised
;
; :Author:
;   Yoshi Miyoshi (miyoshi at stelab.nagoya-u.ac.jp)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2015-11-18 14:02:09 -0800 (Wed, 18 Nov 2015) $
; $LastChangedRevision: 19410 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/akebono/rdm/akb_load_rdm.pro $
;-


function get_akb_rdm_txt_template

  tmpl = { $
    version:float(1.0),$
    datastart:long(1),$
    delimiter:byte(32),$
    missingvalue:float('NaN'),$
    commentsymbol:';',$
    fieldcount:long(11),$
    fieldtypes:long([7,7,4,4,4,4,4,4,4,4,4]), $
    fieldnames:['FIELD01', 'FIELD02', 'FIELD03', 'FIELD04', 'FIELD05', 'FIELD06', 'FIELD07', 'FIELD08', 'FIELD09', 'FIELD10', 'FIELD11'],$
    fieldlocations:long([0,9,17,23,30,37,43,50,59,65,73]),$
    fieldgroups:long([0,1,2,3,4,5,6,7,8,9,10]) $
  }

  return, tmpl
end


PRO akb_load_rdm, $
  trange=trange, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  verbose=verbose


  thm_init

  source = file_retrieve( /struct )
  source.local_data_dir = root_data_dir()+'exosd/rdm/'
  source.remote_data_dir = 'http://darts.isas.jaxa.jp/stp/data/exosd/rdm/'
  if keyword_set(no_download) then source.no_download = 1
  if keyword_set(downloadonly) then source.downloadonly = 1
  if keyword_set(verbose) then source.verbose=verbose
  if keyword_set(trange) and n_elements(trange) eq 2 then timespan, time_double(trange)


  tmpl = get_akb_rdm_txt_template()

  pathformat = 'YYYY/sfyyMMDD'

  relpathnames = file_dailynames(file_format=pathformat,trange=trange)

  prefix_project = 'akb_'
  prefix_descriptor = 'rdm_'
  prefix = prefix_project + prefix_descriptor

  files = file_retrieve(relpathnames, _extra=source, /last_version)
  if keyword_set(downloadonly) then return

  ;Exit unless data files are downloaded or found locally.
  idx = where( file_test(files) )
  if idx[0] eq -1 then begin
    message, /cont, 'No data file is found in the local repository for the designated time range!'
    return
  endif


  for j=0,n_elements(files)-1 do begin
    if file_lines(files[j]) gt 1 then begin
      data=read_ascii(files[j],template=tmpl)
      append_array,data_sum0,data.field01
      append_array,data_sum1,data.field02
      append_array,data_sum2,data.field03
      append_array,data_sum3,data.field04
      append_array,data_sum4,data.field05
      append_array,data_sum5,data.field06
      append_array,data_sum6,data.field07
      append_array,data_sum7,data.field08
      append_array,data_sum8,data.field09
      append_array,data_sum9,data.field10
      append_array,data_sum10,data.field11
    endif
  endfor

  if size(data_sum0,/type) eq 0 then return


  year=strmid(data_sum0,0,4)
  month=strmid(data_sum0,4,2)
  day=strmid(data_sum0,6,2)


  hour=strmid(data_sum1,0,2)
  min=strmid(data_sum1,2,2)
  sec=strmid(data_sum1,4,2)

  dblt=time_double(year+'-'+month+'-'+day+'/'+hour+':'+min+':'+sec)

  L=data_sum2
  INV=data_sum3
  FMLAT=data_sum4
  MLAT=data_sum5
  MLT=data_sum6
  ALT=data_sum7
  GLAT=data_sum8
  GLON=data_sum9
  RDM_E3=data_sum10
  Energy=fltarr(n_elements(RDM_E3))
  Energy[*]=2.5

  store_data,prefix_project+'L',data={x:dblt,y:L}
  store_data,prefix_project+'INV',data={x:dblt,y:INV}
  store_data,prefix_project+'FMLAT',data={x:dblt,y:FMLAT}
  store_data,prefix_project+'MLAT',data={x:dblt,y:MLAT}
  store_data,prefix_project+'MLT',data={x:dblt,y:MLT}
  store_data,prefix_project+'ALT',data={x:dblt,y:ALT}
  store_data,prefix_project+'GLAT',data={x:dblt,y:GLAT}
  store_data,prefix_project+'GLON',data={x:dblt,y:GLON}
  store_data,prefix+'FEIO',data={x:dblt,y:RDM_E3}
  store_data,prefix+'FEIO_Energy',data={x:dblt,y:Energy}

  tdegap,prefix+'FEIO',/overwrite
  options,prefix+'FEIO',psym=4
  ylim,prefix+'FEIO',0.0,0.0,1

  options,prefix_project+'L','L-value'
  options,prefix_project+'INV','Invariant Latitude [deg]'
  options,prefix_project+'FMLAT','Footprint Latitude [deg]'
  options,prefix_project+'MLAT','Magnetic Latitude [deg]'
  options,prefix_project+'MLT','Magnetic Local Time [hour]'
  options,prefix_project+'ALT','Altitude [km]'
  options,prefix_project+'GLAT','Geographic Latitude [deg]'
  options,prefix_project+'GLON','Geographic Longitude [deg]'
  options,prefix+'FEIO','ytitle','Omni-directional Integral Electron Flux'
  options,prefix+'FEIO','ysubtitle', '[/cm2 sec str]'
  options,prefix+'FEIO_Energy','ytitle','Elctron energy [MeV]'

  return
end
