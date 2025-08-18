;+
; FUNCTION:
;         mms_find_perigee_times
;
; PURPOSE:
;         Function that returns the times of perigee just before and after the input time (using the MEC data)
; 
; INPUT: 
;         time: time to find perigee
;         
; KEYWORDS:
;         probe: spacecraft probe #
;         
; EXAMPLE:
;         trange=mms_find_perigee_times('2015-09-02/00:00:00', probe='1')
;         
; NOTES:
;         Created by Naritoshi Kitamura
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-07-31 13:59:16 -0700 (Fri, 31 Jul 2020) $
; $LastChangedRevision: 28961 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_find_perigee_times.pro $
;-

FUNCTION mms_find_perigee_times, time, probe=probe
  
  if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
  time=time_double(time)
  if time lt time_double('2017-02-01') then days=1.d else days=4.d
  
  mms_load_mec,trange=[time-86400.d*days,time+60.d],probes=probe,varformat='*_r_eci',datatype='epht89d',suffix='_before',/time_clip
  get_data,'mms'+probe+'_mec_r_eci_before',data=d1
  r1=sqrt(d1.y[*,0]*d1.y[*,0]+d1.y[*,1]*d1.y[*,1]+d1.y[*,2]*d1.y[*,2])
  i=n_elements(d1.x)-2l
  dr0=r1[i+1l]-r1[i]
  dr=r1[i]-r1[i-1l]
  while dr0 lt 0.d or dr ge 0.d do begin
    dr0=dr
    i=i-1l
    dr=r1[i]-r1[i-1l]
  endwhile
  perigee_time1=d1.x[i]
  
  mms_load_mec,trange=[time,time+86400.d*days],probes=probe,varformat='*_r_eci',datatype='epht89d',suffix='_after',/time_clip
  get_data,'mms'+probe+'_mec_r_eci_after',data=d2
  r2=sqrt(d2.y[*,0]*d2.y[*,0]+d2.y[*,1]*d2.y[*,1]+d2.y[*,2]*d2.y[*,2])
  i=1l
  dr0=r2[i]-r2[i-1l]
  dr=r2[i+1l]-r2[i]
  while dr0 ge 0.d or dr lt 0.d do begin
    dr0=dr
    i=i+1l
    dr=r2[i+1l]-r2[i]
  endwhile
  perigee_time2=d2.x[i]
  
  store_data,['mms'+probe+'_r_eci_before','mms'+probe+'_r_eci_after'],/delete
  return,[perigee_time1,perigee_time2]
  
END
