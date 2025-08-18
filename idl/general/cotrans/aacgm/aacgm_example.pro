;Eric Donovan - U. Calgary
pro aacgm_example

   aacgmidl

   map_set,/mercator,62,256,scale=42e6,/continents
   mlat_range=[50,70]
   mlat_step=5
   height=110
   contour_color=250
   contour_thick=1
   contour_linestyle=0

   ;-------------------------------------------------------------------------------
   ;mlat contours
   ;the call of cnv_aacgm here converts from geomagnetic to geographic
   nmlats=round((mlat_range[1]-mlat_range[0])/float(mlat_step)+1)
   mlats=mlat_range[0]+findgen(nmlats)*mlat_step
   n2=150
   v_lat=fltarr(nmlats,n2)
   v_lon=fltarr(nmlats,n2)
   for i=0,nmlats-1 do begin
     for j=0,n2-1 do begin
          cnv_aacgm,mlats[i],j/float(n2-1)*360,height,u,v,r,error,/geo
          v_lat[i,j]=u
          v_lon[i,j]=v
     endfor
   endfor
   for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=contour_color,thick=contour_thick,linestyle=contour_linestyle
   ;-------------------------------------------------------------------------------
   ;mlon contours
   ;the first call of cnv_aacgm converts from geographic to geomagnetic (to get mag lon of Gillam)
   ;the call in the loop of cnv_aacgm here converts from geomagnetic to geographic
   nmlons=24 ;mlons shown at intervals of 15 degrees or one hour of MLT
   mlon_step=round(360/float(nmlons))
   n2=20
   u_lat=fltarr(nmlons,n2)
   u_lon=fltarr(nmlons,n2)
   cnv_aacgm, 56.35, 265.34, height, outlat,outlon,r,error   ;Gillam
   mlats=mlat_range[0]+findgen(n2)/float(n2-1)*(mlat_range[1]-mlat_range[0])
   for i=0,nmlons-1 do begin
     for j=0,n2-1 do begin
        cnv_aacgm,mlats[j],((outlon+mlon_step*i) mod 360),height,u,v,r,error,/geo
        u_lat[i,j]=u
        u_lon[i,j]=v
     endfor
   endfor

   for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=contour_color,thick=contour_thick,linestyle=contour_linestyle
   for i=0,nmlons-1 do oplot,u_lon[i,*],u_lat[i,*],color=contour_color,thick=contour_thick,linestyle=contour_linestyle
   ;-------------------------------------------------------------------------------

return
end