;;  Keywords
;;
;;    - cruise
;;    - encounter
;;    - enc1
;;    - enc2
;;    - enc3
;;    - enc4
;;    - allenc
;;    - postscript


PRO spp_swp_spi_health

   ;; Housekeeping
   time_encounter1 = ['2018-10-31','2019-02-15']
   time_encounter2 = ['2019-02-15','2019-06-10']
   time_encounter3 = ['2019-06-10','2019-11-10'] 
   time_encounter4 = ['2019-11-10','2020-04-10']
   time_encounter5 = ['2020-04-10','2020-07-15']
   time_encounter6 = ['2020-07-15','2020-10-02']
   time_encounter7 = ['2020-10-02','2021-03-07']
   time_encounter8 = ['2021-03-07','2021-06-01'] 
   ;;time_total =  ['2020-07-15','2021-06-01']
   ;;time_total =  ['2020-04-10',,'2021-06-01'] 
   time_total = ['2018-10-31','2021-06-01'] 
   
   timespan, time_total

   ;;############################;;
   ;;##### COLLECT ALL DATA #####;;
   ;;############################;;

   ;; Temporary store filename
   fn = '~/Desktop/spi_hkp'

   ;; Restore from prevoius run
   IF file_test(fn) THEN restore, filename=fn $

   ELSE BEGIN 

      ;; Load Data
      spp_swp_spi_load, level='L1', types='hkp', /save

      ;; Get housekeeping data
      hkp=(spp_data_product_hash('spi_hkp_L1')).data

      ;; Save tmp file
      save, filename=fn, hkp

   END

   stop
   
   ;; Find Encounter Instances
   ppenc1 = where(hkp.time GE time_double(time_encounter1[0]) AND hkp.time LE time_double(time_encounter1[1]))
   ppenc2 = where(hkp.time GE time_double(time_encounter2[0]) AND hkp.time LE time_double(time_encounter2[1]))
   ppenc3 = where(hkp.time GE time_double(time_encounter3[0]) AND hkp.time LE time_double(time_encounter3[1]))
   ppenc4 = where(hkp.time GE time_double(time_encounter4[0]) AND hkp.time LE time_double(time_encounter4[1]))
   ppenc5 = where(hkp.time GE time_double(time_encounter5[0]) AND hkp.time LE time_double(time_encounter5[1]))
   ppenc6 = where(hkp.time GE time_double(time_encounter6[0]) AND hkp.time LE time_double(time_encounter6[1]))
   ppenc7 = where(hkp.time GE time_double(time_encounter7[0]) AND hkp.time LE time_double(time_encounter7[1]))
   ppenc8 = where(hkp.time GE time_double(time_encounter8[0]) AND hkp.time LE time_double(time_encounter8[1]))
   ;;;ppenc9 = where(hkp.time GE time_double(time_encounter9[0]) AND hkp.time LE time_double(time_encounter9[1]))
   

   ;; Setup plotting window
   ;;window, 1, xsize=1450,ysize=850
   !P.CHARSIZE = 0.85
   !P.CHARTHICK = 4.5
   !P.THICK = 1

   popen, '~/Desktop/test', /landscape
   
   ;; Plot Position Info
   yrr = [1, 1e6]
   nx = 5
   ny = 3
   nn = nx*ny
   px = [0.01, 0.99]
   py = [0.01, 0.99]
   spx = 0.05
   spy = 0.10
   sx = (px[1]-px[0])/nx
   sy = (py[1]-py[0])/ny
   poss = fltarr(nx,ny,4)
   FOR i=0, nx-1 DO FOR j=0, ny-1 DO $
    poss[i,j,*] = [px[0]+spx/2,py[0]+spy/2,px[0]+sx-spx/2,py[0]+sy-spy/2] + [i*sx,j*sy,i*sx,j*sy]

   FOR ienc=0, 7 DO BEGIN 

      CASE ienc OF
         0:   ppp = ppenc1
         1:   ppp = ppenc2
         2:   ppp = ppenc3
         3:   ppp = ppenc4
         4:   ppp = ppenc5
         5:   ppp = ppenc6
         6:   ppp = ppenc7
         7:   ppp = ppenc8
      ENDCASE
      
      ;; Title
      plot, [0,1],[0,1], /nodata, xs=5, ys=5, pos=[0,0,1,1]
      xyouts, 0.025, 1, 'SPAN-Ai Housekeeping Summary - 0x3BE - Encounter '+$
              string(ienc+1,format='(I2)'), charsize=2, charthick=3
      
      ;; 22VA Voltage
      lim = [20,22,27,29]
      tmp = histogram(hkp[ppp].MON_22A_V,loc=loc,binsize=1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[0,0,*],$
            xtitle='V (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='22 Voltage', xs=1, xr=[18,30],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      
      
      ;; 1.5A Current
      lim = [0,1,175,200]
      tmp = histogram(hkp[ppp].MON_1P5_C,loc=loc,binsize=1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[1,0,*],$
            xtitle='mA (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='1.5A Current',xs=1,xr=[0,250],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3

      ;; 3.3A Current
      lim = [0,1,211,260]
      tmp = histogram(hkp[ppp].MON_3P3_C,loc=loc,binsize=1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[2,0,*],$
            xtitle='mA (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='3.3 Current',xs=1, xr=[0,300],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
            
      
      ;; 3.3A Voltage
      tmp = histogram(hkp[ppp].MON_3P3A_V,loc=loc,binsize=0.1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[3,0,*],$
            xtitle='V (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='3.3 Voltage',xs=1, xr=[3,4],thick=4
      
      
      ;; RAW Current Monitor
      lim = [0,1,55,60]
      tmp = histogram(hkp[ppp].MON_RAW_C,loc=loc,binsize=1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[4,0,*],$
            xtitle='mA (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='RAW Current', xs=1, xr=[0,60],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3



      ;; +5A Current
      lim = [0,1,17,20]
      tmp = histogram(hkp[ppp].MON_P5I_C,loc=loc,binsize=1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[0,1,*],$
            xtitle='mA',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='+5 Current', xs=1, xr=[0,30],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3

      ;; +5 Voltage
      lim = [4.75,4.90,5.35,5.50]
      tmp = histogram(hkp[ppp].MON_P5VA_V,loc=loc,binsize=0.1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[1,1,*],$
            xtitle='V (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='+5 Voltage', xs=1, xr=[4,6],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      


      ;; -5A Current
      lim = [0,1,30,35]
      tmp = histogram(hkp[ppp].MON_N5I_C,loc=loc,binsize=1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[2,1,*],$
            xtitle='mA',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='-5 Current', xs=1, xr=[0,40],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=120, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      
      ;; -5 Voltage
      lim = -1*[-5.5,-5.35,-4.9,-4.75]
      tmp = histogram(hkp[ppp].MON_N5VA_V,loc=loc,binsize=0.1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[3,1,*],$
            xtitle='V (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='-5 Voltage', xs=1, xr=[4.5,6],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      
            
      ;; MCP Current Monitor
      lim = [0,1,50,60]
      tmp = histogram(hkp[ppp].MON_MCP_C,loc=loc,binsize=2)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[4,1,*],$
            xtitle='mA (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='MCP Current', xs=1, xr=[0,80],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3


      ;; +8 Current
      nnbin = 2
      tmp = histogram(hkp[ppp].MON_P8VA_I,loc=loc,binsize=nnbin)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[0,2,*],$
            xtitle='mA (Analog)',/noerase, /ylog, ys=1, yr=yrr,$ 
            title='+8 Current', xs=1, xr=[0,35],thick=4

      ;; +8 Voltage
      lim = [7.5,7.75,10.,10.5]
      tmp = histogram(hkp[ppp].MON_P8VA_V,loc=loc,binsize=0.1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[1,2,*],$
            xtitle='V (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='+8 Voltage', xs=1, xr=[7,12],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3      
      
      ;; -8 Current
      tmp = histogram(hkp[ppp].MON_N8VA_I,loc=loc,binsize=5)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[2,2,*],$
            xtitle='mA (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='-8 Current', xs=1, xr=[0,200],thick=4
      

      ;; -8 Voltage
      lim = -1*[-10.5,-10, -8.5, -8.2]
      tmp = histogram(hkp[ppp].MON_N8VA_V,loc=loc,binsize=0.1)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[3,2,*],$
            xtitle='V (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='-8 Voltage', xs=1, xr=[7,11],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
            
      ;; ACC Current Monitor
      lim = [0,1,20,30]
      tmp = histogram(hkp[ppp].MON_ACC_C,loc=loc,binsize=0.05)
      plot, [min(loc),loc,max(loc)], [0,tmp,0], psym=10, pos=poss[4,2,*],$
            xtitle='mA (Analog)',/noerase,/ylog, ys=1, yr=yrr,$ 
            title='ACC Current', xs=1, xr=[0,40],thick=4
      oplot, [lim[0],lim[0]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      oplot, [lim[1],lim[1]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[2],lim[2]], [yrr[0],yrr[1]], color=140, linestyle=2, thick=3
      oplot, [lim[3],lim[3]], [yrr[0],yrr[1]], color=250, linestyle=2, thick=3
      

   ENDFOR
   
   pclose


   
   ;; Find reboot time
   pp = where(hkp.seqn EQ 0,cc)
   IF cc NE 0 THEN reboot_time_seqn = hkp.time[pp]
   IF cc EQ 0 THEN stop, 'No reboots.'


   stop
   
END
