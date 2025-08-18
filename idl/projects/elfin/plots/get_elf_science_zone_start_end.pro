;+
;PROCEDURE:
;   get_elf_science_zone_start_end
;
;PURPOSE:
;   This routine searches a specified time range for science zone collections and returns a 
;   structure sci_zones={starts:sz_starttimes, ends:sz_endtimes}
;   This is a utility routine used by some of the plot routines but can be used standalong 
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probe:        spacecraft specifier, 'a' or 'b'. default value is 'a'
;         instrument:   string containing name of instrument to find the science zone
;                       time frame. 'epd' is the only instrument implemented in this routine
;                       'fgm' needs to be added
;
;OUTPUT:
;   sci_zones={starts:sz_starttimes, ends:sz_endtimes}
;   
;AUTHOR:
;v1.0 S.Frey 12-30-03
;-
function get_elf_science_zone_start_end, trange=trange, probe=probe, instrument=instrument

   ; set up parameters if needed
   if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, -1
   endif
;   if ~undefined(trange) && n_elements(trange) eq 2 $
;     then tr = timerange(trange) else tr = timerange()
   dt=time_double(trange[1])-time_double(trange[0])
   timespan,time_double(trange[0]), dt, /sec
;   print, time_string(timerange())
;   stop
   if not keyword_set(probe) then probe = 'a'
   if not keyword_set(instrument) then begin
    instrument='epde'
   endif else begin
    if instrument EQ 'epd' then instrument = 'epde'
   endelse
   sci_zones=-1
    
  ; define local and remote paths
  local_path=!elf.LOCAL_DATA_DIR+'el'+probe+ '/data_availability/'
  remote_path=!elf.REMOTE_DATA_DIR+'el'+probe+ '/data_availability/'

  ; read csv file
  Case instrument of
    'epde': filename='el'+probe+'_epde_data_availability.csv'
    'epdi': filename='el'+probe+'_epdi_data_availability.csv'
    'fgm': filename='el'+probe+'_fgm_data_availability.csv'
    'mrma':filename='el'+probe+'_mrma_data_availability.csv'
    else: filename='el'+probe+'_epde_data_availability.csv'
  Endcase 
  
  ; Download CSV file
  paths = ''
  ; download data as long as no flags are set
  if file_test(local_path,/dir) eq 0 then file_mkdir2, local_path
  dprint, dlevel=1, 'Downloading ' + remote_path + filename + ' to ' + local_path + filename
  paths = spd_download(remote_file=filename, remote_path=remote_path, $
    local_file=filename, local_path=local_path, ssl_verify_peer=0, ssl_verify_host=0)
  if undefined(paths) or paths EQ '' then $
    dprint, devel=1, 'Unable to download ' + remote_file
  ;making sure the file exists. if not, it will just create one
  existing = FILE_TEST(local_path+filename)
print,local_path+filename
print, existing 
;stop
  ; Read CSV file
  if existing eq 1 then begin 
    data=read_csv(local_path+filename, n_table_header=1)

    ; select times in trange
    ;idx=where(time_double(data.field1) GE time_double(tr[0]) AND time_double(data.field1) LE time_double(tr[1]),ncnt) 
    ;if ncnt GT 0 then sci_zones={starts:time_double(data.field1[idx]), ends:time_double(data.field2[idx]), completeness:data.field3[idx]}
    data_starts=time_double(data.field1)
    data_ends=time_double(data.field2)
    data_completeness=data.field3
  endif 
help, data_starts
help, data_ends
help, data_completeness
;print, time_string(trange)
;stop
if instrument eq 'epde' then datatype='pef'
if instrument eq 'epdi' then datatype='pif'
elf_load_epd, probe=probe, trange=trange, datatype=datatype, type='nflux'
;stop
get_data, 'el'+probe+'_'+datatype+'_nflux', data=pxf_nflux
if (size(pxf_nflux, /type)) EQ 8 then begin
  tdiff = pxf_nflux.x[1:n_elements(pxf_nflux.x)-1] - pxf_nflux.x[0:n_elements(pxf_nflux.x)-2]
  idx = where(tdiff GT 270., ncnt)
  append_array, idx, n_elements(pxf_nflux.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone
  if ncnt EQ 0 then begin
   ; if ncnt is zero then there is only one science zone for this time frame
    sz_starttimes=[pxf_nflux.x[0]]
    sz_endtimes=pxf_nflux.x[n_elements(pxf_nflux.x)-1]
    ts=time_struct(sz_starttimes[0])
    te=time_struct(sz_endtimes[0])
  endif else begin
    for sz=0,ncnt do begin ;changed from ncnt-1
      if sz EQ 0 then begin
        this_s = pxf_nflux.x[0]
        sidx = 0
        this_e = pxf_nflux.x[idx[sz]]
        eidx = idx[sz]
      endif else begin
        this_s = pxf_nflux.x[idx[sz-1]+1]
        sidx = idx[sz-1]+1
        this_e = pxf_nflux.x[idx[sz]]
        eidx = idx[sz]
      endelse
      if (this_e-this_s) lt 15. then continue
      append_array, sz_starttimes, this_s
      append_array, sz_endtimes, this_e
    endfor
  endelse
endif
if ~undefined(sz_starttimes) then begin
  completeness=make_array(n_elements(sz_starttimes), /string)
  completeness=completeness+'None'
  ; FIND completeness
  for i=0,n_elements(sz_starttimes)-1 do begin
    this_start=sz_starttimes[i]
    idx = where(this_start-30. GE sz_starttimes AND this_start+30. LT sz_starttimes, ncnt)
    if ncnt GT 0 then completeness=data_completeness[idx[0]]
;stop
  endfor
  sci_zones={starts:time_double(sz_starttimes), ends:time_double(sz_endtimes), completeness:completeness}
endif
help, sci_zones
;stop
if ~undefined(sci_zones) then return, sci_zones else return, -1
   
end