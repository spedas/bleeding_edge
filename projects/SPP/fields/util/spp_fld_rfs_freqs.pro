function spp_fld_rfs_freqs, lfr = lfr, plasma = plasma

  rfs_freqs = dictionary()

  slash = path_sep()
  sep   = path_sep(/search_path)

  dirs = ['.',strsplit(!path,sep,/extract)]

  if keyword_set(lfr) then begin
    ;csv_file_name = 'freq_spacing_38400000_4096_64HFR_48LFR_8LO_8O_32T_275000fp_LFR_withNeighbors.csv'
    csv_file_name = 'rfs_freq_LFR.csv'
  endif else begin
    ;csv_file_name = 'freq_spacing_38400000_4096_64HFR_48LFR_8LO_8O_32T_275000fp_HFR_withNeighbors.csv'
    csv_file_name = 'rfs_freq_HFR.csv'
  endelse

  csv_path = file_search(dirs + slash + csv_file_name)

  csv_source_file = csv_path[0]

  csv_data = read_csv(csv_source_file, $
    types = ["Long", "Double", "Double", "Long", "Long", "Long", "Long", "Double"])

  rfs_freqs.csv_source_file = csv_source_file

  rfs_freqs.full_index = long(csv_data.field1)
  rfs_freqs.full_freq = double(csv_data.field2)
  rfs_freqs.full_pfb_db = double(csv_data.field3)

  reduced_ind = long(where(csv_data.field5 NE 0))

  rfs_freqs.reduced_index = long(csv_data.field4[reduced_ind])
  rfs_freqs.reduced_indices = long([$
    [csv_data.field5[reduced_ind]], $
    [csv_data.field6[reduced_ind]], $
    [csv_data.field7[reduced_ind]]])
  rfs_freqs.reduced_pfb_db = double(rfs_freqs.full_pfb_db[rfs_freqs.reduced_indices])
  rfs_freqs.reduced_freq = double(csv_data.field8[reduced_ind])

  ;csv_plasma_name = 'freq_spacing_38400000_4096_64HFR_48LFR_8LO_8O_32T_275000fp_LFR_PlasmaTable.csv'
  csv_plasma_name = 'rfs_freq_LFR_Plasma.csv'

  csv_path = file_search(dirs + slash + csv_plasma_name)

  csv_source_file = csv_path[0]

  pldat = read_csv(csv_source_file, $
    types = ["Long", "Long", "Double", $
    "Long", "Long", "Long", "Long", "Long", "Long", "Long", "Long", $
    "Long", "Long", "Long", "Long", "Long", "Long", "Long", "Long", $
    "Long", "Long", "Long", "Long", "Long", "Long", "Long", "Long", $
    "Long", "Long", "Long", "Long", "Long", "Long", "Long", "Long"])

  plasma = dictionary()

  plasma.lfr_ind = long(pldat.field01)
  plasma.lfr_ind_2048 = long(pldat.field02)
  plasma.lfr_freq = double(pldat.field03)
  plasma.plasma_sel = long([ $
    [pldat.field04], [pldat.field05], [pldat.field06], [pldat.field07], $
    [pldat.field08], [pldat.field09], [pldat.field10], [pldat.field11], $
    [pldat.field12], [pldat.field13], [pldat.field14], [pldat.field15], $
    [pldat.field16], [pldat.field17], [pldat.field18], [pldat.field19], $
    [pldat.field20], [pldat.field21], [pldat.field22], [pldat.field23], $
    [pldat.field24], [pldat.field25], [pldat.field26], [pldat.field27], $
    [pldat.field28], [pldat.field29], [pldat.field30], [pldat.field31], $
    [pldat.field32], [pldat.field33], [pldat.field34], [pldat.field35] $
    ])

  return, rfs_freqs

end