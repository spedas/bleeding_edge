;+
; NAME: RBSP_LOAD_EFW_BURST_TIMES
;
; SYNTAX:
;	rbsp_load_efw_burst_times,probe='a b'
;
; PURPOSE: Loads EFW B1 and B2 availability
;
; KEYWORDS:
;	probe = 'a', 'b', 'a b', or ['a','b']
;	trange = time range
;	local_data_dir = local data directory, for overriding default location set
;		in !rbsp_efw or root_data_dir()
;	b1_times, b2_times -> set to named variables to return [x,2] arrays of the start
;		and stop times of each burst in trange
;
;
; HISTORY:
;	11/2012 - Created - Kris Kersten, kris.kersten@gmail.com
;	22 Apr 2013 - changed remote_data_dir location
;	04 Sept 2013 - added support for EB1,2 and MSCB1,2
;	13 Jan 2014 - added b1_times, b2_times keywords (AWB)
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-01-16 10:31:20 -0800 (Thu, 16 Jan 2014) $
;   $LastChangedRevision: 13921 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_efw_burst_times.pro $
;
;-

pro rbsp_load_efw_burst_times,probe=probe,trange=trange, $
	local_data_dir=local_data_dir,force_download=force_download,$
	b1_times=b1t,b2_times=b2t

	rbsp_efw_init

	rbsp_burst=!rbsp_efw
	
	if keyword_set(force_download) then begin
		rbsp_burst.no_download=0
		rbsp_burst.force_download=1
	endif
	
	rbsp_burst.remote_data_dir='http://rbsp.space.umn.edu/data/rbsp/'
	if keyword_set(local_data_dir) then $
		rbsp_burst.local_data_dir=local_data_dir $
	else rbsp_burst.local_data_dir=root_data_dir()+'rbsp/' ; set to default local data dir
	
	dt=1.e-6
	
	if keyword_set(probe) then p_var=probe else p_var='*'
	vprobes = ['a','b']
	p_var = strfilter(vprobes, p_var ,delimiter=' ',/string)

	bnames=['vb','eb','mscb']

	b1start = 0d
	b1end = 0d
	b2start = 0d
	b2end = 0d
		
	for p=0,size(p_var,/n_elements)-1 do begin
	
		rbspx = 'rbsp'+ p_var[p]
	
		for b=1,2 do begin
		
			for bn=0,2 do begin

				bid=bnames[bn]+string(b,format='(I0)')
		
				format = 'burst_playback/'+rbspx + '/'+bid+'_playback/YYYY/'+ $
						rbspx+'_efw_'+bid+'_playback_YYYYMMDD_v*.txt'

				relpathnames = file_dailynames(file_format=format, $
				trange=trange,addmaster=addmaster)

				files=file_retrieve(relpathnames,/last_version, $
					_extra=rbsp_burst)

				nfiles=size(files,/n_elements)


				for i=0,nfiles-1 do begin
				
					file_open,'r',files[i],/test,info=finfo
					if finfo.exists then begin
						file_open,'r',files[i],unit=u
						line=''
						while ~EOF(u) and strpos(line,'-----') eq -1 do $
							readf,u,line
	
						bstart_temp=''
						bend_temp=''
						junk=''
						bcount=0
						while ~EOF(u) do begin
							readf,u,bstart_temp,junk,bend_temp, $
								format='(A26,A2,A26)'
							if bcount eq 0 then begin
								bstart=time_double(bstart_temp)
								bend=time_double(bend_temp)
							endif else begin
								bstart=[bstart,time_double(bstart_temp)]
								bend=[bend,time_double(bend_temp)]
							endelse
							bcount+=1
						endwhile
				

						if bn eq 0 then begin
							if b eq 1 then begin
								b1start = [b1start,bstart]
								b1end = [b1end,bend]
							endif else begin
								b2start = [b2start,bstart]
								b2end = [b2end,bend]
							endelse
						endif		
		
				
						burst_flag=[0.,1.,1.,0.]
						burst_times=[bstart[0]-dt,bstart[0],bend[0],bend[0]+dt]
						for j=1,bcount-1 do begin
							burst_flag=[burst_flag,0.,1.,1.,0.]
							burst_times=[burst_times,$
								bstart[j]-dt,bstart[j],bend[j],bend[j]+dt]
						endfor
					
					
						bname=rbspx+'_efw_'+bid+'_available'
						bdata={x:burst_times,y:burst_flag}
						lim={yrange:[-.05,1.05],ystyle:1,colors:[4],$
							thick:1.5,yticks:1, $
							ytickname:['off','on'],ticklen:0.,panel_size:.2}
						
						get_data,bname,data=btemp
						if is_struct(btemp) then begin
							tempx1=btemp.x
							tempx2=bdata.x
							tempy1=btemp.y
							tempy2=bdata.y
							bdata={x:[tempx1,tempx2],y:[tempy1,tempy2]}
						endif
						store_data,bname,data=bdata,limits=lim,verbose=3
		
					
						free_lun,u
					
					endif
					
				endfor
			
			endfor
			
		endfor
		
	endfor

	;return variables with start and stop times			
	if n_elements(b1start) gt 1 then b1t = [[b1start[1:n_elements(b1start)-1]],[b1end[1:n_elements(b1start)-1]]]
	if n_elements(b2start) gt 1 then b2t = [[b2start[1:n_elements(b2start)-1]],[b2end[1:n_elements(b2start)-1]]]

	
end
