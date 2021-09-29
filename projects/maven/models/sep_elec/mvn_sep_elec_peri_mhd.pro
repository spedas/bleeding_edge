;20180517 Ali
;loads the mhd magnetic field data

pro mvn_sep_elec_peri_mhd,mhd=mhd,bxyz=bijk,b1xyz=b1ijk,rxyz=rijk,plot=plot,save=save,p3d=p3d

  folder='/home/rahmati/Desktop/crustalb/'
  case mhd of
    1: begin
      file='3d__mhd_6_n0040000_int_1000km' ;3deg resolution
      start=12
      ijk=[3,91,61,121]; [3,r,t,p]
    end
    2: begin
      file='3d__ful_6_n0100000_int_1000km' ;1deg resolution
      start=15
      ijk=[3,91,181,361]; [3,r,t,p]
    end
;    3: ;old time-dependent mhd with wrong crustal fields
    ;time='2017/09/13 03:20:34'

    4: begin
      file='3d__ful_6_t_n_int1000km' ;new time-dependent mhd
      time='2017/09/12 22:00:00' ;this is the time for b[*,*,*,3]. next time steps are 5 min apart.
    end
    5: begin ;save the time-dependent field in one single file
      start=15
      ijk=[3,91,61,121]; [3,r,t,p]
      filename=folder+file+'/3d__ful_6_t*_n*_int1000km.dat' ;1deg resolution
      files=file_search(filename)
      nt=n_elements(files)
      bt2=replicate(0.,[ijk,nt])
      bt1=bt2
      for it=0,nt-1 do begin
        bdata=read_ascii(files[it],data_start=start)
        b2=reform(bdata.field1[3:5,*],ijk)
        b1=reform(bdata.field1[6:8,*],ijk)
        bt2[*,*,*,*,it]=b2
        bt1[*,*,*,*,it]=b1
      endfor
      save,bt1,bt2,file=folder+file+'.sav'
    end
  endcase

  if keyword_set(save) then begin
    bdata=read_ascii(folder+file+'.dat',data_start=start)
    r=bdata.field1[0:2,*]
    b=bdata.field1[3:5,*]
    if mhd eq 1 then save,r,b,file=folder+file+'.sav' else begin
      b1=bdata.field1[6:8,*]
      save,r,b,b1,file=folder+file+'.sav'
    endelse
  endif

  restore,folder+file+'.sav'
  if mhd le 2 then begin
    rmars=3396. ;km
    rijk=rmars*reform(r,ijk)
    bijk=reform(b,ijk)
  endif else begin
    
  bijk=bt2 ;total
  b1ijk=bt1 ;induced (draped)
  sizeb=size(bijk,/dim)
;  if mhd ge 2 then b1ijk=reform(b1,ijk)
  endelse

  if keyword_set(plot) then begin
    b0=bijk-b1ijk ;crustal field
;    p=image(transpose(reform(b0[0,5,*,*])),rgb=colortable(70,/reverse),margin=0,min=-100,max=100)
;    p=colorbar(title='Crustal Field (nT)')
    
    for i=0,sizeb[4]-1 do begin
      timestr=time_string(time_double(time)+60.*5.*(i-3))
      p=getwindows('mvn_mhd')
      if keyword_set(p) then p.setcurrent else p=window(name='mvn_mhd',dimensions=[700,1000])
      p=plot(/current,layout=[1,3,1],margin=.1,[0],/nodat,xrange=[0,360],yrange=[-90,90],title='Bx',xtitle='MSO East Longitude',ytitle='MSO Latitude',xtickinterval=45.,ytickinterval=45.,xminor=8.,yminor=8.)
      p=image(/o,transpose(reform(b1ijk[0,10,*,*,i])),360.*findgen(sizeb[3])/sizeb[3],180.*findgen(sizeb[2])/sizeb[2]-90.,rgb=colortable(70,/reverse),min=-40,max=40)
      p=plot(/current,layout=[1,3,2],margin=.1,[0],/nodat,xrange=[0,360],yrange=[-90,90],title='By',xtitle='MSO East Longitude',ytitle='MSO Latitude',xtickinterval=45.,ytickinterval=45.,xminor=8.,yminor=8.)
      p=image(/o,transpose(reform(b1ijk[1,10,*,*,i])),360.*findgen(sizeb[3])/sizeb[3],180.*findgen(sizeb[2])/sizeb[2]-90.,rgb=colortable(70,/reverse),min=-40,max=40)
      p=plot(/current,layout=[1,3,3],margin=.1,[0],/nodat,xrange=[0,360],yrange=[-90,90],title='Bz',xtitle='MSO East Longitude',ytitle='MSO Latitude',xtickinterval=45.,ytickinterval=45.,xminor=8.,yminor=8.)
      p=image(/o,transpose(reform(b1ijk[2,10,*,*,i])),360.*findgen(sizeb[3])/sizeb[3],180.*findgen(sizeb[2])/sizeb[2]-90.,rgb=colortable(70,/reverse),min=-40,max=40)
      p=colorbar(title='nT',target=p,/orient,position=[.95,.3,1,.7])
      p=text(0,.99,timestr+' Draped Field at 200 km')
      p.save,'mhd_draped_200km.pdf',/append,close=i eq sizeb[4]-1
      p.erase
    endfor

  endif

  if keyword_set(p3d) then begin
    a=10000
    b=30
;    plot_3dbox,reform(r[0,b*lindgen(a)]),reform(r[1,b*lindgen(a)]),reform(r[2,b*lindgen(a)]),psym=1
    for i=0,a do p=plot3d(reform(r[0,b*i]),reform(r[1,b*i]),reform(r[2,b*i]),'.',/aspect_r,/aspect_z,/o)
  endif

end