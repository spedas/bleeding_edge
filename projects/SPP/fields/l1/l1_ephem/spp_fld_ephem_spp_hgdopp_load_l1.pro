;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2019-07-18 16:08:19 -0700 (Thu, 18 Jul 2019) $
;  $LastChangedRevision: 27480 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_ephem/spp_fld_ephem_spp_hgdopp_load_l1.pro $
;

pro spp_fld_ephem_spp_hgdopp_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_ephem_SPP_HGDOPP_'

  spp_fld_ephem_load_l1, file, prefix = prefix, varformat = varformat

end