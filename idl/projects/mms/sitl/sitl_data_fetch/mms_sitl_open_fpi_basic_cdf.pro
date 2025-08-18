; Read FPI CDF
;

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-08-25 15:57:16 -0700 (Tue, 25 Aug 2015) $
;  $LastChangedRevision: 18613 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_open_fpi_basic_cdf.pro $


function mms_sitl_open_fpi_basic_cdf, filename

  var_type = ['data']
  CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
    /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
    convert_int1_to_int2=convert_int1_to_int2)

  ; Find out what variables are in here

;  for i = 0, n_elements(cdf_str.vars.name)-1 do begin
;    print, i, '  ', cdf_str.vars(i).name
;  endfor

  time_tt2000 = *cdf_str.vars(0).dataptr
  time_unix = time_double(time_tt2000, /tt2000)

  e_specpx = *cdf_str.vars(37).dataptr
  e_specmx = *cdf_str.vars(38).dataptr

  e_specpy = *cdf_str.vars(39).dataptr
  e_specmy = *cdf_str.vars(40).dataptr

  e_specpz = *cdf_str.vars(41).dataptr
  e_specmz = *cdf_str.vars(42).dataptr

  e_omni_dir = (e_specpx + e_specpy + e_specpz +$
		e_specmx + e_specmy + e_specmz)/6

  i_specpx = *cdf_str.vars(43).dataptr
  i_specmx = *cdf_str.vars(44).dataptr

  i_specpy = *cdf_str.vars(45).dataptr
  i_specmy = *cdf_str.vars(46).dataptr

  i_specpz = *cdf_str.vars(47).dataptr
  i_specmz = *cdf_str.vars(48).dataptr

  i_omni_dir = (i_specpx + i_specpy + i_specpz +$
		i_specmx + i_specmy + i_specmz)/6

  ndens = *cdf_str.vars(77).dataptr
  densname = cdf_str.vars(77).name

  v_x = *cdf_str.vars(78).dataptr
  v_y = *cdf_str.vars(79).dataptr
  v_z = *cdf_str.vars(80).dataptr

  v_dsc = [[v_x],[v_y],[v_z]]

  vstrlen = strlen(cdf_str.vars(78).name)
  vname = strmid(cdf_str.vars(78).name, 0, vstrlen-5) + 'DSC'

  padval = *cdf_str.vars(49).dataptr

  epadm = *cdf_str.vars(35).dataptr
  epadmname = cdf_str.vars(35).name
  ;epadm = epadm[indgen(15)*2] + epadm[indgen(15)*2+1]

  epadh = *cdf_str.vars(36).dataptr
  epadhname = cdf_str.vars(36).name

  specstrlen = strlen(cdf_str.vars(37).name)
  especname = strmid(cdf_str.vars(37).name, 0, specstrlen-2) + 'omni'
  ispecname = strmid(cdf_str.vars(43).name, 0, specstrlen-2) + 'omni'

  ; Load PAD angles - hard coded for now
  padval =[0,6,12,18, $
24,30,36,42,48,54,60,66,72,78,84,90,96,102, $
108,114,120,126,132,138,144,150,156,162,168,174] + 3
;padval = (padval[indgen(15)*2] + padval[indgen(15)*2+1])/2

  ; Load energy tables - for now they are hard coded because
  ; they are not in the CDF.
  nrg01 = [10.958904109589000, $
	   14.051833510123000, $
	   18.017679780904700, $
	   23.102806082448500, $
	   29.623106602709100, $
	   37.983630285592900, $
	   48.703742960593600, $
	   62.449390975440400, $
	   80.074470587586500, $
	   102.673873031106000, $
	   131.651500482625000, $
	   168.807478160251000, $
	   216.449980276406000, $
	   277.538616607854000, $
	   355.868287029812000, $
	   456.304925279898000, $
	   585.087776639255000, $
	   750.216987385536000, $
	   961.950583542695000, $
	   1233.441711847820000, $
	   1581.555729113560000, $
	   2027.917898564260000, $
	   2600.256777307640000, $
	   3334.126747794510000, $
	   4275.116699001150000, $
	   5481.682063277360000, $
	   7028.776138409860000, $
	   9012.506277013540000, $
	   11556.104191359900000, $
	   14817.581256189400000, $
	   18999.544366165800000, $
	   24361.782120892000000]

nrg02 = [12.409379356009200, $
	 15.911676106557200, $
	 20.402425395866400, $
	 26.160597993969600, $
	 33.543898537707400, $
	 43.010986574824500, $
	 55.149969049070800, $
	 70.714934213895700, $
	 90.672796505583000, $
	 116.263362435927000, $
	 149.076348870252000, $
	 191.150138159239000, $
	 245.098404912620000, $
	 314.272480622884000, $
	 402.969542425509000, $
	 516.699558933000000, $
	 662.527576140347000, $
	 849.512606615793000, $
	 1089.270386303560000, $
	 1396.694958070860000, $
	 1790.883907640650000, $
	 2296.324728683900000, $
	 2944.416015503820000, $
	 3775.417981638950000, $
	 4840.953472956760000, $
	 6207.214841191920000, $
	 7959.075892786910000, $
	 10205.364352263600000, $
	 13085.622371919000000, $
	 16778.775058872400000, $
	 21514.245518836000000, $
	 27586.206896551600000]

  energies = (nrg01 + nrg02)/2

  outstruct = {times: time_unix, $
	       espec: e_omni_dir, $
	       ispec: i_omni_dir, $
	       epadm: epadm, $
	       epadh: epadh, $
	       padval: padval, $
	       energies: energies, $
	       ndens: ndens, $
	       ispecname: ispecname, $
	       especname: especname, $
	       densname: densname, $
	       epadmname: epadmname, $
	       epadhname: epadhname, $
	       vdsc: v_dsc, $
	       vname: vname}

  return, outstruct

end
