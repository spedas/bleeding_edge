;+
;Procedure: st_plastic_load
;
;Purpose:  Loads stereo plastic data
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
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision: $
; $URL:$
;-
pro st_plastic_load,type,all=all,files=files,trange=trange, $
    verbose=verbose,burst=burst,probes=probes,level=level,resolution=resolution, $
    source_options=source_options, $
    version=ver

if not keyword_set(source_options) then begin
    stereo_init
    source_options = !stereo
    source_options.remote_data_dir = 'http://stereo-ssc.nascom.nasa.gov/data/ins_data/'
endif
mystereo = source_options

if not keyword_set(probes) then probes = ['a','b']
if not keyword_set(level) then level=2
if not keyword_set(resolution) then resolution = '1min'

res = 3600l*24     ; one day resolution in the files
tr = timerange(trange)
n = ceil((tr[1]-tr[0])/res)  > 1
dates = dindgen(n)*res + tr[0]

for i=0,n_elements(probes)-1 do begin
   probe = probes[i]

   if level eq 1 then begin
      type = ''
      vfm = '*_main *_s'   ;big files!
      if not keyword_set(ver) then ver='V09'
      lstr = '1'
      resdir = ''
      if probe eq 'a' then path = 'plastic/level1/ahead/YYYY/STA_L1_PLA_'+type+'YYYYMMDD_DOY_'+ver+'.cdf'
      if probe eq 'b' then path = 'plastic/level1/behind/YYYY/STB_L1_PLA_'+type+'YYYYMMDD_DOY_'+ver+'.cdf'
   endif
   if level eq 2 then begin
      type = '1DMax_'+resolution+'_'
      if not keyword_set(ver) then ver='V06'
      lstr='2'
      resdir = resolution+'/'
      vfm = '*'

      if probe eq 'a' then path = 'plastic/level2/ahead/'+resdir+'YYYY/STA_L2_PLA_'+type+'YYYYMMDD_'+ver+'.cdf'
      if probe eq 'b' then path = 'plastic/level2/behind/'+resdir+'YYYY/STB_L2_PLA_'+type+'YYYYMMDD_'+ver+'.cdf'
   endif

;   if probe eq 'a' then probestr = '/ahead/'+resdir+'YYYY/STA_L'
;   if probe eq 'b' then probestr = '/behind/'+resdir+'YYYY/STB_L'

;   path = 'plastic/level'+lstr+probestr+lstr+'_PLA_'+type+'YYYYMMDD_DOY_'+ver+'.cdf'
   pref = 'st'+probe+'_pla_'+type

   relpathnames= time_string(dates,tformat= path)

   files = file_retrieve(relpathnames,_extra = mystereo)

   cdf2tplot,file=files,varformat=vfm,all=all,verbose=!stereo.verbose ,prefix=pref , /convert_int1   ; load data into tplot variables

endfor


end
