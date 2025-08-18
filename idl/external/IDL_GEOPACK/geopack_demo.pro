pro geopack_demo

  geopack_recalc_08,2000,90

  plot,[-20,20],[-20,20],/nodata,/isotropic

  for i=5,85,5 do begin
    geopack_sphcar_08,1,i,0,x,y,z,/degree,/to_rect
    geopack_trace_08,x,y,z,1,0,xf,yf,zf,fline=fline,/noboundary
    oplot,fline[*,0],fline[*,2]

    geopack_sphcar_08,1,i,180,x,y,z,/degree,/to_rect
    geopack_trace_08,x,y,z,1,0,xf,yf,zf,fline=fline,/noboundary
    oplot,fline[*,0],fline[*,2]
  endfor

return
end
