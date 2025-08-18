PRO sppeva_get_fld_f1_100bps_old, day, filename=filename
  compile_opt idl2
  
;  catch, errorstatus
;  if (errorstatus ne 0) then begin
;    catch, /cancel
;    print, !error_state.msg
;    ; get the properties that will tell us more about the error.
;    oUrl->getproperty, response_code=rspcode,response_header=rsphdr, response_filename=rspfn
;    print, 'rspcode = ', rspcode
;    print, 'rsphdr= ', rsphdr
;    print, 'rspfn= ', rspfn
;    obj_destroy, oUrl
;    return
;  endif

  if undefined(day) then day = !SPPEVA.COM.commDay
  day = strtrim(string(day),2)
  
  ;--------------
  ; url_path
  ;--------------
  case day of
    '2': begin
      filename = 'spp_fld_l1_f1_100bps_20180813_110000_20180813_180000_v00.cdf'
      !SPPEVA.COM.STRTR = ['2018-08-13/11:00','2018-08-13/18:00']
      end
    '3': begin
      filename = 'spp_fld_l1_f1_100bps_20180814_150000_20180814_171000_v00.cdf'
      !SPPEVA.COM.STRTR = ['2018-08-14/15:00','2018-08-14/17:00']
      end
    '4': begin
      filename = 'spp_fld_l1_f1_100bps_20180815_150000_20180815_210000_v00.cdf'
      !SPPEVA.COM.STRTR = ['2018-08-15/15:00','2018-08-15/21:00']
      end   
    '5': begin
      filename = 'spp_fld_l1_f1_100bps_20180816_195000_20180817_053000_v00.cdf'
      !SPPEVA.COM.STRTR = ['2018-08-16/19:50','2018-08-17/05:30']
      end 
  endcase
  url_path  = 'data/spp/sppfldsoc/cdf/2018/08/20180826_commissioning_plots/commissioning_day'
  url_path += strtrim(string(day),2)+'/'+filename
  
  ;--------------
  ; timespan
  ;--------------
  tr = time_double(!SPPEVA.COM.STRTR)
  timespan,tr[0], tr[1]-tr[0], /seconds
  
  ;--------------
  ; oUrl
  ;--------------
  oUrl = OBJ_NEW('IDLnetUrl')
;  oUrl->SetProperty, CALLBACK_FUNCTION ='test_fields_callback'
  oUrl->SetProperty, VERBOSE = 0
  oUrl->SetProperty, url_username = !SPPEVA.USER.SPPFLDSOC_ID
  oUrl->SetProperty, url_password = !SPPEVA.USER.SPPFLDSOC_PW
  oUrl->SetProperty, url_scheme = 'http'
  oUrl->SetProperty, URL_HOST = 'sprg.ssl.berkeley.edu'
  oUrl->SetProperty, URL_PATH = url_path
  fn = oUrl->Get(FILENAME = filename )
  PRINT, 'filename returned = ', fn
  OBJ_DESTROY, oUrl
END