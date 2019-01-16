pro spp_fld_config, colortable=colortable

  if n_elements(colortable) EQ 0 then begin

    slash = path_sep()
    sep   = path_sep(/search_path)

    dirs = ['.',strsplit(!path,sep,/extract)]

    tbl_name = 'colors_cet.tbl'

    tbl_path = (file_search(dirs + slash + tbl_name))[0]

    if tbl_path NE '' then begin

      setenv, 'IDL_CT_FILE=' + tbl_path

    end

  end

  spd_graphics_config,colortable=colortable

  tvlct, 000, 204, 204, 3 ; darker cyan for white backgrounds
  tvlct, 000, 150, 000, 4 ; darker green for white backgrounds
  tvlct, 204, 204, 000, 5 ; darker yellow (brownish) for white backgrounds

end