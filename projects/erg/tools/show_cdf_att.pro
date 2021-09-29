pro show_cdf_att_redraw, ev

  widget_control, ev.top, get_uval=udata

  tvar=udata['tvar']

  tid=ev.index
  tnew=tvar[tid]

  tab_base=udata['tbase']

  ;;; destroy all tabs ;;;

  widget_control, udata['base'], redraw=0

  widget_control, udata['gid'], /destroy
  widget_control, udata['vid'], /destroy

  ;;; obatin new dlim ;;;

  get_data, tnew, dlim=dlim

  ;;; create new gatt tab ;;;

  tab_gatt=widget_base(tab_base,title='Global Attributes', $
                       /col, /scroll, x_scroll_size=800, $
                       y_scroll_size=600)

  tng=tag_names(dlim.cdf.gatt)

  xs_sum=0
  scroll=0
  count=0

  foreach elems, tng, inx do begin

     if count mod 3 eq 0 then begin
        subbase_g1=widget_base(tab_gatt,/row)
        xs_sum=0
     endif


     if ~strcmp(elems, 'TEXT') and ~strcmp(elems,'RULES_OF_USE') then begin
        xs=strlen(dlim.cdf.gatt.(inx))
        ys=1
        sp=scroll
        scroll=0

        if total(xs)+strlen(elems) gt 120 then begin
           xs=40
           ys=10
           scroll=1
        endif

        ssm=sp+scroll

        xs_sum=xs_sum+total(xs)+strlen(elems)

        if xs_sum gt 120 or ssm mod 2 eq 1 then begin
           subbase_g1=widget_base(tab_gatt,/row)
           xs_sum=0
           count=0
        endif


        label1=widget_label(subbase_g1,value=elems)
        for i=0, n_elements(xs) -1 do $
           text_gatt=widget_text(subbase_g1,value=dlim.cdf.gatt.(inx)[i], xsize=xs[i], ysize=ys, /wrap, scroll=scroll)

        count +=1

        if total(xs)+strlen(elems) gt 120 then count=0

     endif

  endforeach

  ys=10
  xs=40
  scroll=1
  subbase_g1=widget_base(tab_gatt,/row)

  if where(tng eq 'TEXT') ne -1 then begin
     label1=widget_label(subbase_g1,value='TEXT')
     text_ror=widget_text(subbase_g1,value=dlim.cdf.gatt.TEXT, xsize=xs, ysize=ys, /wrap, scroll=scroll)
  endif

  if where(tng eq 'RULES_OF_USE') ne -1 then begin
     label1=widget_label(subbase_g1,value='Rules of Use')
     text_ror=widget_text(subbase_g1,value=dlim.cdf.gatt.RULES_OF_USE, xsize=xs, ysize=ys, /wrap, scroll=scroll)
  endif


  
 ;;;;;;;;;;;;;;;;VATT;;;;;;;;;;;;;;;;;;;;;                                                                                                                                                                                       
  tab_vatt=widget_base(tab_base,title='Variable Attributes', /col)
  tnv=tag_names(dlim.cdf.vatt)

  foreach elems, tnv, inx do begin
     if inx mod 2 eq 0 then subbase_v1=widget_base(tab_vatt, /row)

     xs=strlen(dlim.cdf.vatt.(inx))

     label=widget_label(subbase_v1,value=tnv[inx])
     for i=0, n_elements(xs)-1 do $
        text_vatt=widget_text(subbase_v1, value=string(dlim.cdf.vatt.(inx)[i]),xsize=xs[i])

  endforeach

  ;;;;;; update infos and redraw widgets;;;;;;;

  udata['gid']=tab_gatt
  udata['vid']=tab_vatt
 
  widget_control, udata['base'], /redraw
  
;  stop

END

pro show_cdf_att_event, ev


END

pro show_cdf_att, tvar_in

  @tplot_com.pro
  
  if n_elements(tvar_in) eq 0 then begin
     if (where(tag_names(tplot_vars.settings) eq 'VARNAMES'))[0] ne -1 then begin
        tvar_in = tplot_vars.settings.varnames
        dprint, tvar_in
     endif else begin
        dprint, 'No tplot variables.'
        goto, gt0
     endelse
  endif

  tvar=tnames(tvar_in)
  if where(tvar eq '') ne -1 then begin
     dprint, 'Invalid tplot names.'
     goto, gt0
  endif

  tvar_new=''

  foreach elem, tvar do begin
     
     get_data, elem, dlim=dlim
     
     if ISA(dlim, /number) then begin
        dprint, elem+' has an invalid dlim.'
     endif else begin
        if strcmp(tvar_new[0],'') then tvar_new=elem $
        else tvar_new=[tvar_new,elem]
     endelse
  
  endforeach

  tvar=tvar_new

  if strcmp(tvar[0],'')  then begin
     goto, gt0
  endif

  get_data, tvar[0] ,dlim=dlim

  base=widget_base(title='CDF Attributes', /col)

  if n_elements(tvar) gt 1 then begin
     subbase1=widget_base(base, /row, /frame)
     label1=widget_label(subbase1,value='Attributes of')
     drop1=widget_droplist(subbase1, value=tvar, EVENT_PRO='show_cdf_att_redraw')
  endif

;  stop

  tab_base=widget_tab(base)


  ;;;;;;;;;;;;;;;GATT Summary;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;TBD;;;;;;;;;;;;;;;;;;;;

;  tab_gatts=widget_base(tab_base,title='Global Attribute', $
;                       /col, /scroll, x_scroll_size=800, $
;                       y_scroll_size=600)


  ;;;;;;;;;;;;;;;;;GATT;;;;;;;;;;;;;;;;;;;;
  tab_gatt=widget_base(tab_base,title='Global Attributes', $
                       /col, /scroll, x_scroll_size=800, $
                       y_scroll_size=600)


  tng=tag_names(dlim.cdf.gatt)

  xs_sum=0
  scroll=0
  count=0
  
  foreach elems, tng, inx do begin
     
     if count mod 3 eq 0 then begin
        subbase_g1=widget_base(tab_gatt,/row)
        xs_sum=0
     endif

          
     if ~strcmp(elems, 'TEXT') and ~strcmp(elems,'RULES_OF_USE') then begin
        xs=strlen(dlim.cdf.gatt.(inx))
        ys=1
        sp=scroll
        scroll=0
        
        if total(xs)+strlen(elems) gt 120 then begin
           xs=40
           ys=10
           scroll=1
        endif

        ssm=sp+scroll
        
        xs_sum=xs_sum+total(xs)+strlen(elems)

        if xs_sum gt 120 or ssm mod 2 eq 1 then begin
           subbase_g1=widget_base(tab_gatt,/row)
           xs_sum=0
           count=0
        endif


        label1=widget_label(subbase_g1,value=elems)
        for i=0, n_elements(xs) -1 do $
           text_gatt=widget_text(subbase_g1,value=dlim.cdf.gatt.(inx)[i], xsize=xs[i], ysize=ys, /wrap, scroll=scroll)

        count +=1
        
        if total(xs)+strlen(elems) gt 120 then count=0
        
     endif

  endforeach

  ys=10
  xs=40
  scroll=1
  subbase_g1=widget_base(tab_gatt,/row)  

  if where(tng eq 'TEXT') ne -1 then begin
     label1=widget_label(subbase_g1,value='TEXT')
     text_ror=widget_text(subbase_g1,value=dlim.cdf.gatt.TEXT, xsize=xs, ysize=ys, /wrap, scroll=scroll)
  endif

  if where(tng eq 'RULES_OF_USE') ne -1 then begin
     label1=widget_label(subbase_g1,value='Rules of Use')
     text_ror=widget_text(subbase_g1,value=dlim.cdf.gatt.RULES_OF_USE, xsize=xs, ysize=ys, /wrap, scroll=scroll)
  endif

  ;;;;;;;;;;;;;;;;VATT;;;;;;;;;;;;;;;;;;;;;
  tab_vatt=widget_base(tab_base,title='Variable Attributes', /col)
  tnv=tag_names(dlim.cdf.vatt)

  foreach elems, tnv, inx do begin
     if inx mod 2 eq 0 then subbase_v1=widget_base(tab_vatt, /row) 

     xs=strlen(dlim.cdf.vatt.(inx))

     label=widget_label(subbase_v1,value=tnv[inx])
     for i=0, n_elements(xs)-1 do $
        text_vatt=widget_text(subbase_v1, value=string(dlim.cdf.vatt.(inx)[i]),xsize=xs[i])

  endforeach

  udata=hash(['base','tbase','gid','vid','tvar'])
  
  udata['base']=base
  udata['tbase']=tab_base
  udata['gid']=tab_gatt
  udata['vid']=tab_vatt
  udata['tvar']=tvar

  widget_control, base, set_uval=udata

  widget_control, base, /realize

  xmanager, 'show_cdf_att', base, /no_block

gt0:


END
