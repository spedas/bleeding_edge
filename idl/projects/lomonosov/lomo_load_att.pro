;+
;NAME:
;  lomo_load_att
;           This routine loads local ELFIN ENG Lomonosov attitude data.
;KEYWORDS (commonly used by other load routines):
;  DATATYPE = (Currently downloads all data types. Should change that.)
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
;   lomo_load_state, trange=['2016-06-24', '2016-06-25']

;NOTES:
;  Need to add feature to handle more than one days worth of data
;  Need to add feature to delete variables that weren't requested by the user
;--------------------------------------------------------------------------------------
;-
PRO lomo_load_att,trange=trange

  ;timespan, '2016-07-'
  ;trange=timerange()

  ; this sets the time range for use with the thm_load routines
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr=timerange(trange) $
  else tr=timerange()
  timespan, tr

  ; set up system variable for MMS if not already set
  defsysv, '!elf', exists=exists
  if not(exists) then elf_init

  if undefined(source) then source=!elf
  if undefined(local_data_dir) then local_data_dir = !elf.local_data_dir
  if undefined(remote_data_dir) then remote_data_dir = !elf.remote_data_dir

  hrs = ['00','01','02','03','04','05','06','07','08','09','10', $
    '11','12','13','14','15','16','17','18','19','20', $
    '21','22','23']

  ts = time_string(trange[0])
  yr = strmid(ts,0,4)
  mo = strmid(ts,5,2)
  day = strmid(ts,8,2)
  date0 = yr+mo+day

  for i = 0,5 do begin
    ts = time_string(trange[0]+i*86400.)
    yr = strmid(ts,0,4)
    mo = strmid(ts,5,2)
    day = strmid(ts,8,2)
    date = yr+mo+day
    ;stop
    for j = 0,23  do begin
      remote_file = !elf.remote_data_dir + 'bi/' + date + '/orient_coord-' + strmid(date0,2) + '-' + hrs[j] + '.dat'
      local_file = !elf.local_data_dir + 'bi/' + date0 + '/orient_coord-' + strmid(date0,2) + '-' + hrs[j] + '.dat'
      print, remote_file
      print, local_file
      ;stop
      paths=spd_download(remote_file=remote_file, local_file=local_file)
    endfor
  endfor
END
