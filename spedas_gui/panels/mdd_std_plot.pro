
pro mdd_std_plot,  $
  trange=trange,          $;the time range of the input data
  files=files,            $;(optional)determine the path for output images
  std=std,                $;(optional)calculate the structure velocity using STD method
  delta_t=delta_t,        $;(optional)Determine the time period to calculate the D/Dt  keyword only for std
  B_opt=B_opt,            $;(optional)change the first panel from Btotal to Bx/By/Bz of four SC or 3 components of one sc's mag data
  symsize=symsize,        $;(optional) change the size of symbol
  mode=mode,              $;(optional) switch modes for STD plot according to the dimension number of the structure
  evalue_err=evalue_err

  if not keyword_set(symsize) then symsize=0.01
  Angle = FINDGEN(17) * (!PI*2/16.)
  USERSYM, symsize*COS(Angle), symsize*SIN(Angle),thick=0.5, /FILL

  options,'Error_dots',psym=8
  options,'lamda_dots',psym=8
  options,'Eigenvector_max_dots',psym=8
  options,'Eigenvector_mid_dots',psym=8
  options,'Eigenvector_min_dots',psym=8
  options,'Structure_Dimentions_dots',psym=8
  if keyword_set(std) then begin
    options,'V_max_dots',psym=8   &  options,'Vstructure1_dots',psym=8
    options,'V_mid_dots',psym=8   &  options,'Vstructure_dots',psym=8
    options,'V_min_dots',psym=8   &  options,'V_str_2d_dots',psym=8
  endif
  if ~keyword_set(B_opt) then B_opt='Bt'
  
  thm_init
  tplot_options,'ymargin',[5,5]
  tplot_options,'xmargin',[20,27]
  !p.charthick=1.4   &   !p.charsize=1.4   &  !p.font=-1
  if not keyword_set(std) then begin
    window,0,xsize=1400,ysize=1000
    tplot,[B_opt, 'lamda_c','Structure_Dimentions_c','Eigenvector_max_c','Eigenvector_mid_c','Eigenvector_min_c','Error_indicator'],trange=trange,window=0,$
      title='MDD '+strmid(time_string(trange[0]),0,10)+'/'+strtrim(time_string(time_double(trange[0]),tformat='hh:mm:ss'))+'_'+strtrim(time_string(time_double(trange[1]),tformat='hh:mm:ss'))+''
    if keyword_set(evalue_err) then timebar,evalue_err,varname='lamda_c',color=0,linestyle=1,thick=2,/databar
    timebar,0,varname='Eigenvector_min_c',color=0,linestyle=1,thick=2,/databar
    timebar,0,varname='Eigenvector_mid_c',color=0,linestyle=1,thick=2,/databar
    timebar,0,varname='Eigenvector_max_c',color=0,linestyle=1,thick=2,/databar
    timebar,0.4,varname='Error_c',color=0,linestyle=1,thick=2,/databar
    if keyword_set(files) then $
      makepng,files+'\MDD_'+strmid(time_string(trange[0]),0,10)+strtrim(time_string(time_double(trange[0]),tformat=' hh-mm-ss'))+strtrim(time_string(time_double(trange[1]),tformat=' hh-mm-ss'))+''
  endif
  ;
  if keyword_set(std) then begin
    window,1,xsize=1400,ysize=1000
    case mode of
      '1D': begin
        tplot,['lamda_c','Structure_Dimentions_c','V_max_c','Error_indicator'],trange=trange,window=1,$
          title='STD '+strmid(time_string(trange[0]),0,10)+'/'+strtrim(time_string(time_double(trange[0]),tformat=' hh:mm:ss'))+strtrim(time_string(time_double(trange[1]),tformat=' hh:mm:ss'))+'     delta_t='+strcompress(delta_t)+''
      end
      '2D': begin
        tplot,['lamda_c','V_max_c','V_mid_c','V_str_2d_c','Error_indicator'],trange=trange,window=1,$
          title='STD '+strmid(time_string(trange[0]),0,10)+'/'+strtrim(time_string(time_double(trange[0]),tformat=' hh:mm:ss'))+strtrim(time_string(time_double(trange[1]),tformat=' hh:mm:ss'))+'     delta_t='+strcompress(delta_t)+'s'
      end
      '3D': begin
        tplot,['lamda_c','Structure_Dimentions_c','V_max_c','V_mid_c','V_min_c','Vstructure_c','Error_indicator'],trange=trange,window=1,$
          title='STD '+strmid(time_string(trange[0]),0,10)+'/'+strtrim(time_string(time_double(trange[0]),tformat=' hh:mm:ss'))+strtrim(time_string(time_double(trange[1]),tformat=' hh:mm:ss'))+'     delta_t='+strcompress(delta_t)+''
      end
    endcase
    tplot,[B_opt],trange=trange,window=1,add_var=1,title='STD '+strmid(time_string(trange[0]),0,10)+'/'+strtrim(time_string(time_double(trange[0]),tformat=' hh:mm:ss'))+strtrim(time_string(time_double(trange[1]),tformat=' hh:mm:ss'))+'     delta_t='+strcompress(delta_t)+'s'

    if keyword_set(evalue_err) then timebar,evalue_err,varname='lamda_c',color=0,linestyle=1,thick=2,/databar
    timebar,0,varname='V_max_c',color=0,linestyle=1,thick=2,/databar
    timebar,0,varname='V_mid_c',color=0,linestyle=1,thick=2,/databar
    timebar,0,varname='V_min_c',color=0,linestyle=1,thick=2,/databar
    timebar,0.4,varname='Error_c',color=0,linestyle=1,thick=2,/databar
    if keyword_set(files) then $
      makepng,files+'\STD_'+strmid(time_string(trange[0]),0,10)+strtrim(time_string(time_double(trange[0]),tformat=' hh-mm-ss'))+strtrim(time_string(time_double(trange[1]),tformat=' hh-mm-ss'))+'     delta_t='+strcompress(delta_t)+'s'
  endif
end