;;  @(#)xfastorbparm.pro	1.2 12/15/94   Fast orbit display program

pro xfastorbparm_ev,event

@fastorbdisp.cmn
common xfastorbparm,parmqvalwid,parmresvalwid,parmUToffvalwid

widget_control,event.id,get_uvalue=value

case value of
  'QButton' :  
  'Res'     :  
  'UToff'   :  
  'Default' :  begin
                 widget_control,parmqvalwid,set_value=3
                 widget_control,parmresvalwid,set_value=1
                 widget_control,parmUToffvalwid,set_value=2
               end
  'Cancel'  :  widget_control,event.top,/dest
  'OK'      :  begin
                 widget_control,parmqvalwid,get_value=temp
                 q=temp(0)
                 widget_control,parmresvalwid,get_value=temp
                 res=temp(0)
                 widget_control,parmUToffvalwid,get_value=temp
                 UToff=temp(0)
                 widget_control,event.top,/dest
               end
  else      :  begin
                 elsewid=widget_base(title='Fast Orbit Display Parameters')
                 dum=widget_label(elsewid,value='Event not presently handled.')
                 widget_control,elsewid,/real
                 wait,5
                 widget_control,elsewid,/dest
               end
endcase
return
end

pro xfastorbparm,group_leader=group_leader

@fastorbdisp.cmn
common xfastorbparm,parmqvalwid,parmresvalwid,parmUToffvalwid

if(xregistered('xfastorb_parm')) then return

parmwid=widget_base(group_leader=group_leader,/column,  $
                    title='Fast Orbit Display Parameters')
parmqwid=widget_base(parmwid,/column,frame=1)
;parmqtitlewid=widget_label(parmqwid,value='Auroral Q Index')
parmqvalwid=cw_bgroup(parmqwid,' '+strtrim(string(indgen(7)),2)+' ',/row, $
           /exclusive,label_top='Auroral Q Index    Present Value is '+ $
           strtrim(string(q),2),/no_release,/return_index,uvalue='QButton')
widget_control,parmqvalwid,set_value=q
parmwidb=widget_base(parmwid,/row)
parmreswid=widget_base(parmwidb,/column,frame=1)
parmrestitlewid=widget_label(parmreswid,value='Time Resolution')
parmresvalwid=cw_field(parmreswid,title='Present Value is '+ $
                     strtrim(string(res),2)+' s',/column,/integer,value=res, $
                     uvalue='Res')
parmUToffwid=widget_base(parmwidb,/column,frame=1)
parmUTofftitlewid=widget_label(parmUToffwid,value='Local Time Offset From UT')
if(UToff eq 1) then $
  parmUToffvalwid=cw_field(parmUToffwid,title='Present Value is '+ $
                         strtrim(string(UToff),2)+' hour',/column,/integer, $
                         value=UToff,uvalue='UToff') $
else $
  parmUToffvalwid=cw_field(parmUToffwid,title='Present Value is '+ $
                         strtrim(string(UToff),2)+' hours',/column,/integer, $
                         value=UToff,uvalue='UToff')
xmenu,['Default','Cancel','  OK  '],parmwid,/row,frame=1,/no_release, $
      uvalue=['Default','Cancel','OK']
widget_control,parmwid,/real
xmanager,'xfastorbparm',parmwid,group_leader=group_leader, $
         event_handler='xfastorbparm_ev'
return
end

