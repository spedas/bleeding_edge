;+
;Function: spice_kernel_info
;
;Purpose:  returns info on all load spice kernels
;
;Keywords:
;         None
;
;
;
; Author: Davin Larson
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

function spice_kernel_info,type=type,verbose=verbose,use_cache=use_cache
common spice_kernel_info_com, stats,kernels,c,d

if spice_test() eq 0 then return,0
if keyword_set(use_cache) && keyword_set(stats) then return,stats
stats=0
dlevel=2
if ~keyword_set(type) then type='ALL'
;if ~keyword_set(kernels) then begin
   cspice_ktotal,type,count
   if count eq 0 then begin
      dprint,dlevel=1,verbose=verbose,'No files of type: ',type,' were found. Please load them.'
      return,0
   endif
   kernels = strarr(count)
   for i=0,count-1 do begin
      cspice_kdata,i,type,file,t,s,h,f
      kernels[i] = file
   endfor
;endif
nstats=n_elements(stats) *keyword_set(stats)
;stat={type:'',obj_code:0L,obj_name:'',interval:0L,trange:['',''],handle:0L,found:0 ,filename:''}
for i2 = 0,n_elements(kernels)-1 do begin
      kernel=kernels[i2]
      cspice_kinfo,kernel,type,source,handle,found
      stat={type:type,obj_code:0L,obj_name:'',interval:-1,trange:['',''],handle:handle,found:found ,filename:kernel,source:source}
      ;; From a given CK file, retrieve the list of objects listed
      ;; in the file then retrieve the time coverage for each object.
      ;; Local parameters...
      MAXIV      = 1000
      WINSIZ     = 2 * MAXIV
      MAXOBJ     = 1000
      cover = cspice_celld( WINSIZ )
      ids   = cspice_celli( MAXOBJ )
      ;; Find the set of objects in the CK file. 
      case type of 
        'CK' :   cspice_ckobj,  kernel, ids 
        'SPK':   cspice_spkobj, kernel, ids
        else:    begin
                   ids = 0
                   append_array,stats,stat,index=nstats
                 end
      endcase
      ;; We want to display the coverage for each object. Loop over
      ;; the contents of the ID code set, find the coverage for
      ;; each item in the set, and display the coverage.
      n_objs = keyword_set(ids) ? cspice_card(ids) : 0
      dprint,dlevel=dlevel,verbose=verbose, '=== '+type+' === '+kernel
 ;     dprint,dlevel=dlevel,verbose=verbose,kernel
      for i=0, n_objs-1 do begin
         ;;  Find the coverage window for the current object, 'i'.
         ;;  Empty the coverage window each time 
         ;;  so we don't include data for the previous object.
         catch,error_status
         if error_status ne 0 then begin
            printdat,!error_state
            dprint,dlevel=1,verbose=verbose,'Something is wrong with file: '+kernel+' Skipping Object:'+string(obj)
            error_status = 0
            continue
         endif
         
         obj = ids.base[ ids.data + i ]
         cspice_scard, 0L, cover
;         cspice_ckcov, CK, obj,  SPICEFALSE, 'INTERVAL', 0.D, 'TDB', cover 
         case type of 
           'CK' :   cspice_ckcov,  kernel, obj, 0B, 'INTERVAL',  0.D,  'TDB', cover
           'SPK':   cspice_spkcov, kernel, obj, cover
         endcase
         ;; Get the number of intervals in the coverage window.
         niv = cspice_wncard( cover )
         stat.obj_code = obj
         stat.obj_name = spice_bodc2s(obj)
         dprint,dlevel=dlevel,verbose=verbose, 'Coverage for object:', obj,'  (',stat.obj_name,')'
         ;; Convert the coverage interval start and stop times to TDB
         ;; calendar strings.
         for j=0, niv-1 do begin
            ;; Get the endpoints of the jth interval.
            cspice_wnfetd, cover, j, b, e
            ;; Convert the endpoints to TDB calendar
            ;; format time strings and display them.
            ;; Pass the endpoints in an array, [b,e],
            ;; so cspice_timout returns an array of time 
            ;; strings.
            tformat ='YYYY-MM-DD/HR:MN:SC.###  ::TDB'
            cspice_timout, [b,e],tformat ,  51 ,  timstr 
            dprint,dlevel=dlevel,verbose=verbose,  j, ' Start : ', timstr[0], '  Stop  : ', timstr[1]
            stat.interval =j
            stat.trange =   timstr                  ;  time_ephemeris(/et2ut, [b,e] )    
            append_array,stats,stat,index=nstats         
        endfor
    endfor
      ;; It's always good form to unload kernels after use, particularly in IDL due to data persistence.
endfor
append_array,stats,index=nstats,/done
return,stats
ski_error:  


end


