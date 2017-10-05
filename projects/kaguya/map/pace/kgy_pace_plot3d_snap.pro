;+
; PROCEDURE:
;       kgy_pace_plot3d_snap
; PURPOSE:
;       Plots 3D snapshots for times selected with the cursor in a tplot window.
;       Hold down the left mouse button and slide for a movie effect.
; CALLING SEQUENCE:
;       plot3d_options,map='cylindrical'
;       kgy_pace_plot3d_snap,/log,units='counts',zrange=[1,100]
; KEYWORDS:
;       frame: 'MOON_ME', 'SSE', 'GSE', or 'SELENE_M_SPACECRAFT'
;              (Def. 'SELENE_M_SPACECRAFT')
;       window: window number (Def. a new window will be generated)
;       sensor: sensor number (Def. selected according to the clicked tplot)
;               0: ESA-S1, 1: ESA-S2, 2: IMA, 3: IEA
;       keepwin: do not delete the snap window
;       other keyword will be passed to plot3d_new
; CREATED BY:
;       Yuki Harada on 2016-09-17
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-09-17 15:54:11 -0700 (Sat, 17 Sep 2016) $
; $LastChangedRevision: 21852 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_pace_plot3d_snap.pro $
;-

pro kgy_pace_plot3d_snap, frame=frame, window=window, sensor=sensor, infoangle=infoangle, keepwin=keepwin, _extra=_extra

if size(sensor,/type) ne 0 then sens = long(sensor[0]) else sens = -1

dsize = get_screen_size()
if keyword_set(window) then Dwin = window else begin
   window, /free, xsize=dsize[0]/2., ysize=dsize[1]*2./3.,xpos=0., ypos=0.
   Dwin = !d.window
endelse

print, 'Use button 1 to select time; button 3 to quit.'

ctime,t,npoints=1,/silent,vname=vname

ok = 1
while (ok) do begin

   get3d_func = 'kgy_esa1_get3d'
   if strmatch(vname,'*esa1*') eq 1 then get3d_func = 'kgy_esa1_get3d'
   if strmatch(vname,'*esa2*') eq 1 then get3d_func = 'kgy_esa2_get3d'
   if strmatch(vname,'*ima*') eq 1 then get3d_func = 'kgy_ima_get3d'
   if strmatch(vname,'*iea*') eq 1 then get3d_func = 'kgy_iea_get3d'
   if sens eq 0 then get3d_func = 'kgy_esa1_get3d'
   if sens eq 1 then get3d_func = 'kgy_esa2_get3d'
   if sens eq 2 then get3d_func = 'kgy_ima_get3d'
   if sens eq 3 then get3d_func = 'kgy_iea_get3d'

   d = call_function(get3d_func,t,infoangle=infoangle,/sabin)

   if keyword_set(frame) then d = kgy_pace_convert_frame(d,new=frame)

   wset,Dwin
   newene = total(d.energy*d.bins,2)/total(d.bins,2) ;- get energies right
   str_element,d,'energy',rebin(newene,d.nenergy,d.nbins),/add
   plot3d_new,d,_extra=_extra

   ctime,t,npoints=1,/silent,vname=vname
   if (data_type(t) eq 5) then ok = 1 else ok = 0
endwhile

if ~keyword_set(keepwin) then wdelete,Dwin

end
