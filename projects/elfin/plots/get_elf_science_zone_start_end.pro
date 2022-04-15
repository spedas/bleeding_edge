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
   if ~undefined(trange) && n_elements(trange) eq 2 $
     then tr = timerange(trange) else tr = timerange()
   if not keyword_set(probe) then probe = 'a'
   if not keyword_set(instrument) then instrument='epd'
   sci_zones=-1
    
  ; define local and remote paths
  local_path=!elf.LOCAL_DATA_DIR+'el'+probe+ '/data_availability/'
  remote_path=!elf.REMOTE_DATA_DIR+'el'+probe+ '/data_availability/'

  ; read csv file
  Case instrument of
    'epd': filename='el'+probe+'_epd_data_availability.csv'
    'fgm': filename='el'+probe+'_fgm_data_availability.csv'
    'mrma':filename='el'+probe+'_mrma_data_availability.csv'
    else: filename='el'+probe+'_epd_data_availability.csv'
  Endcase 
  
  ; Download CSV file
  paths = ''
  ; download data as long as no flags are set
  if file_test(local_path,/dir) eq 0 then file_mkdir2, local_path
  dprint, dlevel=1, 'Downloading ' + remote_path + filename + ' to ' + local_path + filename
  paths = spd_download(remote_file=filename, remote_path=remote_path, $
    local_file=filename, local_path=local_path, ssl_verify_peer=1, ssl_verify_host=1)
  if undefined(paths) or paths EQ '' then $
    dprint, devel=1, 'Unable to download ' + remote_file
  ;making sure the file exists. if not, it will just create one
  existing = FILE_TEST(local_path+filename)

  ; Read CSV file
  if existing eq 1 then begin 
    data=read_csv(local_path+filename, n_table_header=1)
    ; select times in trange
    idx=where(time_double(data.field1) GE time_double(tr[0]) AND time_double(data.field1) LE time_double(tr[1]),ncnt) 
    if ncnt GT 0 then sci_zones={starts:time_double(data.field1[idx]), ends:time_double(data.field2[idx]), completeness:data.field3[idx]}
  endif 
  
  return, sci_zones 
   
end