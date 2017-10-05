function mvn_sep_cdf_g_attributes
g_att ={title:'' , $
        project:'', $

'Title',/global_scope)
id1 = cdf_attcreate(fileid,'Project',/global_scope)
id2 = cdf_attcreate(fileid,'Discipline',/global_scope)
id3 = cdf_attcreate(fileid,'Source_name',/global_scope)
id4 = cdf_attcreate(fileid,'Descriptor',/global_scope)
id5 = cdf_attcreate(fileid,'Data_type',/global_scope)
id6 = cdf_attcreate(fileid,'Data_version',/global_scope)
id7 = cdf_attcreate(fileid,'TEXT',/global_scope)
id8 = cdf_attcreate(fileid,'Mods',/global_scope)
id9 = cdf_attcreate(fileid,'Logical_file_id',/global_scope)
id10 = cdf_attcreate(fileid,'Logical_source',/global_scope)
id11 = cdf_attcreate(fileid,'Logical_source_description',/global_scope)
id12 = cdf_attcreate(fileid,'PI_name',/global_scope)
id13 = cdf_attcreate(fileid,'PI_affiliation',/global_scope)
id14 = cdf_attcreate(fileid,'Instrument_type',/global_scope)
id15 = cdf_attcreate(fileid,'Mission_group',/global_scope)
id16 = cdf_attcreate(fileid,'Parents',/global_scope)
id17 = cdf_attcreate(fileid,'HTTP_LINK',/global_scope)
id18 = cdf_attcreate(fileid,'LINK_TEXT',/global_scope)
id19 = cdf_attcreate(fileid,'LINK_TITLE',/global_scope)

cdf_attput,fileid,'Title',0, title
cdf_attput,fileid,'Project',0,project
cdf_attput,fileid,'Discipline',0,discipline
cdf_attput,fileid,'Source_name',0,mission
cdf_attput,fileid,'Descriptor',0,descriptor
cdf_attput,fileid,'Data_type',0,data_type
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,experiment_description
cdf_attput,fileid,'Mods',0,software_revision
cdf_attput,fileid,'Logical_file_id',0,file
cdf_attput,fileid,'Logical_source',0,logical_source
cdf_attput,fileid,'Logical_source_description',0,logical_source_description
cdf_attput,fileid,'PI_name',0,instrument_lead_name
cdf_attput,fileid,'PI_affiliation',0,instrument_lead_affiliation
cdf_attput,fileid,'Instrument_type',0,instrument_type
cdf_attput,fileid,'Mission_group',0,mission_group
cdf_attput,fileid,'Parents',0,parent_CDF_files
cdf_attput,fileid,'HTTP_LINK',0,HTTP_LINK
cdf_attput,fileid,'LINK_TEXT',0,LINK_TEXT
cdf_attput,fileid,'LINK_TITLE',0,LINK_TITLE





return,g_att
end