;+
;PROCEDURE:   tplot_var_labels
;PURPOSE:
;   Helper routine for tplot.  Formats var_labels  
;   
;   The var_label code in the body of tplot.pro was occupying 25% of the file. It needed to be abstracted.  
;
;Inputs:
;  def_opts: all the options need for variables labels
;  trg: time range for plotting
;  var_label: var_label setting from user 
;  local_time: local time keyword from user
;  pos: plot position
;  chsize: desired character size
;  
;Outputs:
;  vtitle=vtitle: title for var labels
;  vlab=vlab: formatted var labels
;  time_offset=time_offset: Used by tplot for ???
;  time_scale=time_scale: Used by tplot for ???
;  
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2014-01-31 17:32:47 -0800 (Fri, 31 Jan 2014) $
; $LastChangedRevision: 14111 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_var_labels.pro $
;-

pro tplot_var_labels,def_opts,trg,var_label,local_time,pos,chsize,vtitle=vtitle,vlab=vlab,time_offset=time_offset,time_scale=time_scale

  compile_opt idl2,hidden

  ;Sections adding different var_label versions
  if def_opts.version eq 2 then begin
    time_setup = time_ticks(trg,time_offset,xtitle=xtitle)
    time_scale = 1.
    if keyword_set(var_label) then begin
      time = time_setup.xtickv+time_offset
      vtitle = 'UT'
      for i=0,n_elements(var_label)-1 do begin
        vtit = strmid(var_label[i],0,3)
        get_data,var_label[i],ptr=pdata,alimits=limits
        if size(/type,pdata) ne 8 then  dprint,verbose=verbose,var_label[i], ' not valid!' $
        else begin
          def = {ytitle:vtit, format:'(F6.1)'}
          ;            extract_tags,def,data,tags = ['ytitle','format']
          extract_tags,def,limits,tags = ['ytitle','format']
          v = data_cut(var_label[i],time)
          vlab = strcompress( string(v,format=def.format) ,/remove_all)
          vtitle = vtitle + '!C' +def.ytitle
          time_setup.xtickname = time_setup.xtickname +'!C'+vlab
          xtitle = '!C'+xtitle
        endelse
      endfor
      def_opts.xtitle = xtitle
    endif else def_opts.xtitle = 'Time (UT) '+xtitle
    extract_tags,def_opts,time_setup
  endif else if def_opts.version eq 1 then begin
    deltat = trg[1] - trg[0]
    case 1 of
      deltat lt 60. : begin & time_scale=1.    & tu='Seconds' & p=16 & end
      deltat lt 3600. : begin & time_scale=60.   & tu='Minutes' & p=13 & end
      deltat le 86400. : begin & time_scale=3600. & tu='Hours'   & p=10 & end
      deltat le 31557600. : begin & time_scale=86400. & tu='Days' & p=7 & end
      else            : begin & time_scale=31557600. & tu='Years' & p = 5 & end
    endcase
    ref = strmid(time_string(trg[0]),0,p)
    time_offset = time_double(ref)
    ;   print,ref+' '+tu,p,time_offset-trg(0)
    def_opts.xtitle = 'Time (UT)  '+tu+' after '+ref
    str_element,def_opts,'xtickname',replicate('',22),/add_replace
  endif else if def_opts.version eq 4 then begin
    deltat = trg[1] - trg[0]
    time_scale=1.
    tu='Seconds'
    p=16
    ref = strmid(time_string(trg[0]),0,p)
    time_offset = 0
    dprint,verbose=verbose,dlevel=2,ref+' '+tu,p,time_offset-trg[0]
    def_opts.xtitle = tu+' after launch'
    str_element,def_opts,'xtickname',replicate('',22),/add_replace
    
  endif else if def_opts.version eq 5 then begin ;version eq 5 is identical to version eq 3 except that time labels are supressed
    str_element,def_opts,'num_lab_min',value=num_lab_min
    str_element,def_opts,'tickinterval',value=tickinterval
    str_element,def_opts,'xtitle',value=xtitle
    if not keyword_set(num_lab_min) then $
      num_lab_min= 2. > (.035*(pos[2,0]-pos[0,0])*!d.x_size/chsize/!d.x_ch_size)
    time_setup = time_ticks(trg,time_offset,num_lab_min=num_lab_min, $
      side=vtitle,xtitle=xtitle,tickinterval=tickinterval,local_time=local_time)
      
    time_scale = 1.
    vtitle=''
    time_setup.xtickname=' '
    time_setup.xtitle=''
    if keyword_set(var_label) then begin
      time = time_setup.xtickv+time_offset
      for i=0,n_elements(var_label)-1 do begin
        vtit = strmid(var_label[i],0,3)
        get_data,var_label[i],ptr=pdata,alimits=limits
        if size(/type,pdata) ne 8 then  dprint,verbose=verbose,var_label[i], ' not valid!'  $
        else begin
          def = {ytitle:vtit, format:'(F6.1)'}
          ;            extract_tags,def,data,tags = ['ytitle','format']
          extract_tags,def,limits,tags = ['ytitle','format']
          v = data_cut(var_label[i],time)
          vlab = strcompress( string(v,format=def.format) ,/remove_all)
          w = where(finite(v) eq 0,nw)
          if nw gt 0 then vlab[w] = ''
          
          if i eq 0 then begin
            vtitle = def.ytitle + vtitle
            time_setup.xtickname[*] = vlab+time_setup.xtickname
            time_setup.xtitle = ''+time_setup.xtitle
          endif else begin
            vtitle = def.ytitle + '!C' +vtitle
            time_setup.xtickname = vlab +'!C'+time_setup.xtickname
            time_setup.xtitle = '!C'+time_setup.xtitle
          endelse
        endelse
      endfor
    endif
    extract_tags,def_opts,time_setup
    ;default version eq 3
  endif else begin
    str_element,def_opts,'num_lab_min',value=num_lab_min
    str_element,def_opts,'tickinterval',value=tickinterval
    str_element,def_opts,'xtitle',value=xtitle
    if not keyword_set(num_lab_min) then $
      num_lab_min= 2. > (.035*(pos[2,0]-pos[0,0])*!d.x_size/chsize/!d.x_ch_size)
    time_setup = time_ticks(trg,time_offset,num_lab_min=num_lab_min, $
      side=vtitle,xtitle=xtitle,tickinterval=tickinterval,local_time=local_time)
      
    time_scale = 1.
    if keyword_set(var_label) then begin
      time = time_setup.xtickv+time_offset
      for i=0,n_elements(var_label)-1 do begin
        vtit = strmid(var_label[i],0,3)
        get_data,var_label[i],ptr=pdata,alimits=limits
        if size(/type,pdata) ne 8 then begin
          dprint,verbose=verbose,var_label[i], ' not valid!'
        endif else begin
        
          def = {ytitle:vtit, format:'(default)'}
          ;       extract_tags,def,data,tags = ['ytitle','format']
          extract_tags,def,limits,tags = ['ytitle','format']
          v = data_cut(var_label[i],time)
          vdimen=dimen(v)
          
          ;This block handles default var_label formatting
          if strmid(def.format,0,1) eq '(' then begin ;following IDL PLOT convention, if format begins with a (, it is a format code
          
            if def.format eq '(default)' then begin ;automatic field width adjustment, prevents '*****'s in data
              max_width = 20 ;arbitrary, prevent infinite loop
              
              for var_label_width=6,max_width do begin
                vlab_format = '(F' + strtrim(var_label_width,2) + '.1)'
                vlab = strcompress( string(v,format=vlab_format) ,/remove_all)
                tmp = where(strmatch(vlab,'*\**'),vlab_star_count)
                if vlab_star_count eq 0 then break
              endfor
              
              ;this block handles a user provided format code(that doesn't use a callback function)
            endif else begin
            
              vlab = strcompress( string(v,format=def.format) ,/remove_all)
              
            endelse
            
            vlab = reform(vlab,vdimen) ;if v has more than one dim, string turns 7x3 into 21 element array, last 14 elements would be lost if not for this change
            
            ;This block handles var_label formatting using user specified function(like in IDL PLOT)
          endif else begin ;code doesn't start with '(' assume that it is a callback function
            vlab = strarr(vdimen)
            for j=0,n_elements(v)-1 do begin ;following IDL plot convention, if format does not begin with a ( it is a unit callback
              if n_elements(vdimen) eq 2 then begin
                vlab[j] = call_function(def.format,0,j mod vdimen[0],v[j],j/vdimen[0])  ;arguments are axis,index,value,level
              endif else begin
                vlab[j] = call_function(def.format,0,j,v[j],0)  ;arguments are axis,index,value,level, level is always zero in the 1-d case
              endelse
            endfor
          endelse
          
          w = where(~finite(v),nw)
          if nw gt 0 then vlab[w] = ''
          ;reduce multi dim var label to one dimen of label strings for plotting
          vlab = strjoin(transpose(vlab),'!C')
          time_setup.xtickname = vlab+'!C'+time_setup.xtickname
          time_setup.xtitle = '!C'+time_setup.xtitle
          if n_elements(vdimen) eq 2 then begin ;handle additional left-hand labels for multi-dim case
            vtitle = strjoin(replicate(def.ytitle+'!C',vdimen[1])) +vtitle
          endif else begin
            vtitle = def.ytitle + '!C' +vtitle
          endelse
        endelse
      endfor
    endif
    str_element,def_opts,'xminor',xminor,success=xminor_success
    extract_tags,def_opts,time_setup
    if xminor_success && xminor ge 0 then begin ;prevent user xminor setting from being ignored by time_ticks
      str_element,def_opts,'xminor',xminor,/add
    endif
  endelse

end
