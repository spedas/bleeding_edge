;+
;Procedure: st_swaves_load
;
;Purpose:  Loads stereo swaves data
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;
;Example:
;   st_plastic_load
;Notes:
;  This routine is (should be) platform independent.
;
;
;  Davin Larson
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision: $
; $URL:$
;-
pro st_swaves_load,type,all=all,files=files,trange=trange, $
    verbose=verbose,burst=burst,probes=probes,level=level, $
    source_options=source_options, $
    version=ver

if not keyword_set(source_options) then begin
    stereo_init
    source_options = !stereo
    source_options.remote_data_dir = 'http://stereo-ssc.nascom.nasa.gov/data/ins_data/'
    source_options.min_age_limit = 3600
endif
mystereo = source_options
mystereo.no_download = file_test(/regular,mystereo.local_data_dir+'swaves/.master')

if not keyword_set(probes) then probes = ['a','b']
if not keyword_set(level) then level=2
type = '_avg'

res = 3600l*24     ; one day resolution in the files
tr =  floor(timerange(trange)/res) * res
n = ceil((tr[1]-tr[0])/res)  > 1
dates = dindgen(n)*res + tr[0]

for i=0,n_elements(probes)-1 do begin
   probe = probes[i]
   path = 'swaves/YYYY/swaves_average_YYYYMMDD_'+probe+'.sav'
   pref = 'st'+probe+'_swaves'+type

   relpathnames= time_string(dates,tformat= path)

   files = file_retrieve(relpathnames,_extra = mystereo)

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
endfor


end
