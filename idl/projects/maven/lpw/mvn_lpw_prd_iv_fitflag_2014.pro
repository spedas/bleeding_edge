pro mvn_lpw_prd_iv_fitflag_2014,data,data_x,data_y,data_dy,data_dv,data_flag,data_boom,data_version    

;how to run
  ;; get_data,'mvn_lpw_swp2_IV',data=data
  ;;mvn_lpw_prd_iv_fitflag_2014,data,data_x,data_y,data_dy,data_dv,data_flag,data_boom


; this is for the early fits where we had sparce sweeps and bidirectional
; time period 2014-10-09 to 2015-01-20 - check endate



;the flag information
; 9999 not a good fit
; 9119  this boom has been by defolt for this time period identified as bad Vsc
; 88888  the SC pot is high and therefore is Ne and TE not reliable but vsc should be provied if reasnoble  - need to be the largest value


;--------------------------------------


SC_pot_thershold = 8 ; the Vsc threshold when Ne and Te is deemed unrelaible


;---------- Read in the data -----------------------

; get the date that is read in:

date=time_string(min(data.x))
result=strsplit(date,'/',/extract)
st=result[0]
print,'Working with date: ',st



;---------------   Change the error bars with time..... -----------------

dnlow=1.
if min(data.x) GT time_double('2015-01-01') then dnlow = 1.5


;------------ Check that the sfiles are there  -----

dir ='/spg/maven/test_products/cmf_temp/'
lpstruc='filled_lpstruc11/'
file1='fitstruc_filled_'+st+'_b1.sav'
file2='fitstruc_filled_'+st+'_b2.sav'


filename1 = file_search(dir+lpstruc,'fitstruc_filled_'+st+'*',count=count)


data_version = ' filled_lpstruc11 '
;-------------------------------------------------


if count EQ 2 then begin     ;  files exists in the structure

  unit=1./8.6173324*1e5  ;change to eV    ; to change eV to K



  ;note we need to get which structure is used....

  mvn_lpw_prd_iv_read_in_structure,dir+lpstruc+file1,1
  mvn_lpw_prd_iv_read_in_structure,dir+lpstruc+file2,2

  get_data,'ree_vswp_1'  ,data=vswp1
  get_data,'ree_iswp_1'  ,data=iswp1
  get_data,'ree_erra_1'  ,data=ErrAIn1
  get_data,'ree_Te_1'    ,data=TeIn1
  get_data,'ree_Ne_1'    ,data=NeIn1
  get_data,'ree_valid_1'  ,data=valid1
  get_data,'ree_vswp_2'  ,data=vswp2
  get_data,'ree_iswp_2'  ,data=iswp2
  get_data,'ree_erra_2'  ,data=ErrAIn2
  get_data,'ree_Te_2'    ,data=TeIn2
  get_data,'ree_Ne_2'    ,data=NeIn2
  get_data,'ree_valid_2'  ,data=valid2

  ;;.r cmf_sweep_info
  result=mvn_lpw_prd_iv_find_points2( vswp1.y, iswp1.y, NeIn1.x, ErrAIn1.y, NeIn1.y, TeIn1.y, valid1.y, vswp2.y, iswp2.y, NeIn2.x, ErrAIn2.y, NeIn2.y, TeIn2.y, valid2.y)

  times1 = NeIn1.x[result[*,0]]
  times2 = NeIn2.x[result[*,1]]
  store_data,'ree_flag_info1',data={x:times1,y:result[*,0]}
  store_data,'ree_flag_info2',data={x:times2,y:result[*,1]}




  ;####################

  st_st=['1','2']

  i=0
  for i=0,1 do begin                  ;loop over the booms
    st=st_st[i]                         ;loop over the booms

    ; altitude

    get_data,'da_alt_iau_'+st,data=datalt    ; use this to get the altitude range

    ; model 1
    get_data,'ree_Ne_'+st      ,data=datxrN
    get_data,'ree_Te_'+st      ,data=datxrT
    get_data,'ree_Vsc_'+st     ,data=datxrV
    get_data,'ree_erra_'+st    ,data=dater
    get_data,'ree_flag_info'+st,data=datfr
    flag=dater.y*0
    flag[datfr.y]=1

    ;model 2
    get_data,'mm_Ne_'+st        ,data=datxmN
    get_data,'mm_Te_'+st        ,data=datxmT
    get_data,'mm_Vsc_'+st       ,data=datxmV
    get_data,'mm_flag_'+st      ,data=datem

    nn=n_elements(datalt.x)       ; number of points to work with

    y_ne = fltarr(nn,5)  * !values.f_nan     ; value  ; lower bound  ; upper bound
    y_te = fltarr(nn,5)  * !values.f_nan      ; value  ; lower bound  ; upper bound
    y_vs = fltarr(nn,5)  * !values.f_nan      ; value  ; lower bound  ; upper bound
    y_cc = fltarr(nn)    * !values.f_nan      ; if we should use the data

    for uu=0,nn-1 do begin                    ; look over all points
      if datalt.y[uu] LT 500  then begin      ; first round only work with the points belo 500 km!!!

        ; investigete if both model has a valid data point

        ffr  = (  (flag[uu] EQ 1) OR (dater.y[uu] LT 1)  )         * (datxrN.y[uu,0] GT 100)                                ; density above 100 cc only
        ffmN = (datem.y[uu] GE 1)        * (datxmN.y[uu,0] LT 1e8) * (datxmN.y[uu,0] GT 100)  * (abs(datxrN.y[uu,0]-datxmN.y[uu,0] )/datxmN.y[uu,0]  LT 0.3 )  ; density above 100 cc only,
        ffmT = (datem.y[uu] GE 1)        * (datxmN.y[uu,0] LT 1e8) * (datxmN.y[uu,0] GT 100)  * (abs(datxrT.y[uu,0]-datxmT.y[uu,0] )/datxmT.y[uu,0]  LT 0.3 )  ; density above 100 cc only,
        ffmV = (datem.y[uu] GE 1)        * (datxmN.y[uu,0] LT 1e8) * (datxmN.y[uu,0] GT 100)  * (abs(datxrV.y[uu,0]-datxmV.y[uu,0] )/datxmV.y[uu,0]  LT 0.3 )  ; density above 100 cc only,

        ; derive the values


        ;  Density   based on both REE and MM  - with MM-s model changed this is no longer valid
        if ffr + ffmN GT 0  and 'n' EQ 'y' then begin  
          y_ne[uu,0] =  (    finite( datxrN.y[uu,0] )   * ffr      + finite(datxmN.y[uu,0] )   * ffmN   )/(ffr+ffmN)    ; this is in cc
          y_ne[uu,1] =  min( [datxrN.y[uu,1]+1e6*(ffr EQ 0), datxmN.y[uu,1]+1e6*(ffmN EQ 0)])
          y_ne[uu,2] =  max( [datxrN.y[uu,2]    * ffr      , datxmN.y[uu,2]    * ffmN])
        endif
        ;  Density   based only on REE 
          y_ne[uu,0] =  datxrN.y[uu,0]     ; this is in cc
          y_ne[uu,1] =  datxrN.y[uu,1]
          y_ne[uu,2] =  datxrN.y[uu,2]  
          y_ne[uu,3] =   dater.y[uu]
          y_ne[uu,4] =   datalt.y[uu]

        ; temperature based only on REE

        if ffr  GT 0 then begin
          y_te[uu,0] =      datxrT.y[uu,0]  ; *unit  ; this is in eV
          if  y_te[uu,0] LT 1.   then begin                                                               ; only temperature below 10000 K is used
            y_te[uu,1] =datxrT.y[uu,1] ;*unit  ;min
            y_te[uu,2] =datxrT.y[uu,2] ;*unit  ;max
          endif else $
            y_te[uu,0] = !values.f_nan
        endif
        y_te[uu,3] =   dater.y[uu]
        y_te[uu,4] =   datalt.y[uu]

        ;  SC potential   based on both REE and MM
        if ffr + ffmV GT 0 and 'n' EQ 'y' then begin
          y_vs[uu,0] =  (     datxrV.y[uu,0]    * ffr      + datxmV.y[uu,0]    * ffmV    )/(ffr+ffmV)        ; this is in V
          y_vs[uu,1] = (abs( min( [datxrV.y[uu,1]+1e6*(ffr EQ 0), datxmV.y[uu,1]+1e6*(ffmV EQ 0)]) ) >0.1)
          y_vs[uu,2] = (abs( max( [datxrV.y[uu,2]    * ffr      , datxmV.y[uu,2]    * ffmV]))  >0.1)
        endif
        y_vs[uu,0] =   datxrV.y[uu,0]    ; this is in V
        y_vs[uu,1] =   datxrV.y[uu,1]
        y_vs[uu,2] =   datxrV.y[uu,2] 
        y_vs[uu,3] =   dater.y[uu] 
        y_vs[uu,4] =   datalt.y[uu] 

 
      endif
    endfor ; end loop over all the points


    ; the LP model is low when the SC potential is high therefore deemed invalid   hard coded number
      y_ne[*,3] = y_ne[*,3]*( y_vs[*,0] LE SC_pot_thershold)  + 88888 * ( y_vs[*,0] GT SC_pot_thershold)   ;
      y_te[*,3] = y_te[*,3]*( y_vs[*,0] LE SC_pot_thershold)  + 88888 * ( y_vs[*,0] GT SC_pot_thershold)   ;


    store_data,'ne'+st,  data={x:datalt.x,y:y_ne}
    options,'ne'+st,yrange=[10,2e5]
    options,'ne'+st,ylog=1
    options,'ne'+st,ystyle=1
    options,'ne'+st,colors=[0,4,4]
    store_data,'te'+st,  data={x:datalt.x,y:y_te}
    options,'te'+st,yrange=[100,20000]
    options,'te'+st,ylog=1
    options,'te'+st,ystyle=1
    options,'te'+st,colors=[0,4,4]
    store_data,'vs'+st, data={x:datalt.x,y:y_vs}
    options,'vs'+st,yrange=[0,8]
    options,'vs'+st,ystyle=1
    options,'vs'+st,colors=[0,4,4]

  endfor ; loop over the booms








  get_data,'ne1' ,data=datn1
  get_data,'ne2' ,data=datn2
  get_data,'te1' ,data=datt1
  get_data,'te2' ,data=datt2
  get_data,'vs1',data=datv1
  get_data,'vs2',data=datv2

  data_x    =   [datn1.x,datn2.x]

  data_y       = fltarr(n_elements(data_x),10) * !values.f_nan
  data_dy      = fltarr(n_elements(data_x),10) * !values.f_nan
  data_dv      = fltarr(n_elements(data_x),10) * !values.f_nan
  data_flag    = dblarr(n_elements(data_x))
  data_alt     = dblarr(n_elements(data_x))


;  str_arr=['ne [cc]','te [K]','usc [V]','not used yet','not used yet','not used yet','not used yet', 'not used yet', 'not used yet','not used yet']   ;['u0','u1','usc','ne','ne1','ne2','Te','Te1','Te2','nsc']
;  str_col=[        0,       6,        4,    3,   3,   3,     3,    3,    3,   3]

 
  data_y(*,0)  =   [datn1.y[*,0],datn2.y[*,0]]
  data_dy(*,0) =   [datn1.y[*,2],datn2.y[*,2]]         ; dy upper value
  data_dv(*,0) =   [datn1.y[*,1],datn2.y[*,1]] *dnlow  ; dv lower value, note increase the error as we go into 2015, dnlow is a constant
  data_y(*,1)  =   [datt1.y[*,0],datt2.y[*,0]]
  data_dy(*,1) =   [datt1.y[*,2],datt2.y[*,2]]         ; dy upper value
  data_dv(*,1) =   [datt1.y[*,1],datt2.y[*,1]]         ; dv lower value
  data_y(*,2)  =   [datv1.y[*,0],datv2.y[*,0]]
  data_dy(*,2) =   [datv1.y[*,2],datv2.y[*,2]]         ; dy upper value
  data_dv(*,2) =   [datv1.y[*,1],datv2.y[*,1]]         ; dv lower value

  data_boom    =   [0.*datn1.x+0.1,0.*datn2.x+0.2]   ; the first decimal in the flad indicates which boom is used

  dne= [datn1.y[*,3],datn2.y[*,3]]
  dte= [datt1.y[*,3],datt2.y[*,3]]
  dvs= [datv1.y[*,3],datv2.y[*,3]]
  for i=0,n_elements(data_flag)-1 do $
      data_flag[i]    =   max([dne[i],dte[i],dvs[i]],/nan)  ; since they are slightly derived independently
  data_alt     =   [datn1.y[*,4],datn2.y[*,4]]

  ;get the data in time orter
  tmp                          = sort( data_x )
  data_x       = data_x[tmp]
  data_boom    = data_boom[tmp]
  data_flag    = data_flag[tmp]
  data_alt     = data_alt[tmp]
  for i=0,9 do data_y[*,i]  = data_y[tmp,i]
  for i=0,9 do data_dy[*,i] = data_dy[tmp,i]
  for i=0,9 do data_dv[*,i] = data_dv[tmp,i]
  ; leave all other variables empty

  data_dy = abs(data_dy)     ; always positive
  data_dv = abs(data_dv)     ; always positive

;-------------------------------


;adjust the numbers....


data_y_old=data_y
data_dy_old=data_dy    
data_dv_old=data_dv    

for ii=1,n_elements(tmp)-2 do begin
  if data_flag[ii-1] GT 0 and  data_flag[ii-1] LT 100  and $
     data_flag[ii]   GT 0 and  data_flag[ii] LT 100  and $
     data_flag[ii+1] GT 0 and  data_flag[ii]+1 LT 100  then begin
     
     data_y[ii,0] = 0.25 * data_y_old[ii-1,0]  + 0.5 * data_y_old[ii,0]  + 0.25 * data_y_old[ii+1,0] 
     data_y[ii,1] = 0.25 * data_y_old[ii-1,1]  + 0.5 * data_y_old[ii,1]  + 0.25 * data_y_old[ii+1,1]
     data_y[ii,2] = 0.25 * data_y_old[ii-1,2]  + 0.5 * data_y_old[ii,2]  + 0.25 * data_y_old[ii+1,2]
     data_dv[ii,0] = min([data_dv_old[ii-1,0],data_dv_old[ii,0],data_dv_old[ii+1,0]],/nan)   ; make sure the lower bound always is low in case boom 2 runns away
     data_dv[ii,1] = min([data_dv_old[ii-1,1],data_dv_old[ii,1],data_dv_old[ii+1,1]],/nan)   ; make sure the lower bound always is low in case boom 2 runns away
     data_dv[ii,2] = min([data_dv_old[ii-1,2],data_dv_old[ii,2],data_dv_old[ii+1,2]],/nan)   ; make sure the lower bound always is low in case boom 2 runns away
  endif
endfor



data_dy[*,0] = data_dy[*,0]  > 1.2*data_y[*,0]; dy upper value
data_dy[*,1] = data_dy[*,1]  > 1.2*data_y[*,1] ; dy upper value
data_dy[*,2] = data_dy[*,2]  > 1.2*data_y[*,2] ; dy upper value
data_dv[*,0] = data_dv[*,0]  < 0.8*data_y[*,0] ; dy low value
data_dv[*,1] = data_dv[*,1]  < 0.8*data_y[*,1] ; dy low value
data_dv[*,2] = data_dv[*,2]  < 0.8*data_y[*,2] ; dy lowr value

;-------------------------------


;produed the ne_all te_all and vs_all

store_data,'ne_all',data={x: data_x   , y: [[data_y[*,0]],[data_dv[*,0]],[data_dy[*,0]],[data_flag],[data_alt]] }
store_data,'te_all',data={x: data_x   , y: [[data_y[*,1]],[data_dv[*,1]],[data_dy[*,1]],[data_flag],[data_alt]] }
store_data,'vs_all',data={x: data_x   , y: [[data_y[*,2]],[data_dv[*,2]],[data_dy[*,2]],[data_flag],[data_alt]] }


;stanna
  
;-------------------------------
  
ENDIF ELSE print, "#### WARNING #### No data present in the structure directory "   



  ;--------------------------------------
  ;--------------------------------------



end