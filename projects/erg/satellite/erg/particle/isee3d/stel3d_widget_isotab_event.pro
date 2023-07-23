;
; Isosurface tab event handler
;
pro stel3d_widget_isotab_event, ev
  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVALUE=uval
  
  oData = val['oData']
  nrange = oData.getNSouceRange()
 
  case uval of 
    'isotab:COLOR1':begin
      cColor = (val['ColorList'])[ev.index]
      (val['oISO1']).SetProperty, COLOR=val['oConf'].GetRGB(cColor)
      (val['oWindow']).Draw
    end
    'isotab:COLOR2':begin
      cColor = (val['ColorList'])[ev.index]
      (val['oISO2']).SetProperty, COLOR=val['oConf'].GetRGB(cColor)
      (val['oWindow']).Draw
    end
    'isotab:ISOMESH1ZBTN':begin
      if ev.select eq 0 then style = 2 else style=1
      val['oISO1'].SetProperty, STYLE=style
      val['oWindow'].Draw
    end
    'isotab:ISOMESH2ZBTN':begin
      if ev.select eq 0 then style = 2 else style=1
      val['oISO2'].SetProperty, STYLE=style
      val['oWindow'].Draw
    end
    'isotab:SLIDERMIN1':begin
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMAX1'), GET_VALUE=maxval
      minval = ev.value
      if minval ge maxval then begin
        minval = maxval-1
        widget_control, ev.id, SET_VALUE=minval
      endif
      minreal = (minval/255.)*(nrange[1]-nrange[0])
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:TEXTMIN1'), SET_VALUE=strcompress(string(minreal, FORMAT='(1F5.1)'), /REMOVE_ALL)
      res = stel3d_create_isosurface(val['oVolume'], [minval, maxval], UPDATE=val['oISO1'])
       (val['oConf']).SetProperty, ISO1_LEVEL= [minval, maxval]
      if res then begin
        (val['oWindow']).Draw
         (val['oConf']).SetProperty, ISO1_LEVEL= [minval, maxval]
      endif
    end
    'isotab:TEXTMIN1':begin
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMAX1'), GET_VALUE=maxslider
      widget_control, ev.id, GET_VALUE=minreal
      minreal=FLOAT(minreal[0])
      if minreal le nrange[0] then minreal=nrange[0]
      minslider = (255./(nrange[1]-nrange[0]))*minreal
      if minslider ge maxslider then begin
        minslider = maxslider-1
        minreal = ((maxslider-1)/255.)*(nrange[1]-nrange[0])
      endif
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:TEXTMIN1'), SET_VALUE=strcompress(string(minreal, FORMAT='(1F5.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMIN1'), SET_VALUE=byte(minslider)
      res = stel3d_create_isosurface(val['oVolume'], [minslider, maxslider], UPDATE=val['oISO1'])
      (val['oConf']).SetProperty, ISO1_LEVEL= [minslider, maxslider]
      if res then begin
        (val['oWindow']).Draw
        (val['oConf']).SetProperty, ISO1_LEVEL= [minslider, maxslider]
      endif
    end
    'isotab:SLIDERMAX1':begin
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMIN1'), GET_VALUE=minval
      maxval = ev.value
      if maxval le minval then begin
        maxval=minval+1
        widget_control, ev.id, SET_VALUE=maxval
      endif
      maxreal = (maxval/255.)*(nrange[1]-nrange[0])
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:TEXTMAX1'), SET_VALUE=strcompress(string(maxreal, FORMAT='(1F5.1)'), /REMOVE_ALL)
      res = stel3d_create_isosurface(val['oVolume'], [minval, maxval], UPDATE=val['oISO1'])
      if res then begin
        (val['oWindow']).Draw
        (val['oConf']).SetProperty, ISO1_LEVEL= [minval, maxval]
      endif
    end
    'isotab:TEXTMAX1':begin
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMIN1'), GET_VALUE=minslider
      widget_control, ev.id, GET_VALUE=maxreal
      maxreal=FLOAT(maxreal[0])
      if maxreal ge nrange[1] then maxreal=nrange[1]
      maxslider = (255./(nrange[1]-nrange[0]))*maxreal
      if maxslider le minslider then begin
        maxslider = minslider+1
        maxreal = ((minslider+1)/255.)*(nrange[1]-nrange[0])
      endif
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:TEXTMAX1'), SET_VALUE=strcompress(string(maxreal, FORMAT='(1F5.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMAX1'), SET_VALUE=byte(maxslider)
      res = stel3d_create_isosurface(val['oVolume'], [minslider, maxslider], UPDATE=val['oISO1'])
      (val['oConf']).SetProperty, ISO1_LEVEL= [minslider, maxslider]
      if res then begin
        (val['oWindow']).Draw
        (val['oConf']).SetProperty, ISO1_LEVEL= [minslider, maxslider]
      endif
    end
    'isotab:SLIDERMIN2':begin
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMAX2'), GET_VALUE=maxval
      minval = ev.value
      if minval ge maxval then begin
        minval = maxval-1
        widget_control, ev.id, SET_VALUE=minval
      endif
      minreal = (minval/255.)*(nrange[1]-nrange[0])
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:TEXTMIN2'), SET_VALUE=strcompress(string(minreal, FORMAT='(1F5.1)'), /REMOVE_ALL)
      res = stel3d_create_isosurface(val['oVolume'], [minval, maxval], UPDATE=val['oISO2'])
      if res then begin
        (val['oWindow']).Draw
        (val['oConf']).SetProperty, ISO2_LEVEL= [minval, maxval]
      endif
    end
    'isotab:TEXTMIN2':begin
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMAX2'), GET_VALUE=maxslider
      widget_control, ev.id, GET_VALUE=minreal
      minreal=FLOAT(minreal[0])
      if minreal le nrange[0] then minreal=nrange[0]
      minslider = (255./(nrange[1]-nrange[0]))*minreal
      if minslider ge maxslider then begin
        minslider = maxslider-1
        minreal = ((maxslider-1)/255.)*(nrange[1]-nrange[0])
      endif
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:TEXTMIN2'), SET_VALUE=strcompress(string(minreal, FORMAT='(1F5.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMIN2'), SET_VALUE=byte(minslider)
      res = stel3d_create_isosurface(val['oVolume'], [minslider, maxslider], UPDATE=val['oISO2'])
      (val['oConf']).SetProperty, ISO2_LEVEL= [minslider, maxslider]
      if res then begin
        (val['oWindow']).Draw
        (val['oConf']).SetProperty, ISO2_LEVEL= [minslider, maxslider]
      endif
    end
    'isotab:SLIDERMAX2':begin
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMIN2'), GET_VALUE=minval
      maxval=ev.value
      if maxval le minval then begin
        maxval=minval+1
        widget_control, ev.id, SET_VALUE=maxval
      endif
      ; update the value in Text Widget
      maxreal = (maxval/255.)*(nrange[1]-nrange[0])
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:TEXTMAX2'), SET_VALUE=strcompress(string(maxreal, FORMAT='(1F5.1)'), /REMOVE_ALL)
      ; update isosurface object
      res = stel3d_create_isosurface(val['oVolume'], [minval, maxval], UPDATE=val['oISO2'])
      if res then begin
        (val['oWindow']).Draw
        (val['oConf']).SetProperty, ISO2_LEVEL= [minval, maxval]
      endif
    end  
    'isotab:TEXTMAX2':begin
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMIN2'), GET_VALUE=minslider
      widget_control, ev.id, GET_VALUE=maxreal
      maxreal=FLOAT(maxreal[0])
      if maxreal ge nrange[1] then maxreal=nrange[1]
      maxslider = (255./(nrange[1]-nrange[0]))*maxreal
      if maxslider le minslider then begin
        maxslider = minslider+1
        maxreal = ((minslider+1)/255.)*(nrange[1]-nrange[0])
      endif
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:TEXTMAX2'), SET_VALUE=strcompress(string(maxreal, FORMAT='(1F5.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='isotab:SLIDERMAX2'), SET_VALUE=byte(maxslider)
      res = stel3d_create_isosurface(val['oVolume'], [minslider, maxslider], UPDATE=val['oISO2'])
      (val['oConf']).SetProperty, ISO2_LEVEL= [minslider, maxslider]
      if res then begin
        (val['oWindow']).Draw
        (val['oConf']).SetProperty, ISO2_LEVEL= [minslider, maxslider]
      endif
    end
  endcase
  
  
  

end