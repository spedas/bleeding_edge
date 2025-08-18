pro stel3d_widget_context_menu_event, ev
;common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVALUE=uval

  oData = val['oData']

  case uval of
    'context:CTButton':begin ;Change Color Table
      xloadct, GROUP=ev.top, /MODAL
      tvlct, r, g, b, /GET  ;Get Color Table information
      
      oPalette = oData.getPalette()
      oPalette->SetProperty, Red=r, Green=g, Blue=b
      ;
      ; update scatter-plot color
      !null = stel3d_create_scatter(oData, UPDATE=val['oScatter'])
      ;
      ; update volume color
      (val['oVolume']).SetProperty, RGB_TABLE0=[[r],[g],[b]]
    end
    'context:XYplot':begin
      print, 'X-Y plane'
      stel3d_widget_profiler, ev, /XY
    end
    'context:YZplot':begin
      print, 'Y-Z plane'
       stel3d_widget_profiler, ev, /YZ
    end
    'context:XZplot':begin
      print, 'X-Z plane'
      stel3d_widget_profiler, ev, /XZ
    end
    else:print, 'else'
  endcase
  
;help, ev, /STRUCT
 (val['oWindow']).draw

end