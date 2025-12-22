;;  @(#)xfastorbtp.pro	1.2 12/15/94   Fast orbit display program

pro xfastorbtp_ev,event

@fastorb.cmn
@fastorbtp.cmn

widget_control,event.id,get_uvalue=value

putdata=1    ; Tells data-fetching routines to place data into rdvectp.
;if(value eq 'Op') then print,event.value
case value of
  'Op' : case event.value of
    'File.New': begin
      widget_control,event.top,/hour
      curfile=pickfile(path=curpath,get_path=curpath, $
                       title='FASTOrb file to use:',group=event.top,/read,/must)
      fastorbfileread
    end
    'File.Quit': widget_control,event.top,/dest
    'File.Close': widget_control,event.top,/icon
    'File.Cancel':

    'Prev': begin
      if(tpmode eq 0l) then satdescindx=(satdescindx-1)>0 $
      else tpdoy=(tpdoy-1)>satdesc(0).epochdoy
      widget_control,event.top,/hour
      fastorbgetdata
      fastorbtpwindrw
    end

    'Orbit.Select': begin
      wselbase=widget_base(/column,group=event.top,title='FAST Orbit Display')
      wsellab=widget_label(wselbase,value='Choose an Orbit')
      wsellist=widget_list(wselbase,value=strtrim(string(satdesc.orbit),2), $
                           ysize=10)
      wselcan=widget_button(wselbase,value='Cancel')
      widget_control,wselbase,/real
      wselres=widget_event(wselbase)
      widget_control,wselbase,/dest
      if(wselres.id ne wselcan) then begin
        satdescindx=wselres.index
        widget_control,event.top,/hour
        fastorbgetdata
        fastorbtpwindrw
      endif
    end
    'Orbit.Prev': begin
      satdescindx=(satdescindx-1)>0
      widget_control,event.top,/hour
      fastorbgetdata
      fastorbtpwindrw
    end
    'Orbit.Next': begin
      satdescindx=(satdescindx+1)<(n_elements(satdesc)-1)
      widget_control,event.top,/hour
      fastorbgetdata
      fastorbtpwindrw
    end
    'Orbit.Use Days': begin
      widget_control,event.top,/hour
      tpmode=1l
      buttonnames=replicate(' ',n_elements(opids))
      uvals=buttonnames
      for i=0,n_elements(opids)-1 do begin
        widget_control,opids(i),get_value=buttonname
        buttonnames(i)=buttonname
        widget_control,opids(i),get_uvalue=uval
        uvals(i)=uval
      endfor
      ind=(where(buttonnames eq 'Orbit'))(0)
      buttonnames(ind)='Day'
      widget_control,opids(ind),set_value=buttonnames(ind)
      uvals(ind)='Day'
      widget_control,opids(ind),set_uvalue=uvals(ind)
      ind=(where(buttonnames eq 'Use Days'))(0)
      buttonnames(ind)='Use Orbits'
      widget_control,opids(ind),set_value=buttonnames(ind)
      uvals(ind)='Day.Use Orbits'
      widget_control,opids(ind),set_uvalue=uvals(ind)
      ind=where(strmid(uvals,0,5) eq 'Orbit')
      uvals(ind)='Day'+strmid(uvals(ind),5,1000)
      for i=0,n_elements(ind)-1 do $
        widget_control,opids(ind(i)),set_uvalue=uvals(ind(i))
      fastorbgetdata
      fastorbtpwindrw
    end
    'Orbit.Cancel':

    'Day.Select': begin
      wselbase=widget_base(/column,group=event.top,title='FAST Orbit Display')
      wsellab=widget_label(wselbase,value='Choose a Day')
      vals=satdesc(uniq(satdesc.epochdoy)).epochdoy
      wsellist=widget_list(wselbase,value=string(vals,form='(i3.3)'), $
        ysize=10<n_elements(vals))
      wselcan=widget_button(wselbase,value='Cancel')
      widget_control,wselbase,/real
      wselres=widget_event(wselbase)
      widget_control,wselbase,/dest
      if(wselres.id ne wselcan) then begin
        tpdoy=vals(wselres.index)
        widget_control,event.top,/hour
        fastorbgetdata
        fastorbtpwindrw
      endif
    end
    'Day.Prev': begin
      tpdoy=(tpdoy-1)>satdesc(0).epochdoy
      widget_control,event.top,/hour
      fastorbgetdata
      fastorbtpwindrw
    end
    'Day.Next': begin
      tpdoy=(tpdoy+1)<max(satdesc.epochdoy)
      widget_control,event.top,/hour
      fastorbgetdata
      fastorbtpwindrw
    end
    'Day.Use Orbits': begin
      widget_control,event.top,/hour
      tpmode=0l
      buttonnames=replicate(' ',n_elements(opids))
      uvals=buttonnames
      for i=0,n_elements(opids)-1 do begin
        widget_control,opids(i),get_value=buttonname
        buttonnames(i)=buttonname
        widget_control,opids(i),get_uvalue=uval
        uvals(i)=uval
      endfor
      ind=(where(buttonnames eq 'Day'))(0)
      buttonnames(ind)='Orbit'
      widget_control,opids(ind),set_value=buttonnames(ind)
      uvals(ind)='Orbit'
      widget_control,opids(ind),set_uvalue=uvals(ind)
      ind=(where(buttonnames eq 'Use Orbits'))(0)
      buttonnames(ind)='Use Days'
      widget_control,opids(ind),set_value=buttonnames(ind)
      uvals(ind)='Orbit.Use Days'
      widget_control,opids(ind),set_uvalue=uvals(ind)
      ind=where(strmid(uvals,0,3) eq 'Day')
      uvals(ind)='Orbit'+strmid(uvals(ind),3,1000)
      for i=0,n_elements(ind)-1 do widget_control,opids(ind(i)),set_uvalue=uvals(ind(i))
      fastorbgetdata
      fastorbtpwindrw
    end
    'Day.Cancel':

    'Next': begin
      if(tpmode eq 0l) then satdescindx=(satdescindx+1)<(n_elements(satdesc)-1) $
      else tpdoy=(tpdoy+1)<max(satdesc.epochdoy)
      widget_control,event.top,/hour
      fastorbgetdata
      fastorbtpwindrw
    end

    'Plot Setup.View.Plots': begin
      wselbase=widget_base(/column,group=event.top,title='FAST Orbit Display')
      wselbut=cw_bgroup(wselbase,label_top='Display Plots', $
                        plotparm(1:*).name,column=2,/non, $
                        set_value=plotparm(1:*).stat and 1l)
      wseldone=widget_button(wselbase,value='Done')
      wselcan=widget_button(wselbase,value='Cancel')
      widget_control,wselbase,/real
      repeat wselres=widget_event(wselbase) until wselres.id ne wselbut
      if(wselres.id ne wselcan) then begin
        widget_control,wselbut,get_value=setbuttons
        plotparm(1:*).stat=setbuttons
        fastorbtpwindrw
      endif
      widget_control,wselbase,/dest
    end
    'Plot Setup.View.Order': begin
      toplot=where(plotparm(1:*).stat and 1l,nplot)+1
      if(nplot gt 1l) then begin
        toplot=toplot(sort(plotparm(toplot).order))
        wselbase=widget_base(/column,group=event.top,title='FAST Orbit Display')
        wselbut=cw_bgroup(wselbase,label_top='Change Order',ids=butids, $
                          'Move '+plotparm(toplot(1:*)).name+' up',column=1,/frame)
        wseldone=widget_button(wselbase,value='Done')
        wselcan=widget_button(wselbase,value='Cancel')
        widget_control,wselbase,/real
        wselres=widget_event(wselbase)
        while(wselres.id eq wselbut) do begin
          temp=toplot(wselres.value+1)
          toplot(wselres.value+1)=toplot(wselres.value)
          toplot(wselres.value)=temp
          if(wselres.value ge 1) then widget_control,butids(wselres.value-1), $
                 set_value='Move '+plotparm(toplot(wselres.value)).name+' up'
          widget_control,butids(wselres.value), $
                 set_value='Move '+plotparm(toplot(wselres.value+1)).name+' up'
          wselres=widget_event(wselbase)
        endwhile
        if(wselres.id ne wselcan) then begin
          plotparm(toplot).order=1+indgen(n_elements(toplot))
          noplot=where((plotparm(1:*).stat and 1l) ne 1,nplot)+1
          noplot=noplot(sort(plotparm(noplot).order))
          plotparm(noplot).order=1+n_elements(toplot)+indgen(n_elements(noplot))
          fastorbtpwindrw
        endif
        widget_control,wselbase,/dest
      endif
    end
    'Plot Setup.Axis.Time':
    'Plot Setup.Axis.Ordinate': xfastorbtpaxis,group=event.top

    'Redraw': fastorbtpwindrw

    'Print.Print': begin
      printout=1
      fastorbtpwindrw
      printout=0
    end
    'Print.Setup.Dest':
    'Print.Setup.Orient.Land': printorient=1l
    'Print.Setup.Orient.Port': printorient=2l
    'Print.Setup.Orient.HalfPort': printorient=3l
    'Print.Cancel':

    'IDL Cmd' : xidlcmd,group=event.top

    'Info.IDL Help' : call_procedure,'man_proc',' '
    'Info.FASTOrb Help' : xfastorbhelp,group=event.top
    'Info.Specifications' : xfastorbspec,group=event.top
    'Info.News' : xfastorbnews,group=event.top
    'Info.Cancel' :

    'Close' : widget_control,wtpa,/dest

    else : xfastbadev,group=event.top

  endcase
  else : xfastbadev,group=event.top
endcase
putdata=0

return
end

pro fastorbtpwindrw

@fastorb.cmn
@fastorbtp.cmn

if(n_elements(rdvectp) le 0) then rdvectp=rdvec
if(printout) then begin
  set_plot,'ps'
  device,/times
  !p.font=0
  case printorient of
    1: device,/land
    2: device,/port,/inch,yoff=1.0,ysize=9.0
    3: device,/port
  endcase
endif else wset,fastorbtpwin

toplot=where(plotparm(1:*).stat and 1l,nplot)+1
toplot=toplot(sort(plotparm(toplot).order))
yplot=fltarr(n_elements(rdvectp),nplot)
for i=0,nplot-1 do begin
  case plotparm(toplot(i)).name of
    'lat': yplot(*,i)=rdvectp.lat
    'lng': yplot(*,i)=rdvectp.lng
    'alt': yplot(*,i)=rdvectp.alt
    'mlat': yplot(*,i)=rdvectp.mlat
    'mlng': yplot(*,i)=rdvectp.mlng
    'mlt': yplot(*,i)=rdvectp.mlt
    'ilat': yplot(*,i)=rdvectp.ilat
    'ilng': yplot(*,i)=rdvectp.ilng
    'bmag': yplot(*,i)=sqrt(rdvectp.bx^2+rdvectp.by^2+rdvectp.bz^2)
  endcase
endfor
if(tpmode ne 0l) then begin
  tit='FAST Orbits   Day '+string(tpdoy,form='(i3.3)')+' of '+ $
      string(satdesc(0).epochyr,form='(i4.4)')
  plotparmsave=plotparm(0)
  plotparm(0).axis.range=[0,24]
  plotparm(0).axis.ticks=8
  plotparm(0).axis.minor=3
  timeoff=[1,satdesc(rdvectp(0).satptr).epochyr,tpdoy,0,0,0]
  epochoff=(((satdesc(rdvectp(0).satptr).epochdoy-tpdoy)*24.0+ $
              satdesc(rdvectp(0).satptr).epochhr)*60.0+ $
              satdesc(rdvectp(0).satptr).epochmin)*60.0+ $
              satdesc(rdvectp(0).satptr).epochsec
endif else begin
  plotparm(0).axis.range=[0,0]
  tit=satdesc(rdvectp(0).satptr).sat+' Orbit '+ $
      strtrim(string(satdesc(rdvectp(0).satptr).orbit),2)
  timeoff=[1,satdesc(rdvectp(0).satptr).epochyr,  $
             satdesc(rdvectp(0).satptr).epochdoy, $
             satdesc(rdvectp(0).satptr).epochhr,  $
             satdesc(rdvectp(0).satptr).epochmin, $
             satdesc(rdvectp(0).satptr).epochsec]
  epochoff=0.0
endelse
panplot,tit=tit,stamp=systime(0)+'!C'+curfile, $
        xdata=rdvectp.time+epochoff,xaxis=plotparm(0).axis, $
        ydata=yplot,yaxis=plotparm(toplot).axis, $
        timeoff=timeoff
if(tpmode ne 0l) then plotparm(0)=plotparmsave

if(printout) then begin
  device,/close
  case !version.os of
    'sunos': spawn,'lpr -P'+printque+' idl.ps'
    else: spawn,'print/del/que='+printque+' idl.ps'
  endcase
  set_plot,'x'
  !p.font=-1
endif
return
end


pro xfastorbtp,group=group

@fastorb.cmn
@fastorbtp.cmn

if(xregistered('xfastorbtp')) then return
printout=0l
printorient=1l      ; 1 => landscape, 2 => portrait, 3 => half portrait
if(keyword_set(group)) then $
  wtpa=widget_base(title='FAST Orbit Display',/column,group=group) $
else $
  wtpa=widget_base(title='FAST Orbit Display',/column)
wtpb=widget_draw(wtpa,xsize=640,ysize=512)
opwid=widget_base(wtpa,/row)
opdesc={cw_pdmenu_s,flags:0,name:''}  ;  Just to define cw_pdmenu_s
opdesc1=[{cw_pdmenu_s,1,'File'}, $
          {cw_pdmenu_s,0,'New'}, $
          {cw_pdmenu_s,0,'Close'}, $
          {cw_pdmenu_s,0,'Quit'}, $
          {cw_pdmenu_s,2,'Cancel'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,0,'Prev'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,1,'Orbit'}, $
          {cw_pdmenu_s,0,'Select'}, $
          {cw_pdmenu_s,0,'Prev'}, $
          {cw_pdmenu_s,0,'Next'}, $
          {cw_pdmenu_s,0,'Use Days'}, $
          {cw_pdmenu_s,2,'Cancel'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,0,'Next'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,1,'Plot Setup'}, $
          {cw_pdmenu_s,1,'View'}, $
           {cw_pdmenu_s,0,'Plots'}, $
           {cw_pdmenu_s,2,'Order'}, $
          {cw_pdmenu_s,1,'Axis'}, $
           {cw_pdmenu_s,0,'Time-'}, $
           {cw_pdmenu_s,2,'Ordinate'}, $
          {cw_pdmenu_s,2,'Cancel'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,0,'Redraw'}]
opdesc1=[opdesc1, $
         {cw_pdmenu_s,1,'Print'}, $
          {cw_pdmenu_s,0,'Print'}, $
          {cw_pdmenu_s,1,'Setup'}, $
           {cw_pdmenu_s,0,'Dest-'}, $
           {cw_pdmenu_s,3,'Orient'}, $
            {cw_pdmenu_s,0,'Land'}, $
            {cw_pdmenu_s,0,'Port'}, $
            {cw_pdmenu_s,0,'HalfPort'}, $
            {cw_pdmenu_s,2,'Cancel'}, $
          {cw_pdmenu_s,2,'Cancel'}]
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
         {cw_pdmenu_s,2,'Close'}]

opmenuwid1=cw_pdmenu(opwid,opdesc1,ids=opids,/return_full_name,uvalue='Op')
for i=0,n_elements(opids)-1 do begin
  widget_control,opids(i),get_value=buttonname
  if(strmid(buttonname,strlen(buttonname)-1,1) eq '-') then begin
    widget_control,opids(i),set_value=strmid(buttonname,0,strlen(buttonname)-1)
    widget_control,opids(i),sensitive=0
  endif else if(tpmode eq 1l) then begin
    if(buttonname eq 'Orbit') then begin
      widget_control,opids(i),set_value='Day'
      widget_control,opids(i),set_uvalue='Day'
    endif else if(buttonname eq 'Use Days') then begin
      widget_control,opids(i),set_value='Use Orbits'
      widget_control,opids(i),set_uvalue='Day.Use Orbits'
    endif else begin
      widget_control,opids(i),get_uvalue=uval
      if(strmid(uval,0,5) eq 'Orbit') then $
        widget_control,opids(i),set_uvalue='Day'+strmid(uval,5,1000)
    endelse
  endif
endfor
if(n_elements(plotparm) le 0) then begin
  plotparm= {plotdesc,name:'time',axis:!x,stat:0l,order:0l}
  plotparm=[plotparm, $
            {plotdesc,name:'lat',axis:!y,stat:0l,order:n_elements(plotparm)}]
  plotparm=[plotparm, $
            {plotdesc,name:'lng',axis:!y,stat:0l,order:n_elements(plotparm)}]
  plotparm=[plotparm, $
            {plotdesc,name:'alt',axis:!y,stat:0l,order:n_elements(plotparm)}]
  plotparm=[plotparm, $
            {plotdesc,name:'mlat',axis:!y,stat:0l,order:n_elements(plotparm)}]
  plotparm=[plotparm, $
            {plotdesc,name:'mlng',axis:!y,stat:0l,order:n_elements(plotparm)}]
  plotparm=[plotparm, $
            {plotdesc,name:'mlt',axis:!y,stat:0l,order:n_elements(plotparm)}]
  plotparm=[plotparm, $
            {plotdesc,name:'ilat',axis:!y,stat:0l,order:n_elements(plotparm)}]
  plotparm=[plotparm, $
            {plotdesc,name:'ilng',axis:!y,stat:0l,order:n_elements(plotparm)}]
  plotparm=[plotparm, $
            {plotdesc,name:'bmag',axis:!y,stat:0l,order:n_elements(plotparm)}]
; Set default values for plot parameters.
  i=where(plotparm.name eq 'time')
  plotparm(i).stat=1l
  plotparm(i).axis.style=1
  i=where(plotparm.name eq 'lat')
  plotparm(i).axis.title='Latitude (deg)'
  plotparm(i).axis.range=[-90,90]
  plotparm(i).axis.ticks=6
  plotparm(i).axis.minor=3
  plotparm(i).axis.style=1
  i=where(plotparm.name eq 'lng')
  plotparm(i).axis.title='Longitude (deg)'
  plotparm(i).axis.range=[-180,180]
  plotparm(i).axis.ticks=6
  plotparm(i).axis.minor=3
  plotparm(i).axis.style=1
  i=where(plotparm.name eq 'alt')
  plotparm(i).axis.title='Altitude (km)'
  plotparm(i).axis.range=[0,5000]
  plotparm(i).axis.style=1
  plotparm(i).stat=1l
  i=where(plotparm.name eq 'mlat')
  plotparm(i).axis.title='Mag. Latitude (deg)'
  plotparm(i).axis.range=[-90,90]
  plotparm(i).axis.ticks=6
  plotparm(i).axis.minor=3
  plotparm(i).axis.style=1
  i=where(plotparm.name eq 'mlng')
  plotparm(i).axis.title='Mag. Longitude (deg)'
  plotparm(i).axis.range=[-180,180]
  plotparm(i).axis.ticks=6
  plotparm(i).axis.minor=3
  plotparm(i).axis.style=1
  i=where(plotparm.name eq 'mlt')
  plotparm(i).axis.title='MLT (hours)'
  plotparm(i).axis.range=[0,24]
  plotparm(i).axis.style=1
  plotparm(i).axis.ticks=4
  plotparm(i).axis.minor=3
  plotparm(i).stat=1l
  i=where(plotparm.name eq 'ilat')
  plotparm(i).axis.title='Inv. Latitude (deg)'
  plotparm(i).axis.range=[-90,90]
  plotparm(i).axis.style=1
  plotparm(i).axis.ticks=6
  plotparm(i).axis.minor=3
  plotparm(i).stat=1l
  i=where(plotparm.name eq 'ilng')
  plotparm(i).axis.title='Inv. Longitude (deg)'
  plotparm(i).axis.range=[-180,180]
  plotparm(i).axis.ticks=6
  plotparm(i).axis.minor=3
  plotparm(i).axis.style=1
  i=where(plotparm.name eq 'bmag')
  plotparm(i).axis.title='Mag. Field (nT)'
  plotparm(i).axis.range=[0,60000]
  plotparm(i).axis.ticks=6
  plotparm(i).axis.minor=2
  plotparm(i).axis.style=1
endif

widget_control,wtpa,/real
widget_control,wtpb,get_value=fastorbtpwin
fastorbtpwindrw
if(keyword_set(group)) then $
  xmanager,'xfastorbtp',wtpa,group_leader=group,event_handler='xfastorbtp_ev' $
else $
  xmanager,'xfastorbtp',wtpa,event_handler='xfastorbtp_ev'
return
end
