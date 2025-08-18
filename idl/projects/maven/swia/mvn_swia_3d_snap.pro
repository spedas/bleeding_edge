;+
; PROCEDURE:
;       mvn_swia_3d_snap
; PURPOSE:
;       Plots 3D distributions for the times and data types selected by cursor.
;       Hold down the left mouse button and slide for a movie effect.
; CALLING SEQUENCE:
;       mvn_swia_3d_snap
; INPUTS:
;       
; OPTIONAL KEYWORDS:
;       same as 'plot3d_new' except...
;       ARCHIVE: Returns archive distribution instead of survey
;       ERANGE: Specifies energy range to plot
;       WINDOW: Specifies window to plot (Def: generates new window)
;       STATIC: If set, shows STATIC field of view (SPICE kernels and STATIC CA data need to have been loaded)
;       SPC: If set, draws spacecraft blockage using mvn_spc_fov_blockage
;       MSO: If set, shows MSO +-XYZ
; CREATED BY:
;       Yuki Harada on 2015-04-22
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2015-05-06 09:00:37 -0700 (Wed, 06 May 2015) $
; $LastChangedRevision: 17483 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_3d_snap.pro $
;-

pro mvn_swia_3d_snap, archive=archive, erange=erange, window=window, static=static, spc=spc, mso=mso, _extra=_extra

  if keyword_set(erange) then erange = minmax(erange)

  dsize = get_screen_size()

;- set up windows

;- plot3d window
  if keyword_set(window) then Dwin = window else begin
     window, /free, xsize=dsize[0]/2., ysize=dsize[1]*2./3.,xpos=0., ypos=0.
     Dwin = !d.window
  endelse

  print, 'Use button 1 to select time; button 3 to quit.'

  ctime,t,npoints=1,/silent,vname=vname

  ok = 1
  while (ok) do begin

     get3d_func = 'mvn_swia_get_3dc' ;- coarse by default
     if strmatch(vname,'*swif*') eq 1 then get3d_func = 'mvn_swia_get_3df'

     d = call_function(get3d_func,t,archive=archive)
     if keyword_set(erange) then begin
        ebins = where( average(d.energy,2) gt erange[0] and average(d.energy,2) lt erange[1] , nw )
        if nw eq 0 then begin
           dprint,'No energy bins in the specified erange'
           return
        endif
     endif

     wset,Dwin
     plot3d_new,d,ebins=ebins, _extra=_extra

     if keyword_set(static) then begin ;- cf. Takuya's mvn_sta_3d_snap
        dsta = mvn_sta_get_ca(t)
        w = where( average(dsta.theta,1) gt 0 , nw, complement=cw, ncomplement=ncw )
        csta = bytescale(average(dsta.phi,1), bottom=7, top=254, range=[-180., 180.])
        mvn_pfp_cotrans,dsta,from='MAVEN_STATIC',to='MAVEN_SWIA',theta=thsta,phi=phsta
        thsta = reform(thsta[dsta.nenergy-1,*])
        phsta = reform(phsta[dsta.nenergy-1,*])
        plots,phsta[w],thsta[w],psym=6,color=csta[w]
        plots,phsta[cw],thsta[cw],psym=5,color=csta[cw]
        xyouts, !x.window[0]*1.2, !y.window[1]-!y.window[0]*0.5, 'STATIC FOV, +Z: Square / -Z: Triangle', charsize=!p.charsize, /normal, color=255
        xyouts, !x.window[0]*1.2, !y.window[1]-!y.window[0]*1.1,'STATIC Phi:', charsize=!p.charsize,/normal,color=255
        lsta = [-180,-90,0,90,180]
        clsta = bytescale(lsta, bottom=7, top=254, range=[-180., 180.])
        for i=0, n_elements(lsta)-1 do $
           xyouts, !x.window[0]*1.2 + 0.04*i + 0.1, !y.window[1]-!y.window[0]*1.1, string(lsta[i], '(I0)'), charsize=!p.charsize, /normal, color=clsta[i]
     endif

     if keyword_set(spc) then mvn_spc_fov_blockage,trange=[d.time,d.end_time],/invert_phi,/invert_theta,/swia ;- cf. Roberto's mvn_spc_fov_blockage

     if keyword_set(mso) then begin ;- cf. Takuya's mvn_sta_3d_snap
        xyz = [ [1., 0., 0.], [0., 1., 0.], [0., 0., 1.] ]
        xyzmso = transpose(xyz*0.)
        for iii=0,2 do xyzmso[iii,*] = spice_vector_rotate(xyz[*,iii],(d.time+d.end_time)/2.d,'MAVEN_MSO','MAVEN_SWIA',verb=-1)
        xyz_to_polar,xyzmso,theta=thmso,phi=phmso,/ph_0_360
        plots,phmso,thmso,psym=1,color=[2,4,6], thick=2, symsize=1.5
        plots,phmso+180.,-thmso,psym=4,color=[2,4,6], thick=2, symsize=1.5
        xyouts, !x.window[1], !y.window[0]*1.2, 'MSO XYZ', charsize=!p.charsize, /normal, color=255, align=1.
        xyouts, !x.window[1], !y.window[1]-!y.window[0]*0.5, '(+: Plus / -: Diamond) ', charsize=!p.charsize, /normal, color=255, align=1.
     endif

     ctime,t,npoints=1,/silent,vname=vname
     if (data_type(t) eq 5) then ok = 1 else ok = 0
  endwhile

end
