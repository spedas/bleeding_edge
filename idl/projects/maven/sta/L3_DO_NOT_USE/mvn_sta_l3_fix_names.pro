pro mvn_sta_l3_fix_names
;;; gwen messed up the version number so fix it!

start_date=time_double('2021-01-01')
end_date=time_double('2024-01-01')

ndays = ceil((end_date-start_date)/86400.)

basedir = '/disks/data/maven/data/sci/sta/l3/temperature/'
;fname = 'mvn_sta_l3_temp_????????_full_v'+tfile_version+'.tplot'
fn = 'mvn_sta_l3_temp_'

for i=0,ndays-1 do begin
  this_date=start_date+86400.*i
  
  year_month_day = strsplit(time_string(this_date,prec=-3),'-',/extract)
  year = year_month_day[0]
  month = year_month_day[1]
  day = year_month_day[2]
  
  dir = basedir+year+'/'+month+'/'
  
  fname_wrong_tpl = dir+fn+year+month+day+'_full_03.tplot'
  fname_right_tpl = dir+fn+year+month+day+'_full_v03.tplot'
  
  fname_wrong_sav = dir+fn+year+month+day+'_gwen_03.sav'
  fname_right_sav = dir+fn+year+month+day+'_gwen_v03.sav'
  
  spawn, 'mv '+fname_wrong_tpl+' '+fname_right_tpl
  spawn, 'mv '+fname_wrong_sav+' '+fname_right_sav
  
  if i mod 365. eq 0 then print, 'year done'
  
endfor 

print, 'done! filenames fixed!' 


end