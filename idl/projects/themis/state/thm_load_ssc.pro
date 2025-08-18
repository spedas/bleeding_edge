;+
; Procedure: thm_load_ssc
;
; Purpose:
;   Load THEMIS current/past orbit data, and predicted data, from CDAWeb/SSCWeb (Satellite Situation Center).

;
; Keywords:
;             trange:       Standard time range of interest.
;             probes:       Probe names. This can be an array of strings, e.g., ['a', 'b']
;             predicted:    If set, it loads predicted data.
;             varformat:    Only load these variable names. If not set, load all.
;             downloadonly: Only download files, do not load them into tplot.
;             prefix:       Give this prefix to tplot variable names
;             suffix:       Give this suffix to tplot variable names
;             no_time_clip: Do not time clip tplot variables (not recommended because some files contain a year of data)
;             ssc_server:   (optional) URL of CDAWeb server.
;
; Returns:
;             tplotnames:   List of variables loaded into tplot
;
;
; Examples:
;   thm_load_ssc, trange = ['2026-01-01', '2026-01-10'], probes=['a','b','c'], /predicted
;   thm_load_ssc, trange = ['2016-01-01', '2016-01-10'], probes='e'
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2024-09-27 15:53:46 -0700 (Fri, 27 Sep 2024) $
; $LastChangedRevision: 32864 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/thm_load_ssc.pro $
;-


pro thm_load_ssc, trange = trange, probes = probes, predicted=predicted, varformat=varformat, downloadonly=downloadonly, $
  prefix=prefix, suffix=suffix, no_time_clip=no_time_clip, ssc_server=ssc_server, tplotnames=tplotnames, _extra=_extra

  compile_opt idl2

  thm_init

  tplotnames = [] ; tplot variables loaded

  if undefined(trange) then trange=['2024-01-01/00:00:00', '2024-01-02/00:00:00']
  if undefined(probes) then probes=['a']
  if undefined(predicted) then predicted=0 else predicted=1
  if undefined(varformat) then varformat='*'
  if undefined(downloadonly) then downloadonly=0 else downloadonly=1
  if undefined(prefix) then prefix=''
  if undefined(suffix) then suffix=''
  if undefined(no_time_clip) then no_time_clip=0 else no_time_clip=1
  if undefined(ssc_server) then ssc_server='https://cdaweb.gsfc.nasa.gov/pub/data/themis/'

  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()

  catch, errstats
  if errstats ne 0 then begin
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  for i=0, n_elements(probes)-1 do begin ; loop through the probes

    prb = probes[i]

    if predicted eq 1 then begin
      pathformat = 'th' + prb + '/ccc_pre/YYYY/th' + prb + 'pred_or_ccc_' + 'YYYY0101_v??.cdf'
    endif else begin
      pathformat =  'th' + prb + '/ccc/YYYY/th' + prb + '_or_ccc_' + 'YYYYMM01_v??.cdf'
    endelse

    for j = 0, n_elements(pathformat)-1 do begin
      ; Find paths.
      relpathnames = file_dailynames(file_format=pathformat[j], trange=tr, res=30*24l*3600, /unique)
      for k=0, n_elements(relpathnames)-1 do begin
        temp = relpathnames[k]
        str_replace, temp, 'ccc', 'ssc'
        str_replace, temp, 'ccc', 'ssc'
        relpathnames[k] = temp
      endfor
      ; Download files.
      files = spd_download(remote_file=relpathnames, remote_path=ssc_server, local_path = !themis.local_data_dir, /last_version)

      if downloadonly eq 0 then begin

        prefixlocal = prefix + 'th' + prb + "_"
        ; Load files into tplot.
        cdf2tplot, files, tplotnames=tplotnames, varformat=varformat, prefix=prefixlocal, suffix=suffix

        ; Time clip
        if ~undefined(tr) && ~undefined(tplotnames) then begin
          if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            if no_time_clip ne 1 then time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
          endif
        endif

      endif

    endfor

  endfor

end

