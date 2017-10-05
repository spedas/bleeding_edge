;+
;NAME:
;  elf_load_epd
;           This routine loads local ELFIN EPD Lomonosov data.
;KEYWORDS (commonly used by other load routines):
;  DATATYPE =  for epd there are two datatypes: epde, epdi
;  LEVEL    = levels include 1 (2 will be available shortly)
;  TRANGE   = (Optional) Time range of interest  (2 element array), if
;             this is not set, the default is to prompt the user. Note
;             that if the input time range is not a full day, a full
;             day's data is loaded
;  LOCAL_DATA_DIR = local directory to store the CDF files; should be set if
;             you're on *nix or OSX, the default currently assumes the IDL working directory
;  SOURCE   = sets a different system variable. By default the MMS mission system variable
;             is !elf
;  TPLOTNAMES = set to override default names for tplot variables
;  NO_UPDATES = use local data only, don't query the http site for updated files.
;  SUFFIX   = append a suffix to tplot variables names
;
;EXAMPLE:
;   elf_load_epd,datatype='epde', trange=['2016-06-24', '2016-06-25']
;
;NOTES:
;  Need to add feature to handle more than one days worth of data
;  Need to add feature to delete variables that weren't requested by the user
;--------------------------------------------------------------------------------------
;-
PRO elf_load_epd, datatype=datatype, level=level, trange=trange, $
  source=source, local_data_dir=local_data_dir, tplotnames=tplotnames, $
  no_updates=no_updates, suffix=suffix

  ; this sets the time range for use with the thm_load routines
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr=timerange(trange) $
    else tr=timerange()
  timespan, trange
 
  ; set up system variable for MMS if not already set
  defsysv, '!elf', exists=exists
  if not(exists) then elf_init

  validtypes=['epde']
  validlevels=['l1']
  
  if undefined(source) then source=!elf
  if undefined(datatype) then datatype=validtypes else datatype=strlowcase(datatype)
  ; for now only epde is available
  datatype=validtypes
  if undefined(level) then level='l1' else level=strlowcase(level)
  if datatype[0] EQ '*' then datatype=validtypes
  if undefined(local_data_dir) then local_data_dir = !elf.local_data_dir
  spawn, 'echo ' + local_data_dir, local_data_dir
  if is_array(local_data_dir) then local_data_dir = local_data_dir[0]

  for i = 0, n_elements(datatype)-1 do begin
    idx = where(validtypes eq datatype[i], ncnt)
    if ncnt EQ 0 then begin
      dprint, 'elf_load_epd error, found unrecognized datatype: ' + datatype[i]
      return
    endif
  endfor
  for i = 0, n_elements(level)-1 do begin
    idx = where(validlevels eq level[i], ncnt)
    if ncnt EQ 0 then begin
      dprint, 'elf_load_epd error, found unrecognized level: ' + level[i]
      return
    endif
  endfor

  ts = time_struct(trange[0])
  yr = strmid(trange[0],0,4)
  mo = strmid(trange[0],5,2)
  day = strmid(trange[0],8,2)

  ; temporary kluge for l2 data
  ; for now use level 1 and calibrate on the fly.
  ; construct local file name
  local_file = !elf.local_data_dir + level+'/epd/'+yr+'/lomo_'+level+'_'+yr+mo+day+'_epd_v01.cdf'

  no_download = !elf.no_download or !elf.no_server or ~undefined(no_update)
  if no_download eq 0 then begin

    ; Construct file name
    remote_file = !elf.remote_data_dir + 'l1_ingo/EPD/lomo_'+strupcase(level)+'_elfin_'+yr+mo+day+'_EPD.cdf'
    paths=spd_download(remote_file=remote_file, local_file=local_file)

  endif

  init_time=systime(/sec)
  cdf2tplot, file=local_file, get_support_data=1

;  requested_epd_tvars='ell_'+datatype
;  all_epd_tvars=tnames('ell_epd*')
;  tvar_to_delete = ssl_set_complement(requested_epd_tvars, all_epd_tvars)
  ;store_data, delete=tvar_to_delete
  ; temporary kluge till mastercdf is changed
  store_data, delete=['ell_epde_err', 'ell_epdi_err', 'ell_epd_time']

END
