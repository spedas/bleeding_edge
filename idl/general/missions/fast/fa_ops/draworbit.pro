;;  @(#)draworbit.pro	1.2 12/15/94   Fast orbit display program

pro draworbit

@fastorb.cmn
@fastorbdisp.cmn
@colors.cmn

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
    plots,rdvec(0).lng,rdvec(0).lat
    for i=0,nbreak do plots,rdvec(break(i)+1:break(i+1)).lng, $
                            rdvec(break(i)+1:break(i+1)).lat, $
                            col=pltcol(stat(break(i)+1:break(i+1))), $
                            /cont,thick=2
  end
  1: begin
    !p.position=pmap(*,0)
    map_set,/noe,/nob,gs_view(0),gs_view(1),0,/ortho
    plots,rdvec(0).lng,rdvec(0).lat
    for i=0,nbreak do plots,rdvec(break(i)+1:break(i+1)).lng, $
                            rdvec(break(i)+1:break(i+1)).lat, $
                            col=pltcol(stat(break(i)+1:break(i+1))), $
                            /cont,thick=2
    !p.position=pmap(*,1)
    if(map_mode eq 0) then map_set,/noe,/nob,gs_view(2),gs_view(3),0,/ortho $
    else begin
      map_set,/noe,/nob,gs_view(0),gs_view(1),0,/ortho,lim=map_zoom_region, $
              pos=map_zoom_win
      !p.clip=map_zoom_clip
    endelse
    plots,rdvec(0).lng,rdvec(0).lat,noclip=0
    for i=0,nbreak do plots,rdvec(break(i)+1:break(i+1)).lng, $
                            rdvec(break(i)+1:break(i+1)).lat, $
                            col=pltcol(stat(break(i)+1:break(i+1))), $
                            /cont,thick=2,noclip=0
  end
  else:
endcase
!p.position=psave

  for j=0,3 do begin
    north=where((rdvec.ilat gt 0.0) and (stat eq j),nnorth)
    if(nnorth gt 0l) then begin
      break=[-1l,where(north(1:*)-north ne 1l,nbreak),nnorth-1]
      if(nbreak le 0l) then break=break([0,2])
      for i=0,nbreak do $
        plot,/noe,/polar,[cos(rdvec(north(break(i)+1:break(i+1))).ilat*!dtor)],$
             [(rdvec(north(break(i)+1:break(i+1))).mlt/12.0-0.5)*!pi],  $
             pos=pnorth,xrange=[-1,1],xstyle=5,yrange=[-1,1],ystyle=5, $
             col=pltcol(j)
    endif
    south=where((rdvec.ilat lt 0.0) and (stat eq j),nsouth)
    if(nsouth gt 0l) then begin
      break=[-1l,where(south(1:*)-south ne 1l,nbreak),nsouth-1]
      if(nbreak le 0l) then break=break([0,2])
      for i=0,nbreak do $
        plot,/noe,/polar,[cos(rdvec(south(break(i)+1:break(i+1))).ilat*!dtor)],$
             [(rdvec(south(break(i)+1:break(i+1))).mlt/12.0-0.5)*!pi],  $
             pos=psouth,xrange=[1,-1],xstyle=5,yrange=[-1,1],ystyle=5, $
             col=pltcol(j)
    endif
  endfor
  !p.position=psave

return
end
