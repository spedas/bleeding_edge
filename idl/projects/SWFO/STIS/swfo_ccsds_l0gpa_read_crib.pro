;swfo_test
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-01-17 04:27:14 -0800 (Fri, 17 Jan 2025) $
; $LastChangedRevision: 33069 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_frame_read_crib.pro $



if 1 || ~keyword_set(files) then begin

  run_proc = 1

  ;stop
  
  
  
  files = '~/analysis/SWFO_STIS_xray_L0A.bin'
  files = '~/analysis/SWFO_STIS_ioncal_L0A.bin'

  hexprint,files
  
  ;stop



  if ~isa(rdr) then begin
    swfo_stis_apdat_init,/save_flag
    rdr = ccsds_reader(/no_widget,verbose=verbose,run_proc=run_proc)
    !p.charsize = 1.2
  endif


endif

rdr.file_read,files





swfo_apdat_info,/create_tplot_vars,/all;,/print  ;  ,verbose=0


; level_0A_sci_



;apdats = swfo_apdat('*')
;for i= 0,n_elemenst(pdat



sciobj = swfo_apdat('stis_sci')    ; This gets the object that contains all science products
level_0b_da = sciobj.getattr('level_0b')  ; this a (dynamic) array of structures that contain all level_0B data
level_1A_da = sciobj.getattr('level_1a')
level_1b_da = sciobj.getattr('level_1b')


;Additional examples of how to extract data from the object and then recompute the data

level_0b_structs = level_0b_da.array
level_1a_structs = level_1a_da.array
level_1a_structs =   swfo_stis_sci_level_1a(level_0b_structs)
level_1b_structs =   swfo_stis_sci_level_1b(level_1a_structs)



level_0b_da.make_ncdf,filename='STIS_L0B_test.nc'
level_1a_da.make_ncdf,filename='STIS_L1A_test.nc'
level_1b_da.make_ncdf,filename='STIS_L1B_test.nc'


swfo_stis_tplot,'cpt2',/set


swfo_stis_tplot,/set,'dl1'
swfo_stis_tplot,/set,'iongun',/add

swfo_stis_plot,param=param    ; extract the parameter the control plotting
xlim,param.lim,0,100,0    ; set xrange plot limits 0 to 100 , linear
param.range=10   ; set integration range to 10 seconds

ctime,/silent,t,routine_name="swfo_stis_plot"




end
