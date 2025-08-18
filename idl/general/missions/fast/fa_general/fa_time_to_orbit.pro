function fa_time_to_orbit,t,string=string,five_string=five_string

time=t
time=time_double(time)
ntime=n_elements(time)
orbitarray=lonarr(ntime)

orbit00001=dblarr(3)
orbit51314=dblarr(3)
orbit00001=[840625910d,840629910d]
orbit51314=[1241079567d,1241083410d]
for i=0,ntime-1 do begin
	if (time[i] GE orbit00001[0]) AND (time[i] LT orbit00001[1]) then time[i]=orbit00001[1]
	if (time[i] GE orbit51314[0]) AND (time[i] LE orbit51314[1]) then time[i]=orbit51314[0]
	if (time[i] LT orbit00001[0]) then begin
		print,'Error: Time Before First Orbit'
		return,0
	endif
	if (time[i] GT orbit51314[1]) then begin
		print,'Error: Time After Last Orbit'
		return,0
	endif
endfor

;Run Davin's routine
times='1996-08-30/22:01 1998-01-21/02:47 1999-06-07/17:21 2000-10-15/16:35 2002-01-27/18:26 2003-06-30/11:09 2004-11-10/22:21 2006-04-20/11:07 2007-09-25/22:00 2009-04-30/05:32'
orbits=[      103.01045 ,      5599.8664,       11054.278,       16467.985,       21636.072,      27401.815,        32986.090,       38879.855,       44761.655,       51312.285]
times=time_double(strsplit(times,' ',/extract))
orbn=fix(long(interp(orbits,times,time)),type=13)

fa_init
common fa_information,info_struct
timesarray=info_struct.timesarray

for i=0,ntime-1 do begin

 orbitline=fa_orbit_to_time(orbn[i])
  starttime=orbitline[1]
  endtime=orbitline[2]
  
  case 1 of
  
       (time[i] GE starttime) AND (time[i] LT endtime): begin
  		orbitarray[i]=orbn[i]
  		d_flag=0
  	end
  	
  	time[i] LT starttime: d_flag=-1
  	
  	time[i] GE endtime: d_flag=1
  	
  	else: begin
  		print,'Unexpected Error on Time'+time[i]+'.'
  		orbitarray[i]=-1
  		d_flag=0
  	end
  	
  endcase
  
  if d_flag EQ 0 then continue

  while 1 do begin

    
     orbn[i]+=d_flag
     orbitline=fa_orbit_to_time(orbn[i])
     starttime=orbitline[1]
     endtime=orbitline[2]

    
     if (time[i] GE starttime) AND (time[i] LT endtime) then begin

       
        orbitarray[i]=orbn[i]

       break

     endif

  endwhile

endfor

if n_elements(orbitarray) EQ 1 then orbitarray=orbitarray[0]
if keyword_set(string) then return,strcompress(string(orbitarray),/remove_all)
if keyword_set(five_string) then return,strcompress(string(orbitarray,format='(i05)'),/remove_all)

return,orbitarray

end