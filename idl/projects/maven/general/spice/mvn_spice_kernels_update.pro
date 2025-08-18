;+
;NAME: 
; MVN_SPICE_KERNELS_UPDATE
;PURPOSE:
; Updates all spice kernels from NAIF, should be run from a cronjob
; once in a while; it can take a long time because all ck kernel
; files are checked
;CALLING SEQUENCE:
; mvn_spice_kernels_update
;INPUT:
; none
;OUTPUT:
; none, spice kernels are updated
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-03-27 13:38:59 -0700 (Mon, 27 Mar 2017) $
; $LastChangedRevision: 23049 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_kernels_update.pro $
;-
Pro mvn_spice_kernels_update

  retrievetime = systime(1)

  naif = spice_file_source(/valid_only, /last_version)

  source = naif
  dprint, dlevel = 2, phelp = 2, source
  ;Standard kernels
  k0 = spice_standard_kernels(source = source, /mars) ;  "Standard" kernels
  ;comets kernels
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'generic_kernels/spk/comets/siding_spring_8-19-14.bsp', $
                         local_path = source.local_data_dir+'generic_kernels/spk/comets/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  ;leap second kernels
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'generic_kernels/lsk/naif00??.tls', $
                         local_path = source.local_data_dir+'generic_kernels/lsk/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  ;spacecraft clock kernels
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/sclk/MVN_SCLKSCET.00???.tsc', $
                         local_path = source.local_data_dir+'MAVEN/kernels/sclk/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  ;Frame kernels, not downloaded, but hard coded in mvn_spice_kernels
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/fk/maven_v??.tf', $
                         local_path = source.local_data_dir+'MAVEN/kernels/fk/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  ;Instrument Kernels are hard-coded in mvn_spice_kernels too
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_ant_v??.ti', $
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_euv_v??.ti',$
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_iuvs_v??.ti',$
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_lpw_v??.ti',$
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_mag_v??.ti',$
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_ngims_v??.ti',$
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_sep_v??.ti',$
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_static_v??.ti',$
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_swea_v??.ti',$
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_swia_v??.ti',$
                         local_path = source.local_data_dir+'MAVEN/kernels/ik/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  ;spk are spacecraft position
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/trj_c_131118-140923_rec_v?.bsp', $
                         local_path = source.local_data_dir+'MAVEN/kernels/spk/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb_rec_??????_??????_v?.bsp', $
                         local_path = source.local_data_dir+'MAVEN/kernels/spk/', $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb_rec.bsp', $
                         local_path = source.local_data_dir+'MAVEN/kernels/spk/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb.bsp', $
                         local_path = source.local_data_dir+'MAVEN/kernels/spk/', /last_version, $
                         no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
  ;Spacecraft Attitude  (CK)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ck/mvn_sc_rel_??????_??????_v??.bc', $
                         local_path = source.local_data_dir+'MAVEN/kernels/ck/', $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ck/mvn_sc_red_??????_v??.bc', $
                         local_path = source.local_data_dir+'MAVEN/kernels/ck/', $
                         file_mode = '666'o, dir_mode = '777'o)
  ;APP Attitude (CK files)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ck/mvn_app_rel_??????_??????_v??.bc', $
                         local_path = source.local_data_dir+'MAVEN/kernels/ck/', $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ck/mvn_app_red_??????_v??.bc', $
                         local_path = source.local_data_dir+'MAVEN/kernels/ck/', $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/misc/app/mvn_app_nom_131118_141031_v1.bc', $
                         local_path = source.local_data_dir+'MAVEN/misc/app/', /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
  k0 = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ck/mvn_swea_nom_131118_300101_v??.bc',  $
                         local_path = source.local_data_dir+'MAVEN/kernels/ck/',/last_version, $
                         file_mode = '666'o, dir_mode = '777'o)

  print,'Time to retrieve SPICE kernels: '+strtrim(systime(1)-retrievetime,2)+ ' seconds'

end
