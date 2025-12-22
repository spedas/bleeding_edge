;;  @(#)xfastorbtpaxis.pro	1.3 12/15/94   Fast orbit display program

pro xfastorbtpaxis_ev,event

@fastorbtpaxis.cmn

widget_control,event.id,get_uvalue=value

case value of
  'Sel' : begin
    fastorbtpaxis,/save
    curedit=event.value
    fastorbtpaxis,/load
  end
  'Act': case event.value of
    'Set': fastorbtpaxis,/save      ; Save displayed values.
    'Reset': fastorbtpaxis,/load    ; Copy displayed values from saved values.
    'Help': begin                   ; Display Help list.
      helpbase=widget_base(title='FAST Orbit Display',/column,group=event.top)
      helplab=widget_label(helpbase,val='Help Listing for Time Plot Axis Editing.')
      helptext=widget_text(helpbase,val=[ $
        'Buttons:  Accept edited values for currently chosen plot and edit a new plot.', $
        '-----', $
        'Editing:  Indicates which plot axis is being edited.', $
        'Title:  Allows editing of axis title for current plot.', $
        'Limits:  Allows editing of axis upper and lower limits for current plot', $
        '         If both limits are set to zero, plot will autoscale.', $
        'No. of Tick Intervals:  Allows editing of number of tick intervals to ', $
        '         put on axis of current plot.  If zero, ticks are automatic.', $
        'Major:  Number of major tick intervals (i.e. with labels).', $
        'Minor:  Number of minor tick intervals (i.e. between major tick marks).', $
        '-----', $
        'Set:  Accept edited values for currently chosen plot.', $
        'Reset:  Undo edited values for currently chosen plot.', $
        'Help:  This listing.', $
        'Cancel:  Abandon currently edited values and end edits.', $
        'Done:  Accept edited values for currently chosen plot and end edits.'], $
        xsize=65,ysize=16)
      helpdone=widget_button(helpbase,val='Done with Help')
      widget_control,helpbase,/real
      helpres=widget_event(helpdone)
      widget_control,helpbase,/dest
    end
    'Cancel': widget_control,event.top,/dest  ; Close widget w/o further saves.
    'Done': begin                   ; Save displayed values and close widget.
      fastorbtpaxis,/save
      widget_control,event.top,/dest
    end
  endcase
endcase
return
end

pro fastorbtpaxis,save=save,load=load

@fastorbtp.cmn
@fastorbtpaxis.cmn

if(keyword_set(save)) then begin
  widget_control,wtitfield,get_value=readval
  plotparm(1+curedit).axis.title=readval(0)
  widget_control,wlimtop,get_value=readval
  plotparm(1+curedit).axis.range(1)=readval(0)
  widget_control,wlimbot,get_value=readval
  plotparm(1+curedit).axis.range(0)=readval(0)
  widget_control,wtikmaj,get_value=readval
  plotparm(1+curedit).axis.ticks=readval(0)
  widget_control,wtikmin,get_value=readval
  plotparm(1+curedit).axis.minor=readval(0)
endif
if(keyword_set(load)) then begin
  widget_control,wlab,set_value=plotparm(1+curedit).name
  widget_control,wtitfield,set_value=plotparm(1+curedit).axis.title
  widget_control,wlimtop,set_value=plotparm(1+curedit).axis.range(1)
  widget_control,wlimbot,set_value=plotparm(1+curedit).axis.range(0)
  widget_control,wtikmaj,set_value=plotparm(1+curedit).axis.ticks
  widget_control,wtikmin,set_value=plotparm(1+curedit).axis.minor
endif
return
end

pro xfastorbtpaxis,group=group

@fastorbtp.cmn
@fastorbtpaxis.cmn

if(xregistered('xfastorbtpaxis')) then return
curedit=0l
base=widget_base(title='FAST Orbit Display',/row,group=group)
wselbase=widget_base(base,/row,/frame)
wselbut=cw_bgroup(wselbase,label_top='Axis to Edit', $
                  plotparm(1:*).name,column=1,/exc, $
                  set_value=curedit,uvalue='Sel')
wdispbase=widget_base(base,/column)
weditbase=widget_base(wdispbase,/column,/frame)
wlab=cw_field(weditbase,title='Editing: ',value=plotparm(1+curedit).name, $
              /string,/row,/frame,/noedit)
wtitfield=cw_field(weditbase,title='Title',value=plotparm(1+curedit).axis.title, $
                   /string,/column,/frame)
wlimbase=widget_base(weditbase,/column,/frame)
wlimlab=widget_label(wlimbase,value='Limits')
wlimtop=cw_field(wlimbase,title='     Top:',value=plotparm(1+curedit).axis.range(1), $
                 /float,/row)
wlimbot=cw_field(wlimbase,title='Bottom:',value=plotparm(1+curedit).axis.range(0), $
                 /float,/row)
wtikbase=widget_base(weditbase,/column,/frame)
wtiklab=widget_label(wtikbase,value='No. of Tick Intervals')
wtikmaj=cw_field(wtikbase,title='Major:',value=plotparm(1+curedit).axis.ticks, $
                 /int,/row)
wtikmin=cw_field(wtikbase,title='Minor:',value=plotparm(1+curedit).axis.minor, $
                 /int,/row)
wactbase=widget_base(wdispbase,/row,/frame)
opdesc={cw_pdmenu_s,flags:0,name:''}  ;  Just to define cw_pdmenu_s
actdesc=[{cw_pdmenu_s,0,'Set'}, $
         {cw_pdmenu_s,0,'Reset'}, $
         {cw_pdmenu_s,0,'Help'}, $
         {cw_pdmenu_s,0,'Cancel'}, $
         {cw_pdmenu_s,0,'Done'}]
wact=cw_pdmenu(wactbase,actdesc,ids=actids,/return_full_name,uvalue='Act')
for i=0,n_elements(actids)-1 do begin
  widget_control,actids(i),get_value=buttonname
  if(strmid(buttonname,strlen(buttonname)-1,1) eq '-') then begin
    widget_control,actids(i),set_value=strmid(buttonname,0,strlen(buttonname)-1)
    widget_control,actids(i),sensitive=0
  endif
endfor
widget_control,base,/real
xmanager,'xfastorbtpaxis',base,event='xfastorbtpaxis_ev'
return
end
