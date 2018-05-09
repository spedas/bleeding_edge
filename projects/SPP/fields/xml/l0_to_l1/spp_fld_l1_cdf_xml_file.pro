;+
; NAME:
;   SPP_FLD_L1_CDF_XML_FILE
;
; PURPOSE:
;   Returns the path to the XML definition file for a given PSP/FIELDS Level
;   1 data type.  The XML file contains a list of the items available from
;   the TMlib database for the specified data type, as well as the metadata
;   for the Level 1 CDF file which will be created.
;
; INPUTS:
;   L1_DATA_TYPE: The name of the data type for the L1 XML file.  Uses the 
;     abbreviated APID packet identifier rather than the hex code (e.g. 
;     'rfs_lfr' instead of '0x2b2').
;
; RETURNS:
;   XML_FILE: The path to the requested XML file.
;
; EXAMPLE:
;     SPP_FLD_L1_CDF_XML_FILE is called from the routine 
;     SPP_FLD_LOAD_TMLIB_DATA, using the syntax:
;     
;     cdf_xml = spp_fld_l1_cdf_xml_file('rfs_lfr_auto')
;
; NOTE:
;     This file should be in the same directory as the L1 XML files.  If the 
;     XML files are in a directory without any IDL routines ('.pro' files) then
;     the FILE_SEARCH routine will not find them using the !PATH IDL system
;     variable.
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2018-05-08 15:29:49 -0700 (Tue, 08 May 2018) $
; $LastChangedRevision: 25184 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/xml/l0_to_l1/spp_fld_l1_cdf_xml_file.pro $
;-
function spp_fld_l1_cdf_xml_file, l1_data_type

  slash = path_sep()
  sep   = path_sep(/search_path)

  dirs = ['.',strsplit(!path,sep,/extract)]
  
  xml_file_name = 'l1_' + l1_data_type + '.xml'

  xml_path = file_search(dirs + slash + xml_file_name)

  xml_file = xml_path[0]

  return, xml_file

end