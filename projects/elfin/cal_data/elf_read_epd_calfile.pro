;+
; PROCEDURE:
;         elf_read_epd_calibration
;
; PURPOSE:
;         returns epd calibration parameters
;
; OUTPUT:
;         EPD calibration data structure
;         cal_params include: epd_gf
;                             epd_overaccumulation_factors
;                             epd_thresh_factors
;                             epd_ch_efficiencies
;                             epd_cal_ch_factors
;                             epd_ebins
;                             epd_ebins_logmean
;                             epd_ebin_lbls
;
; KEYWORDS:
;         probe:       elfin probe name, 'a' or 'b'
;         instrument:  epd instrument name, 'epde' or 'epdi'
;         no_download: if set this routine will look locally for calibration file
;
; EXAMPLES:
;         elf> cal_params = elf_get_epd_calibration(probe='a', instrument='epde')
;
; NOTES:  This routine is obsolete and has been replaced by elf_read_epd_cal_data. Originally this
;         routine was written to read the initial calibration data. The calibration data has now been 
;         split into 2 different files - one containing calibration data, the other containing operational
;         data.
;
; HISTORY:
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_cal_mrmi.pro $
;-
function elf_read_epd_calfile, probe=probe, instrument=instrument, no_download=no_download

  ; check that the elfin system variable exits
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init
  
  ; initialize parameters
  if ~keyword_set(probe) then probe='a' else probe=strlowcase(probe)
  if ~keyword_set(instrument) then instrument='epde' else instrument=strlowcase(instrument)
  if ~keyword_set(no_download) then no_download=0 else no_download=1

  get_data, 'epd_calibration_data', data=epd_cal
  if is_struct(epd_cal) then begin
    epd_calibration_data=epd_cal.epd_calibration_data[0]
    stop
    return, epd_calibration_data
  endif

  ebins = make_array(16, /float)
  ebins_logmean = make_array(16, /float)
  ebins_minmax = make_array(16, 2, /float)
  ebin_lbls = make_array(16, /string)
  gf=0.0
  overaccumulation_factors = make_array(16, /float)
  thresh_factors = make_array(16, /float)
  ch_efficiencies = make_array(16, /float)
  cal_ch_factors = make_array(16, /float)
  
  ; create calibration file name
  sc='el'+probe
  remote_cal_dir=!elf.REMOTE_DATA_DIR+sc+'/calibration_files'  
  local_cal_dir=!elf.LOCAL_DATA_DIR+sc+'/calibration_files'
  remote_filename=remote_cal_dir+'/'+sc+'_cal_'+instrument+'.txt'
  local_filename=local_cal_dir+'/'+sc+'_cal_'+instrument+'.txt'
  paths = ''

  if no_download eq 0 then begin
    ; NOTE: directory is temporarily password protected. this will be
    ;       removed when data is made public.
;    if undefined(user) OR undefined(pw) then authorization = elf_get_authorization()
;    user=authorization.user_name
;    pw=authorization.password

    ; only query user if authorization file not found
;    If user EQ '' OR pw EQ '' then begin
;      print, 'Please enter your ELFIN user name and password'
;      read,user,prompt='User Name: '
;      read,pw,prompt='Password: '
;    endif
    if file_test(local_cal_dir,/dir) eq 0 then file_mkdir2, local_cal_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_cal_dir
    paths = spd_download(remote_file=remote_filename, $   ;remote_path=remote_cal_dir, $
      local_file=local_filename,ssl_verify_peer=1, ssl_verify_host=1)
    if undefined(paths) or paths EQ '' then $
      dprint, devel=1, 'Unable to download ' + local_filename 
  endif

    ;check that file exists
    local_file = file_search(local_filename)
    
    ; if file exists then open the file and read the calibration parameters
    if is_string(local_file) then begin
    
      ; open file and read first 7 lines (these are just headers)
      openr, lun, local_file, /get_lun
      le_string=''
      for i=0,5 do readf, lun, le_string  
      
      ; read EBINS
      if le_string EQ 'ebins:' then begin
        for i=0,15 do begin
          readf, lun, le_string
          ebins[i]=float(le_string)
        endfor
      endif 

      ; read EBINS_LOGMEAN
      readf, lun, le_string
      readf, lun, le_string
      if le_string EQ 'ebins_logmean:' then begin
        for i=0,15 do begin
          readf, lun, le_string
          ebins_logmean[i]=float(le_string)
        endfor
      endif

      ; read EBINS_MINMAX 
      readf, lun, le_string
      readf, lun, le_string
      if le_string EQ 'ebins_minmax:' then begin
        for i=0,15 do begin
          readf, lun, le_string
        endfor
      endif

      ; read EBIN_LBLS
      readf, lun, le_string
      readf, lun, le_string
      if le_string EQ 'ebin_lbls:' then begin
        for i=0,15 do begin
          readf, lun, le_string
          ebin_lbls[i]=le_string
        endfor
      endif
    
      ; read GEOMETRIC_FACTORS
      readf, lun, le_string
      readf, lun, le_string
      if le_string EQ 'gf:' then begin
        readf, lun, le_string
        gf=float(le_string)
      endif
    
      ; read OVERACCUMULATION_FACTORS
      readf, lun, le_string
      readf, lun, le_string
      if le_string EQ 'overaccumulation_factors:' then begin
        for i=0,15 do begin
          readf, lun, le_string
          overaccumulation_factors[i]=float(le_string)
        endfor
      endif
      
      ; read THRESHOLD_FACTORS
      readf, lun, le_string
      readf, lun, le_string
      if le_string EQ 'thresh_factors:' then begin
        for i=0,15 do begin
          readf, lun, le_string
          thresh_factors[i]=float(le_string)
        endfor
      endif
     
      ; read CH_EFFICIENCIES
      readf, lun, le_string
      readf, lun, le_string
      if le_string EQ 'ch_efficiencies:' then begin
        for i=0,15 do begin
          readf, lun, le_string
          ch_efficiencies[i]=float(le_string)
        endfor
      endif
    
      ; read CAL_CH_FACTORS
      readf, lun, le_string
      readf, lun, le_string
      if le_string EQ 'cal_ch_factors:' then begin
        for i=0,15 do begin
          readf, lun, le_string
          cal_ch_factors[i]=float(le_string)
        endfor
      endif
      
    endif else begin
      dprint, dlevel=1, 'Local calibration file '+local_file+ 'could not be found.'
      return, -1
    endelse
  
  ; close file
  close, lun
  free_lun, lun

  ebins_minmax[*,0]=ebins
  ebins_minmax[0:14,1]=ebins[1:15]
  ebins_minmax[15,1]=8000.
     
  ; return calibration information in a structure
  epd_calibration_data = { epd_gf:gf, $
      epd_overaccumulation_factors:overaccumulation_factors, $
      epd_thresh_factors:thresh_factors, $
      epd_ch_efficiencies:ch_efficiencies, $
      epd_cal_ch_factors:cal_ch_factors, $
      epd_ebins:ebins, $
      epd_ebins_logmean:ebins_logmean, $
      epd_ebins_minmax:ebins_minmax, $
      epd_ebin_lbls:ebin_lbls }

  store_data, 'epd_calibration_data', data=epd_calibration_data
  
  return, epd_calibration_data
  
end