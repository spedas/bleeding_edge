;;  @(#)xidlcmd.pro	1.2 12/15/94   Fast orbit display program

; Generalized widget to accept IDL commands into widget applications.  To
; access variables, put commons (preferably using include files) below.
; Procedure is invoked by button in application widget by:
;       xidlcmd, group=group
; J. Clemmons, 12/94

; First we have the event handler:
pro xidlcmd_ev,event

common xidlcmd,idlwid,idlfield,idlctrl,idlprev,idlstore,choice
; Insert application-specific commons here.
@colors.cmn
@fastorb.cmn
@fastorbdisp.cmn
@fastorbtimer.cmn
@fastorbtp.cmn
@fastorbtpaxis.cmn

case event.id of
  idlfield : begin
               widget_control,idlfield,get_value=idlcmd
               firstchar=strmid(strtrim(idlcmd(0),2),0,1)
               if((firstchar ge '0') and (firstchar le '9')) then begin
                 reads,idlcmd(0),choice
                 if(choice lt n_elements(idlstore)) then begin
                   widget_control,idlfield,set_value=strmid(idlstore(choice), $
                                  3+strpos(idlstore(choice),':  '),1000)
                 endif else begin
                   choice=0l
                   widget_control,idlfield,set_value=''
                 endelse
               endif else begin
                  if(idlcmd(0) ne strmid(idlstore(choice), $
                    3+strpos(idlstore(choice),':  '),1000)) then choice=0l
                  if(idlcmd(0) ne '') then $
                   if(execute(idlcmd(0)) ne 0) then begin
                     if(choice eq 0l) then begin
                       idlstore=[idlstore,string(n_elements(idlstore))+':  '+idlcmd(0)]
                       widget_control,idlprev,set_value=idlstore(reverse(lindgen(n_elements(idlstore))))
                     endif
                     widget_control,idlfield,set_value=''
                     choice=0l
                   endif
               endelse
             end
  idlprev  : begin
               if(event.index lt n_elements(idlstore)-1) then begin
                 choice=n_elements(idlstore)-1-event.index
                 widget_control,idlfield,set_value=strmid(idlstore(choice), $
                                3+strpos(idlstore(choice),':  '),1000)
               endif
             end
  idlctrl  : case event.value of
               'OK'    : begin
                           widget_control,idlfield,get_value=idlcmd
                           if(idlcmd(0) ne strmid(idlstore(choice), $
                                3+strpos(idlstore(choice),':  '),1000)) then choice=0l
                           if(idlcmd(0) ne '') then $
                             if(execute(idlcmd(0)) ne 0) then begin
                               if(choice eq 0l) then begin
                                 idlstore=[idlstore,string(n_elements(idlstore))+':  '+idlcmd(0)]
                                 widget_control,idlprev,set_value=idlstore(reverse(lindgen(n_elements(idlstore))))
                               endif
                               widget_control,idlfield,set_value=''
                               choice=0l
                             endif
                         end
               'Clear' : begin
                           widget_control,idlfield,set_value=''
                           choice=0l
                         end
               'Delete': begin
                           widget_control,idlfield,get_value=idlcmd
                           if(idlcmd(0) ne strmid(idlstore(choice), $
                             3+strpos(idlstore(choice),':  '),1000)) then choice=0l
                           if(choice gt 0l) then begin
                              idlstore=idlstore(where(  $
                                      lindgen(n_elements(idlstore)) ne choice))
                             for i=choice,n_elements(idlstore)-1 do $
                               idlstore(i)=string(i)+':  '+strmid(idlstore(i), $
                                             3+strpos(idlstore(i),':  '),1000)

                             widget_control,idlprev,set_value=idlstore(reverse(lindgen(n_elements(idlstore))))
                             widget_control,idlfield,set_value=''
                             choice=0l
                           endif
                         end
               'Reset' : begin
                           idlstore=[idlstore(0)]
                           widget_control,idlprev,set_value=idlstore(reverse(lindgen(n_elements(idlstore)))) 
                           choice=0l
                         endif
               'Done'  : widget_control,idlwid,map=0
               else    :
             endcase
  else     :
endcase
return
end

pro xidlcmd,group=group

common xidlcmd,idlwid,idlfield,idlctrl,idlprev,idlstore,choice

if(not xregistered('xidlcmd')) then begin
  idlwid=widget_base(title='IDL Command',/column)
  idlfield=cw_field(idlwid,title='IDL>',value=' ',/return_ev,xsize=60)
  if(n_elements(idlstore) le 0) then idlstore=''
  idlprev=widget_list(idlwid,value=idlstore,ysize=10)
  idlctrl=cw_pdmenu(idlwid,/return_name, $
                    [{cw_pdmenu_s,flags:0,name:'OK'},  $
                     {cw_pdmenu_s,flags:0,name:'Clear'},  $
                     {cw_pdmenu_s,flags:0,name:'Delete'},  $
                     {cw_pdmenu_s,flags:0,name:'Reset'},  $
                     {cw_pdmenu_s,flags:2,name:'Done'}])

  widget_control,idlwid,/real
  choice=0l
  xmanager,'xidlcmd',idlwid,event_handler='xidlcmd_ev',group=group
endif else widget_control,idlwid,/map

return
end
