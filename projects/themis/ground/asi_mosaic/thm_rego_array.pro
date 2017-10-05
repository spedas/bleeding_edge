PRO thm_rego_array,iyear_in,im1,id,ih,im,is,tgb_sites,$
                     img1,cor1,ele1,www1,n_sites,verbose=verbose,$
                     cal_files=cal_files,thumb=thumb,$
                     show=show,exclude=exclude,insert=insert

;+
; NAME: thm_rego_array
;    
;
; PURPOSE: read red line images for mosaic generation
;    
;
; CATEGORY:
;    None
;
; CALLING SEQUENCE:
;    thm_rego_array,iyear_in,im1,id,ih,im,is,tgb_sites,img1,cor1,ele1,www1,n_sites
;
; INPUTS:
;    iyear_in	year
;    im1	month
;    id		day
;    ih		hour
;    im		minute
;    is		second
;    tgb_sites  sites to show
;
; OPTIONAL INPUTS:
;    None
;
; KEYWORD PARAMETERS:
;    verbose	print debug messages
;    cal_files	provide or read calibration files
;    thumb	thumbnail instead of full resolution
;    show	which sites to show
;    exclude	which sites to exclude
;    insert	stop before exiting program
;
; OUTPUTS:
;    img1	images
;    cor1	corner coordinates
;    ele1	pixel elevation angles
;    www1	pixel imaged or not
;    n_sites	number of sites found
;
; OPTIONAL OUTPUTS:
;    None
;
; COMMON BLOCKS:
;    None
;
; SIDE EFFECTS:
;    None
;
; RESTRICTIONS:
;    None
;
; EXAMPLE:
;
; 
;
; SEE ALSO:
;
;
; MODIFICATION HISTORY:
;    Written by: Harald Frey, Date: 2015-07-16
;                Original version Eric Donovan and Brian Jackel
;                (c) Eric Donovan and Brian Jackel - 2007
;          2007-02-10, hfrey, extend for cdf-files and tplot
;          2007-03-15, hfrey, thumbnails
;          2008-04-28, hfrey, 
;          2015-07-16, hfrey, modified for red line images
;
; NOTES:
;
; VERSION:
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;     
;-

	; path to data
sav_relpathname = 'thg/l2/asi/cal/thm_map_add.sav'
sav_file = spd_download(remote_file=sav_relpathname, _extra=!themis)
restore, sav_file

	; correct date
if iyear_in lt 50 then iy=2000+iyear_in else iy=iyear_in
date_string=string(iy,im1,id,format='(i4.4,2i2.2)')
date_and_hour_string=date_string+'_'+string(ih,im,format='(2i2.2)')
exposure_time_string=string(iy,format='(i4.4)')+'-'+string(im1,format='(i2.2)')+$
  	'-'+string(id,format='(i2.2)')+' '+string(ih,format='(i2.2)')+':'+string(im,format='(i2.2)')+':'+string(is,format='(i2.2)')
w=thm_gbo_site_list(tgb_sites,verbose=verbose)

	; search sites
if w(0) ne -1 then begin
    thg_site_abbreviations=strarr(n_elements(w))
    thg_date_and_site_string=strarr(n_elements(w))
    for i=0,n_elements(w)-1 do begin $
       thg_site_abbreviations(i)=strlowcase(thg_map_gb_sites(w(i)).abbreviation) & $
       thg_date_and_site_string(i)=date_and_hour_string+'_'+strlowcase(thg_map_gb_sites(w(i)).abbreviation)+'_' & $
       endfor
    if keyword_set(verbose) then for i=0,n_elements(w)-1 do dprint, 'VERBOSE_COMMENT_01:  '+$
    	string(i+1,format='(i2.2)')+'  '+thg_date_and_site_string(i)
    n_sites=n_elements(w)
    if keyword_set(thumb) then n1=1024l else n1=512l*512l
    n2=n_elements(n_sites)
    img1=fltarr(n1,n_sites)
    cor1=fltarr(n1,4,2,n_sites)
    ele1=fltarr(n1,n_sites)
    www1=intarr(n1,n_sites)-1

    if keyword_set(verbose) then dprint, 'After init: ',systime(1)-verbose,' Seconds'

	; correct time
    time=string(iy,'(i4)')+'-'+string(im1,'(i2.2)')+'-'+string(id,'(i2.2)')+'/'+$
         string(ih,'(i2.2)')+':'+string(im,'(i2.2)')+':'+string(is,'(i2.2)')
    
    	; loop through sites
    for i_sites=0,n_sites-1 do begin
       dat=0
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
          if (dummy[0] eq -1) then continue
          endif

		; imager data, full or thumb
       if keyword_set(thumb) then begin
         thm_load_rego,site=station_string,time=time,datatype='ast'
         get_data,'clg_ast_'+station_string,data=dat
         endif else begin
         thm_load_rego,site=station_string,time=time,datatype='rgf'
         get_data,'clg_rgf_'+station_string,data=dat
         endelse

		; found an image
       if (size(dat,/type) eq 8) then begin

		; calibration data if there are images
         if keyword_set(cal_files) then begin
           station_index=where((strpos(cal_files.vars[0].name,station_string)) ne -1)
           cal=cal_files[station_index]
           endif else $
           thm_load_asi_cal,station_string,cal,/rego

         	; get longitude/latitude arrays
          case 1 of
          keyword_set(thumb): begin
            lon_name='clg_ast_'+station_string+'_glon' 
            field_index=where(cal.vars.name eq lon_name)
            x=*cal.vars[field_index[0]].dataptr
            lat_name='clg_ast_'+station_string+'_glat'
            field_index=where(cal.vars.name eq lat_name)
            y=*cal.vars[field_index[0]].dataptr
            ele_name='clg_ast_'+station_string+'_elev'
            field_index=where(cal.vars.name eq ele_name)
            elev=*cal.vars[field_index[0]].dataptr
            endcase
          ELSE: begin ; full resolution image
            lon_name='clg_rgf_'+station_string+'_glon'
            field_index=where(cal.vars.name eq lon_name)
            x=*cal.vars[field_index[0]].dataptr
            x=reform(x[1,*,*])
            lat_name='clg_rgf_'+station_string+'_glat'
            field_index=where(cal.vars.name eq lat_name)
            y=*cal.vars[field_index[0]].dataptr
            y=reform(y[1,*,*])
            ele_name='clg_rgf_'+station_string+'_elev'
            field_index=where(cal.vars.name eq ele_name)
            elev=*cal.vars[field_index[0]].dataptr
            endcase
            endcase

         	; images
         u=dat.y

		;crude corner average substract and supress negative numbers
         if not (keyword_set(thumb)) then g=(u-mean(u[0:10,0:10])) > 0 else g=rotate(u,8)

		; setup for arrays
         img=g[*]			;fltarr(n1)
         cor=fltarr(n1,4,2)
         ele=elev[*]		;fltarr(n1)
         www=intarr(n1)-1   	;if www(k) eq -1 then that pixel is not imaged
         k1=0l
 
          	; looping y,x is faster than x,y
         case 1 of
         keyword_set(thumb): begin	; 
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
             else: begin		; full resolution
             max_number=511
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
             endcase

         endif		; found an image
       endfor		; site loop

  if keyword_set(verbose) then dprint, 'After stations: ',systime(1)-verbose,' Seconds'

  endif	; search sites
  
if keyword_set(insert) then stop
end
