; TODO: Documentation

function spp_fld_l1_cdf_xml_file, l1_data_type

  slash = path_sep()
  sep   = path_sep(/search_path)

  dirs = ['.',strsplit(!path,sep,/extract)]
  
  xml_file_name = 'l1_' + l1_data_type + '.xml'

  xml_path = file_search(dirs + slash + xml_file_name)

  xml_file = xml_path[0]

  return, xml_file

;  cdf_xml_dir = getenv('SPP_FLD_CDF_XML_DIR')
;
;  cdf_xml_l0_to_l1_dir = cdf_xml_dir + 'l0_to_l1/'
;
;  cdf_xml = cdf_xml_l0_to_l1_dir + 'l1_' + l1_data_type + '.xml'
;
;  return, cdf_xml

end