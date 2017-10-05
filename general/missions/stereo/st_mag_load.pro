
;+
;Procedure: st_mag_load
;
;Purpose:  Loads stereo mag data
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;
;Example:
;   st_mag_load,probe='a'
;Notes:
;  This routine is (should be) platform independent.
;
;
; $LastChangedBy: lphilpott $
; $LastChangedDate: 2011-12-19 16:12:02 -0800 (Mon, 19 Dec 2011) $
; $LastChangedRevision: 9453 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/stereo/st_mag_load.pro $
;-
pro st_mag_load,trange=trange,verbose=verbose,version = ver, $
    unvalidated = unvalid, $
    calibrate = calibrate, $
    polar = polar,  $
    split_vec = split_vec, $
    probe=probe,resolution=res,coords=coord,burst=burst,tnames=tn

;if not keyword_set(probes) then begin
;  stop
;  return
;endif

if not keyword_set(source_options) then begin
    stereo_init
    source_options = !stereo
endif
mystereo = source_options

vb =mystereo.verbose

defprobe = struct_value(mystereo,'probe',def='a')    ; use default probe
if not keyword_set(probe) then probe = defprobe
if not keyword_set(coord)  then coord = 'RTN'
if not keyword_set(res)    then res  =  '8hz'
if keyword_set(burst)  then res = '32hz'
if not keyword_set(ver) then ver='V0?'
if keyword_set(calibrate) then unvalid = 1


fileres = 3600l*24     ; one day resolution in all files
tr = timerange(trange)
n = ceil((tr[1]-tr[0])/fileres)  > 1
dates = dindgen(n)*fileres + tr[0]

pn = (byte(strlowcase(probe))-byte('a'))[0]
probes = (['a','b'])[pn]
STX_    = (['STA_','STB_'])[pn]
dir    = (['ahead','behind'])[pn]
brst = keyword_set(burst) ? 'B' : ''
burststr = keyword_set(burst) ? 'burst_' : ''

if keyword_set(unvalid) then begin
     path = 'impact/misc/uv/spdir/STX_L1_MAG_YYYYMMDD_V01.cdf'
     str_replace,path,'spdir',dir
     str_replace,path,'STX_',STX_
     str_replace,path,'MAG','MAG'+brst
     pref = 'st'+probe+'_UV_'+burststr
     varformat = 'B_SC'
     if keyword_set( imaghkp ) then varformat = [varformat,'IMAGHKP']
     relpathnames= time_string(dates,tformat= path)
     files = file_retrieve(relpathnames,_extra = mystereo)
     cdf2tplot,tplotnames=tn,file=files,varformat=varformat,verbose=vb,pref=pref  ;,/get_support   ; load data into tplot variables
     options,pref+'B_SC',constant=0.,/def
;     if keyword_set(burst) then $
        options,pref+'B_SC',datagap=10.,/def
     if keyword_set(calibrate) then begin
        if size(/type,calibrate) eq 8 then begin
          par = calibrate 
        endif else begin
          ; TEMPORARY CHANGE as st_mag_cal is missing
          ;par = st_mag_cal(probe=probe)
          dprint, "Calibration routine st_mag_cal is not currently available. Please specify a structure using keyword calibrate if you wish to calibrate the data."
          return
        endelse
        get_data,pref+'B_SC',ptr=ptr,alim=lim
        store_data,pref+'cal_B_SC' , data = {x:ptr.x, y: func(*ptr.y, param=par) }, dlim = lim
     endif

endif else if  res eq '8hz' or keyword_set(burst) then begin
     path = 'impact/level1/spdir/mag/COORD/YYYY/MM/STX_L1_MAG?_COORD_YYYYMMDD_V??.cdf'
     str_replace,path,'spdir',dir
     str_replace,path,'COORD',coord
     str_replace,path,'COORD',coord
     str_replace,path,'MAG?','MAG'+brst
     str_replace,path,'STX_',STX_
     str_replace,path,'V??', ver
     dprint,verbose=verbose,dlevel=4,'path= ',path
     relpathnames= time_string(dates,tformat= path)
     files = file_retrieve(relpathnames,_extra = mystereo,/last_version)
     varformat = 'BFIELD'
     pref = strlowcase(stx_)+burststr
     cdf2tplot,tplotnames=tn,file=files,varformat=varformat,verbose=vb,midfix='B_'+coord,midpos=varformat,pref=pref

     if keyword_set(tn) then begin
            get_data,tn,ptr=ptr
            if keyword_set(ptr) then begin
              *ptr.y = (*ptr.y)[*,0:2]
;              *ptr.v = (*ptr.v)[0:2]
              lim = struct(colors='bgr',labels= ['Bx','By','Bz'],constant=0.)
              if keyword_set(burst) then str_element,/add,lim,'datagap',10.
              store_data,tn,dlimit = lim
              dprint,dlevel=4,tn
            endif
            if keyword_set(polar) then xyz_to_polar,tn
            if keyword_set(split_vec) then split_vec,tn
     endif

endif else  if res eq '2sec' or res eq '1min' then  begin
;      message,'no longer functional'
      B_all = 0
      time_all=0
      path = 'impact/lowres/?res?/spdir/mag/COORD/YYYY/MM/STX_?res?_MAG_COORD_YYYYMMDD_V??.sav'
      str_replace,path,'spdir',dir
      str_replace,path,'STX_',STX_
      str_replace,path,'?res?',res
      str_replace,path,'?res?',res
      str_replace,path,'COORD',coord
      str_replace,path,'COORD',coord
      str_replace,path,'V??', ver
      pref = 'st'+probe+'_'+res+'_B_'+coord
     relpathnames= time_string(dates,tformat= path)
     files = file_retrieve(relpathnames,_extra = mystereo,/last_version)
      for i=0,n_elements(files)-1 do begin
         file = files[i]
         if file_test(/regular,file) then begin
           dprint,dlevel=2,'Loading: ',file
           restore,file=file,verbose=verbose
           append_array,B_all,Bfield
           append_array,time_all,time
         endif else dprint,dlevel=1,'File not found: ',file
      endfor
      store_data,pref,data={x:time_all,y:B_all}
      tn = pref  ; tnames('st?_mag_*_B_*')
endif

;   options,/def,strfilter(tn,'*_B_*'),colors='bgr'
;   options,/def,strfilter(tn,'*_B_*_RTN'),labels=['R','T','N']
;   options,/def,strfilter(tn,'*_B_*_SC'),labels=['X','Y','Z']



end
