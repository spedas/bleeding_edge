function mdd_dot, x, y
  Compile_Opt StrictArr
  return, total(x*y)
end

pro mdd_std_for_gui,xname,yname,  $
  trange=trange,          $;the time range of the input data
  delta_t=delta_t,        $;(optional)Determine the time period to calculate the D/Dt  keyword only for std
  points=points,          $;(optional)Determine the time period to calculate the D/Dt    points=fix(delta_t/dpre)  dpre is the time resolution of the mag data keyword only for std
  std=std,                $;(optional)calculate the structure velocity using STD method
  fl1=fl1,                $;(optional)Change the eigenvector_Nmax component value(+/-) for ploting
  fl2=fl2,                $;(optional)Same as fl1 but change the sign of Nmid component
  fl3=fl3,                $;(optional)Same as fl1 but change the sign of Nmin component
  noexp = noexp

  ;Input:
  ;xname: A string of tplot names of the SC position data.
  ;yname: A string of tplot names of the Magnetic field data.
  ;
  ;Examples1:
  ;MDD_STD,['SC1','SC2','SC3','SC4'],['B1','B2','B3','B4'],trange=trange,points=3,dpre=0.2,/std  Return Eigenvalues and Eigenvectors and Velocity in three eigenvectors' directions as tplot variations
  ;tplot,['SC1_B','lamda_c','Eigenvector_max_c','Eigenvector_mid_c','Eigenvector_min_c','Error_indicator']    MDD_result
  ;tplot,['Bt','Vstructure_c','V_max_c','V_mid_c','V_min_c','Vstructure1_c']    STD_result
  ;Examples2:
  ;MDD_STD,['SC1','SC2','SC3','SC4'],['B1','B2','B3','B4'],trange=trange,dpre=4,points=3,files='C:\user\Desktop\',/std,/clear         Export two png images stored in the path
  ;written by S.C.Bai 2015.09

  if ~undefined(trange) && n_elements(trange) eq 2 $
    then trange = timerange(trange) $
  else trange = timerange()

  if n_elements(xname) ne 4 or n_elements(yname) ne 4 then begin
    print,'Error:MDD&STD must be done with four spacecraft data!'
    return
  endif

  if not keyword_set(points) and not keyword_set(delta_t) then points=1.0
  if not keyword_set(fl1) then fl1=2.0
  if not keyword_set(fl2) then fl2=0.0
  if not keyword_set(fl3) then fl3=1.0


  for i=0,3 do begin
    tinterpol,xname[i],yname[0],/overwrite
  endfor

  get_data,yname[0],data=mag1   &   get_data,xname[0],data=pos1
  get_data,yname[1],data=mag2   &   get_data,xname[1],data=pos2
  get_data,yname[2],data=mag3   &   get_data,xname[2],data=pos3
  get_data,yname[3],data=mag4   &   get_data,xname[3],data=pos4

  aaa=mag1.x[1:n_elements(mag1.x)-1]-mag1.x[0:n_elements(mag1.x)-2]
  his=histogram(aaa)
  dpre=aaa[where(his eq max(his))]
  delvar,aaa,his

  if keyword_set(delta_t) then points=fix(delta_t/dpre[0])
  exp=points*dpre[0]

  if keyword_set(noexp) then exp=0
  index1=where(mag1.x ge time_double(trange[0])-exp and mag1.x le time_double(trange[1])+exp)
  store_data,'mag1',data={x:mag1.x[index1],y:mag1.y[index1,*]}
  index2=where(mag2.x ge time_double(trange[0])-exp and mag2.x le time_double(trange[1])+exp)
  store_data,'mag2',data={x:mag2.x[index2],y:mag2.y[index2,*]}
  index3=where(mag3.x ge time_double(trange[0])-exp and mag3.x le time_double(trange[1])+exp)
  store_data,'mag3',data={x:mag3.x[index3],y:mag3.y[index3,*]}
  index4=where(mag4.x ge time_double(trange[0])-exp and mag4.x le time_double(trange[1])+exp)
  store_data,'mag4',data={x:mag4.x[index4],y:mag4.y[index4,*]}

  tinterpol,'mag2','mag1',/overwrite
  tinterpol,'mag3','mag1',/overwrite
  tinterpol,'mag4','mag1',/overwrite

  get_data,'mag1',data=mag1
  get_data,'mag2',data=mag2
  get_data,'mag3',data=mag3
  get_data,'mag4',data=mag4

  index1=where(pos1.x ge time_double(trange[0])-exp and pos1.x le time_double(trange[1])+exp)
  store_data,'pos1',data={x:pos1.x[index1],y:pos1.y[index1,*]}
  get_data,'pos1',data=pos1
  index2=where(pos2.x ge time_double(trange[0])-exp and pos2.x le time_double(trange[1])+exp)
  store_data,'pos2',data={x:pos2.x[index2],y:pos2.y[index2,*]}
  get_data,'pos2',data=pos2
  index3=where(pos3.x ge time_double(trange[0])-exp and pos3.x le time_double(trange[1])+exp)
  store_data,'pos3',data={x:pos3.x[index3],y:pos3.y[index3,*]}
  get_data,'pos3',data=pos3
  index4=where(pos4.x ge time_double(trange[0])-exp and pos4.x le time_double(trange[1])+exp)
  store_data,'pos4',data={x:pos4.x[index4],y:pos4.y[index4,*]}
  get_data,'pos4',data=pos4

  if not keyword_set(points) and keyword_set(delta_t) then points=fix(delta_t/dpre)

  sc_d_11 = [[pos1.x],[pos1.y - pos3.y]]
  sc_d_12 = [[pos2.x],[pos2.y - pos3.y]]
  sc_d_13 = [[pos3.x],[pos3.y - pos3.y]]
  sc_d_14 = [[pos4.x],[pos4.y - pos3.y]]

  mag_ave=(mag1.y+mag2.y+mag3.y+mag4.y)/4.0
  time_ave=(mag1.x+mag2.x+mag3.x+mag4.x)/4.0

  btotal1=[[mag1.x],[sqrt(mag1.y[*,0]^2+mag1.y[*,1]^2+mag1.y[*,2]^2)]]
  btotal2=[[mag2.x],[sqrt(mag2.y[*,0]^2+mag2.y[*,1]^2+mag2.y[*,2]^2)]]
  btotal3=[[mag3.x],[sqrt(mag3.y[*,0]^2+mag3.y[*,1]^2+mag3.y[*,2]^2)]]
  btotal4=[[mag4.x],[sqrt(mag4.y[*,0]^2+mag4.y[*,1]^2+mag4.y[*,2]^2)]]

  All_A=dblarr(n_elements(mag1.x),3,3)  &   All_B=dblarr(n_elements(mag1.x))  &   All_C=dblarr(n_elements(mag1.x),3)   &   All_EXP=dblarr(n_elements(mag1.x),2)
  Bx=dblarr(4)   &   By=dblarr(4)   &   Bz=dblarr(4)   &    lamda=dblarr(n_elements(mag1.x),3)   &   Dimention=dblarr(n_elements(mag1.x),3)
  lamda1=dblarr(n_elements(mag1.x))   &   lamda2=dblarr(n_elements(mag1.x))   &   lamda3=dblarr(n_elements(mag1.x))
  egvt1=dblarr(n_elements(mag1.x),3)  &   egvt2=dblarr(n_elements(mag1.x),3)  &   egvt3=dblarr(n_elements(mag1.x),3)

  if keyword_set(std) then begin
    PBx_Pt=dblarr(n_elements(mag1.x))   &   PBy_Pt=dblarr(n_elements(mag1.x))   &   PBz_Pt=dblarr(n_elements(mag1.x))
    N_2d=dblarr(n_elements(mag1.x))     &   Nx_2d=dblarr(n_elements(mag1.x))    &   Ny_2d=dblarr(n_elements(mag1.x))    &   Nz_2d=dblarr(n_elements(mag1.x))
    V_L=dblarr(n_elements(mag1.x),3)   &   V_M=dblarr(n_elements(mag1.x),3)   &   V_N=dblarr(n_elements(mag1.x),3)
    V_L_T=dblarr(n_elements(mag1.x))   &   V_M_T=dblarr(n_elements(mag1.x))   &   V_N_T=dblarr(n_elements(mag1.x))
    V=dblarr(n_elements(mag1.x),3)
    Vx_L=dblarr(n_elements(mag1.x))    &   Vy_L=dblarr(n_elements(mag1.x))    &   Vz_L=dblarr(n_elements(mag1.x))
    Vx_M=dblarr(n_elements(mag1.x))    &   Vy_M=dblarr(n_elements(mag1.x))    &   Vz_M=dblarr(n_elements(mag1.x))
    Vx_N=dblarr(n_elements(mag1.x))    &   Vy_N=dblarr(n_elements(mag1.x))    &   Vz_N=dblarr(n_elements(mag1.x))
    V_x=dblarr(n_elements(mag1.x))      &   V_y=dblarr(n_elements(mag1.x))      &   V_z=dblarr(n_elements(mag1.x))
    V_2d=dblarr(n_elements(mag1.x))     &   Vx_2d=dblarr(n_elements(mag1.x))    &   Vy_2d=dblarr(n_elements(mag1.x))    &   Vz_2d=dblarr(n_elements(mag1.x))
  endif

  for j=0,n_elements(mag1.x)-1 do begin

    r11=sc_d_11[j,1:3]
    r12=sc_d_12[j,1:3]
    r13=sc_d_13[j,1:3]
    r14=sc_d_14[j,1:3]

    Bx[0]=mag1.y[j,0]   &   By[0]=mag1.y[j,1]   &   Bz[0]=mag1.y[j,2]
    Bx[1]=mag2.y[j,0]   &   By[1]=mag2.y[j,1]   &   Bz[1]=mag2.y[j,2]
    Bx[2]=mag3.y[j,0]   &   By[2]=mag3.y[j,1]   &   Bz[2]=mag3.y[j,2]
    Bx[3]=mag4.y[j,0]   &   By[3]=mag4.y[j,1]   &   Bz[3]=mag4.y[j,2]

    Ar=[[r11[0],r11[1],r11[2]],$
      [r12[0],r12[1],r12[2]],$
      [r14[0],r14[1],r14[2]]]

    DBx=[Bx[0]-Bx[2],Bx[1]-Bx[2],Bx[3]-Bx[2]]
    DBy=[By[0]-By[2],By[1]-By[2],By[3]-By[2]]
    DBz=[Bz[0]-Bz[2],Bz[1]-Bz[2],Bz[3]-Bz[2]]

    PBx=DBx#matrix_power(Ar,-1)   &   PBy=DBy#matrix_power(Ar,-1)   &   PBz=DBz#matrix_power(Ar,-1)

    A=[[PBx(0),PBy(0),PBz(0)],$
      [PBx(1),PBy(1),PBz(1)],$
      [PBx(2),PBy(2),PBz(2)]]


    All_A[j,0:2,0:2]=A[0:2,0:2]
    All_B[j]=PBx(0)+PBy(1)+PBz(2);divergence
    All_C[j,0:2]=[PBz(1)-PBy(2),PBx(2)-PBz(0),PBy(0)-PBx(1)]
    All_EXP[j,0]=abs(All_B[j])/sqrt(All_C[j,0:2]#transpose(All_C[j,0:2]))
    All_EXP[j,1]=abs(All_B[j])/max(abs(All_A[j,0:2,0:2]))

    if keyword_set(std) then begin
      if j ge points and j le n_elements(mag1.x)-1-points then begin
        PBx_Pt(j)=(mag_ave(j+points,0)-mag_ave(j-points,0))/((time_ave(j+points)-time_ave(j-points)))
        PBy_Pt(j)=(mag_ave(j+points,1)-mag_ave(j-points,1))/((time_ave(j+points)-time_ave(j-points)))
        PBz_Pt(j)=(mag_ave(j+points,2)-mag_ave(j-points,2))/((time_ave(j+points)-time_ave(j-points)))
      endif else  begin
        PBx_Pt(j)=0   &    PBy_Pt(j)=0   &    PBz_Pt(j)=0
      endelse
    endif
  endfor

  for j=0,n_elements(mag1.x)-1 do begin

    A[0:2,0:2]=All_A[j,0:2,0:2]

    A1=transpose(A)#A+0d

    DD = LA_EIGENproblem(A1,eigenvectors = eigenvectors,/double)
    vv=eigenvectors

    if imaginary(DD[0]) eq 0 and imaginary(DD[1]) eq 0 and imaginary(DD[2]) eq 0 then begin
      DDmin=where(abs(DD) eq min([abs(DD[0]),abs(DD[1]),abs(DD[2])]))   &    DDmax=where(abs(DD) eq max([abs(DD[0]),abs(DD[1]),abs(DD[2])]))
      if n_elements(DDmin) gt 1 then continue
      if total([double(DDmin),double(DDmax)]) eq 1 then DDmid=2   &   if total([double(DDmin),double(DDmax)]) eq 2 then DDmid=1   &   if total([double(DDmin),double(DDmax)]) eq 3 then DDmid=0
      lambda1R=real_part(DD[DDmax])   &   lambda2R=real_part(DD[DDmid])   &   lambda3R=real_part(DD[DDmin])
      lambda1I=imaginary(DD[DDmax])   &   lambda2I=imaginary(DD[DDmid])   &   lambda3I=imaginary(DD[DDmin])
      N1=VV(*,DDmax)   &   N2=VV(*,DDmid)   &   N3=VV(*,DDmin);
    endif else begin
      if imaginary(DD[0]) eq 0 then begin
        kk1=0   &   kk2=1   &   kk3=2
      endif
      if imaginary(DD[1]) eq 0 then begin
        kk1=1   &   kk2=0   &   kk3=2;
      endif
      if imaginary(DD[2]) eq 0 then begin
        kk1=2   &   kk2=0   &   kk3=1;
      endif
      lambda1R=real_part(DD[kk3])   &   lambda2R=real_part(DD[kk2])   &   lambda3R=real_part(DD[kk1])
      lambda1I=imaginary(DD[kk3])   &   lambda2I=imaginary(DD[kk2])   &   lambda3I=imaginary(DD[kk1])
      N1=VV(*,kk3)   &   N2=VV(*,kk2)   &   N3=VV(*,kk1)
    endelse
    
    if keyword_set(std) then begin
      PBx_Pt1=PBx_Pt[j]   &   PBy_Pt1=PBy_Pt[j]   &   PBz_Pt1=PBz_Pt[j];
      VINTNeg_PB_pt=-[PBx_Pt1,PBy_Pt1,PBz_Pt1]    &    Vs=VINTNeg_PB_pt#matrix_power([[A[0,0],A[0,1],A[0,2]],[A[1,0],A[1,1],A[1,2]],[A[2,0],A[2,1],A[2,2]]],-1);
      Vs_new_n1=mdd_dot(Vs,N1)
      ;      if Vs_new_n1 le 0 then begin
      ;        Vs_new_n1=-Vs_new_n1;
      ;        N1=-N1;
      ;      endif
      Vs_new_n2=mdd_dot(Vs,N2)
      ;      if Vs_new_n2 le 0 then begin
      ;        Vs_new_n2=-Vs_new_n2;
      ;        N1=-N2;
      ;      endif
      Vs_new_n3=mdd_dot(Vs,N3)
      Vx_L[j]=Vs_new_n1*N1[0]   &   Vy_L[j]=Vs_new_n1*N1[1]   &   Vz_L[j]=Vs_new_n1*N1[2]
      Vx_M[j]=Vs_new_n2*N2[0]   &   Vy_M[j]=Vs_new_n2*N2[1]   &   Vz_M[j]=Vs_new_n2*N2[2]
      Vx_N[j]=Vs_new_n3*N3[0]   &   Vy_N[j]=Vs_new_n3*N3[1]   &   Vz_N[j]=Vs_new_n3*N3[2]
      V_x[j]=Vs[0]   &   V_y[j]=Vs[1]   &   V_z[j]=Vs[2];
      V_2d=Vs_new_n1*N1+Vs_new_n2*N2   &   Vx_2d[j]=V_2d[0]   &   Vy_2d[j]=V_2d[1]   &   Vz_2d[j]=V_2d[2]
      N_2d=N1+N2   &   Nx_2d[j]=N_2d[0]/sqrt(2)   &   Ny_2d[j]=N_2d[1]/sqrt(2)   &   Nz_2d[j]=N_2d[2]/sqrt(2);
    endif

    lamda3[j]=lambda3R   &   lamda2[j]=lambda2R   &   lamda1[j]=lambda1R
    egvt3[j,0]=N3[0]   &   egvt2[j,0]=N2[0]   &   egvt1[j,0]=N1[0]
    egvt3[j,1]=N3[1]   &   egvt2[j,1]=N2[1]   &   egvt1[j,1]=N1[1]
    egvt3[j,2]=N3[2]   &   egvt2[j,2]=N2[2]   &   egvt1[j,2]=N1[2]
  endfor

  for k=0,n_elements(mag1.x)-1 do begin
    if egvt1[k,fl1] lt 0 then begin
      egvt1[k,*]=-egvt1[k,*];
    endif
    if egvt2[k,fl2] lt 0 then begin
      egvt2[k,*]=-egvt2[k,*];
    endif
    if egvt3[k,fl3] lt 0 then begin
      egvt3[k,*]=-egvt3[k,*];
    endif
  endfor

  lamda1=sqrt(lamda1)
  lamda2=sqrt(lamda2)
  lamda3=sqrt(lamda3)

  lamda[*,0]=lamda1  &   lamda[*,1]=lamda2  &   lamda[*,2]=lamda3
  Dimention[*,0]=(lamda1-lamda2)/lamda1
  Dimention[*,1]=(lamda2-lamda3)/lamda1
  Dimention[*,2]=lamda3/lamda1
  if keyword_set(std) then begin
    V[*,0]=V_x        &   V[*,1]=V_y        &   V[*,2]=V_z
    V_L[*,0]=Vx_L   &   V_L[*,1]=Vy_L   &   V_L[*,2]=Vz_L
    V_M[*,0]=Vx_M   &   V_M[*,1]=Vy_M   &   V_M[*,2]=Vz_M
    V_N[*,0]=Vx_N   &   V_N[*,1]=Vy_N   &   V_N[*,2]=Vz_N
    V_L_T=sqrt(V_L[*,0]^2+V_L[*,1]^2+V_L[*,2]^2)
    V_M_T=sqrt(V_M[*,0]^2+V_M[*,1]^2+V_M[*,2]^2)
    V_N_T=sqrt(V_N[*,0]^2+V_N[*,1]^2+V_N[*,2]^2)
    V_T=dblarr(n_elements(mag1.x),2)
    V_T1=dblarr(n_elements(mag1.x))
    V_T1=sqrt(V_L_T^2)
    V_T[*,0]=V_L_T   &    V_T[*,1]=V_M_T
  endif

  store_data,'SC1_Bt',data={x:mag1.x,y:btotal1[*,1]},dlimit={colors:'x'}
  store_data,'SC2_Bt',data={x:mag2.x,y:btotal2[*,1]},dlimit={colors:'r'}
  store_data,'SC3_Bt',data={x:mag3.x,y:btotal3[*,1]},dlimit={colors:'g'}
  store_data,'SC4_Bt',data={x:mag4.x,y:btotal4[*,1]},dlimit={colors:'b'}
  store_data,'Bt',data=['SC1_Bt','SC2_Bt','SC3_Bt','SC4_Bt'],dlimit={colors:['x','b','g','r'],labflag:1,labels:['SC1','SC2','SC3','SC4'],thick:1,ysubtitle:'[nT]'}

  store_data,'Error',data={x:mag1.x,y:all_exp}
  store_data,'Eigenvector_max',data={x:mag1.x,y:egvt1},dlimit={ytitle:'Nmax',labels:['Nmax_x','Nmax_y','Nmax_z'],labflag:1,colors:['b','g','r']}
  store_data,'Eigenvector_mid',data={x:mag1.x,y:egvt2},dlimit={ytitle:'Nmid',labels:['Nmid_x','Nmid_y','Nmid_z'],labflag:1,colors:['b','g','r']}
  store_data,'Eigenvector_min',data={x:mag1.x,y:egvt3},dlimit={ytitle:'Nmin',labels:['Nmin_x','Nmin_y','Nmin_z'],labflag:1,colors:['b','g','r']}
  store_data,'lamda',data={x:mag1.x,y:lamda},dlimit={labels:['!7k!x_max','!7k!x_mid','!7k!x_min'],labflag:-1,colors:['b','g','r'],ytitle:'Square roots !Cof Eigenvalues',ysubtitle:'[nT/km]',ylog:1}
  store_data,'Structure_Dimentions',data={x:mag1.x,y:Dimention},dlimit={labels:['D1','D2','D3'],labflag:-1,colors:['b','g','r'],ytitle:'Rezeau et al!CDimention!Cnumber index',ylog:0}

  options,'lamda', ysubtitle='[nT/km]',labels=['sqrt(!7k!x_max)','sqrt(!7k!x_mid)','sqrt(!7k!x_min)']
  copy_data,'Error','Error_dots'
  copy_data,'Eigenvector_max','Eigenvector_max_dots'
  copy_data,'Eigenvector_mid','Eigenvector_mid_dots'
  copy_data,'Eigenvector_min','Eigenvector_min_dots'
  copy_data,'lamda','lamda_dots'
  copy_data,'Structure_Dimentions','Structure_Dimentions_dots'

  store_data,'lamda_c',data=['lamda','lamda_dots']
  store_data,'Structure_Dimentions_c',data=['Structure_Dimentions','Structure_Dimentions_dots']
  store_data,'Eigenvector_max_c',data=['Eigenvector_max','Eigenvector_max_dots']
  store_data,'Eigenvector_mid_c',data=['Eigenvector_mid','Eigenvector_mid_dots']
  store_data,'Eigenvector_min_c',data=['Eigenvector_min','Eigenvector_min_dots']
  store_data,'Error_indicator',data=['Error','Error_dots'],dlimit={labels:['ABS(!9G . !xB)/ABS(!9GX!xB)','ABS(!9G . !xB)/max(ABS(!9D!xBi/!9D!xj))'],labflag:1,colors:['b','r']}


;  ylim,'lamda',10^(alog10(min(lamda))-1),10^(alog10(max(lamda))+1),1
  ylim,'lamda',1e-5,10^(alog10(max(lamda))+1),1
  ylim,'Error_indicator',0,1

  if keyword_set(std) then begin
    store_data,'Vstructure1',data={x:mag1.x,y:V_T1},dlimit={ytitle:'V!lstr!n_1D',ysubtitle:'[km/s]',colors:['b','g'],labflag:1}
    store_data,'Vstructure',data={x:mag1.x,y:V},dlimit={ytitle:'V!lstr!n_3D',ysubtitle:'[km/s]',colors:['b','g','r'],labels:['Vx','Vy','Vz'],labflag:1}
    store_data,'V_max',data={x:mag1.x,y:V_L},dlimit={ytitle:'V!lmax!n',ysubtitle:'[km/s]',labels:['Vmax_x ','Vmax_y','Vmax_z'],colors:['b','g','r'],labflag:1}
    store_data,'V_mid',data={x:mag1.x,y:V_M},dlimit={ytitle:'V!lmid!n',ysubtitle:'[km/s]',labels:['Vmid_x ','Vmid_y','Vmid_z'],colors:['b','g','r'],labflag:1}
    store_data,'V_min',data={x:mag1.x,y:V_N},dlimit={ytitle:'V!lmin!n',ysubtitle:'[km/s]',labels:['Vmin_x ','Vmin_y','Vmin_z'],colors:['b','g','r'],labflag:1}

    copy_data,'Vstructure1','Vstructure1_dots'
    copy_data,'V_max','V_max_dots'
    copy_data,'V_mid','V_mid_dots'
    copy_data,'V_min','V_min_dots'
    copy_data,'Vstructure','Vstructure_dots'

    store_data,'Vstructure1_c',data=['Vstructure1','Vstructure1_dots']

    store_data,'V_max_c',data=['V_max','V_max_dots']
    store_data,'V_mid_c',data=['V_mid','V_mid_dots']
    store_data,'V_min_c',data=['V_min','V_min_dots']
    store_data,'Vstructure_c',data=['Vstructure','Vstructure_dots']
    v_2d =V_L+ V_M
    store_data,'V_str_2d',data={x:mag1.x,y:v_2d},dlimit={ytitle:'V!lstr!n_2D!C[km/s]',labels:['V!lstr!n_x ','V!lstr!n_y','V!lstr!n_z'],colors:['b','g','r'],labflag:1}
    copy_data,'V_str_2d','V_str_2d_dots'
    store_data,'V_str_2d_c',data=['V_str_2d','V_str_2d_dots']

    ylim,'Vstructure_c',0,0
    ylim,'Vstructure1_c',0,0
    ylim,'V_min_c',0,0
  endif

    split_vec,yname[0]   &   split_vec,yname[1]   &   split_vec,yname[2]   &   split_vec,yname[3]
    store_data,'Bx',data=[yname[0]+'_x',yname[1]+'_x',yname[2]+'_x',yname[3]+'_x'],dlimit={colors:['x','b','g','r'],labflag:1,labels:['SC1','SC2','SC3','SC4'],thick:1}
    store_data,'By',data=[yname[0]+'_y',yname[1]+'_y',yname[2]+'_y',yname[3]+'_y'],dlimit={colors:['x','b','g','r'],labflag:1,labels:['SC1','SC2','SC3','SC4'],thick:1}
    store_data,'Bz',data=[yname[0]+'_z',yname[1]+'_z',yname[2]+'_z',yname[3]+'_z'],dlimit={colors:['x','b','g','r'],labflag:1,labels:['SC1','SC2','SC3','SC4'],thick:1}

    split_vec,yname[0]   &   split_vec,yname[1]   &   split_vec,yname[2]   &   split_vec,yname[3]
    store_data,'SC1_B',data=[yname[0]+'_x',yname[0]+'_y',yname[0]+'_z'],dlimit={colors:['b','g','r'],labflag:1,labels:['Bx','By','Bz']}
    store_data,'SC2_B',data=[yname[1]+'_x',yname[1]+'_y',yname[1]+'_z'],dlimit={colors:['b','g','r'],labflag:1,labels:['Bx','By','Bz']}
    store_data,'SC3_B',data=[yname[2]+'_x',yname[2]+'_y',yname[2]+'_z'],dlimit={colors:['b','g','r'],labflag:1,labels:['Bx','By','Bz']}
    store_data,'SC4_B',data=[yname[3]+'_x',yname[3]+'_y',yname[3]+'_z'],dlimit={colors:['b','g','r'],labflag:1,labels:['Bx','By','Bz']}

  del_data,['pos1','pos2','pos3','pos4','mag1','mag2','mag3','mag4']
end