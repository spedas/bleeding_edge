;+
; NAME:
; SYNTAX:
; PURPOSE:
; INPUT:
; OUTPUT:
; KEYWORDS:
; HISTORY: Original version Eric Donovan and Brian Jackel
;          2007-02-10, hfrey, extend for cdf-files and tplot
;          2007-03-15, hfrey, thumbnails
;          2008-04-28, hfrey, run full full_minute with pgm
;
; VERSION:
;   $LastChangedBy: hfrey $
;   $LastChangedDate: 2015-12-11 06:10:53 -0800 (Fri, 11 Dec 2015) $
;   $LastChangedRevision: 19600 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_mosaic_array.pro $
;-

;---------------------------------------------------------------------------------
;(c) Eric Donovan and Brian Jackel - 2007
pro thm_mosaic_array,iyear_in,im1,id,ih,im,is,tgb_sites,$
                     img1,cor1,ele1,www1,n_sites,$
                     verbose=verbose,$
                     special=special,local=local,$
                     pgm_file=pgm_file,cal_files=cal_files,thumb=thumb,$
                     show=show,exclude=exclude,full_minute=full_minute,$
                     merge=merge,mask_file=mask_file,block_moon=block_moon

; we will figure out the mask later, hfrey, 2009-09-30

  ;kbromund
  sav_relpathname = 'thg/l2/asi/cal/thm_map_add.sav'
  sav_file = spd_download(remote_file=sav_relpathname, _extra=!themis)
  restore, sav_file
  if iyear_in lt 50 then iy=2000+iyear_in else iy=iyear_in
  date_string=string(iy,im1,id,format='(i4.4,2i2.2)')
  date_and_hour_string=date_string+'_'+string(ih,im,format='(2i2.2)')
  exposure_time_string=string(iy,format='(i4.4)')+'-'+string(im1,format='(i2.2)')+'-'+string(id,format='(i2.2)')+' '+string(ih,format='(i2.2)')+':'+string(im,format='(i2.2)')+':'+string(is,format='(i2.2)')
  w=thm_gbo_site_list(tgb_sites,verbose=verbose)
  if w(0) ne -1 then begin
    thg_site_abbreviations=strarr(n_elements(w))
    thg_date_and_site_string=strarr(n_elements(w))
    for i=0,n_elements(w)-1 do begin
       thg_site_abbreviations(i)=strlowcase(thg_map_gb_sites(w(i)).abbreviation)
       thg_date_and_site_string(i)=date_and_hour_string+'_'+strlowcase(thg_map_gb_sites(w(i)).abbreviation)+'_'
    endfor
    if keyword_set(verbose) then for i=0,n_elements(w)-1 do dprint, 'VERBOSE_COMMENT_01:  '+string(i+1,format='(i2.2)')+'  '+thg_date_and_site_string(i)
    n_sites=n_elements(w)
    if (keyword_set(thumb) and not keyword_set(special)) then n1=1024l else n1=256l*256l
    n2=n_elements(n_sites)
    if keyword_set(full_minute) then img1=fltarr(n1,n_sites,20) else img1=fltarr(n1,n_sites)
    cor1=fltarr(n1,4,2,n_sites)
    ele1=fltarr(n1,n_sites)
    www1=intarr(n1,n_sites)-1
    merge_special=intarr(n_sites)-1

if keyword_set(verbose) then dprint, 'After init: ',systime(1)-verbose,$
   ' Seconds'

	; for now we leave both options, CDF-files and pgm-files
    if not keyword_set(pgm_file) then begin
     time=string(iy,'(i4)')+'-'+string(im1,'(i2.2)')+'-'+string(id,'(i2.2)')+'/'+$
         string(ih,'(i2.2)')+':'+string(im,'(i2.2)')+':'+string(is,'(i2.2)')
     for i_sites=0,n_sites-1 do begin
       dat=0
       station_string=thg_site_abbreviations(i_sites)
;stop
       	; do not read if excluded
       if keyword_set(exclude) then begin
          stat_ind=where(strlowcase(exclude) eq strlowcase(station_string),count_stat)
          if (count_stat gt 0) then continue
          endif

       		; check if only specific stations should be shown
       if keyword_set(show) then begin
          dummy=where(strlowcase(show) eq station_string)
          dprint, dummy,station_string
;          stop
          if (dummy[0] eq -1) then continue
          endif
;stop              
		; imager data
       if keyword_set(thumb) then begin
         thm_load_asi,site=station_string,time=time,datatype='ast'
         get_data,'thg_ast_'+station_string,data=dat
       endif else begin
         merge_thumb=0
         thm_load_asi,site=station_string,time=time,datatype='asf'
         get_data,'thg_asf_'+station_string,data=dat
         if (keyword_set(merge) and size(dat,/type) ne 8) then begin
           thm_load_asi,site=station_string,time=time,datatype='ast'
           get_data,'thg_ast_'+station_string,data=dat
           if (size(dat,/type) eq 8) then merge_thumb=1
           merge_special[i_sites]=1
           endif
       endelse

		; found an image
       if (size(dat,/type) eq 8) then begin

		; calibration data if there are images
         if keyword_set(cal_files) then begin
           station_index=where((strpos(cal_files.vars[0].name,station_string)) ne -1)
           cal=cal_files[station_index]
           endif else $
           thm_load_asi_cal,station_string,cal
;stop
         	; get longitude/latitude arrays
         if keyword_set(special) then begin
            dummy=where(strlowcase(special) eq strlowcase(station_string),special_treat)
            endif else special_treat=0
         case 1 of
         keyword_set(thumb) and special_treat gt 0: begin
            lon_name='thg_asf_'+station_string+'_glon' 
            field_index=where(cal.vars.name eq lon_name)
            x=*cal.vars[field_index[0]].dataptr
            x=reform(x[1,*,*])
            lat_name='thg_asf_'+station_string+'_glat'
            field_index=where(cal.vars.name eq lat_name)
            y=*cal.vars[field_index[0]].dataptr
            y=reform(y[1,*,*])
            ele_name='thg_asf_'+station_string+'_elev'
            field_index=where(cal.vars.name eq ele_name)
            elev=*cal.vars[field_index[0]].dataptr
            endcase
         keyword_set(thumb): begin
            lon_name='thg_ast_'+station_string+'_glon' 
            field_index=where(cal.vars.name eq lon_name)
            x=*cal.vars[field_index[0]].dataptr
            lat_name='thg_ast_'+station_string+'_glat'
            field_index=where(cal.vars.name eq lat_name)
            y=*cal.vars[field_index[0]].dataptr
            ele_name='thg_ast_'+station_string+'_elev'
            field_index=where(cal.vars.name eq ele_name)
            elev=*cal.vars[field_index[0]].dataptr
;restore,'~hfrey/idl/themis-gbo/skymap/20080209/themis_skymap_yknf_19700101.sav'
;restore,'~hfrey/idl/themis-gbo/skymap/skymap.20081118/yknf_20081029/themis_skymap_yknf_20080331.sav'
;x=transpose(reverse(skymap.bin_map_longitude))
;y=transpose(reverse(skymap.bin_map_latitude))
;stop
            endcase
         keyword_set(merge_thumb): begin
            lon_name='thg_ast_'+station_string+'_glon' 
            field_index=where(cal.vars.name eq lon_name)
            x=*cal.vars[field_index[0]].dataptr
            lat_name='thg_ast_'+station_string+'_glat'
            field_index=where(cal.vars.name eq lat_name)
            y=*cal.vars[field_index[0]].dataptr
            ele_name='thg_ast_'+station_string+'_elev'
            field_index=where(cal.vars.name eq ele_name)
            elev=*cal.vars[field_index[0]].dataptr
            endcase
         ELSE: begin 
            lon_name='thg_asf_'+station_string+'_glon'
            field_index=where(cal.vars.name eq lon_name)
            x=*cal.vars[field_index[0]].dataptr
            x=reform(x[1,*,*])
            lat_name='thg_asf_'+station_string+'_glat'
            field_index=where(cal.vars.name eq lat_name)
            y=*cal.vars[field_index[0]].dataptr
            y=reform(y[1,*,*])
            ele_name='thg_asf_'+station_string+'_elev'
            field_index=where(cal.vars.name eq ele_name)
            elev=*cal.vars[field_index[0]].dataptr
            endcase
        endcase

         	; images
         u=dat.y

		;crude corner average substract and supress negative numbers
         if not (keyword_set(thumb) or keyword_set(merge_thumb)) then g=(u-mean(u[0:10,0:10])) > 0 else g=rotate(u,8)

		; setup for arrays
         img=g[*]	;fltarr(n1)
         cor=fltarr(n1,4,2)
         ele=elev[*]	;fltarr(n1)
         www=intarr(n1)-1    ;if www(k) eq -1 then that pixel is not imaged
         k1=0l
 
		; keyword mask set
;	 if keyword_set(mask) then begin
;            mask=intarr(256l*256l)+1
;	    mask_name='thg_asf_'+station_string+'_mask'
;	    field_index=where(cal.vars.name eq mask_name)
;	    mask=*cal.vars[field_index[0]].dataptr
;	    if (station_string eq 'inuv') then begin
;	       restore,'~hfrey/mask.sav'
;	       bad=where(mask eq 0)
;	       mask[bad]=-1
;	       mask=mask[*]
;	    endif
;	    endif
	 
          	; looping y,x is faster than x,y
         case 1 of
         (keyword_set(special) and special_treat gt 0): begin	; special treatment
           max_number=255
           img=reverse(reverse(rebin(reform(img,32,32),256,256,/sample),2),1)
           for j1=0,max_number do for i1=0,max_number do begin
             corx=x[[i1,i1,i1+1,i1+1],[j1,j1+1,j1+1,j1]]
             cory=y[[i1,i1,i1+1,i1+1],[j1,j1+1,j1+1,j1]]
             wt=where(finite(corx))
             if n_elements(wt) eq 4 then www(k1)=1
             cor(k1,*,0)=corx
             cor(k1,*,1)=cory
             k1=k1+1l
             endfor
           a=sort(ele) & img=img(a) & cor=cor(a,*,*) & www=www(a) & ele=ele(a) ;sort by increasing elevation
           img1(*,i_sites)=img
           cor1(*,*,*,i_sites)=cor
           www1(*,i_sites)=www
           ele1(*,i_sites)=ele
             endcase
         (keyword_set(special) and special_treat eq 0): begin	; special set for others
           for j1=0,1023 do begin
             corx=x[*,k1]
             cory=y[*,k1]
             wt=where(finite(corx))
             if n_elements(wt) eq 4 then www(k1)=1
             cor(k1,*,0)=corx
             cor(k1,*,1)=cory
             k1=k1+1l
             endfor
             a=sort(ele) & img=img(a) & cor=cor(a,*,*) & www=www(a) & ele=ele(a) ;sort by increasing elevation
             img1(0:1023,i_sites)=img
             cor1(0:1023,*,*,i_sites)=cor
             www1(0:1023,i_sites)=www
             ele1(0:1023,i_sites)=ele
             endcase
         keyword_set(thumb): begin	; no special treatment
           for j1=0,1023 do begin
             corx=x[*,k1]
             cory=y[*,k1]
             wt=where(finite(corx))
             if n_elements(wt) eq 4 then www(k1)=1
             cor(k1,*,0)=corx
             cor(k1,*,1)=cory
             k1=k1+1l
             endfor
             a=sort(ele) & img=img(a) & cor=cor(a,*,*) & www=www(a) & ele=ele(a) ;sort by increasing elevation
             img1(*,i_sites)=img
             cor1(*,*,*,i_sites)=cor
             www1(*,i_sites)=www
             ele1(*,i_sites)=ele
             endcase
         keyword_set(merge_thumb): begin	; no special treatment
           for j1=0,1023 do begin
             corx=x[*,k1]
             cory=y[*,k1]
             wt=where(finite(corx))
             if n_elements(wt) eq 4 then www(k1)=1
             cor(k1,*,0)=corx
             cor(k1,*,1)=cory
             k1=k1+1l
             endfor
             a=sort(ele) & img=img(a) & cor=cor(a,*,*) & www=www(a) & ele=ele(a) ;sort by increasing elevation
             img1(0:1023,i_sites)=img
             cor1(0:1023,*,*,i_sites)=cor
             www1(0:1023,i_sites)=www
             ele1(0:1023,i_sites)=ele
             endcase
         else: begin		; full resolution
           max_number=255
           for j1=0,max_number do for i1=0,max_number do begin
             corx=x[[i1,i1,i1+1,i1+1],[j1,j1+1,j1+1,j1]]
             cory=y[[i1,i1,i1+1,i1+1],[j1,j1+1,j1+1,j1]]
             wt=where(finite(corx))
             if n_elements(wt) eq 4 then www(k1)=1
             cor(k1,*,0)=corx
             cor(k1,*,1)=cory
             k1=k1+1l
             endfor
;           if keyword_set(mask) then begin
;              blocked_mask=where(mask eq -1,block_count)
;              if (block_count gt 0) then www[blocked_mask]=-1
;              endif
           a=sort(ele) & img=img(a) & cor=cor(a,*,*) & www=www(a) & ele=ele(a) ;sort by increasing elevation
           img1(*,i_sites)=img
           cor1(*,*,*,i_sites)=cor
           www1(*,i_sites)=www
           ele1(*,i_sites)=ele
           endcase
         endcase

         endif
;stop
       endfor		; site loop

if keyword_set(verbose) then dprint, 'After stations: ',systime(1)-verbose,$
   ' Seconds'

    endif else begin				; read pgm-files
    for i_sites=0,n_sites-1 do begin
       station_string=thg_site_abbreviations(i_sites)

       	; do not read if excluded
       if keyword_set(exclude) then begin
          stat_ind=where(strlowcase(exclude) eq strlowcase(station_string),count_stat)
          if (count_stat gt 0) then continue
          endif

       		; check if only specific stations should be shown
       if keyword_set(show) then begin
          dummy=where(strlowcase(show) eq station_string)
          dprint, dummy,station_string
;          stop
          if (dummy[0] eq -1) then continue
          endif
       ;--------------------------------------------------------------------------------------
		; hfrey
       if not keyword_set(local) then f_img=!themis.LOCAL_DATA_DIR+'thg/mirrors/asi/hi_res_copy/'+$
              string(iy,'(i4)')+'/'+string(im1,'(i2.2)')+'/'+string(id,'(i2.2)')+'/'+$
              station_string+'_themis??/ut'+string(ih,'(i2.2)')+'/'+date_and_hour_string+'_'+station_string+'*full*'
;       if not keyword_set(local) then f_img=themis_full_res_image_filename(iy,im1,id,ih,im,station_string,special=special) ;Harald: pgm filename in Calgary tree
		; hfrey
       if keyword_set(local) then f_img='local_images/'+date_string+'/'+date_and_hour_string+'_'+station_string+'*full*pgm*'
;       if keyword_set(local) then f_img='local_images\'+date_string+'\'+date_and_hour_string+'_'+station_string+'*full.pgm*'
       find_img=findfile(f_img)
       jtf_img=strpos(find_img,thg_date_and_site_string(i_sites))
       		; check for directory with capital letters
       if (jtf_img eq -1) then begin
         f_img=!themis.LOCAL_DATA_DIR+'thg/mirrors/asi/hi_res_copy/'+$
              string(iy,'(i4)')+'/'+string(im1,'(i2.2)')+'/'+string(id,'(i2.2)')+'/'+$
              strupcase(station_string)+'_themis??/ut'+string(ih,'(i2.2)')+'/'+$
              date_and_hour_string+'_'+strupcase(station_string)+'*full*'
         find_img=findfile(f_img)
         jtf_img=strpos(find_img,strupcase(thg_date_and_site_string(i_sites)))
         endif
       		; check for directory with small but file with capital letters
       if (jtf_img eq -1) then begin
         f_img=!themis.LOCAL_DATA_DIR+'thg/mirrors/asi/hi_res_copy/'+$
              string(iy,'(i4)')+'/'+string(im1,'(i2.2)')+'/'+string(id,'(i2.2)')+'/'+$
              station_string+'_themis??/ut'+string(ih,'(i2.2)')+'/'+$
              date_and_hour_string+'_'+strupcase(station_string)+'*full*'
         find_img=findfile(f_img)
;stop
         jtf_img=strpos(find_img,strupcase(thg_date_and_site_string(i_sites)))
         endif
       if keyword_set(verbose) then dprint, 'VERBOSE_COMMENT_03:'+'  '+$
            string(jtf_img,format='(i3.3)')+'  '+f_img
     ;--------------------------------------------------------------------------------------
          ;this means the routine found the pgm file in our tree
       if jtf_img ne -1 then begin
           THM_ASI_IMAGER_READFILE,find_img,s1,metadata,COUNT=nframes
		; allow for 1.5 seconds offset
           specific_image=where(abs(time_double(exposure_time_string)-$
                time_double(metadata.exposure_time_string)) le 1.5)
;stop
	   		; go for whole full_minute
	   if keyword_set(full_minute) then begin
             ss=size(s1)
             if (ss[3] ne 20) then begin
                 s1_equiv=uintarr(256,256,20)
                 s1_start=time_double(strmid(metadata[0].EXPOSURE_TIME_STRING,0,10)+'/'+strmid(metadata[0].EXPOSURE_TIME_STRING,11,5))
                 s1_times=fix((time_double(metadata.EXPOSURE_TIME_STRING)-s1_start)/3)
                 s1_mask=intarr(20)+99
                 s1_mask[s1_times]=s1_times
                 s1_equiv[*,*,s1_times]=s1
                 for ijk=0,19 do begin
                   case 1 of
                   (s1_mask[ijk] eq 99 and ijk le 9): s1_equiv[*,*,ijk]=s1[*,*,0]
                   (s1_mask[ijk] eq 99 and ijk gt 9): s1_equiv[*,*,ijk]=s1[*,*,n_elements(metadata)-1]
                   (s1_mask[ijk] ne 99): ok=1
                   endcase
                   endfor
                 s1=s1_equiv
                 endif
             for ijk=0,19 do begin
               u=reform(s1(*,*,ijk))       ;get specific image from pgm file
;               u=rotate(u,8)              ;rotation of image to match skymap arrays
;               u=reverse(reverse(u,1),1)              ;rotation of image to match skymap arrays
               s1[*,*,ijk]=u
               endfor
             u=s1
             u=(u-mean(u[0:10,0:10,*]))   ;crude corner average substract
             g=(u > 0)                  ;supress small negative numbers from corner subtraction
             img=fltarr(n1,20)
             cor=fltarr(n1,4,2)
             ele=fltarr(n1)
             www=intarr(n1) & www(*)=-1 ;if www(k) eq -1 then that pixel is not imaged onto
             k1=long(0)
		; allow for 1.5 seconds offset
           endif else begin
           if specific_image(0) ne -1 then begin
             i0=specific_image(0)
             u=reform(s1(*,*,i0))       ;get specific image from pgm file
;             u=rotate(u,8)              ;rotation of image to match skymap arrays
;             u=reverse(reverse(u,1),1)              ;rotation of image to match skymap arrays
             u=(u-mean(u(0:10,0:10)))   ;crude corner average substract
             g=(u > 0)                  ;supress small negative numbers from corner subtraction
             img=fltarr(n1)
             cor=fltarr(n1,4,2)
             ele=fltarr(n1)
             www=intarr(n1) & www(*)=-1 ;if www(k) eq -1 then that pixel is not imaged onto
             k1=long(0)
             endif
             endelse
       ;--------------------------------------------------------------------------------------
		; read calibration only if data are found

		; calibration data if there are images
         if keyword_set(cal_files) then begin
           station_index=where((strpos(cal_files.vars[0].name,station_string)) ne -1)
           cal=cal_files[station_index]

         	; get longitude/latitude arrays
           lon_name='thg_asf_'+station_string+'_glon'
           field_index=where(cal.vars.name eq lon_name)
           x=*cal.vars[field_index[0]].dataptr
           x=reverse(reform(x[1,*,*]),1)	; same orientation as images
           lat_name='thg_asf_'+station_string+'_glat'
           field_index=where(cal.vars.name eq lat_name)
           y=*cal.vars[field_index[0]].dataptr
           y=reverse(reform(y[1,*,*]),1)
           ele_name='thg_asf_'+station_string+'_elev'
           field_index=where(cal.vars.name eq ele_name)
           elev=*cal.vars[field_index[0]].dataptr
           elev=reverse(elev,1)
           endif else begin
 		; restore save-files
           if not keyword_set(local) then sky_dir_0=!themis.local_data_dir+$
              'thg/l2/asi/cal/' else sky_dir_0='local_skymap/'
           f_skymap=findfile(sky_dir_0+'themis_skymap*'+station_string+$
                '*19700101.sav')
           if keyword_set(verbose) then dprint, 'VERBOSE_COMMENT_02:'+$
               '  '+f_skymap(0)
           restore,f_skymap(0)
           y=skymap.full_map_latitude     &     y=reform(y(*,*,1))
           x=skymap.full_map_longitude    &     x=reform(x(*,*,1)) ; 110 km
           elev=skymap.full_elevation
           endelse
       ;--------------------------------------------------------------------------------------
           if specific_image(0) ne -1 then begin
             for i1=0,255 do for j1=0,255 do begin
               i=255-i1 & j=j1
               corx=x([i,i,i+1,i+1],[j,j+1,j+1,j])
               cory=y([i,i,i+1,i+1],[j,j+1,j+1,j])
               wt=where(finite(corx))
               if n_elements(wt) eq 4 then www(k1)=1
               if keyword_set(full_minute) then for ijk=0,19 do img(k1,ijk)=g(i,j,ijk) else img(k1)=g(i,j)
               cor(k1,*,0)=corx
               cor(k1,*,1)=cory
               ele(k1)=elev(i,j)
               k1=k1+1l
               endfor
             a=sort(ele)
             if keyword_set(full_minute) then for ijk=0,19 do img[*,ijk]=img[a,ijk] else img=img(a)
             cor=cor(a,*,*) & www=www(a) & ele=ele(a) ; sort by increasing elevation
             if keyword_set(full_minute) then for ijk=0,19 do img1(*,i_sites,*)=img else img1(*,i_sites)=img
             cor1(*,*,*,i_sites)=cor
             www1(*,i_sites)=www
             ele1(*,i_sites)=ele
           endif        ; specific image
       endif 		; found file
    endfor		; stations
  endelse		; pgm files
  endif
merge=merge_special
;stop
return
end

;---------------------------------------------------------------------------------------------------------------
