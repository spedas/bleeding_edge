;  Warning DON'T USE THE REALTIME KEYWORD - IT RUN'S VERY SLOW!

pro mav_gse_structure_append,ptrs,str,tname=tname,tags=tagsformat,realtime=realtime,reset=reset,clear=clear,insert_gap=gap

  if n_params() eq 2 then begin              ; append data
     if size(/type,str) ne 8 then begin
         dprint,dlevel=3,'Not a structure!'
         return
     endif
     if arg_present(ptrs)  then begin    ;&& ~keyword_set(realtime)
         if not keyword_set(ptrs) then ptrs = { name:keyword_set(tname) ? tname :'' ,  x:ptr_new(0),  xi:ptr_new(0) }
         if keyword_set(gap) then append_array,*ptrs.x,fill_nan(str[0]), index = *ptrs.xi
         append_array,*ptrs.x, str, index= *ptrs.xi,/fillnan
     endif
     if size(/type,tname) eq 7 && keyword_set(realtime) then begin            ; Note setting the realtime keyword will make it substantially slower!
        if not keyword_set(tags) then tags = tag_names( str )
        time = str.time
        time_dim = size(time,/dimensions)
        nstr = n_elements(str)
        for i = 0,n_elements(tags)-1 do begin
            if tags[i] eq 'TIME' then continue
            dlim = 0
            vvalue=0
            yvalue = str.(i)
            if  (size(/type,yvalue) ne 10) then begin
                dim= size(yvalue,/dimensions)
                if (nstr eq 1 && (n_elements(dim) eq 2 || (dim[0] gt 1))) then begin
                    yvalue=transpose(yvalue)
                    vvalue=findgen(dim[0])
                endif
                if  (nstr gt 1 && (n_elements(dim) eq 2 )) then begin
                    yvalue=transpose(yvalue)
                    vvalue=findgen(dim[0])
                       dprint,/phelp,tname+'_'+tags[i],time,yvalue,time_dim,dim,dlevel=4
                endif
                if strpos(tags[i],'FLAG') ge 0 then dlim =struct(dlim,tplot_routine='bitplot',colors='bmgr',panel_size=.4)
                if keyword_set(gap) then $
                   store_data,tname+'_'+tags[i], fill_nan(time),fill_nan( yvalue),fill_nan(vvalue), /append  ,dlim=dlim                
                store_data,tname+'_'+tags[i], time, yvalue,vvalue, /append  ,dlim=dlim
            endif
        endfor
     endif
  endif else begin                   ; one parameter - perform finalization of data
     if keyword_set(reset) then begin     ; cleanup pointers if reset is set to anything
         ptr_free,ptr_extract(ptrs)          
         ptrs = 0
     endif
     if not keyword_set(ptrs) then ptrs = { name:keyword_set(tname) ? tname :'' ,  x:ptr_new(0),  xi:ptr_new(0) }
     if size(/type,ptrs) ne 8 || ptr_valid(ptrs.x) eq 0 then return
     if keyword_set(clear) then begin
         *ptrs.x =0
         *ptrs.xi=0
         return
     endif
     if size(/type,*ptrs.x) ne 8 then begin
        if size(/type,tname) eq 7 then dprint,'No data for ',tname,dlevel=2
        return
     endif
     append_array, *ptrs.x, index= *ptrs.xi,/done    ;  truncate arrays as needed
     if size(/type,tname) eq 7 && ~keyword_set(realtime) then begin
 ;       str_all = (*ptrs.x)   ' don't copy for efficiency
        tags_all = tag_names( *ptrs.x)
        if keyword_set(tagsformat) then tags = tags_all[strfilter(/index,tags_all,strsplit(/extract,tagsformat) ) > 0] ; else  tags= tags_all
        time = (*ptrs.x).time
        for i = 0,n_elements(tags)-1 do begin
            if tags[i] eq 'TIME' then continue
            dlim = 0
            vvalue=0
            str_element,(*ptrs.x),tags[i],yvalue
            dprint,/phelp,tags[i],yvalue,dlevel=4
            if  (size(/type,yvalue) ne 10) then begin
                dim= size(yvalue,/dimensions)
                if (n_elements(dim) eq 2 ) then begin
                    yvalue=transpose(yvalue)
                    vvalue=findgen(dim[0])
                endif
                if strpos(tags[i],'FLAG') ge 0 then dlim =struct(dlim,tplot_routine='bitplot',colors='bmgr',panel_size=.4)
                store_data,tname+'_'+tags[i], time, yvalue,vvalue ,dlim=dlim
            endif
        endfor
     endif
  endelse
end

