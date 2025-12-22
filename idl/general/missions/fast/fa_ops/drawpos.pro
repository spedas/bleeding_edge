;;  @(#)drawpos.pro	1.2 12/15/94   Fast orbit display program

pro drawpos

@fastorb.cmn
@fastorbdisp.cmn
@fastorbtimer.cmn
@colors.cmn

; Clock stuff
sec=round(satdesc(rdvec(curvec).satptr).epochsec+rdvec(curvec).time)
min=satdesc(rdvec(curvec).satptr).epochmin+sec/60
sec=sec mod 60
hour=satdesc(rdvec(curvec).satptr).epochhr+min/60
min=min mod 60
doy=satdesc(rdvec(curvec).satptr).epochdoy+hour/24
hour=hour mod 24
year=satdesc(rdvec(curvec).satptr).epochyr+doy/ $
     (365+((satdesc(rdvec(curvec).satptr).epochyr mod 4) eq 0))
doy=doy mod (365+((satdesc(rdvec(curvec).satptr).epochyr mod 4) eq 0))
plot,/polar,/noe,[-.1,0.6],[1,1]*(2.9-(hour mod 12)-min/60.0)/6.0*!pi,  $
     pos=pclock,xrange=[-1,1],xstyle=5,yrange=[-1,1],ystyle=5,thick=5
plot,/polar,/noe,[-.15,0.8],[1,1]*(15-min)/30.0*!pi,  $
     pos=pclock,xrange=[-1,1],xstyle=5,yrange=[-1,1],ystyle=5,thick=2
timstr=string(hour,min,form='(2i2.2)')+':'+string(sec,form='(i2.2)')
xyouts,(pclock(0)+pclock(2))/2,pclock(1)-1.5*!d.y_ch_size/!d.y_size, $
       /norm,timstr,al=0.5
datstr='Day '+string(doy,form='(i3.3)')+' '+string(year,form='(i4.4)')
xyouts,(pclock(0)+pclock(2))/2,pclock(1)-3.0*!d.y_ch_size/!d.y_size, $
       /norm,datstr,al=0.5

; ILAT-MLT plots.
if(rdvec(curvec).ilat ge 0) then plot,/noe,/polar,[cos(rdvec(curvec).ilat*!dtor)], $
              [(rdvec(curvec).mlt/12.0-0.5)*!pi],  $
              pos=pnorth,/norm,xrange=[-1,1],xstyle=5,yrange=[-1,1],ystyle=5, $
              col=pltcol(stat(curvec)),psym=4,thick=2 $
else plot,/noe,/polar,[cos(rdvec(curvec).ilat*!dtor)], $
              [(rdvec(curvec).mlt/12.0-0.5)*!pi],  $
              pos=psouth,/norm,xrange=[1,-1],xstyle=5,yrange=[-1,1],ystyle=5, $
              col=pltcol(stat(curvec)),psym=4,thick=2
cglatstr=' '+strtrim(string(rdvec(curvec).ilat,format='(f8.2)'),2)
xyouts,(pnorth(0)+pnorth(2))/2,pnorth(1)-1.5*!d.y_ch_size/!d.y_size, $
      /norm,cglatstr
mltstr=' '+string(fix(rdvec(curvec).mlt+1.0/120.0),format='(i2.2)')+ $
       string((fix((rdvec(curvec).mlt+1.0/120.0)*60) mod 60.0),format='(i2.2)')
xyouts,(pnorth(0)+pnorth(2))/2,pnorth(1)-3.0*!d.y_ch_size/!d.y_size, $
       /norm,mltstr
latstr=' '+strtrim(string(rdvec(curvec).lat,format='(f8.2)'),2)
xyouts,(psouth(0)+psouth(2))/2,psouth(1)-1.5*!d.y_ch_size/!d.y_size, $
       /norm,latstr
lonstr=' '+strtrim(string(rdvec(curvec).lng,format='(f8.2)'),2)
xyouts,(psouth(0)+psouth(2))/2,psouth(1)-3.0*!d.y_ch_size/!d.y_size, $
       /norm,lonstr

; Status annotations.
orbitno=satdesc(rdvec(curvec).satptr).orbit
qstr=['SubAur','AurZon','PolCap']
cglatequ3=azonloc(rdvec(curvec).mlt,3,/lat,/deg)
cglatpol3=azonloc(rdvec(curvec).mlt,3,/pole,/lat,/deg)
cglatequ6=azonloc(rdvec(curvec).mlt,6,/lat,/deg)
cglatpol6=azonloc(rdvec(curvec).mlt,6,/pole,/lat,/deg)
if(abs(rdvec(curvec).ilat) ge cglatpol3) then q3str=qstr(2) $
else if(abs(rdvec(curvec).ilat) ge cglatequ3) then q3str=qstr(1) $
else q3str=qstr(0)
if(abs(rdvec(curvec).ilat) ge cglatpol6) then q6str=qstr(2) $
else if(abs(rdvec(curvec).ilat) ge cglatequ6) then q6str=qstr(1) $
else q6str=qstr(0)
statusstr=(['N','Y'])(playmode)+'!C!C'+string(orbitno)+'!C!C'+ $
          q3str+'!C!C'+q6str+'!C!C'+'?'
plot,/noe,/nod,[1],pos=pstatus,/norm,xrange=[0,1],xstyle=5,yrange=[0,1],ystyle=5
xyouts,.95,.85,statusstr,al=1
if((stat(curvec) and 2) eq 0) then viewstr='None!C!C--!C!C--' $
else begin
  stations=where(gstatlook(1,curvec,*) ge tmstation.elevmin)
  range=min(gstatlook(0,curvec,stations),station)
  station=stations(station)
  viewstr=tmstation(station).abbr+'!C!C'+  $
       strtrim(string(gstatlook(1,curvec,station),format='(f8.1)'),2)+'!Eo!N!C!C'+ $
       strtrim(string(round(gstatlook(0,curvec,station)),format='(i10)'),2)
endelse
xyouts,.95,.85,'!C!C!C!C!C!C!C!C!C!C'+viewstr,al=1

; Map plot.
plots,rdvec(curvec).lng,rdvec(curvec).lat,psym=4,thick=2,col=pltcol(stat(curvec))
case map_type of
  'polar': begin
    map_proj=1
  end
  'tangent_gs': begin
    map_proj=1
  end
  else: map_proj=0
endcase
psave=!p.position
break=[0l,where(abs(rdvec(1:*).lng-rdvec.lng) gt 270.0,nbreak),n_elements(rdvec)-1]
if(nbreak eq 0l) then break=break([0,2])
case map_proj of
  0: begin
    !p.position=pmap
    map_set,/noe,/nob,0,0,0
    plots,rdvec(curvec).lng,rdvec(curvec).lat,psym=4,thick=2,col=pltcol(stat(curvec))
  end
  1: begin
    !p.position=pmap(*,0)
    map_set,/noe,/nob,gs_view(0),gs_view(1),0,/ortho
    plots,rdvec(curvec).lng,rdvec(curvec).lat,psym=4,thick=2,col=pltcol(stat(curvec))
    !p.position=pmap(*,1)
    if(map_mode eq 0) then map_set,/noe,/nob,gs_view(2),gs_view(3),0,/ortho $
    else begin
      map_set,/noe,/nob,gs_view(0),gs_view(1),0,/ortho,lim=map_zoom_region, $
              pos=map_zoom_win
      !p.clip=map_zoom_clip
    endelse
    plots,rdvec(curvec).lng,rdvec(curvec).lat,psym=4,thick=2, $
          col=pltcol(stat(curvec)),noclip=0
  end
  else:
endcase
!p.position=psave


alt=rdvec(curvec).alt
altstr=strtrim(string(round(alt)),2)
plot,/noe,pos=palt,/norm,[1],[alt],xrange=[0,1],xstyle=5,  $
     yrange=[0,5000],ystyle=5,/noclip,thick=2,psym=4
xyouts,0.82,.015,/norm,altstr,al=0.5
vel=sqrt(total(rdvec(curvec).vx^2+rdvec(curvec).vy^2+rdvec(curvec).vz^2))
velstr=strtrim(string(vel,form='(f8.3)'),2)
plot,/noe,pos=pvel,/norm,[1],[vel],xrange=[0,1],xstyle=5,  $
     yrange=[0,10],ystyle=5,/noclip,thick=2,psym=4
xyouts,0.92,.015,/norm,velstr,al=0.5


return
end
