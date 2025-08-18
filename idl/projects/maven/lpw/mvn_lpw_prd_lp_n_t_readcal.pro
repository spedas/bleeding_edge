;+
;FUNCTION:   mvn_lpw_prd_lp_n_t_readcal
;   Read calibration text file for maven lpw sweep analysis.
;
;INPUTS:
;   input: information to identify the file name and output. 'input' can be
;           % full path of the cal file (ex.'lpwdata_dir/data/sci/lpw/fitpar/2014/11/mvn_lpw_fitpar_20141010_l1a_p1_v00_r00.txt')
;           % time in format of 'YYYY-MM-DD/HH:MM:SS'
;           % date in format of YYYYMMDD (integer) or 'YYYY-MM-DD'
;   prb:    probe no (1/2)
;KEYWORDS:
;   lpw_cal_dir:  Specify the data stored directory. If not default is getenv('ROOT_DATA_DIR')
;   no_latest  :  Set this keyword to chose old cal file.
;OUTPUT:
;   cal info structure. 
;EXAMPLE:
; caldata = mvn_lpw_prd_lp_n_t_readcal('lpwdata_dir/data/sci/lpw/fitpar/2014/11/mvn_lpw_fitpar_20141010_l1a_p1_v00_r00.txt')
; caldata = mvn_lpw_prd_lp_n_t_readcal(20141010,1)
; caldata = mvn_lpw_prd_lp_n_t_readcal('2014-10-10/00:00:00.0',1)
; caldata = mvn_lpw_prd_lp_n_t_readcal(1.4129352e+09,1); (time in tplot time format) 
;
;CREATED BY:   Michiko Morooka  11-18-14
;FILE:         mvn_lpw_prd_lp_n_t_readcal.pro
;VERSION:      0.0
;LAST MODIFICATION:
;-

;------- this_version_mvn_lpw_prd_lp_n_t_readcal ------------------
function this_version_mvn_lpw_prd_lp_n_t_readcal
  ver = 0.0
  pdr_ver= 'version mvn_lpw_prd_lp_n_t_readcal: ' + string(ver,format='(F4.1)')
  return, pdr_ver
end
;-------------------- this_version_mvn_lpw_prd_lp_n_t -----

function mvn_lpw_prd_lp_n_t_readcal, input, prb, lpw_cal_dir=lpw_cal_dir, ext=ext, no_latest=no_latest
                                     
  ;------ the version number of this routine ------------------------------------------------------
  t_routine=SYSTIME(0)
  pdr_ver= this_version_mvn_lpw_prd_lp_n_t_readcal()

  ;----- Check input & define file name -----------------------------------------------------------
  if keyword_set(ext) eq 0 then ext = 'l2'
  if size(input,/type) eq 7 and strmid(input,strlen(input)-4,4) eq '.txt' then begin
     cal_file_name = input & goto, READ_CAL
  endif
  
  sl = path_sep()  ;/ for unix, \ for Windows
  if keyword_set(lpw_cal_dir) then lpw_cal_dir = lpw_cal_dir + sl+'data'+sl+'sci'+sl+'lpw'+sl+'fitpar'+sl $
  else                             lpw_cal_dir = getenv('ROOT_DATA_DIR') + sl+'data'+sl+'sci'+sl+'lpw'+sl+'fitpar'+sl

  prb_char = string(prb,format='(I01)')
  case size(input,/type) of
    7: begin
         YEAR = strmid(input,0,4) & MONTH = strmid(input,5,2) & DAY = strmid(input,8,2)
       end
    3: begin
         YEAR  = string(fix(input/10000),format=('(I04)'))
         MONTH = string(fix((input mod 10000)/100),format=('(I02)'))
         DAY   = string(fix(input mod 100),format=('(I02)'))         
       end
    5: begin
         input = time_string(input)
         YEAR = strmid(input,0,4) & MONTH = strmid(input,5,2) & DAY = strmid(input,8,2)
       end
  endcase
  lpw_cal_dir = lpw_cal_dir+YEAR+sl+MONTH+sl
  filename_head = lpw_cal_dir+'mvn_lpw_fitpar_'+YEAR+MONTH+DAY+'_'+ext+'_p'+prb_char+'*.txt'
  cal_file_name = file_search(filename_head)
  if keyword_set(cal_file_name) eq 0 then begin
    print, 'no cal data file. (searched for '+filename_head+')'
    return, -1
  endif
  if n_elements(cal_file_name) gt 1 then begin
     if keyword_set(no_latest) then begin
       for ii=0,n_elements(cal_file_name)-1 do begin
         print, string(ii,format='(I02)') + ' /' + cal_file_name(ii)
       endfor
       READ, element, PROMPT='Which file? (type number) '      
     endif else element = n_elements(cal_file_name)-1
     cal_file_name = cal_file_name(element)
  endif

  if strlen(input) ge 19 then time = time_double(input)

READ_CAL:

  if file_test(cal_file_name) eq 0 then return, -1
  
  
  filename = strsplit(cal_file_name,path_sep(),/extract) & filename = filename(n_elements(filename)-1)  
  file_size = file_info(cal_file_name) & file_len = file_size.size/73
  paramset = {time: double(!values.F_nan), givenU:[!values.F_nan,!values.F_nan,!values.F_nan], fit_name:'', $
              file_name:filename}
  fit_info = REPLICATE(paramset, file_len)
  line = ''
  ii=0
  OPENR, lun, cal_file_name, /GET_LUN
  ; Read one line at a time, saving the result into array
  WHILE NOT EOF(lun) DO BEGIN 
    READF, lun, line
    ;printf, unit, format='(i4, i3, i3, i3, i3, f9.3, f9.3, f9.3, f9.3, a20)', data, swp_pp[ii].fit_function_name
    t    = strcompress(strmid(line,0,4),/remove_all)  +'-'+ $
           strcompress(strmid(line,4,3),/remove_all)  +'-'+ $
           strcompress(strmid(line,7,3),/remove_all)  +'/'+ $
           strcompress(strmid(line,10,3),/remove_all) +':'+ $
           strcompress(strmid(line,13,3),/remove_all) +':'+ $
           strcompress(strmid(line,16,9),/remove_all)
    fit_info(ii).time     = time_double(t)
    fit_info(ii).givenU   = [float(strmid(line,25,9)), float(strmid(line,34,9)), float(strmid(line,43,9))]
    fit_info(ii).fit_name = strcompress(strmid(line,52,20),/remove_all)
    ii=ii+1    
  ENDWHILE
  ; Close the file and free the file unit
  FREE_LUN, lun
  
  if keyword_set(time) then begin
    ind = where(abs(fit_info.time-time) eq min(abs(fit_info.time-time)))
    if ind eq -1 then begin
      print, 'time out of range' & return, -1
    endif
    fit_info=fit_info(ind)
  endif

  return, fit_info

end