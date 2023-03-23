;+
;
;Procedure: st_swaves_load
;
;Purpose:  Loads stereo swaves data
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;
;Example:
;   st_swaves_load
;Notes:
;  This routine is (should be) platform independent.
;
;
;  Davin Larson
;  
; $LastChangedBy: pulupa $
; $LastChangedDate: 2023-03-22 11:04:33 -0700 (Wed, 22 Mar 2023) $
; $LastChangedRevision: 31647 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/stereo/st_swaves_load.pro $
; 
;-

pro st_swaves_load,type,all=all,files=files,trange=trange, $
  verbose=verbose,burst=burst,probes=probes,level=level, $
  source_options=source_options, $
  version=ver

  if not keyword_set(source_options) then begin
    stereo_init
    source_options = !stereo
    source_options.remote_data_dir = 'https://stereo-ssc.nascom.nasa.gov/data/ins_data/'
    source_options.min_age_limit = 3600
  endif
  mystereo = source_options
  mystereo.no_download = file_test(/regular,mystereo.local_data_dir+'swaves/.master')

  if not keyword_set(probes) then probes = ['a','b']
  if not keyword_set(level) then level=3
  if not keyword_set(type) then begin
    if level EQ 3 then begin
      st_swaves_load,'hfr',all=all,files=files,trange=trange, $
        verbose=verbose,burst=burst,probes=probes,level=level, $
        source_options=source_options, $
        version=ver
      st_swaves_load,'lfr',all=all,files=files,trange=trange, $
        verbose=verbose,burst=burst,probes=probes,level=level, $
        source_options=source_options, $
        version=ver
      return
    endif else begin
      type = '_avg'
    endelse
  endif

  if level EQ 3 then begin
    mystereo.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/stereo/'
  endif

  res = 3600l*24     ; one day resolution in the files
  tr =  floor(timerange(trange)/res) * res
  n = ceil((tr[1]-tr[0])/res)  > 1
  dates = dindgen(n)*res + tr[0]

  for i=0,n_elements(probes)-1 do begin
    probe = probes[i]
    path = 'swaves/YYYY/swaves_average_YYYYMMDD_'+probe+'.sav'
    pref = 'st'+probe+'_swaves'+type

    if level EQ 3 then begin

      pref = 'st'+probe+'_swaves_' + type + '_'
      if probe EQ 'a' then fullprobe = 'ahead' else fullprobe = 'behind'
      path = fullprobe + '/l3/waves/' + type + '/YYYY/st' + probe + '_l3_wav_' + $
        type + '_YYYYMMDD_' + 'v??.cdf'

    endif

    relpathnames= time_string(dates,tformat= path)

    files = spd_download(remote_file=relpathnames,_extra = mystereo)

    if level EQ 3 then begin

      cdf2tplot, files, prefix = pref, tplotnames = tnames
      
      options, tnames(pref+['PSD*','WAVE*','STOKES*','SOURCE_SIZE']), $
        'ystyle', 1

    endif else begin
      spectrums = replicate(!values.f_nan,n*1440,367)
      times     = replicate(!values.f_nan,n*1440)
      for j=0l,n-1 do begin
        restore,verbose=keyword_set(verbose),file=files[j]
        spectrums[j*1440:(j+1)*1440-1,*] = transpose(spectrum)
        times[j*1440:(j+1)*1440-1] = dindgen(1440) * 60d +dates[j]
        ;       append_array,spectrums,transpose(spectrum)
        ;       append_array,times,dindgen(1440)*60d+dates[j]
      endfor

      store_data,pref+'_spec',data={x:times,y:spectrums,v:frequencies},dlim={ylog:1,spec:1,yrange:minmax(frequencies),ystyle:1,zrange:[0,30]}
    endelse
  endfor

end
