pro swfo_stis_make_l0b
  dprint , 'make_l0b'
  ;ncdf_file = 'test.nc'

  ;rawfile='/cache/maven/data/sci/pfp/l0_all/2021/04/mvn_pfp_all_l0_20210419_v003.dat'


  stack = scope_traceback(/structure)
  pathname = stack[n_elements(stack)-1].filename
  dirname  = file_dirname(pathname)

  masterfile = dirname + '/templates/swfo_stis_l0b_masters/MASTER_sfwo_stis_l0b-all.nc'
  
  root_dir = 'temp/swfo/stis/ncdf/l0b'
  ncdf_file_format = root_dir+'/YYYY/MM/DD/swfo_stis_l0b_YYYYMMDD_XX_v00.nc'
  
  if ~keyword_set(time) then time= systime(1)
  ncdf_filename = time_string(time,tformat=ncdf_file_format)

  file_mkdir2, file_dirname(ncdf_filename)
  file_copy, masterfile, ncdf_filename,/verbose,/overwrite
  
  stop
  
  return

  cdfid =ncdf_create(ncdf_file,/clobber,/netcdf4_format)

  ncdf_attput, cdfid, 'Title', 'SWFO data',/global
  ncdf_attput, cdfid, 'STIS', 'Raw data',/global


  nbins = 256
  dim_sci_time = ncdf_dimdef(cdfid,'dim_sci_time',/unlimited)
  dim_sci_bins = ncdf_dimdef(cdfid,'dim_sci_bins',nbins)
  var_sci_time = ncdf_vardef(cdfid,'rawtime',[dim_sci_time],/double)
  var_sci_bins = ncdf_vardef(cdfid,'rawdat',[dim_sci_bins,dim_sci_time],/float)

  dim_hkp_time = ncdf_dimdef(cdfid,'dim_hkp_time',/unlimited)
  dim_hkp_rates = ncdf_dimdef(cdfid,'dim_hkp_rates',6)
  dim_hkp_temp = ncdf_dimdef(cdfid,'dim_hkp_temp',5)
  var_hkp_time = ncdf_vardef(cdfid,'hkp_time',[dim_hkp_time],/double)
  var_hkp_rates = ncdf_vardef(cdfid,'hkp_rates',[dim_hkp_rates,dim_hkp_time],/float)


  dim_nse_time = ncdf_dimdef(cdfid,'dim_nse_time',/unlimited)
  dim_nse_hist = ncdf_dimdef(cdfid,'dim_nse_histgrm',60)

  ncdf_control,cdfid,/endef

  ncdf_varput,cdfid,var_sci_bins,findgen(256,23)
  ncdf_varput,cdfid,var_sci_time,dindgen(23)*10. +systime(1)

  ncdf_varput,cdfid,var_hkp_rates,findgen(6,17)
  ncdf_varput,cdfid,var_sci_time,dindgen(17)*10. +systime(1)


  ncdf_attput,cdfid,'rawdat','Units','Counts'
  ncdf_attput,cdfid,'rawtime','Units','Seconds'

  ncdf_list,ncdf_file,/var,/vatt,/gatt,/dimen


  stop


  grpid = cdfid
  Result = NCDF_DIMIDSINQ( Grpid  )
  printdat,result

  inq = NCDF_INQUIRE(Cdfid)

  dim_struct = replicate({name:'',size:0L},inq.ndims)
  for dimid = 0,inq.ndims-1 do begin
    NCDF_DIMINQ, Cdfid, Dimid, Name, Size
    dim_struct[dimid].name = name
    dim_struct[dimid].size = size
  endfor

  printdat,dim_struct

  stop


  ncdf_close,cdfid

  ncdf_list,ncdf_file,/var,/vatt,/gatt,/dimen



  stop







end
