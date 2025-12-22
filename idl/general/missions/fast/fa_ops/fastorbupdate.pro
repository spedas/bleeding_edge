;;  @(#)fastorbupdate.pro	1.2 12/15/94   Fast orbit display program

pro fastorbupdate,first=first,last=last

; Provides "animation" of orbit display.  First call causes data file to be
; read and orbit to be plotted.  Subsequent calls move satellite and update
; clock, etc.

@fastorb.cmn
@fastorbdisp.cmn
@fastorbtimer.cmn

if(keyword_set(first)) then begin
  if(not keyword_set(last)) then fastorbfileread
; Plot orbit on map.
  wset,winanimtempl
  draworbit
if(keyword_set(last)) then return
  curvec=0l
  playstart=rdvec(curvec).time
  rtstart=systime(1)
endif

wset,winanimdraw
device,copy=[0,0,640,512,0,0,winanimtempl]
; Find out which vector to use based on system time and play speed.
playtime=(systime(1)-rtstart)*playspeed+playstart
if(((playtime-rdvec(satdesc(rdvec(curvec).satptr).ndata-1).time) gt  $
     playspeed*rtint) and (satdescindx lt n_elements(satdesc)-1)) then begin
  satdescindx=satdescindx+1
  widget_control,wa,/hour
  fastorbgetdata
  fastorbupdate,/first,/last
  wset,winanimdraw
  playstart=playstart- $
    (satdesc(satdescindx).epochyr-satdesc(satdescindx-1).epochyr)*365l*86400 - $
    (satdesc(satdescindx).epochdoy-satdesc(satdescindx-1).epochdoy)*86400 - $
    (satdesc(satdescindx).epochhr-satdesc(satdescindx-1).epochhr)*3600 - $
    (satdesc(satdescindx).epochmin-satdesc(satdescindx-1).epochmin)*60 - $
    satdesc(satdescindx).epochsec-satdesc(satdescindx-1).epochsec            
  playtime=(systime(1)-rtstart)*playspeed+playstart
endif
dum=min(abs(playtime-rdvec.time),curvec)
drawpos
wset,fastorbwin
device,copy=[0,0,640,512,0,0,winanimdraw]
return
end
