;+
;PROCEDURE:   mvn_swe_shape_dailysave
;PURPOSE:
;
;USAGE:
;  mvn_swe_shape_dailysave,start_day=start_day,end_day=end_day,ndays=ndays, saveflux=saveflux
;
;INPUTS:
;       None
;
;KEYWORDS:
;       start_day:     Save data over this time range.  If not
;                      specified, then timerange() will be called
;
;       end_day:       The end day of intented time range
;
;       ndays:         Number of dates to process. Will be overwritten
;                      if start_day & end_day are given. If both
;                      end_day and ndays are not specified, ndays=7
;
;       saveflux:      If set to 1, will save eflux for 3 PA ranges to
;                      a provided directory. 
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-23 10:14:21 -0700 (Mon, 23 Jun 2025) $
; $LastChangedRevision: 33407 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_shape_dailysave.pro $
;
;CREATED BY:    Shaosui Xu, 08/01/2017
;FILE: mvn_swe_shape_dailysave.pro
;-

Pro mvn_swe_shape_dailysave,start_day=start_day,end_day=end_day,ndays=ndays,$
                            saveflux=saveflux,dirflx=dirflx

    @mvn_swe_com

    dpath=root_data_dir()+'maven/data/sci/swe/l3/shape/'
    froot='mvn_swe_l3_shape_'
    vr='_v00_r02'
    oneday=86400.D

    if (size(ndays,/type) eq 0 and size(end_day,/type) eq 0) then ndays = 7
    dt = oneday

    if (size(saveflux,/type) eq 0) then saveflux=0

    if (size(start_day,/type) eq 0) then begin
        tr = timerange()
        start_day = tr[0]
        ndays = floor( (tr[1]-tr[0])/oneday )
    endif

    start_day2 = time_double(time_string(start_day,prec=-3))
    if (size(end_day,/type) ne 0 ) then $
        end_day2 = time_double(time_string(end_day,prec=-3)) $
    else end_day2 = time_double(time_string(start_day2+ndays*oneday,prec=-3))

    dt = end_day2 - start_day2
    nday = floor(dt/oneday)

    print,start_day2,end_day2,nday

    En=[4627.50,4118.51,3665.50,3262.32,2903.48,2584.12,$
	    2299.88,2046.91,1821.77,1621.38,1443.04,$
        1284.32,1143.05,1017.32,905.424,805.833,717.197,$
        638.310,568.100,505.613,449.999,400.502,$
        356.449,317.242,282.348,251.291,223.651,199.051,$
        177.157,157.671,140.328,124.893,111.155,$
        98.9290,88.0475,78.3628,69.7435,62.0721,55.2446,$
        49.1681,43.7599,38.9466,34.6627,30.8501,$
        27.4568,24.4367,21.7488,19.3566,17.2275,15.3326,$
        13.6461,12.1451,10.8092,9.62030,8.56213,$
        7.62036,6.78217,6.03617,5.37223,4.78132,4.25541,$
        3.78734,3.37076,3.00000]
    erange1 = [100,300]
    ine1 = where(en gt erange1[0] and en le erange1[1])
    erange = [35,60]
    ine = where(en gt erange[0] and en le erange[1])

    for j=0L,nday-1L do begin
        tst = start_day2+j*oneday
        print,j,' ',time_string(tst)
        tnd = tst+oneday
        opath = dpath + time_string(tst,tf='YYYY/MM/')
        file_mkdir2, opath, mode='0775'o ;create directory structure, if needed
        ofile = opath+froot+time_string(tst+1000.,tf='YYYYMMDD')+vr+'.sav'

        timespan,tst,1
        
        mvn_swe_spice_init,/force
        mvn_swe_load_l2
        ;mvn_swe_load_l2,prod=['arcpad'],/noerase
        
        if (size(mvn_swe_pad,/type) eq 8) then begin
            
            mvn_swe_addmag
            mvn_swe_sumplot,/eph,/orb,/burst,/loadonly

            mvn_mag_load;, spice='iau_mars'
;            options,'mvn_B_1sec_iau_mars','ytitle','B!dGEO!n (nT)'
;            options,'mvn_B_1sec_iau_mars','labels',['Bx','By','Bz']
;            options,'mvn_B_1sec_iau_mars','labflag',1
;            options,'mvn_B_1sec_iau_mars','constant',0.
            mvn_mag_geom            
            get_data,'mvn_B_1sec_iau_mars',data=mage,index=ok
            if ok eq 0 then continue
            mvn_scpot
            swe_shape_par_pad_l2_3pa,spec=30,mag_geo=mage,erange=[20,80],$
                                     pot=1,tsmo=16

            str_element, mvn_swe_pad, 'time', ptime, success=ok
            get_mvn_eph,ptime,eph
            store_data,'ephall',data={x:eph.time, xmso:eph.x_ss, $
                                ymso:eph.y_ss, zmso:eph.z_ss,$
                                xgeo:eph.x_pc, ygeo:eph.y_pc, zgeo:eph.z_pc,$
                                lon:eph.elon, lat:eph.lat, alt:eph.alt, $
                                sza:eph.sza, lst:eph.lst}

            get_data,'Shape_PAD',data=shp
            tsh=shp.x
            shape=shp.shape
            f3pa=shp.f3pa
            mid = shp.mid
            pots = shp.pots
            parange = shp.parange

            Nt=n_elements(tsh)
            amp=dblarr(Nt) & az=amp & elev=az & clk=az

            ;get_data,'mvn_B_1sec_iau_mars',data=mage
            tmag=mage.x
            amp_ori=mage.amp
            azim_ori=mage.azim
            elev_ori=mage.elev
            clk_ori=mage.clock
            ;now interpolate data
            amp=interpol(amp_ori,tmag,tsh,/spline)
            elev=interpol(elev_ori,tmag,tsh,/spline)

            ;get mag level
            mag_level = fltarr(Nt)
            if size(swe_mag1,/type) eq 8 then begin
                bdx = nn(swe_mag1.time, tsh)
                mag_level = swe_mag1[bdx].level
            endif

            xi=cos(azim_ori*!dtor)
            yi=sin(azim_ori*!dtor)
            xx=interpol(xi,tmag,tsh,/spline)
            yy=interpol(yi,tmag,tsh,/spline)
            azim=atan(yy,xx)*!radeg
            indx=where(azim lt 0)
            azim[indx]=360.+azim[indx]

            xi=cos(clk_ori*!dtor)
            yi=sin(clk_ori*!dtor)
            xx=interpol(xi,tmag,tsh,/spline)
            yy=interpol(yi,tmag,tsh,/spline)
            clk=atan(yy,xx)*!radeg
            indx=where(clk lt 0)
            clk[indx]=360.+clk[indx]

            get_data,'ephall',data=eph
            lon=eph.lon
            lat=eph.lat
            alt=eph.alt
            sza=eph.sza
            lst=eph.lst

            str =  {t:0.D,shape:fltarr(3,3),parange:[0.,0.],$
                    alt:0.,sza:0.,lst:0., lat:0.,lon:0.,$
                    xmso:0., ymso:0.,zmso:0., xgeo:0.,$
                    ygeo:0., zgeo:0., mid:0., f40:0., $
                    Bmag:0.,Belev:0.,Baz:0.,Bclk:0.,pot:0.,mag_level:0,$
                    fratio_a2t:fltarr(2,3)}         

            strday =  replicate(str,n_elements(tsh))
            strday.t =  tsh
            strday.shape =  transpose(shape,[1,2,0])
            strday.parange =  transpose(parange)

            rat=reform(f3pa[ine,*,0,*]/f3pa[ine,*,1,*])           
            a=mean(rat,dim=1,/nan)
            rat=reform(f3pa[ine1,*,0,*]/f3pa[ine1,*,1,*])           
            b=mean(rat,dim=1,/nan)
            c=fltarr(2,3,n_elements(tsh))
            c[0,*,*]=a
            c[1,*,*]=b
            strday.fratio_a2t=c
           
            strday.alt =  alt
            strday.sza =  sza
            strday.lst =  lst
            strday.lat =  lat
            strday.lon =  lon
            strday.xmso =  eph.xmso
            strday.ymso =  eph.ymso
            strday.zmso =  eph.zmso
            strday.xgeo =  eph.xgeo
            strday.ygeo =  eph.ygeo
            strday.zgeo =  eph.zgeo
            strday.bmag =  amp
            strday.belev =  elev
            strday.Baz =  azim
            strday.Bclk =  clk
            strday.mid =  mid
            strday.pot =  pots
            strday.mag_level=mag_level
            
            f40 = mvn_swe_engy.data[40]
            t1 = mvn_swe_engy.time
            strday.f40 = interpol(f40,t1,tsh)

            save,strday,file=ofile,/compress
            spawn,'chgrp maven '+ofile
            file_chmod, ofile, '0664'o

            if (saveflux) then begin
               strc2={t:0.D,f3pa:fltarr(64,3,3),mag_level:0}
               flx = replicate(strc2,n_elements(tsh))
               flx.t = tsh
               flx.f3pa =  transpose(f3pa,[0,2,1,3])
               flx.mag_level=mag_level

               if ~keyword_set(dirflx) then dirflx=$
                  '/disks/phobos/home/maven/shaosui.xu/data/shape/'

               ofile1 = dirflx+'flx_3pa_'+time_string(tst+1000.,tf='YYYYMMDD')+'.sav'

               save,flx,file=ofile1,/compress
               
            endif
        endif
        
    endfor

end
