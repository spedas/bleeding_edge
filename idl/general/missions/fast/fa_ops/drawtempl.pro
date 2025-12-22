;;  @(#)drawtempl.pro	1.2 12/15/94   Fast orbit display program

pro drawtempl

@fastorb.cmn
@fastorbdisp.cmn
@colors.cmn

; Assume aspect ratio of 5:4, e.g. 640 x 512 pixels.
; PostScript: use 7 x 5.6 inches (otherwise scale font)

ar=5.0/4.0
; Make clock face
;pclock=[0,.6,.3,.9]*512
;plot,/polar,replicate(1.0,181),findgen(181)*2.0*!dtor,pos=pclock,/dev, $
;     xstyle=4,ystyle=4,title='UT'
pclock=[0/ar,.6,.3/ar,.9]
plot,/polar,replicate(1.0,181),findgen(181)*2.0*!dtor,pos=pclock, $
     xstyle=4,ystyle=4,title='UT'
oplot,/polar,replicate(0.9,12),findgen(12)*30*!dtor,psym=4
oplot,/polar,replicate(0.9,4),findgen(4)*90*!dtor,psym=3

;Make north polar plot
;pnorth=[.37,.6,.67,.9]*512
;plot,/noe,/polar,replicate(1.0,181),findgen(181)*2.0*!dtor,pos=pnorth,/dev, $
;     xrange=[-1,1],yrange=[-1,1],xstyle=5,ystyle=5,title='North!C'
;xyouts,pnorth(0)-.01*512,(pnorth(1)+pnorth(3)-!d.y_ch_size)/2,'18',/dev,al=1.0
pnorth=[.37/ar,.6,.67/ar,.9]
plot,/noe,/polar,replicate(1.0,181),findgen(181)*2.0*!dtor,pos=pnorth, $
     xrange=[-1,1],yrange=[-1,1],xstyle=5,ystyle=5,title='North!C'
xyouts,pnorth(0)-!d.x_ch_size/2.0/!d.x_size, $
       (pnorth(1)+pnorth(3)-float(!d.y_ch_size)/!d.y_size)/2, $
       '18',/norm,al=1.0
oplot,/polar,[0],[0],psym=1,col=blue
for i=15,75,15 do oplot,/polar,replicate(cos(i*!dtor),181), $
                               findgen(181)*2.0*!dtor,col=blue
for i=0,11 do oplot,/polar,sin([10,90]*!dtor),[i,i]*30*!dtor,  $
                    col=blue,linestyle=1
hrs=findgen(10*24+1)/10.0
;plot,/noe,/nod,/polar,[1],[1],pos=pnorth,/dev,xrange=[-1,1],yrange=[-1,1], $
;     xstyle=5,ystyle=5,title='!CQ='+strtrim(string(q),2),col=green
plot,/noe,/nod,/polar,[1],[1],pos=pnorth,xrange=[-1,1],yrange=[-1,1], $
     xstyle=5,ystyle=5,title='!CQ='+strtrim(string(q),2),col=green
oplot,/polar,sin(azonloc(hrs,q)),(hrs-6)/12.0*!pi,col=green
oplot,/polar,sin(azonloc(hrs,q,/pole)),(hrs-6)/12.0*!pi,col=green
;xyouts,(pnorth(0)+pnorth(2))/2,pnorth(1)-.035*512,/dev,'ILAT: ',al=1.0
;xyouts,(pnorth(0)+pnorth(2))/2,pnorth(1)-.07*512,/dev,'MLT: ',al=1.0
xyouts,(pnorth(0)+pnorth(2))/2, $
       pnorth(1)-1.5*!d.y_ch_size/!d.y_size, $
       /norm,'ILAT: ',al=1.0
xyouts,(pnorth(0)+pnorth(2))/2, $
       pnorth(1)-3.0*!d.y_ch_size/!d.y_size, $
       /norm,'MLT: ',al=1.0

;Make south polar plot
;psouth=[.68,.6,.98,.9]*512
;plot,/noe,/polar,replicate(1.0,181),findgen(181)*2.0*!dtor,pos=psouth,/dev, $
;     xrange=[-1,1],yrange=[-1,1],xstyle=5,ystyle=5,title='South!C'
;xyouts,psouth(2)+.01*512,(psouth(1)+psouth(3)-!d.y_ch_size)/2,'18',/dev
psouth=[.68/ar,.6,.98/ar,.9]
plot,/noe,/polar,replicate(1.0,181),findgen(181)*2.0*!dtor,pos=psouth, $
     xrange=[-1,1],yrange=[-1,1],xstyle=5,ystyle=5,title='South!C'
xyouts,psouth(2)+!d.x_ch_size/2.0/!d.x_size, $
       (psouth(1)+psouth(3)-float(!d.y_ch_size)/!d.y_size)/2, $
       '18',/norm
oplot,/polar,[0],[0],psym=1,col=blue
for i=15,75,15 do oplot,/polar,replicate(cos(i*!dtor),181), $
                               findgen(181)*2.0*!dtor,col=blue
for i=0,11 do oplot,/polar,sin([10,90]*!dtor),[i,i]*30*!dtor,  $
                    col=blue,linestyle=1
;plot,/noe,/nod,/polar,[1],[1],pos=psouth,/dev,xrange=[1,-1],yrange=[-1,1], $
;     xstyle=5,ystyle=5,title='!CQ='+strtrim(string(q),2),col=green
plot,/noe,/nod,/polar,[1],[1],pos=psouth,xrange=[1,-1],yrange=[-1,1], $
     xstyle=5,ystyle=5,title='!CQ='+strtrim(string(q),2),col=green
oplot,/polar,sin(azonloc(hrs,q)),(hrs-6)/12.0*!pi,col=green
oplot,/polar,sin(azonloc(hrs,q,/pole)),(hrs-6)/12.0*!pi,col=green
;xyouts,(psouth(0)+psouth(2))/2,psouth(1)-.035*512,/dev,'Lat: ',al=1.0
;xyouts,(psouth(0)+psouth(2))/2,psouth(1)-.07*512,/dev,'Lon: ',al=1.0
xyouts,(psouth(0)+psouth(2))/2, $
       psouth(1)-1.5*!d.y_ch_size/!d.y_size, $
       /norm,'Lat: ',al=1.0
xyouts,(psouth(0)+psouth(2))/2, $
       psouth(1)-3.0*!d.y_ch_size/!d.y_size, $
       /norm,'Lon: ',al=1.0

;Make status titles
;pstatus=[1.05,.6,1.25,.9]*512
;plot,/noe,[1],pos=pstatus,/dev,xrange=[0,1],xstyle=5,yrange=[0,1],ystyle=5, $
;     title='Status'
pstatus=[1.0/ar+3.0*!d.x_ch_size/!d.x_size,.6,1.0,.9]
plot,/noe,[1],pos=pstatus,xrange=[0,1],xstyle=5,yrange=[0,1],ystyle=5, $
     title='Status'
xyouts,0,.85,'RealTime:!C!COrbit:!C!CQ=3:!C!CQ=6:!C!CEclipse:!C!C'+ $
             'Station:!C!CElev:!C!CRange:'

;Make world map
case map_type of
  'polar': begin
    map_proj=1
    if(map_mode eq 0) then begin
      gs_view=[90,0,-90,0]
      strleft='North Polar'
      strright='South Polar'
    endif else begin
      gs_view=[90,0,90,0]
      strleft='North Polar'
      strright=strtrim(string(map_zoom_ang,form='(f7.1)'),2)+'-Degree Zoom'
    endelse
  end
  'tangent_gs': begin
    map_proj=1
    if(map_mode eq 0) then begin
;      if(tmstation(gs_proj).lat ge 0) then begin
        gs_view=[tmstation(gs_proj).lat,tmstation(gs_proj).lon, $
                -tmstation(gs_proj).lat,((tmstation(gs_proj).lon+360) mod 360)-180]
        strleft=tmstation(gs_proj).name
        strright=''
;      endif else begin
;        gs_view=[-tmstation(gs_proj).lat,((tmstation(gs_proj).lon+360) mod 360)-180, $
;                tmstation(gs_proj).lat,tmstation(gs_proj).lon]
;        strleft=''
;        strright=tmstation(gs_proj).name
;      endelse
    endif else begin
      gs_view=[tmstation(gs_proj).lat,tmstation(gs_proj).lon]
      strleft=tmstation(gs_proj).name
      strright=strtrim(string(map_zoom_ang,form='(f7.1)'),2)+'-Degree Zoom'
    endelse
  end
  else: map_proj=0
endcase
psave=!p.position
case map_proj of
  0: begin
    pmap=[0,0,.75,.5]
    !p.position=pmap
    map_set,/noe,0,0,0,lim=lim,/cont,col=blue
    oplot,tmstation.lon,tmstation.lat,psym=1,thick=2,col=yellow
  end
  1: begin
    plots,[0,.75,.75,0,0],[0,0,.5,.5,0],/norm,col=blue
    pmap=[[0,0,.375,.469],[.375,0,.75,.469]]
    !p.position=pmap(*,0)
    map_set,/noe,/nob,gs_view(0),gs_view(1),0,/cont,/ortho,col=blue
    plots,tmstation.lon,tmstation.lat,psym=1,thick=2,col=yellow
; Factor of 0.4 in ranges is empirically determined.
    plot,/noe,/polar,replicate(1.0,361),findgen(361)/360*2*!pi, $
         xrange=[-1,1]*(!p.position(2)-!p.position(0))/ $
           (!p.position(2)-!p.position(0)-0.4*float(!d.x_ch_size)/!d.x_size), $
         yrange=[-1,1]*(!p.position(3)-!p.position(1))/ $
           (!p.position(3)-!p.position(1)-0.4*float(!d.y_ch_size)/!d.y_size), $
         xstyle=5,ystyle=5,col=blue
    xyouts,(!p.position(0)+!p.position(2))/2,!p.position(3), $
           strleft,col=blue,/norm,al=0.5
    !p.position=pmap(*,1)
    if(map_mode eq 0) then begin
      map_set,/noe,/nob,gs_view(2),gs_view(3),0,/cont,/ortho,col=blue
      map_zoom_clip=pmap(*,1)*[!d.x_size,!d.y_size,!d.x_size,!d.y_size]
      plots,tmstation.lon,tmstation.lat,psym=1,thick=2,col=yellow
; Factor of 0.4 in ranges is empirically determined.
      plot,/noe,/polar,replicate(1.0,361),findgen(361)/360*2*!pi, $
           xrange=[-1,1]*(!p.position(2)-!p.position(0))/ $
            (!p.position(2)-!p.position(0)-0.4*float(!d.x_ch_size)/!d.x_size), $
           yrange=[-1,1]*(!p.position(3)-!p.position(1))/ $
            (!p.position(3)-!p.position(1)-0.4*float(!d.y_ch_size)/!d.y_size), $
           xstyle=5,ystyle=5,col=blue
      xyouts,(!p.position(0)+!p.position(2))/2,!p.position(3), $
             strright,col=blue,/norm,al=0.5
    endif else begin
      map_set,/noe,/nob,gs_view(0),gs_view(1),0,/ortho
      if(gs_view(0)+map_zoom_ang ge 90) then begin
;        map_zoom_region=[gs_view(0)-map_zoom_ang,-180,90,180]
;        pts2=ll_arc_distance(gs_view([1,0]),map_zoom_ang*!dtor,90,/deg)
;        map_zoom_win=[pmap(0,1),pmap(1,1), $
;          pmap(2,1),pmap(3,1)*(90-gs_view(0)+map_zoom_ang)/map_zoom_ang]
;        extent=fltarr(2,361)
;      for j=0,360 do extent(*,j)= $
;        ll_arc_distance(gs_view([1,0]),map_zoom_ang*!dtor*0.999,j,/deg)
;        for i=0,3 do begin $
;          map_set,/noe,/cont,/grid,/ortho,gs_view(0),gs_view(1), $
;                  lim=[gs_view(0)-map_zoom_ang,gs_view(1)+90*i, $
;                  gs_view(0)+map_zoom_ang,gs_view(1)+90*(1+i)],col=blue &$
;      plots,extent,col=blue
;        for i=0,3 do begin $
;          !p.position=[pmap(0,1)+((pmap(2,1)-pmap(0,1))/2)*(1-i/2), $
;                       pmap(1,1)+((pmap(3,1)-pmap(1,1))/2)*((i eq 1) or (i eq 2)), $
;                       pmap(2,1)-((pmap(2,1)-pmap(0,1))/2)*(i/2), $
;                       pmap(3,1)-((pmap(3,1)-pmap(1,1))/2)*((i eq 0) or (i eq 3))] &$
;          map_set,/noe,/nob,gs_view(0),gs_view(1),0,/cont,/ortho,col=blue, $
;                  lim=[gs_view(0)-map_zoom_ang,gs_view(1)+90*i, $
;                  gs_view(0)+map_zoom_ang,gs_view(1)+90*(1+i)]
          
      endif else begin
        pts0=ll_arc_distance(gs_view([1,0]),2.3*map_zoom_ang*!dtor,270,/deg)
        pts2=ll_arc_distance(gs_view([1,0]),2.3*map_zoom_ang*!dtor,90,/deg)
        lat1=gs_view(0)+map_zoom_ang
        lon1=gs_view(1)
        map_zoom_region=[pts0([1,0]),lat1,lon1, $
                         pts2([1,0]),gs_view(0)-map_zoom_ang,gs_view(1)]
        map_zoom_win=[pmap(0,1)-(pmap(2,1)-pmap(0,1))*1.3/2,pmap(1,1), $
                      pmap(2,1)+(pmap(2,1)-pmap(0,1))*1.3/2,pmap(3,1)]
      endelse
      map_set,/noe,/nob,gs_view(0),gs_view(1),0,/ortho,lim=map_zoom_region, $
              pos=map_zoom_win
      map_zoom_clip=pmap(*,1)*[!d.x_size,!d.y_size,!d.x_size,!d.y_size]
      !p.clip=map_zoom_clip
      map_continents,col=blue
      plots,tmstation.lon,tmstation.lat,psym=1,thick=2,col=yellow
      extent=fltarr(2,361)
      for i=0,360 do extent(*,i)= $
        ll_arc_distance(gs_view([1,0]),map_zoom_ang*!dtor*0.999,i,/deg)
      plots,extent,col=blue
    endelse
    xyouts,(!p.position(0)+!p.position(2))/2,!p.position(3), $
           strright,col=blue,/norm,al=0.5
  end
  else:
endcase
!p.position=psave

;Make alt/vel display
palt=[.82,.05,.85,.45]
plot,/noe,/nod,[1],pos=palt,/norm,xrange=[0,1],xstyle=5,yrange=[0,5000],ystyle=9, $
     ticklen=.4,yticks=5,yminor=4,title='Alt'
pvel=[.92,.05,.95,.45]
plot,/noe,/nod,[1],pos=pvel,/norm,xrange=[0,1],xstyle=5,yrange=[0,10],ystyle=9, $
     ticklen=.4,yticks=5,yminor=4,title='Vel'

if(!d.name eq 'PS') then plots,[0,1,1,0,0],[0,0,1,1,0],/norm

return
end
