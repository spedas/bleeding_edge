;+
;PROCEDURE:   tplot_var_labels
;PURPOSE:
;   Helper routine for tplot.  Formats var_labels  
;   The var_label code in the body of tplot.pro was occupying 25% of the file. It needed to be abstracted.  
;Inputs:
;  def_opts: all the options need for variables labels, labels are
;            added to the xtickname values in the def_opts structure
;  trg: time range for plotting
;  var_label: var_label setting from user 
;  local_time: local time keyword from user
;  pos: plot position
;  chsize: desired character size
;  
;Outputs:
;  vtitle=vtitle: title for var labels, for first variable
;  vlab=vlab: formatted var labels, for first variable
;  time_offset=time_offset: Used by tplot, as the start time of the
;                           plot in unix time
;  time_scale=time_scale: Used by tplot to scale the time variable,
;                         typically 1.0, but larger for longer time
;                         ranges
; 2021-06-07, jmm, Added option option to allow two variables on a
; line when labeling tplots. To be invoked, the var_label keyword must
; be set up with a valid tplot variable name in square brackets [] after a
; valid tplot variable. Note that even single labels must be passed in as arrays.
; e.g., 
; tplot, 'tha_fag_dsl', var_label = ['tha_state_pos_gse_x[tha_state_pos_gei_x]']
; 2022-03-09, jmm, Swapped square brackets for parentheses in
;                  two-variable option declaration
; $LastChangedBy: jimm $
; $LastChangedDate: 2022-03-09 12:10:35 -0800 (Wed, 09 Mar 2022) $
; $LastChangedRevision: 30666 $
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
                                ;add option for var_label to contain 2
                                ;variables, 2nd one in parentheses after
                                ;the first one, jmm, 2021-05-25
        double_var_label = strpos(var_label[i], '[') ;Brackets, 2022-03-09, jmm
        If(double_var_label[0] Ne -1) Then Begin ;assure that there are two valid variables
           var_labelx = var_label[i]
           var1 = strmid(var_labelx, 0, double_var_label)
           var2 = strmid(var_labelx, double_var_label+1, strlen(var_labelx)-double_var_label-2)
           get_data, var1, ptr = pdata, alimits = limits & get_data, var2, ptr = pvar2, alimits = limits2
           vtit = strmid(var1,0,3)
           v2tit = strmid(var2,0,3)
           If(is_struct(pdata) && is_struct(pvar2)) Then twovars = 1b Else twovars = 0b
        Endif Else Begin
           vtit = strmid(var_label[i],0,3)
           twovars = 0b 
           get_data,var_label[i],ptr=pdata,alimits=limits
        Endelse                 ;end twovars setup block

        if size(/type,pdata) ne 8 then begin
          dprint,verbose=verbose,var_label[i], ' not valid!'
        endif else begin
          ;define ytitle, and format
          def = {ytitle:vtit, format:'(default)'}
          extract_tags,def,limits,tags = ['ytitle','format']
          If(twovars) Then Begin
             v = data_cut(var1, time)
             v2 = data_cut(var2, time)
             vdimen=dimen(v)
             v2dimen = dimen(v2)
             If(~array_equal(vdimen, v2dimen)) Then Begin
                dprint, 'Array mismatch in twovar setup for labels'
                twovars = 0b
             Endif
             def2 = {ytitle:v2tit, format:'(default)'}
             extract_tags,def2,limits2,tags = ['ytitle','format']
          Endif Else Begin
             v = data_cut(var_label[i],time)
             vdimen=dimen(v)
          Endelse
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
          endif else begin       ;code doesn't start with '(' assume that it is a callback function
            vlab = strarr(vdimen)
            for j=0,n_elements(v)-1 do begin ;following IDL plot convention, if format does not begin with a ( it is a unit callback
              if n_elements(vdimen) eq 2 then begin
                vlab[j] = call_function(def.format,0,j mod vdimen[0],v[j],j/vdimen[0])  ;arguments are axis,index,value,level
              endif else begin
                vlab[j] = call_function(def.format,0,j,v[j],0)  ;arguments are axis,index,value,level, level is always zero in the 1-d case
              endelse
            endfor
          endelse
          If(twovars) Then Begin;same formatting process as for var 1
             if strmid(def2.format,0,1) eq '(' then begin
                if def2.format eq '(default)' then begin
                   max_width = 20
                   for var_label_width=6,max_width do begin
                      v2lab_format = '(F' + strtrim(var_label_width,2) + '.1)'
                      v2lab = strcompress( string(v2,format=v2lab_format) ,/remove_all)
                      tmp = where(strmatch(v2lab,'*\**'),v2lab_star_count)
                      if v2lab_star_count eq 0 then break
                   endfor
                endif else begin
                   v2lab = strcompress( string(v2,format=def2.format) ,/remove_all)
                endelse
                v2lab = reform(v2lab,v2dimen)
             endif else begin
                v2lab = strarr(v2dimen)
                for j=0,n_elements(v2)-1 do begin
                   if n_elements(v2dimen) eq 2 then begin
                      v2lab[j] = call_function(def2.format,0,j mod v2dimen[0],v2[j],j/v2dimen[0])
                   endif else begin
                      v2lab[j] = call_function(def2.format,0,j,v2[j],0)
                   endelse
                endfor
             endelse
          Endif                 ;twovars format setup
;combine labels here if needed, after finite check
          If(twovars) Then Begin 
             w = where(~finite(v),nw)
             if nw gt 0 then vlab[w] = ''
             w2 = where(~finite(v2),nw2)
             if nw2 gt 0 then v2lab[w2] = ''
             vlab = vlab+'('+v2lab+')'
                                ;supress the first label, so that the
                                ;ytitles can be seen? If
                                ;time_setup.xtickv = 0, removed
                                ;2021-07-16, jmm
;             If(time_setup.xtickv[0] Eq 0) Then vlab[0, *] = ''
          Endif Else Begin
             w = where(~finite(v),nw)
             if nw gt 0 then vlab[w] = ''
          Endelse
;Handle ytitles here, replace references for def.ytitle to def_ytitle
          If(twovars) Then Begin
             def_ytitle = def.ytitle+'('+def2.ytitle+')'
          Endif Else def_ytitle = def.ytitle
          ;reduce multi dim var label to one dimen of label strings for plotting
          vlab = strjoin(transpose(vlab),'!C')

          ; egrimes added version 6 on 21 March 2019 - flips the time label to the top
          ; clrussell added version 7 on 11 Oct 2019 - flips time label to top, removes
          ; 'hhmm' and moves date text up one line
          if def_opts.version ge 6 then begin
            if def_opts.version eq 6 then begin
              time_setup.xtickname = time_setup.xtickname+'!C'+vlab
              if n_elements(vdimen) eq 2 then begin ;handle additional left-hand labels for multi-dim case, allow array ytitle
                 If(n_elements(def_ytitle) Eq vdimen[1]) Then vtitle = vtitle + '!C' + strjoin(def_ytitle+'!C') $
                 Else vtitle = vtitle + '!C' + strjoin(replicate(def_ytitle+'!C',vdimen[1]))
              endif else begin
                vtitle = vtitle + '!C' + def_ytitle
              endelse
            endif
            if def_opts.version eq 7 then begin
              if i NE 0 then time_setup.xtickname = time_setup.xtickname+'!C'+vlab $
              else time_setup.xtickname = time_setup.xtickname+vlab
              if n_elements(vdimen) eq 2 then begin ;handle additional left-hand labels for multi-dim case, allow array ytitle
                 If(n_elements(def_ytitle) Eq vdimen[1]) Then vtitle = vtitle + '!C' + strjoin(def_ytitle+'!C') $
                 Else vtitle = vtitle + '!C' + strjoin(replicate(def_ytitle+'!C',vdimen[1]))
              endif else begin
                if i EQ 0 then vtitle = strmid(vtitle,6,11) + '!C' + def_ytitle  $
                else vtitle=vtitle + '!C' + def_ytitle
              endelse
            endif
          endif else begin
            time_setup.xtickname = vlab+'!C'+time_setup.xtickname
            if n_elements(vdimen) eq 2 then begin ;handle additional left-hand labels for multi-dim case, allow array ytitle
               If(n_elements(def_ytitle) Eq vdimen[1]) Then vtitle = strjoin(def_ytitle+'!C') +vtitle $
               Else vtitle = strjoin(replicate(def_ytitle+'!C',vdimen[1])) +vtitle
            endif else begin
              vtitle = def_ytitle + '!C' +vtitle
            endelse
          endelse
          time_setup.xtitle = '!C'+time_setup.xtitle
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
