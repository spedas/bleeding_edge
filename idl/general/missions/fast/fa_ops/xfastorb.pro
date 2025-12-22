;;  @(#)xfastorb.pro	1.2 12/15/94   Fast orbit display program

; Main IDL widget routines for displaying FAST orbital parameters.
; Registers with XMANAGER to handle events.  File contains programs:
;  xfastorb_ev    Handles events for widget declared by xfastorb.
;  xfastorbkill   Callback routine which is invoked when xfastorb is killed.
;                 Cleans up some variables.
;  xfastorbbadev  Called by xfastorb_ev for unrecognized events.
;  xfastorb       Sets up widget for animation display and starts animation.
;                 Only one instance is allowed.
; J. Clemmons, June 1994

; First we have the event handler.
pro xfastorb_ev, event

@fastorb.cmn
@fastorbdisp.cmn
@fastorbtimer.cmn

widget_control,event.id,get_uvalue=value

case value of
  'TimerInt': begin
    widget_control,event.id,timer=rtint
    fastorbupdate
  end
  'Op' : case event.value of
    'File.New': begin
      fastorbfileread,/new
      fastorbgetdata
    end
    'File.Quit': widget_control,event.top,/dest
    'File.Close': widget_control,event.top,/icon
    'File.Cancel':

    'Config.Plot Proj.Equator' : begin
      map_type='cyl'
      wset,winanimtempl
      drawtempl
      draworbit
    end
    'Config.Plot Proj.Polar' : begin
      map_type='polar'
      wset,winanimtempl
      drawtempl
      draworbit
    end
    'Config.Plot Proj.Ground Station' : begin
      map_type='tangent_gs'
      wset,winanimtempl
      drawtempl
      draworbit
    end
    'Config.Right Plot.Opp Hem': begin
      map_mode=0
      wset,winanimtempl
      drawtempl
      draworbit
    end
    'Config.Right Plot.Zoom': begin
      map_mode=1
      wset,winanimtempl
      drawtempl
      draworbit
    end
    'Config.Right Plot.All Sky': begin
      map_mode=2
      wset,winanimtempl
      drawtempl
      draworbit
    end
    'Config.Colors.Load Palette' : xloadct,group=ctrlwid
    'Config.Colors.Edit Palette' : xpalette,group=ctrlwid
    'Config.Print' :  begin
      prtcfgwid=widget_base(title='FAST Orbit Display',/column)
      prtcfgfield=cw_field(prtcfgwid,title='New Print Queue >', $
                           value=printque,/return_ev,xsize=16)
      widget_control,prtcfgwid,/real
      prtcfgresult=widget_event(prtcfgfield)
      widget_control,prtcfgfield,get_value=printque
      printque=printque(0)
      widget_control,prtcfgwid,/dest
    end
    'Config.Cancel' :

    'View.File': xfastorbvfil,group=event.top
    'View.Elements': xfastorbvele,group=event.top
    'View.Time Plots': xfastorbtp,group=event.top
    'View.Cancel' :

    'Print': begin
      widget_control,wa,/hour
      old_dev=!d.name
      set_plot,'ps'
      device,/times,/port,/inch,xs=7,ys=5.6
      !p.font=0
      drawtempl
      draworbit
      drawpos
      device,/close
      case !version.os of
        'sunos': spawn,'lpr -P'+printque+' idl.ps'
        else: spawn,'print/del/que='+printque+' idl.ps'
      endcase
      set_plot,old_dev
      !p.font=-1
    end

    'IDL Cmd' : xidlcmd,group=event.top

    'Info.IDL Help' : call_procedure,'man_proc',' '
    'Info.FASTOrb Help' : xfastorbhelp,group=event.top
    'Info.Specifications' : xfastorbspec,group=event.top
    'Info.News' : xfastorbnews,group=event.top
    'Info.Cancel' :

    'Bugs.Cancel' :  ; Wanted to have bug reporting here.

    'Quit' : widget_control,event.top,/dest
      

    else : xfastorbbadev,group=event.top

  endcase
  else : xfastorbbadev,group=event.top
endcase
return
end

pro xfastorbkill,kill_id
; Called when main animation widget is killed.
@fastorbdisp.cmn
wdelete,winanimdraw
wdelete,winanimtempl
return
end

pro xfastorbbadev,group=group
  if(keyword_set(group)) then elsewid=widget_base(group,title='FAST Orbit Display') $
  else elsewid=widget_base(title='FAST Orbit Display')
  dum=widget_label(elsewid,value='Event not presently handled.')
  widget_control,elsewid,/real
  wait,5
  widget_control,elsewid,/dest
return
end



pro xfastorb,group_leader=group_leader

;  IDL procedure to display FAST orbit.  Uses widgets and XMANAGER routine.
;  Updates display in real time using timer widget function.

@fastorb.cmn
@fastorbdisp.cmn
@colors.cmn
@fastorbtimer.cmn

if(xregistered('xfastorb',/noshow)) then return

if(n_elements(satdesc) le 0) then begin
  xfastorbcfg
  putdata=0
  playmode=0l
  tpmode=0l
  map_type='cyl'
  map_mode=0
  gs_proj=0
  map_zoom_ang=6.2  ; 6.2 degrees is half angle subtended by 100-km aurora at 5 deg elev.
  UToff=-8
  q=3
endif
device,pseudo=8
wa=widget_base(title='FAST Orbit Display',/column,uvalue='TimerInt')
wb=widget_draw(wa,xsize=640,ysize=512,colors=20)
window,/free,/pixmap,xsize=640,ysize=512,colors=20
winanimtempl=!d.window
window,/free,/pixmap,xsize=640,ysize=512
winanimdraw=!d.window
opwid=widget_base(wa,/row)
opdesc={cw_pdmenu_s,flags:0,name:''}  ;  Just to define cw_pdmenu_s
opdesc1=[{cw_pdmenu_s,1,'File'}, $
          {cw_pdmenu_s,0,'New'}, $
          {cw_pdmenu_s,0,'Close'}, $
          {cw_pdmenu_s,0,'Quit'}, $
          {cw_pdmenu_s,2,'Cancel'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,1,'Config'}, $
          {cw_pdmenu_s,1,'Plot Proj'}, $
           {cw_pdmenu_s,0,'Equator'}, $
           {cw_pdmenu_s,0,'Polar'}, $
           {cw_pdmenu_s,2,'Ground Station'}, $
          {cw_pdmenu_s,1,'Right Plot'}, $
           {cw_pdmenu_s,0,'Opp Hem'}, $
           {cw_pdmenu_s,0,'Zoom'}, $
           {cw_pdmenu_s,2,'All Sky-'}, $
;          {cw_pdmenu_s,1,'Colors-'}, $
;           {cw_pdmenu_s,0,'Load Palette'}, $
;           {cw_pdmenu_s,2,'Edit Palette'}, $
          {cw_pdmenu_s,0,'Print'}, $
          {cw_pdmenu_s,2,'Cancel'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,1,'View'}, $
          {cw_pdmenu_s,0,'File'}, $
          {cw_pdmenu_s,0,'Elements'}, $
          {cw_pdmenu_s,0,'Time Plots'}, $
          {cw_pdmenu_s,2,'Cancel'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,1,'Controls'}, $
          {cw_pdmenu_s,0,'???-'}, $
          {cw_pdmenu_s,2,'Cancel'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,0,'Redraw'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,0,'Print'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,0,'IDL Cmd'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,1,'Info'}, $
          {cw_pdmenu_s,0,'IDL Help'}, $
          {cw_pdmenu_s,0,'FASTOrb Help'}, $
          {cw_pdmenu_s,0,'Specifications'}, $
          {cw_pdmenu_s,0,'News'}, $
          {cw_pdmenu_s,2,'Cancel'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,2,'Quit'}]

opmenuwid1=cw_pdmenu(opwid,opdesc1,ids=opids,/return_full_name,uvalue='Op')
for i=0,n_elements(opids)-1 do begin 
  widget_control,opids(i),get_value=buttonname
  if(strmid(buttonname,strlen(buttonname)-1,1) eq '-') then begin
    widget_control,opids(i),set_value=strmid(buttonname,0,strlen(buttonname)-1)
    widget_control,opids(i),sensitive=0
  endif
endfor
widget_control,wa,/real
widget_control,wa,kill_notify='xfastorbkill'
widget_control,wa,/hour
widget_control,wb,get_value=fastorbwin
wset,winanimtempl
if(n_elements(black) le 0) then begin   ; Use 20-color palette.
  black=0
  blue=1
  green=2
  yellow=3
  red=4
  tvlct,[0,0,0,255,255],[0,0,255,255,0],[0,255,0,0,0],0
  gray=indgen(10)+10
  white=19
  tvlct,indgen(10)/9.0*255,indgen(10)/9.0*255,indgen(10)/9.0*255,10
  pltcol=[white,green,yellow,red]
endif
drawtempl
wset,fastorbwin
device,copy=[0,0,640,512,0,0,winanimtempl]
; Timer stuff for animation
if(n_elements(rtint) le 0) then rtint=1.0
widget_control,wa,timer=rtint
if(n_elements(playspeed) le 0) then playspeed=10.0
fastorbupdate,/first
xmanager,'xfastorb',wa,group_leader=group_leader,event_handler='xfastorb_ev'
return
end
