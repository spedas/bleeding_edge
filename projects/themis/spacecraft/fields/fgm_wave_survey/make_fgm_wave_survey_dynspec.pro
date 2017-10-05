;+
;Procedure: make_fgm_wave_survey_dynspec
;
;Purpose:
;  Routine to generate wave survey plots. Built from survey code provided by Ferdinand Plaschke(fplaschke@igpp.ucla.edu)
;  Generates a full set of survey views.  FGE/FGL Artemis & THEMIS 2hr, 6hr,24 hr for the provided date.
;
; Arguments:
;        date: Set this to the date for which the plots should be
;        generated. 
; Keywords:
;        directory: Set this to the output directory for plots, the
;        default is the local working directory './'. Be sure to add a
;        slash to the end.
; Notes:
;   There are several helper routines for this code.  The main routine(make_fgm_wave_survey_dynspec.pro) is near the bottom of the file.
;
; Examples:
;   See helper routine make_fgm_wave_survey_testdates
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2012-09-07 11:22:10 -0700 (Fri, 07 Sep 2012) $
; $LastChangedRevision: 10902 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/fgm_wave_survey/make_fgm_wave_survey_dynspec.pro $
;-

pro survey_dynspec_psd, x, p, freq=f, dt=dt

percent	= 5.D

n_x	= n_elements(x)

cosinewindow	= replicate(1.D,n_x)
n_percent		= round(double(n_x) / 100.D * percent)
cosinewindow(0:n_percent - 1L)			= 0.5D * (1.0D - cos(!DPI * dindgen(n_percent) / double(n_percent)))
cosinewindow(n_x - n_percent:n_x - 1L)	= 0.5D * (1.0D - cos(!DPI * dindgen(n_percent) / double(n_percent)))

taperfactor	= total(cosinewindow^2) / double(n_x)

n_f	= long(n_x / 2)
f	= dindgen(n_f) / (n_x * dt)

xnew	= x
temp	= linfit(dindgen(n_x) * dt, xnew, /double, yfit=yfit)
xnew	-= yfit
xnew	*= cosinewindow
fftx = fft(xnew, /double)

px	= abs(fftx)^2 * n_x * dt * 2.D / taperfactor
p	= px(0:n_f - 1)

return
end



pro survey_dynspec_helper, time_in, data_in, n_points, freq_out, dynspec_out, time_out

n_rounds	= n_elements(time_in) / n_points
initial		= 1

for i = 0L, n_rounds - 1L do begin
	time_r	= time_in(i * n_points:(i + 1L) * n_points - 1L)
	data_r	= data_in(i * n_points:(i + 1L) * n_points - 1L)
	idx = where(~finite(data_r),n_finite_count)
	dt		= time_r(1)-time_r(0)
  
  if (n_finite_count gt 0) then begin
    survey_dynspec_psd, dindgen(n_points), psd_r, freq=freq, dt=dt ;process with fake data to get right dimensions on output
    freq_out  = freq(1:*)
    if (initial eq 1) then begin
     dynspec_out  = replicate(!VALUES.D_NAN,n_elements(psd_r(1:*)))
     time_out = mean(time_r)
     initial    = 0
    endif else begin
     dynspec_out  = [[dynspec_out],[replicate(!VALUES.D_NAN,n_elements(psd_r(1:*)),n_elements(data_r))]]
     time_out = [time_out, time_r]
    endelse
  endif else begin
    survey_dynspec_psd, data_r, psd_r, freq=freq, dt=dt
	  freq_out	= freq(1:*)
    if (initial eq 1) then begin
		 dynspec_out	= psd_r(1:*)
		 time_out	= mean(time_r)
		 initial		= 0
		endif else begin
		 dynspec_out	= [[dynspec_out],[psd_r(1:*)]]
		 time_out	= [time_out, mean(time_r)]
		endelse
  endelse
endfor

dynspec_out	= reverse(transpose(dynspec_out), 2)
freq_out	= reverse(freq_out)

return
end

;splits data into segments, smooths each segment separately.  Clips the unsmoothed edges off of each segment.
pro survey_dynspec_data_sanitizer,varname,gap_margin,smooth_margin,data_cadence,suffix,fail=fail,nosmooth=nosmooth

  compile_opt idl2
  
  fail=1
  
  get_data,varname,time,data,dlimit=dl
  
  n_ele = n_elements(time)
  
  if n_ele lt 2 then return 

  gap_start = where((time[1:n_ele-1]-time[0:n_ele-2]) gt gap_margin,cnt) 
 
  ;add one more "gap" so that it will process the last segment, or process the only segment, if there are no gaps
  if cnt eq 0 then begin
    gap_start = [n_ele-1]   
  endif else begin
    gap_start = [gap_start,n_ele-1]
  endelse
  
  cnt++
    
  for i = 0,cnt-1 do begin
  
    if i eq 0 then begin
      segment_start = 0
    endif else begin
      segment_start = gap_start[i-1]+1
    endelse
    
    segment_stop = gap_start[i]
  
    ;segment too small?
    if (segment_stop - segment_start) lt smooth_margin then begin
      continue ;don't add to output
    endif    
  
    segment_time = time[segment_start:segment_stop]
    segment_data = data[segment_start:segment_stop,*]
    dim = dimen(segment_data)
    
    if ~keyword_set(nosmooth) then begin
      ;smooth data
      for j = 0,dim[1]-1 do begin
        segment_data[*,j] = smooth(segment_data[*,j],smooth_margin)
      endfor
    endif
    
    smooth_offset = floor(smooth_margin/2l)
    
    ;clip unsmoothed edges
    segment_data = segment_data[smooth_offset:n_elements(segment_time)-1-smooth_offset,*]
    segment_time = segment_time[smooth_offset:n_elements(segment_time)-1-smooth_offset]
    
    ;nan at the beginning of segment(except first segment)
    if i gt 0 then begin
      segment_time = [min(segment_time)-data_cadence,segment_time]
      segment_data = [transpose(replicate(!VALUES.D_NAN,dim[1])),segment_data]
    endif
    
    ;nan at the end of segment(except last segment)
    if i lt cnt-1 then begin 
      segment_time = [segment_time,max(segment_time)+data_cadence]
      segment_data = [segment_data,transpose(replicate(!VALUES.D_NAN,dim[1]))]
    endif
    
    output_time=array_concat(segment_time,output_time)
    output_data=array_concat(segment_data,output_data)
    
  endfor 
  
  if undefined(output_time) then begin
    return
  endif
  
  ;replace output data
  store_data,varname+suffix,data={x:output_time,y:output_data},dlimit=dl

  fail=0

end

;Modified to support one probe and to provide an image raster so that plots can be composed with the appropriate var_labeling
pro load_survey_dynspec, date, sc, dur, fge=fge, ylog=ylog, fci=fci, use_l2=use_l2 

compile_opt idl2

; date = '2012-01-01' or in UNIX time
; directory	= '../results/'

thx='th'+sc

if ~keyword_set(date) then date = '2012-01-01'
if ~keyword_set(fge) then dp = 'l' else dp = 'e'
if ~keyword_set(fge) then dt=0.25 else dt = 0.125

;gap_size=10
gap_size=dt*1.05
smooth_pts=601

in_date	= time_double(date)
timespan, in_date-60.d*60.d*dur/2.,2*dur,/hours
If(keyword_set(use_l2)) Then Begin
    thm_load_fgm, /get_supp, probe=sc, level='l2', coord='gse'
Endif Else Begin
    thm_load_fgm, /get_supp, probe=sc
    thm_cotrans, thx+'_fg'+dp, out_coord='gse', out_suff='_gse'
Endelse

;version for FAC and cyclotron lines
survey_dynspec_data_sanitizer,thx+'_fg'+dp+'_gse',gap_size,smooth_pts,dt,'_sm601',fail=fail

;version for dynspec 
survey_dynspec_data_sanitizer,thx+'_fg'+dp+'_gse',gap_size,smooth_pts,dt,'',/nosmooth

If(~fail) Then Begin
    calc, '"'+thx+'_fg'+dp+'_fci_h" = sqrt(total("'+thx+'_fg'+dp+'_gse_sm601"^2,2)) * 0.015240060',nan=0
    calc, '"'+thx+'_fg'+dp+'_fci_he" = sqrt(total("'+thx+'_fg'+dp+'_gse_sm601"^2,2)) * 0.0038363860',nan=0
    calc, '"'+thx+'_fg'+dp+'_fci_o" = sqrt(total("'+thx+'_fg'+dp+'_gse_sm601"^2,2)) * 0.00095960185',nan=0

    options, thx+'_fg'+dp+'_fci_h', 'linestyle', 0
    options, thx+'_fg'+dp+'_fci_he', 'linestyle', 2
    options, thx+'_fg'+dp+'_fci_o', 'linestyle', 3
    options, thx+'_fg'+dp+'_fci_*', 'ystyle', 1
    options, thx+'_fg'+dp+'_fci_*', 'labels', ' '
    options, thx+'_fg'+dp+'_fci_h','thick',3.0
    options, thx+'_fg'+dp+'_fci_he','thick',3.0
    options, thx+'_fg'+dp+'_fci_o','thick',3.0
Endif

fake_time	= [in_date - 86400.D + 3*86400.D*dindgen(100)/99]
fake_data	= transpose(dindgen(10)) ## replicate(!VALUES.D_NAN,100)
fake_freq	= transpose(dindgen(10) / 10.D * 2.D) ## replicate(1.D,100)

if fail then begin
  valid_count = 0
endif else begin

  get_data,thx+'_fg'+dp+'_gse_sm601',test_time2  
  ;we load extra data on each end. Do we have any data on the actual date?
  idx = where(test_time2 ge in_date and test_time2 lt in_date+dur*60.d*60.d,valid_count)

endelse

if valid_count gt 601 then begin

  ;since smoothed data got clipped by the sanitizer, we need to interpolate unsmoothed data to match clipped
  ;tinterpol_mxn,thx+'_fg'+dp+'_gse',thx+'_fg'+dp+'_gse_sm601',/overwrite
  
  fac_matrix_make, thx+'_fg'+dp+'_gse_sm601', other_dim='xgse', newname = thx+'_fg'+dp+'_gse_sm601_fac_mat'
  tvector_rotate, thx+'_fg'+dp+'_gse_sm601_fac_mat', thx+'_fg'+dp+'_gse', newname = thx+'_fg'+dp+'_facx'
  get_data, thx+'_fg'+dp+'_facx', t, d, v
  ddx	= (d[*,0] - shift(d[*,0],1))[1:*]
  ddy	= (d[*,1] - shift(d[*,1],1))[1:*]
  ddz	= (d[*,2] - shift(d[*,2],1))[1:*]
  tt	= t[1:*]
  survey_dynspec_helper, tt, ddx, 256, freq_out, dynspec_outx, time_out
  survey_dynspec_helper, tt, ddy, 256, freq_out, dynspec_outy, time_out
  survey_dynspec_helper, tt, ddz, 256, freq_out, dynspec_outz, time_out
  dynspec_outxy	= dynspec_outx + dynspec_outy
  ff	= transpose(freq_out) ## replicate(1.D, n_elements(time_out))
   
endif else begin
	time_out	= fake_time
	dynspec_outxy	= fake_data
	dynspec_outz	= fake_data
	ff	= fake_freq
	dt=median(deriv(fake_time))
	
  store_data,thx+'_fg'+dp+'_fci_h',data={x:fake_time,y:replicate(!VALUES.D_NAN,n_elements(fake_time),3)}
  store_data,thx+'_fg'+dp+'_fci_he',data={x:fake_time,y:replicate(!VALUES.D_NAN,n_elements(fake_time),3)}
  store_data,thx+'_fg'+dp+'_fci_o',data={x:fake_time,y:replicate(!VALUES.D_NAN,n_elements(fake_time),3)}
endelse

store_data, thx+'_facx_dynspecxy_temp', data={x:time_out, y:dynspec_outxy, v:ff}, dlimits={spec:1b, ystyle:1, no_interp:1, zlog:1, zstyle:1, zrange:[1.D-9, 1.D-1] * 256.D, ztitle:'PSD [nT!u2!n/Hz]', ytitle:'TH'+strupcase(sc)+' B!9x!3!c!cfreq [Hz]'}
store_data, thx+'_facx_dynspecz_temp', data={x:time_out, y:dynspec_outz, v:ff}, dlimits={spec:1b, ystyle:1, no_interp:1, zlog:1, zstyle:1, zrange:[1.D-9, 1.D-1] * 256.D, ztitle:'PSD [nT!u2!n/Hz]', ytitle:'TH'+strupcase(sc)+' B!9#!3!c!cfreq [Hz]'}
;store_data, thx+'_facx_dynspecxy_temp', data={x:time_out, y:dynspec_outxy, v:ff}, dlimits={spec:1b, ystyle:1, no_interp:1, zlog:1, zstyle:1, ztitle:'PSD [nT!u2!n/Hz]', ytitle:'TH'+strupcase(sc)+' B!9x!3!c!cfreq [Hz]'}
;store_data, thx+'_facx_dynspecz_temp', data={x:time_out, y:dynspec_outz, v:ff}, dlimits={spec:1b, ystyle:1, no_interp:1, zlog:1, zstyle:1, ztitle:'PSD [nT!u2!n/Hz]', ytitle:'TH'+strupcase(sc)+' B!9#!3!c!cfreq [Hz]'}

if keyword_set(fci) then begin    
	store_data, thx+'_facx_dynspecxy', data=[thx+'_facx_dynspecxy_temp', thx+'_fg'+dp+'_fci_h', thx+'_fg'+dp+'_fci_he', thx+'_fg'+dp+'_fci_o']
	store_data, thx+'_facx_dynspecz', data=[thx+'_facx_dynspecz_temp', thx+'_fg'+dp+'_fci_h', thx+'_fg'+dp+'_fci_he', thx+'_fg'+dp+'_fci_o']
	options, thx+'_facx_dynspecz', 'ystyle', 1
	options, thx+'_facx_dynspecxy', 'ystyle', 1
endif


;Do transformation to create var_labels
thm_load_state,coord='gse',probe=sc
tkm2re,thx+'_state_pos',newname=thx+'_state_pos_gse'
split_vec,thx+'_state_pos_gse_re'
options,thx+'_state_pos_gse_re_x',ytitle='X_RE_GSE'
options,thx+'_state_pos_gse_re_y',ytitle='Y_RE_GSE'
options,thx+'_state_pos_gse_re_z',ytitle='Z_RE_GSE'

if (sc eq 'c' || sc eq 'b') && in_date ge time_double('2010-09-01') then begin
  thm_load_slp
  thm_load_state,coord='sse',probe=sc
  calc,'"'+thx+'_state_pos_sse_le"="'+thx+'_state_pos"/1738.0' ;convert from km to lunar radii
  split_vec,thx+'_state_pos_sse_le'
  options,thx+'_state_pos_sse_le_x',ytitle='X_LE_SSE'
  options,thx+'_state_pos_sse_le_y',ytitle='Y_LE_SSE'
  options,thx+'_state_pos_sse_le_z',ytitle='Z_LE_SSE'
endif else begin  
  thm_load_state,coord='sm',probe=sc

  xyz_to_polar,thx+'_state_pos'
  calc,'"'+thx+'_state_pos_phi_mlt"=(("'+thx+'_state_pos_phi"+180) mod 360)*24/360'
  tkm2re,thx+'_state_pos_mag'

  options,thx+'_state_pos_mag_re',ytitle='R_RE_SM'
  options,thx+'_state_pos_phi_mlt',ytitle='MLT_SM'
  options,thx+'_state_pos_th',ytitle='MLAT_SM'
 
endelse

end

pro raster_survey_dynspec,date,dur,probe,raster_out=raster_out,resolution=resolution,notime=notime,title=title,ylog=ylog,fci=fci,fge=fge

compile_opt idl2

thx = 'th'+probe

if keyword_set(notime) then begin
  tplot_options,'version',5
  ymargin=[1,0.5]
endif else begin
  tplot_options,'version',3
  ymargin=[2,0.5]
endelse

if keyword_set(title) then begin

  ymargin[1]+=1.5
  tplot_options,'title',title

endif else begin
  
  tplot_options,'title',title
  
endelse  

if (keyword_set(ylog) eq 0) then begin

  if keyword_set(fge) then begin
    yrange = [0.,4.]
  endif else begin
    yrange  = [0.,2.]
  endelse
  
endif else begin

  if keyword_set(fge) then begin
    yrange = [0.05,4.]
  endif else begin
    yrange  = [0.05, 2.]
  endelse
   
endelse

tplot_options,'ymargin',ymargin
tplot_options,'xmargin',[12,10]

options, '*', yrange=yrange
options, '*', ylog=ylog

tplot_options,'ygap',0.0d

if (probe eq 'c' || probe eq 'b') && time_double(date) ge time_double('2010-09-01') then begin
  var_label=thx+['_state_pos_sse_le_z','_state_pos_sse_le_y','_state_pos_sse_le_z','_state_pos_gse_re_z','_state_pos_gse_re_y','_state_pos_gse_re_x']
endif else begin 
  var_label=thx+['_state_pos_mag_re','_state_pos_phi_mlt','_state_pos_th','_state_pos_gse_re_z','_state_pos_gse_re_y','_state_pos_gse_re_x']
endelse
 
set_plot, 'Z'
device, set_resolution	= resolution
!P.background	= 255
!P.color	= 0
;tplot_options, 'datagap', 300
timespan, date,dur,/hours
if (keyword_set(fci) ne 0) then begin
  options, thx+'_facx_dynspecxy',yrange=yrange,ylog=ylog
  options, thx+'_facx_dynspecz',yrange=yrange,ylog=ylog
	tplot, thx+'_facx_dynspecxy ' + thx + '_facx_dynspecz',var_label=var_label
endif else begin
  options, thx+'_facx_dynspecxy_temp',yrange=yrange,ylog=ylog
  options, thx+'_facx_dynspecz_temp',yrange=yrange,ylog=ylog
	tplot, thx+'_facx_dynspecxy_temp ' + thx +'_facx_dynspecz_temp',var_label=var_label
endelse
raster_out=tvrd()

end

pro make_fgm_wave_survey_dynspec,date,directory=directory, use_l2=use_l2

  if(keyword_set(directory)) then pdir=directory else pdir='./'
  resolution=[750,400]
    
  dur=[replicate(2,12),replicate(6,4),24]
  offset=[dindgen(12)*2,dindgen(4)*6,0] 
;time string for plot filenames
  tstr = time_string(date, /date_only)+'-'+string(offset,format='(%"%2.2I")')+string(offset+dur,format='(%"%2.2I")')
          
  del_data,'*'
  ;2012-01-01 b has no data on 1 hr dur, good for testing missing data errors
  load_survey_dynspec,date,'b',24,/fci, use_l2=use_l2
  load_survey_dynspec,date,'c',24,/fci, use_l2=use_l2
  
  for i = 0,n_elements(dur)-1 do begin
   
    in_date = time_string(time_double(date)+offset[i]*60.*60.)
   
    for log=0,1 do begin 
  
      if keyword_set(log) then begin
        title_log = '(Log)'
        fname_log = 'log'
      endif else begin
        title_log = '(Lin)'
        fname_log = 'lin'
      endelse
   
      raster_survey_dynspec,in_date,dur[i],'b',raster_out=re1,resolution=resolution,ylog=log,/fci,/notime,title='Artemis(THB,THC) FGL Wave Survey Plot '+title_log
      raster_survey_dynspec,in_date,dur[i],'c',raster_out=re2,resolution=resolution,ylog=log,/fci
    
      set_plot,'z'
      device,set_resolution=[resolution[0],resolution[1]*2]
      !P.background = 255
      !P.color  = 0
      tv,transpose([transpose(re2),transpose(re1)])
      makepng,pdir+tstr[i]+'_wave_survey_fgl_artemis_'+fname_log
    
    endfor
  endfor
  
  del_data,'*'
  ;2012-01-01 b has no data on 1 hr dur, good for testing missing data errors
  load_survey_dynspec,date,'b',24,/fci,/fge, use_l2=use_l2
  load_survey_dynspec,date,'c',24,/fci,/fge, use_l2=use_l2
  
  for i = 0,n_elements(dur)-1 do begin
   
    in_date = time_string(time_double(date)+offset[i]*60.*60.)
   
    for log=0,1 do begin 
  
      if keyword_set(log) then begin
        title_log = '(Log)'
        fname_log = 'log'
      endif else begin
        title_log = '(Lin)'
        fname_log = 'lin'
      endelse
   
      raster_survey_dynspec,in_date,dur[i],'b',raster_out=re1,resolution=resolution,ylog=log,/fci,/fge,/notime,title='Artemis(THB,THC) FGE Wave Survey Plot '+title_log
      raster_survey_dynspec,in_date,dur[i],'c',raster_out=re2,resolution=resolution,ylog=log,/fci,/fge
    
      set_plot,'z'
      device,set_resolution=[resolution[0],resolution[1]*2]
      !P.background = 255
      !P.color  = 0
      tv,transpose([transpose(re2),transpose(re1)])
      makepng,pdir+tstr[i]+'_wave_survey_fge_artemis_'+fname_log
    
    endfor
  endfor
  
  del_data,'*'
  load_survey_dynspec,date,'a',24,/fci, use_l2=use_l2
  load_survey_dynspec,date,'d',24,/fci, use_l2=use_l2
  load_survey_dynspec,date,'e',24,/fci, use_l2=use_l2
   
  for i=0,n_elements(dur)-1 do begin
    
    in_date = time_string(time_double(date)+offset[i]*60*60)
    
    for log=0,1 do begin 
  
      if keyword_set(log) then begin
        title_log = '(Log)'
        fname_log = 'log'
      endif else begin
        title_log = '(Lin)'
        fname_log = 'lin'
      endelse
      
      raster_survey_dynspec,in_date,dur[i],'a',raster_out=re1,resolution=resolution,ylog=log,/fci,/notime,title='THEMIS(THA,THD,THE) FGL Wave Survey Plot '+title_log
      raster_survey_dynspec,in_date,dur[i],'d',raster_out=re2,resolution=resolution,ylog=log,/fci,/notime
      raster_survey_dynspec,in_date,dur[i],'e',raster_out=re3,resolution=resolution,ylog=log,/fci
     
      set_plot,'z'
      device,set_resolution=[resolution[0],resolution[1]*3]
      !P.background = 255
      !P.color  = 0
      tv,transpose([transpose(re3),transpose(re2),transpose(re1)])
      makepng,pdir+tstr[i]+'_wave_survey_fgl_themis_'+fname_log
  
    endfor
    
  endfor
  
  del_data,'*'
  load_survey_dynspec,date,'a',24,/fci,/fge, use_l2=use_l2
  load_survey_dynspec,date,'d',24,/fci,/fge, use_l2=use_l2
  load_survey_dynspec,date,'e',24,/fci,/fge, use_l2=use_l2
 
  for i=0,n_elements(dur)-1 do begin
    
    in_date = time_string(time_double(date)+offset[i]*60*60)
    
    for log=0,1 do begin 

      if keyword_set(log) then begin
        title_log = '(Log)'
        fname_log = 'log'
      endif else begin
        title_log = '(Lin)'
        fname_log = 'lin'
      endelse
      
      raster_survey_dynspec,in_date,dur[i],'a',raster_out=re1,resolution=resolution,ylog=log,/fci,/fge,/notime,title='THEMIS(THA,THD,THE) FGE Wave Survey Plot '+title_log
      raster_survey_dynspec,in_date,dur[i],'d',raster_out=re2,resolution=resolution,ylog=log,/fci,/fge,/notime
      raster_survey_dynspec,in_date,dur[i],'e',raster_out=re3,resolution=resolution,ylog=log,/fci,/fge
      
      set_plot,'z'
      device,set_resolution=[resolution[0],resolution[1]*3]
      !P.background = 255
      !P.color  = 0
      tv,transpose([transpose(re3),transpose(re2),transpose(re1)])
      makepng,pdir+tstr[i]+'_wave_survey_fge_themis_'+fname_log
      
    endfor
  
  endfor
    
 
end

pro make_fgm_wave_survey_testdates

  cd,'~/IDLWorkspace/Default/dynspec_output'
  make_fgm_wave_survey_dynspec,'2007-06-29'
  make_fgm_wave_survey_dynspec,'2008-06-28'
  make_fgm_wave_survey_dynspec,'2010-06-25'

end



