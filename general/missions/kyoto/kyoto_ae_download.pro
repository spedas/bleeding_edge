

;+
;
;***** WARNING: This routine is still being written!!! Do not attempt to use!
;
;NAME:
;  KYOTO_AE_DOWNLOAD.PRO
;
;PURPOSE:
;  This routine will download the requested month of AE, AL, AO, and AU
;data from the Kyoto server and store to the directory/file,
;YYYY/kyoto_ae_YYYY_MM.dat.
;
;Code: W.M.Feuerstein, 4/17/2008.
;
;-

pro kyoto_ae_download ,year,month,n_days_in_month

localdir='/disks/data/geom_indices/kyoto/ae/'

;Convert inputs to strings:
;==========================
year=strtrim(year,2)
month=strtrim(month,2)
n_days_in_month = strtrim(n_days_in_month,2)


;Format URL inputs:
;==================
tens=strmid(year,0,3)
yr=strmid(year,3,1)
mnth=fix(month)
if mnth le 9 then mnth='0'+string(mnth) else mnth=string(mnth)
day_tens='0'
days='1'
hour_tens='0'
hour='0'
dur_day_tens=strtrim(fix(n_days_in_month/10),2)
dur_day=strtrim(n_days_in_month mod 10,2)
dur_hour_tens='0'
dur_hour='0'



;url='http://swdcwww.kugi.kyoto-u.ac.jp/cgi-bin/aeasy-cgi?Tens=200&Year=7&Month=12&Day_Tens=0&Days=1&Hour_Tens=0&Hour=0&Dur_Day_Tens=0&Dur_Day=2&Dur_Hour_Tens=0'
;url+='&Dur_Hour=0&Image+Type=GIF&COLOR=COLOR&AE+Sensitivity=0&ASY%2FSYM++Sensitivity=0&Output=DATA&Data+Type=ASY&Email=thuser@ssl.berkeley.edu'

url='http://swdcwww.kugi.kyoto-u.ac.jp/cgi-bin/aeasy-cgi?'+ $
  'Tens='+tens+'&'+ $
  'Year='+yr+'&'+ $
  'Month='+mnth+'&'+ $
  'Day_Tens='+day_tens+'&'+ $
  'Days='+days+'&'+ $
  'Hour_Tens='+hour_tens+'&'+ $
  'Hour='+hour+'&'+ $
  'Dur_Day_Tens='+dur_day_tens+'&'+ $
  'Dur_Day='+dur_day+'&'+ $
  'Dur_Hour_Tens='+dur_hour_tens+'&'+ $
  'Dur_Hour='+dur_hour+'&'+ $
  'Image+Type=GIF&COLOR=COLOR&AE+Sensitivity=0&ASY%2FSYM++'+ $
  'Sensitivity=0&Output=DATA&Data+Type=ASY&Email=thuser@ssl.berkeley.edu'


;serverdir='http://swdcwww.kugi.kyoto-u.ac.jp/cgi-bin/aeasy-cgi?Tens=200&Year=5&Month=01&Day_Tens=0&Days=1&Hour_Tens=0&Hour=0&Dur_Day_Tens=0&Dur_Day=1&Dur_Hour_Tens=0&Dur_Hour=0&Image+Type=GIF&COLOR=COLOR&AE+Sensitivity=0&ASY%2FSYM++Sensitivity=0&Output


file_http_copy,url,$
  localdir+year+'/'+'kyoto_ae_'+strtrim(year,2)+mnth+'.dat', $
  verbose=2
  ;serverdir=serverdir, $
  ;localdir=localdir

;files=file_retrieve(url,$
;  localdir+year+'/'+'kyoto_ae_'+strtrim(year,2)+mnth+'.dat', $
;  verbose=2)
;  ;serverdir=serverdir, $
;  ;localdir=localdir

end



