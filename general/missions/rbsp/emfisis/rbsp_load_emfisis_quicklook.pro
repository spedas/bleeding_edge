;+
; NAME:
;   rbsp_load_emfisis_quicklook (procedure)
;
; PURPOSE:
;   Load EMFISIS quick-look data. As noted by the EMFISIS team, the quick-look
;   data are *not* for publication purposes.
;
;   As 10/29/12, Valid datatypes are:
;       '1sec-gse' (in default)
;       '4sec-gse'   
;       'hires-gse'
;       'uvw'
;       'hfr'  (in default)
;       'hfr-waveform' (not yet available)
;       'hfr-burst' (not yet available)
;       'wfr-BuBu' (in default)
;       'wfr-BvBv'
;       'wfr-BwBw'
;       'wfr-EuEu' (in default)
;       'wfr-EvEv'
;       'wfr-EwEw'
;       'wfr-matrix' (not yet available)
;       'wfr-burst' (not yet available)
;       'wfr-burst-matrix' (not yet available)
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_load_emfisis_quicklook, probe = probe, datatype = datatype $
;           , _extra = _extra, use_local = use_local
;
; ARGUMENTS:
;
; KEYWORDS:
;   probe: (In, optional) RBSP spacecraft names, either 'a', or 'b', or 
;         ['a', 'b']. The default is ['a', 'b']
;   datatype: (In, optional) See above.
;   _extra: Extra keywords passed into file_http_copy.
;   /use_local: If set, will skip looking up the remote server and use local
;         files. This is a remedy when the remote server is down.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;   file_http_copy
;
; HISTORY:
;   2012-10-29: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-05: Initial release to TDAS. JBT, SSL/UCB.
;   2012-11-05: JBT, SSL/UCB.
;           1. Added keyword *use_local*.
;   2012-11-23: JBT, SSL/UCB.
;           1. Added keyword *downloadonly*.
;
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-11-23 12:15:23 -0800 (Fri, 23 Nov 2012) $
; $LastChangedRevision: 11295 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/emfisis/rbsp_load_emfisis_quicklook.pro $
;
;-

function rbsp_load_emfisis_quicklook_urls, sc, date
; date must be acceptable by time_double.
; sc should be 'a' or 'b'

compile_opt idl2, hidden

; EMFISIS server root dir.
emfisis_root_dir = 'http://emfisis.physics.uiowa.edu/Flight/'

scdir = strupcase('rbsp-' + sc[0]) + '/Quick-Look/'

; Make sure date format is yyyy-mm-dd
dstr = strmid(time_string(time_double(date)), 0, 10)
year = strmid(dstr, 0, 4)
mm = strmid(dstr, 5, 2)
dd = strmid(dstr, 8, 2)
date_dir = year + '/' + mm + '/' + dd + '/'

remote_dir = emfisis_root_dir + scdir + date_dir
urls = jbt_fileurls(remote_dir, verbose = 0)

return, urls

end

;-------------------------------------------------------------------------------
function rbsp_load_emfisis_quicklook_fname_filter, dtype
compile_opt idl2, hidden

case dtype of 
  '1sec-gse': filter = '*_magnetometer_1sec-gse_*'
  '4sec-gse': filter = '*_magnetometer_4sec-gse_*'
  'hires-gse': filter = '*_magnetometer_hires-gse_*'
  'uvw': filter = '*_magnetometer_uvw_*'
  'hfr': filter = '*_HFR-spectra_*'
  'hfr-waveform': filter = '*_HFR-waveform_*'
  'hfr-burst': filter = '*_HFR-spectra-burst_*'
  'wfr-BuBu': filter = '*_WFR-spectral-matrix-diagonal_*'
  'wfr-BvBv': filter = '*_WFR-spectral-matrix-diagonal_*'
  'wfr-BwBw': filter = '*_WFR-spectral-matrix-diagonal_*'
  'wfr-EuEu': filter = '*_WFR-spectral-matrix-diagonal_*'
  'wfr-EvEv': filter = '*_WFR-spectral-matrix-diagonal_*'
  'wfr-EwEw': filter = '*_WFR-spectral-matrix-diagonal_*'
;   'wfr-matrix': filter = '*_WFR-spectral-matrix_*'
  'wfr-burst': filter = '*_WFR-spectral-matrix-burst-diagonal_*'
;   'wfr-burst-matrix': filter = '*_WFR-spectral-matrix-burst_*'
  else: begin
      dprint, 'Invalid data type. Returning a filter of "InvalidFilter".'
;       stop
      return, 'InvalidFilter'
    end
endcase

return, filter

end

;-------------------------------------------------------------------------------
function rbsp_load_emfisis_quicklook_fname, dtype, urls
; dtype should be a scalar string of data type.
compile_opt idl2, hidden

fnames = file_basename(urls)

; dprint, dtype

; case dtype of 
;   '1sec-gse': filter = '*_magnetometer_1sec-gse_*'
;   '4sec-gse': filter = '*_magnetometer_4sec-gse_*'
;   'hires-gse': filter = '*_magnetometer_hires-gse_*'
;   'uvw': filter = '*_magnetometer_uvw_*'
;   'hfr': filter = '*_HFR-spectra_*'
;   'hfr-waveform': filter = '*_HFR-waveform_*'
;   'hfr-burst': filter = '*_HFR-spectra-burst_*'
;   'wfr-BuBu': filter = '*_WFR-spectral-matrix-diagonal_*'
;   'wfr-BvBv': filter = '*_WFR-spectral-matrix-diagonal_*'
;   'wfr-BwBw': filter = '*_WFR-spectral-matrix-diagonal_*'
;   'wfr-EuEu': filter = '*_WFR-spectral-matrix-diagonal_*'
;   'wfr-EvEv': filter = '*_WFR-spectral-matrix-diagonal_*'
;   'wfr-EwEw': filter = '*_WFR-spectral-matrix-diagonal_*'
; ;   'wfr-matrix': filter = '*_WFR-spectral-matrix_*'
;   'wfr-burst': filter = '*_WFR-spectral-matrix-burst-diagonal_*'
; ;   'wfr-burst-matrix': filter = '*_WFR-spectral-matrix-burst_*'
;   else: begin
;       dprint, 'Invalid data type. '
; ;       stop
;       return, -1
;     end
; endcase

filter = rbsp_load_emfisis_quicklook_fname_filter(dtype)
if strcmp(filter, 'InvalidFilter') then return, ''

;rbsp-a_WFR-spectral-matrix-diagonal_emfisis-Quick-Look_20121016_v1.2.4

ind = where(strmatch(fnames, filter), nind)
if nind gt 0 then return, fnames[ind[0]] else return, ''

end

;-------------------------------------------------------------------------------
pro rbsp_load_emfisis_quicklook_meta, dtype, sc, tvar, dlim
; dtype should be a scalar string of data type.
compile_opt idl2, hidden

; dtype - in
; sc    - in
; tvar  - out
; dlim  - out

rbx = 'rbsp' + strlowcase(sc) + '_'

case dtype of 
  '1sec-gse': begin
      tvar = rbx + 'mag_gse_1sec'
      coord  = 'gse'
      units = 'nT'
      lbl_suf = strupcase(' ' + coord)
      labels = ['Bx'+lbl_suf, 'By'+lbl_suf, 'Bz'+lbl_suf]
      ysub = '[' + units + ']'
      dlim = {ysubtitle:ysub, colors:[2,4,6], labels:labels, labflag:1}
    end
  '4sec-gse': begin
      tvar = rbx + 'mag_gse_4sec'
      coord  = 'gse'
      units = 'nT'
      lbl_suf = strupcase(' ' + coord)
      labels = ['Bx'+lbl_suf, 'By'+lbl_suf, 'Bz'+lbl_suf]
      ysub = '[' + units + ']'
      dlim = {ysubtitle:ysub, colors:[2,4,6], labels:labels, labflag:1}
    end
  'hires-gse': begin
      tvar = rbx + 'mag_gse_hires'
      coord  = 'gse'
      units = 'nT'
      lbl_suf = strupcase(' ' + coord)
      labels = ['Bx'+lbl_suf, 'By'+lbl_suf, 'Bz'+lbl_suf]
      ysub = '[' + units + ']'
      dlim = {ysubtitle:ysub, colors:[2,4,6], labels:labels, labflag:1}
    end
  'uvw': begin
      tvar = rbx + 'mag_uvw'
      coord  = 'uvw'
      units = 'nT'
      lbl_suf = strupcase(' ' + coord)
      labels = ['Bx'+lbl_suf, 'By'+lbl_suf, 'Bz'+lbl_suf]
      ysub = '[' + units + ']'
      dlim = {ysubtitle:ysub, colors:[2,4,6], labels:labels, labflag:1}
    end
  'hfr': begin
      tvar = rbx + 'hfr'
      coord  = ''
      units = 'V^2/m^2/Hz'
      ztitle = '[V!U2!N/m!U2!N/Hz]'
      ysub = '[Hz]'
      dlim = {ysubtitle:ysub, spec:1, ylog:1, zlog:1, ztitle:ztitle, $
        yrange:[1e4, 486.97e3], ystyle:1}
    end
  'wfr-BuBu': begin
      tvar = rbx + 'wfr_BuBu'
      coord = ''
      units = 'nT^2/Hz'
      ztitle = '[nT!U2!N/Hz]'
      ysub = '[Hz]'
      dlim = {ysubtitle:ysub, spec:1, ylog:1, zlog:1, ztitle:ztitle, $
        yrange:[4, 12e3], ystyle:1}
    end
  'wfr-EuEu': begin
      tvar = rbx + 'wfr_EuEu'
      coord = ''
      units = 'V^2/m^2/Hz'
      ztitle = '[V!U2!N/m!U2!N/Hz]'
      ysub = '[Hz]'
      dlim = {ysubtitle:ysub, spec:1, ylog:1, zlog:1, ztitle:ztitle, $
        yrange:[4, 12e3], ystyle:1}
    end
  else: begin
      dprint, 'Invalid data type. '
      return
    end
endcase

att = {coord_sys:coord, units:units}
str_element, dlim, 'data_att', att, /add

end

;-------------------------------------------------------------------------------
function rbsp_load_emfisis_quicklook_spec, dtype
; dtype should be a scalar string of data type.
compile_opt idl2, hidden

case dtype of 
  '1sec-gse': return, -1
  '4sec-gse': return, -1
  'hires-gse': return, -1
  'uvw': return, -1
  'hfr': return, 1
  'wfr-BuBu': return, 1
  'wfr-BvBv': return, 1
  'wfr-BwBw': return, 1
  'wfr-EuEu': return, 1
  'wfr-EvEv': return, 1
  'wfr-EwEw': return, 1
  else: begin
      dprint, 'Invalid data type. '
      return, !values.f_nan
    end
endcase

end

;-------------------------------------------------------------------------------
function rbsp_load_emfisis_quicklook_spec_name, dtype
; dtype should be a scalar string of data type.
compile_opt idl2, hidden

; common rbsp_load_emfisis_quicklook_com, wfr_name

case dtype of 
  '1sec-gse': return, ''
  '4sec-gse': return, ''
  'hires-gse': return, ''
  'uvw': return, ''
  'hfr': return, 'HFR_Spectra'
  'wfr-BuBu': return, 'BuBu'
  'wfr-BvBv': return, 'BvBv'
  'wfr-BwBw': return, 'BwBw'
  'wfr-EuEu': return, 'EuEu'
  'wfr-EvEv': return, 'EvEv'
  'wfr-EwEw': return, 'EwEw'
  else: begin
      dprint, 'Invalid data type. '
      return, !values.f_nan
    end
endcase

end

;-------------------------------------------------------------------------------
pro rbsp_load_emfisis_quicklook_download, sc, date, dtype, urls $
  , _extra = _extra
compile_opt idl2, hidden

fname = rbsp_load_emfisis_quicklook_fname(dtype, urls)

sep = '/'
scdir = strupcase('rbsp-' + sc[0]) + sep + 'Quick-Look' + sep

; Make sure date format is yyyy-mm-dd
dstr = strmid(time_string(time_double(date)), 0, 10)
year = strmid(dstr, 0, 4)
mm = strmid(dstr, 5, 2)
dd = strmid(dstr, 8, 2)
date_dir = year + sep + mm + sep + dd + sep

emfisis_root_dir = 'http://emfisis.physics.uiowa.edu/Flight/'

; sep = path_sep()
serverdir = emfisis_root_dir
localdir = !rbsp_efw.local_data_dir + 'emfisis' + sep
pathname = scdir + date_dir + fname
; print, 'pathname: ', pathname
; print, 'serverdir: ',serverdir
; print, 'localdir: ', localdir
; stop
file_http_copy, pathname $
  , serverdir=serverdir $
  , localdir=localdir $
  , _extra = _extra

end

;-------------------------------------------------------------------------------
function rbsp_load_emfisis_quicklook_file, sc, date, dtype, urls, $
  use_local = use_local
compile_opt idl2, hidden

sep = path_sep()
scdir = strupcase('rbsp-' + sc[0]) + sep + 'Quick-Look' + sep

; Make sure date format is yyyy-mm-dd
dstr = strmid(time_string(time_double(date)), 0, 10)
year = strmid(dstr, 0, 4)
mm = strmid(dstr, 5, 2)
dd = strmid(dstr, 8, 2)
date_dir = year + sep + mm + sep + dd + sep

localdir = !rbsp_efw.local_data_dir + 'emfisis' + sep

if ~keyword_set(use_local) then begin
  fname = rbsp_load_emfisis_quicklook_fname(dtype, urls)
  if strlen(fname) eq 0 then return, ''
endif else begin
  ; Find the file name in local disk.
  tmpdir = localdir + scdir + date_dir
  files = file_search(tmpdir, '*.cdf')
  fnames = file_basename(files)
  filter = rbsp_load_emfisis_quicklook_fname_filter(dtype)
  if strcmp(filter, 'InvalidFilter') then return, ''

  ind = where(strmatch(fnames, filter), nind)
  if nind gt 0 then return, files[ind[0]] else return, ''

;   print, files
;   stop
endelse

pathname = scdir + date_dir + fname

file = localdir + pathname

return, file

end

;-------------------------------------------------------------------------------
pro rbsp_load_emfisis_quicklook, probe = probe, datatype = datatype $
  , _extra = _extra, use_local = use_local, downloadonly = downloadonly

compile_opt idl2

if ~keyword_set(datatype) then datatype = ['1sec-gse', 'hfr', 'wfr-BuBu', $
  'wfr-EuEu']
if ~keyword_set(probe) then probe = ['a', 'b']
if n_elements(downloadonly) eq 0 then downloadonly = !rbsp_efw.downloadonly

rbsp_efw_init

tspan = timerange()
dsta = strmid(time_string(tspan[0]+10.), 0, 10)
dend = strmid(time_string(tspan[1]-10.), 0, 10)
days = (time_double(dend) - time_double(dsta) )/(24d * 3600d) + 1
tsta = time_double(dsta)

; Take care of leap second table. This issue is due to the use of CDFlib 3.4.1,
; which is used by EMFISIS to generate their quick-look data.
cdf_leap_second_init

ntype = n_elements(datatype)
nsc = n_elements(probe)

; Loop over data types.
for itype = 0, ntype - 1 do begin
  dtype = datatype[itype]

  ; Loop over spacecraft.
  for ip = 0, nsc-1 do begin
    sc = probe[ip]
    rbx = 'rbsp' + sc + '_'
    ; Loop over dates.
    for i = 0L, days-1 do begin
      t0 = tsta + i * 24d * 3600d
      tmptr = t0 + [0d, 24d*3600d]
      date = strmid(time_string(t0), 0, 10)
      if ~keyword_set(use_local) then begin
        urls = rbsp_load_emfisis_quicklook_urls(sc, date)

        ; Download data using file_http_copy.
        rbsp_load_emfisis_quicklook_download, sc, date, dtype, urls $
          , _extra = _extra
        if keyword_set(downloadonly) then continue
      endif

      ; Load cdf data into tplot.
      file = rbsp_load_emfisis_quicklook_file(sc, date, dtype, urls, $
        use_local = use_local)
      if strlen(file) gt 0 then cdf2tplot, file = file else begin
        dprint, dtype, ' data not available for RBSP ', strupcase(sc), '.'
        continue
      endelse

      ; Accumulate data into arrays.
      if rbsp_load_emfisis_quicklook_spec(dtype) gt 0 then begin
        spec_name = rbsp_load_emfisis_quicklook_spec_name(dtype)
        get_data, spec_name, data = data
        ind = where(data.x ge tmptr[0] and data.x lt tmptr[1], nind)
        if nind eq 0 then begin
          dprint, 'Something is off.'
          stop
        endif
        tarr = data.x[ind]
        spec_y = data.y[ind, *]
        v_tmp = reform(data.v)
        dim = size(v_tmp, /dim)
        if n_elements(dim) eq 1 then begin
          nv = dim[0]
          spec_v = transpose(rebin(v_tmp, nv, nind))
        endif else spec_v = v_tmp

        if n_elements(x_tplot) eq 0 then begin
          x_tplot = tarr
          spec_y_tplot = spec_y
          spec_v_tplot = spec_v
        endif else begin
          x_tplot    = [x_tplot    , tarr]
          spec_y_tplot = [spec_y_tplot, spec_y]
          spec_v_tplot = [spec_v_tplot, spec_v]
        endelse
      endif else begin
        get_data, 'Mag', data = data
        ind = where(data.x ge tmptr[0] and data.x lt tmptr[1], nind)
        if nind eq 0 then begin
          dprint, 'Something is off.'
          stop
        endif
  ;       btot = sqrt(total(data.y^2,2))
        bx = data.y[ind,0]
        by = data.y[ind,1]
        bz = data.y[ind,2]
        tarr = data.x[ind]
        if n_elements(x_tplot) eq 0 then begin
          x_tplot = tarr
          bx_tplot = bx
          by_tplot = by
          bz_tplot = bz
  ;         btot_tplot = btot
        endif else begin
          x_tplot    = [x_tplot    , tarr]
          bx_tplot   = [bx_tplot   , bx]
          by_tplot   = [by_tplot   , by]
          bz_tplot   = [bz_tplot   , bz]
  ;         btot_tplot = [btot_tplot , btot]
        endelse
      endelse
    endfor  ; day loop
    if keyword_set(downloadonly) then continue

    ; Store data into tplot
    nt = n_elements(x_tplot)
    if nt eq 0 then continue else begin
      rbsp_load_emfisis_quicklook_meta, dtype, sc, tvar, dlim
      ind = where(x_tplot ge tspan[0] and x_tplot le tspan[1], nind)
      if nind eq 0 then begin
        dprint, 'Something is off.'
        stop
      endif
      if rbsp_load_emfisis_quicklook_spec(dtype) gt 0 then begin
        data = {x:x_tplot[ind], y:spec_y_tplot[ind, *], $
          v:spec_v_tplot[ind, *]}
        undefine, x_tplot
      endif else begin
        data = {x:x_tplot[ind], y:[$
               [bx_tplot[ind]] $
             , [by_tplot[ind]] $
             , [bz_tplot[ind]] $
           ]}
        undefine, x_tplot
      endelse
      store_data, tvar, data = data, dlim = dlim

      ; Remove spikes due to change of mag range in hires data
      if strmatch(dtype, '*hires*') or $
         strmatch(dtype, '*uvw*') $
        then begin
        get_data, tvar, data = data, dlim = dlim, lim = lim
        btot = sqrt(total(data.y^2,2))
        bsm = thm_lsp_median_smooth(btot, 20)
        bdiff = abs(btot - bsm)
        ind = where(bdiff gt 100)
        data.y[ind, *] = !values.d_nan
        data.y[*,0] = interp(data.y[*,0], data.x, data.x, /ignore_nan)
        data.y[*,1] = interp(data.y[*,1], data.x, data.x, /ignore_nan)
        data.y[*,2] = interp(data.y[*,2], data.x, data.x, /ignore_nan)
        store_data, tvar, data = data, dlim = dlim, lim = lim
      endif
    endelse
  endfor ; sc loop
endfor ; data type loop
if keyword_set(downloadonly) then return

; Clean up.
store_data, ['Mag', 'Magnitude', 'delta', 'lambda', 'rms', 'coordinates'], $
  /del, verbose = 0
store_data, ['HFR_Spectra', 'BuBu', 'BvBv', 'BwBw', 'EuEu', 'EvEv', 'EwEw'], $
  /del, verbose = 0

end

