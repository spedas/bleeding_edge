;+
; FUNCTION:
;         elf_load_att
;
; PURPOSE:
;         Load data from a csv file on the elfin server.
;         The attitude data is a by-product of the attitude
;         determination software.
;
;
; KEYWORDS:
;         probe:        specify which ELFIN probe to load 'a' or 'b'
;         tdate:        time and date of interest with the format
;                       'YYYY-MM-DD/hh:mm:ss'
;         no_download:  set this flag to search for the file on your local disk
;
;-
function elf_load_att, probe=probe, tdate=tdate, no_download=no_download

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if undefined(tdate) then begin
    dprint, 'You must enter a date (e.g. 2020-02-24/03:45:00)'
    return, -1
  endif else begin
    tdate=time_double(tdate)
  endelse

  if undefined(probe) then probe = 'a' else probe = strlowcase(probe)

  ; check if the tplot var attitudes already exists - if so then no need to download and
  ; read the csv file
  tvar_att='el'+probe+'_attitudes'
  get_data, tvar_att, data=att
  if size(att, /type) NE 8 then begin

    ; create file name
    att_filename='el'+probe+'_attitudes.csv'
    remote_att_dir=!elf.REMOTE_DATA_DIR+'/attitude'
    local_att_dir=!elf.LOCAL_DATA_DIR+'/attitude'
    if strlowcase(!version.os_family) eq 'windows' then local_att_dir = strjoin(strsplit(local_att_dir, '/', /extract), path_sep())
    remote_filename=remote_att_dir+'/'+att_filename
    local_filename=local_att_dir+'/'+att_filename
    paths = ''  
    if keyword_set(no_download) then no_download=1 else no_download=0
    
    paths = ''
    if no_download eq 0 then begin
      if file_test(local_att_dir,/dir) eq 0 then file_mkdir2, local_att_dir
      dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_att_dir
      paths = spd_download(remote_file=remote_filename, local_file=local_filename, $
         ssl_verify_peer=1, ssl_verify_host=1)
      if undefined(paths) or paths EQ '' then $
        dprint, devel=1, 'Unable to download ' + local_filename
    endif
  
    ; if file not found on server then
    if paths[0] EQ '' || no_download EQ 1 then begin
      ; check that there is a local file
      if file_test(local_filename) NE 1 then begin
        dprint, dlevel=1, 'Unable to find local file ' + local_filename
        return, -1
      endif
    endif
    ; check that the file exists
    if file_test(local_filename) NE 1 then begin
      dprint, dlevel=1, 'Unable to find file '+ local_filename
      return, -1
    endif  
  
    att_fields = read_csv(local_filename)
    store_data, tvar_att, data={x:time_double(att_fields.field1), $
      y:[[att_fields.field2],[att_fields.field3],[att_fields.field4]], $
      u:att_fields.field5, $
      rpm:att_fields.field6}
    get_data, tvar_att, data=att

  endif
  
  td=time_double(att.x)
  rpm=att.rpm
  ; interpolate data
  ; find start and end points for interpolation
  npts=n_elements(att.x)
  if td[npts-1] GT tdate then edate=td[npts-1] else edate=tdate+3600.
  if td[0] LT tdate then sdate=td[0] else sdate=tdate-3600.
  ; create time for interpolation
  num_min=fix((edate-sdate)/86400.)*1440.
  ntime=(findgen(num_min)*60)+sdate
  int_rpm=interp(att.rpm, td, ntime)
  tdiff=min(abs(ntime-tdate),midx)

  return, int_rpm[midx]

end