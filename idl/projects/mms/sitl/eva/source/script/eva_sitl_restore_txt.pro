;+
; NAME:
;   EVA_SITL_RESTORE_TXT
;
; PURPOSE:
;   This is a command-line script to be used when the SITL has a long list of
;   burst-selections requested from non-SITL scientists. This script was developed
;   during the commissioning phase when various instrument teams were requesting
;   certain burst time periods for calibration purposes ("Extended ROI").
;   By using this script, the SITL could easily add those requested segments
;   into EVA without the hassle of adding segments manually one-by-one.
;
; USAGE:
;
;   1. Launch EVA and display automated FOM, as usual.
;   2. From the IDL console, type in the command:  MMS> eva_sitl_restore_txt
;   3. A dialog appears for you to select a text file. There is a sample file at
;      [YOUR_SPEDAS_DIRECTORY]/projects/mms/sitl/eva/source/script/eva_sitl_restore_txt_sample.txt
;   4. Once you select a file, then the FOM-structure gets updated in EVA.
;
;   The key point here is that we need to have the input file in a certain format.
;   Please see the sample file above. No need to put a date for end-time (3rd column);
;   If a segment was crossing mid-night, then the script will assume the day after
;   the input date (See the 3rd line of the sample file).
;
;   I still suggest checking each selection carefully after importing with this script.
;   If you encounter an error, please check if there is any overlap in the selections.
;
; CREATED BY: Mitsuo Oka   August 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2024-07-13 23:29:53 -0700 (Sat, 13 Jul 2024) $
; $LastChangedRevision: 32741 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/script/eva_sitl_restore_txt.pro $
;-
function eva_sitl_restore_template
  compile_opt idl2
  anan = fltarr(1)
  anan[0] = 'NaN'
  ppp = {version: 1.00000, $
    datastart: 0l, $
    delimiter: 44b, $
    missingvalue: anan[0], $
    commentsymbol: '', $
    fieldcount: 5l, $
    fieldtypes: [7l, 7l, 7l, 4l, 7l], $
    fieldnames: ['str_date', 'str_stime', 'str_etime', 'fom', 'discussion'], $
    fieldlocations: [0l, 11l, 21l, 31l, 38l], $
    fieldgroups: [0l, 1l, 2l, 3l, 4l]}
  return, ppp
end

pro eva_sitl_restore_txt
  compile_opt idl2
  common mms_sitl_connection, netUrl, connection_time, login_source

  ; ------------------
  ; Fetch ABS
  ; ------------------
  get_latest_fom_from_soc, fom_file, error_flag, error_msg
  if error_flag then message, 'FOMStr not found in SDC. Ask Super SITL.'
  restore, fom_file
  mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string

  ; ------------------
  ; Get Username
  ; ------------------
  type = size(netUrl, /type) ; will be 11 if object has been created
  if (type eq 11) then begin
    netUrl.getProperty, url_username = username
  endif else begin
    message, 'Something is wrong'
  endelse

  ; ------------------
  ; Input File
  ; ------------------
  filename = dialog_pickfile(/read)
  if strlen(filename) eq 0 then begin
    answer = dialog_message('Cancelled', /center, /info)
    return
  endif
  found = file_test(filename)
  if ~found then begin
    answer = dialog_message('File not found!', /center, /error)
    return
  endif

  r = read_ascii(filename, template = eva_sitl_restore_template())

  ; ------------------
  ; FOM Structure
  ; ------------------
  print, '--------------'
  print, 'INPUTS'
  print, '--------------'
  NSEGS = n_elements(r.fom)
  SEGLENGTHS = lonarr(NSEGS)
  SOURCEID = strarr(NSEGS)
  START = dblarr(NSEGS)
  STOP = dblarr(NSEGS)
  for n = 0, NSEGS - 1 do begin
    strFOM = string(r.fom[n], format = '(F5.1)')
    print, r.str_date[n], ': ', r.str_stime[n], ' - ', r.str_etime[n], ', FOM=', strFOM, ', ', strtrim(r.discussion[n], 2)
    stime = time_double(r.str_date[n] + '/' + r.str_stime[n])
    etime = time_double(r.str_date[n] + '/' + r.str_etime[n])
    if etime lt stime then etime += 86400.d0
    etime -= 10.d0
    rs = min(abs(unix_FOMstr.timestamps - stime), ids)
    re = min(abs(unix_FOMstr.timestamps - etime), ide)
    SEGLENGTHS[n] = STOP[n] - START[n] + 1
    SOURCEID[n] = username + '(EVA)'
    START[n] = long(ids)
    STOP[n] = long(ide)
  endfor
  str_element, /add, unix_FOMstr, 'DISCUSSION', r.discussion
  str_element, /add, unix_FOMstr, 'FOM', r.fom
  str_element, /add, unix_FOMstr, 'NBUFFS', total(SEGLENGTHS)
  str_element, /add, unix_FOMstr, 'NSEGS', NSEGS
  str_element, /add, unix_FOMstr, 'SEGLENGTHS', SEGLENGTHS
  str_element, /add, unix_FOMstr, 'SOURCEID', SOURCEID
  str_element, /add, unix_FOMstr, 'START', START
  str_element, /add, unix_FOMstr, 'STOP', STOP
  mms_convert_fom_unix2tai, unix_FOMstr, tai_FOMstr
  eva_lim = {unix_fomstr_mod: unix_FOMstr, $
    yrange: [0., 253.], ystyle: 1, ysubtitle: '(SITL)', ytitle: 'FOM'}

  FOMstr = eva_lim.unix_fomstr_mod
  if n_tags(FOMstr) eq 0 then begin
    answer = dialog_message('Not a valid FOMstr!', /center, /error)
    return
  endif

  ; update 'mms_stlm_fomstr'
  tfom = eva_sitl_tfom(FOMstr)
  D = eva_sitl_strct_read(FOMstr, tfom[0])
  store_data, 'mms_stlm_fomstr', data = D, lim = eva_lim, dl = eva_dl ; update the tplot-variable
  eva_sitl_stack

  ; update 'mms_stlm_output_fom'
  eva_sitl_strct_yrange, 'mms_stlm_output_fom'
  eva_sitl_strct_yrange, 'mms_stlm_fomstr'
  eva_sitl_copy_fomstr

  tplot
  answer = dialog_message('FOMstr successfully restored!', /center, /info)
end