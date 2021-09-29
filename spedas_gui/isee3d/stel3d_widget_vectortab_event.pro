;
; Vector tab event handler
;
pro stel3d_widget_vectortab_event, ev

  ;help, ev
  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVALUE=uval
  oData = val['oData']
  oWindow = val['oWindow']
  oConf = val['oConf']
  oConf.GetProperty, BFIELD=mag_info, VELOCITY=vel_info, USER=user_info 
;  help, mag_info, /STRUCT
;  print, uval
;  help, ev, /STRUCT

  case uval of 
    'vectortab:MAGVECTORBTN':begin
      mag_info.show=ev.select
      oMagVec = val['oMagVec']
      oVec=oMagVec.Get(ISA='IDLgrPolyline')
      oVec.SetProperty, HIDE=~(mag_info.show)
      oWindow.draw
    end
    'vectortab:MAGCOLOR':begin
      mag_info.color = (val['ColorList'])[ev.index]
      oMagVec = val['oMagVec']
      oVec=oMagVec.Get(ISA='IDLgrPolyline')
      oVec.SetProperty, COLOR=oConf.GetRGB(mag_info.color)
      oWindow.draw
    end
    'vectortab:MAGLENGTH':begin
      oMagVec = val['oMagVec']
      org_length=mag_info.length
      length = (val['LengthList'])[ev.index]
      mag_info.length = length
      case org_length of
        'full':begin
           if length eq 'half' then oMagVec.Scale, 0.5, 0.5, 0.5
           if length eq 'quarter' then oMagVec.Scale, 0.25, 0.25, 0.25
        end
        'half':begin
          if length eq 'full' then oMagVec.Scale, 2, 2, 2
          if length eq 'quarter' then oMagVec.Scale, 0.5, 0.5, 0.5
        end
        'quarter':begin
          if length eq 'full' then oMagVec.Scale, 4, 4, 4
          if length eq 'half' then oMagVec.Scale, 2, 2, 2
        end
        else:message, 'no match for the length'
      endcase
      oWindow.draw
    end
    'vectortab:MAGTHICKNESS':begin
      mag_info.thick = (val['ThickList'])[ev.index]
      oMagVec = val['oMagVec']
      oVec=oMagVec.Get(ISA='IDLgrPolyline')
      oVec.SetProperty, THICK=mag_info.thick
      oWindow.draw
    end
    'vectortab:VELOVECTORBTN':begin
      vel_info.show = ev.select
      oVelVec = val['oVelVec']
      oVec=oVelVec.Get(ISA='IDLgrPolyline')
      oVec.SetProperty, HIDE=~(vel_info.show)
      oWindow.draw
    end
    'vectortab:VELOCOLOR':begin
      vel_info.color = (val['ColorList'])[ev.index]
      oVelVec = val['oVelVec']
      oVec=oVelVec.Get(ISA='IDLgrPolyline')
      oVec.SetProperty, COLOR=oConf.GetRGB(vel_info.color)
      oWindow.draw
    end
    'vectortab:VELOLENGTH':begin
      oVelVec = val['oVelVec']
      org_length=vel_info.length
      length = (val['LengthList'])[ev.index]
      vel_info.length = length
      case org_length of
        'full':begin
          if length eq 'half' then oVelVec.Scale, 0.5, 0.5, 0.5
          if length eq 'quarter' then oVelVec.Scale, 0.25, 0.25, 0.25
        end
        'half':begin
          if length eq 'full' then oVelVec.Scale, 2, 2, 2
          if length eq 'quarter' then oVelVec.Scale, 0.5, 0.5, 0.5
        end
        'quarter':begin
            if length eq 'full' then oVelVec.Scale, 4, 4, 4
            if length eq 'half' then oVelVec.Scale, 2, 2, 2
        end
        else:message, 'no match for the length'
      endcase
      oWindow.draw
    end
    'vectortab:VELOTHICKNESS':begin
      vel_info.thick = (val['ThickList'])[ev.index]
      oVelVec = val['oVelVec']
      oVec=oVelVec.Get(ISA='IDLgrPolyline')
      oVec.SetProperty, THICK=vel_info.thick
      oWindow.draw
    end
    'vectortab:USERVECTORBTN':begin
      user_info.show = ev.select
      oUserVec = val['oUserVec']
      oVec=oUserVec.Get(ISA='IDLgrPolyline')
      oVec.SetProperty, HIDE=~(user_info.show)
      oWindow.draw
    end
    'vectortab:USERCOLOR':begin
      user_info.color = (val['ColorList'])[ev.index]
      oUserVec = val['oUserVec']
      oVec=oUserVec.Get(ISA='IDLgrPolyline')
      oVec.SetProperty, COLOR=oConf.GetRGB(user_info.color)
      oWindow.draw
    end
    'vectortab:USERLENGTH':begin
        oUserVec = val['oUserVec']
        org_length=user_info.length
        length = (val['LengthList'])[ev.index]
        user_info.length = length
        case org_length of
          'full':begin
            if length eq 'half' then oUserVec.Scale, 0.5, 0.5, 0.5
            if length eq 'quarter' then oUserVec.Scale, 0.25, 0.25, 0.25
          end
          'half':begin
            if length eq 'full' then oUserVec.Scale, 2, 2, 2
            if length eq 'quarter' then oUserVec.Scale, 0.5, 0.5, 0.5
          end
          'quarter':begin
            if length eq 'full' then oUserVec.Scale, 4, 4, 4
            if length eq 'half' then oUserVec.Scale, 2, 2, 2
          end
        else:message, 'no match for the length'
      endcase
      oWindow.draw
    end
    'vectortab:USERTHICKNESS':begin
      user_info.thick = (val['ThickList'])[ev.index]
      oUserVec = val['oUserVec']
      oVec=oUserVec.Get(ISA='IDLgrPolyline')
      oVec.SetProperty, THICK=user_info.thick
      oWindow.draw
    end
    'vectortab:USERVECTORX':begin
      oUserVec = val['oUserVec']
      widget_control, ev.id, GET_VALUE=xval
      pos = stregex(xval, '[A-Za-z]+')
      if pos ne -1 then return else xval = float(xval)
      user_info.x = xval
      tmp = stel3d_create_vector([user_info.x, user_info.y, user_info.z], $
        UPDATE=oUserVec)
      oWindow.Draw 
    end
    'vectortab:USERVECTORY':begin
      oUserVec = val['oUserVec']
      widget_control, ev.id, GET_VALUE=yval
      pos = stregex(yval, '[A-Za-z]+')
      if pos ne -1 then return else yval = float(yval)
      user_info.y = yval
      tmp = stel3d_create_vector([user_info.x, user_info.y, user_info.z], $
        UPDATE=oUserVec)
      oWindow.Draw
    end
    'vectortab:USERVECTORZ':begin
      oUserVec = val['oUserVec']
      widget_control, ev.id, GET_VALUE=zval
      pos = stregex(zval, '[A-Za-z]+')
      if pos ne -1 then return else zval = float(zval)
      user_info.z = zval
      tmp = stel3d_create_vector([user_info.x, user_info.y, user_info.z], $
        UPDATE=oUserVec)
      oWindow.Draw
    end
    else:message, 'no match for vectortab uvalue'
  endcase

  oConf.SetProperty, BFIELD=mag_info, VELOCITY=vel_info, USER=user_info
  ;help, mag_info, /STRUCT

end