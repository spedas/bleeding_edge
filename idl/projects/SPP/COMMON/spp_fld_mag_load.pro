; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-06-05 01:18:01 -0700 (Wed, 05 Jun 2019) $
; $LastChangedRevision: 27320 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_fld_mag_load.pro $

pro spp_fld_mag_load,  trange=trange, ltype = ltype, files=files,save=save

  if not keyword_set(ltype) then ltype = 'flds_mag'
  if not keyword_set(ltype) then ltype = 'l1_mago_survey'

  if not keyword_set(pathformats) then begin
  if not keyword_set(level) then level = strmid(ltype,0,2)  ; first two characters
  if not keyword_set(type) then type = strmid(ltype,3)      ; last characters
  src = spp_file_source(source='FIELDS')

  staging = 'psp/data/sci/fields/staging/'
  ;  http://sprg.ssl.berkeley.edu/data/psp/data/sci/fields/staging/l1/mago_survey/2018/11/spp_fld_l1_mago_survey_20181103_v00.cdf
  ; http://sprg.ssl.berkeley.edu/data/psp/data/sci/fields/staging/l2_draft/mag/2018/11/psp_fld_l2_mag_20181103_v00.cdf
  
  pathformat =    staging+'/LEVEL/TYPE/YYYY/MM/spp_fld_LEVEL_TYPE_YYYYMMDD_v??.cdf'

  if ltype eq 'flds_mag' then  pathformat = staging + 'l2_draft/mag/YYYY/MM/psp_fld_l2_mag_YYYYMMDD_v??.cdf'


  pathformat = str_sub(pathformat,'LEVEL',level)
  pathformat = str_sub(pathformat,'TYPE',type)
  pathformat = str_sub(pathformat,'ss', 's\s' )    ; replace ss with escape so that ss will not be converted to seconds

  files=spp_file_retrieve(pathformat,trange=trange,source=src,/last_version,/daily_names,/valid_only)

 ; prefix = 'psp_fld_'

  case ltype of
    'l1_mago_survey': begin
 ;     mag_offset = [2.54,10.625,-17.482]
 ;     mag_offset = [ 9.25346  ,    21.4749  ,   -11.5850]
      mag_offset = [ -6.13143   ,  -12.9155 ,     19.7749]
 ;     mag_scale  = [1,-1,-1]
 ;     mag_scale  = [1,1,1]
      
      spp_fld_load_l1,files
      get_data,'spp_fld_mago_survey_nT',data=d,alimit=lim
      for i=0,2 do begin
        d.y[*,i] =  d.y[*,i] + mag_offset[i]
      endfor
      d.x = d.x - 3.255
      options,lim,'colors','bgr'
      store_data,'spp_fld_mago_correct_nT',data=d,dlimit=lim
      end
      'l1_magi_survey': begin
        mag_offset = [2.54,10.625,-17.482]
        mag_scale  = [1,-1,-1]

        spp_fld_load_l1,files
        get_data,'spp_fld_magi_survey_nT',data=d,alimit=lim
        for i=0,2 do begin
          d.y[*,i] = mag_offset[i] + d.y[*,i] * mag_scale[i]
        endfor
        options,lim,'colors','bgr'
        store_data,'spp_fld_magi_correct_nT',data=d,dlimit=lim
      end
    else:  begin
         if keyword_set(save) then begin
            vardata = !null
            novardata = !null
            loadcdfstr,filenames=files,vardata,novardata
            dummy = spp_data_product_hash(ltype,vardata)
         endif
         cdf2tplot,files,prefix = prefix,verbose=1

       end
  endcase


     
end
end

