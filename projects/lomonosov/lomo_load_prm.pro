;+
;NAME:
;  lomo_load_prm
;           This routine loads local ELFIN PRM Lomonosov data.
;KEYWORDS (commonly used by other load routines):
;  DATATYPE =  for prm there is only one datatype: mag
;  LEVEL    = levels include 1. level 2 will be available shortly. 
;  TRANGE   = (Optional) Time range of interest  (2 element array), if
;             this is not set, the default is to prompt the user. Note
;             that if the input time range is not a full day, a full
;             day's data is loaded
;  LOCAL_DATA_DIR = local directory to store the CDF files; should be set if
;             you're on *nix or OSX, the default currently assumes the IDL working directory
;  SOURCE   = sets a different system variable. By default the MMS mission system variable
;             is !lomo
;  TPLOTNAMES = set to override default names for tplot variables
;  NO_UPDATES = use local data only, don't query the http site for updated files.
;  SUFFIX   = append a suffix to tplot variables names
;
;EXAMPLE:
;   lomo_load_prm,trange=['2016-06-24', '2016-06-25']
;
;NOTES:
;  Need to deal with level 2
;  Need to add feature to handle more than one days worth of data 
;  Implement tplotnames and suffix
;--------------------------------------------------------------------------------------
;-
PRO lomo_load_prm, datatype=datatype, level=level, trange=trange, $
  source=source, local_data_dir=local_data_dir, tplotnames=tplotnames, $
  no_updates=no_updates, suffix=suffix 

  ; this sets the time range for use with the thm_load routines
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr=timerange(trange) $
    else tr=timerange()
  timespan, trange
 
  ; set up system variable for MMS if not already set
  defsysv, '!lomo', exists=exists
  if not(exists) then lomo_init
  
  if undefined(source) then source=!lomo
  validtypes = ['*', 'mag']
  validlevels = ['l1', 'l2']
  if undefined(level) then level = 'l1' else level=strlowcase(level)
  if undefined(datatype) then datatype=validtypes
  if undefined(suffix) then suffix=''
  if datatype[0] EQ '*' then $
    datatype=validtypes $
    else datatype=strlowcase(datatype)
  if undefined(local_data_dir) then local_data_dir = !lomo.local_data_dir
  spawn, 'echo ' + local_data_dir, local_data_dir
  if is_array(local_data_dir) then local_data_dir = local_data_dir[0]

  ; check for valid types and levels
  for i = 0, n_elements(datatype)-1 do begin
    idx = where(validtypes eq datatype[i], ncnt)
    if ncnt EQ 0 then begin
      dprint, 'lomo_load_prm error, found unrecognized datatype: ' + datatype[i]
      return
    endif
  endfor
  for i = 0, n_elements(level)-1 do begin
    idx = where(validlevels eq level[i], ncnt)
    if ncnt EQ 0 then begin
      dprint, 'lomo_load_prm error, found unrecognized level: ' + level[i]
      return
    endif
  endfor

  ts = time_struct(trange[0])
  yr = strmid(trange[0],0,4)
  mo = strmid(trange[0],5,2)
  day = strmid(trange[0],8,2)
  
  local_file = !lomo.local_data_dir +level+'/prm/'+yr+'/lomo_'+level+'_'+yr+mo+day+'_prm_v01.cdf'

  no_download = !lomo.no_download or !lomo.no_server or ~undefined(no_update) 

  if no_download eq 0 then begin
        
          ; Construct file name
          ; temporary kluge for l2 data
          ; for now use level 1 and calibrate on the fly.
          if level EQ 'l2' then remote_level = 'L1' else remote_level=strupcase(level) 
          remote_file = !lomo.remote_data_dir + 'l1_ingo/PRM/lomo_'+remote_level+'_elfin_'+yr+mo+day+'_PRM.cdf'
          paths=spd_download(remote_file=remote_file, local_file=local_file)
          
  endif 
    
      init_time=systime(/sec)
      cdf2tplot, file=local_file, get_support_data=1
     
      If level EQ 'l2' then begin

        ; calibrate on the fly for now
        get_data, 'ell_prm', data=d, dlimits=dl, limits=l
        
        if ~is_struct(d) then begin
          dprint, dlevel = 0, 'No ELFIN data loaded'
          return
        endif
        d.y[*,0]=d.y[*,0]/106.4   ;27238.4
        d.y[*,1]=d.y[*,1]/97.9    ;25062.4
        d.y[*,2]=d.y[*,2]/104.5   ;26572.
        ; update attributes
        miny=min(d.y[*,1])
        maxy=max(d.y[*,0])
        newdl={cdf:dl.cdf, spec:0, log:0, colors:[2,4,6], labels:['x','y','z'], labflag:1, ytitle:'[nT]', $
            color_table:39, yrange:[miny,maxy]}

        store_data, 'ell_prm', data=d, dlimits=newdl, limits=l
        tplot_gui, 'ell_prm', /no_verify, /no_draw
      Endif
    
end