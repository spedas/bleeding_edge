pro spp_fld_config, colortable=colortable

  if n_elements(colortable) EQ 0 then begin

    slash = path_sep()
    sep   = path_sep(/search_path)

    dirs = ['.',strsplit(!path,sep,/extract)]

    ;
    ; Load color tables for use by PSP
    ; The file spp_fld_colors is based on the thm_colors.tbl file
    ; and the default IDL color table, with additional color maps
    ; from Peter Kovesi's collection "CET Perceptually Uniform Colour Maps":
    ;
    ; https://peterkovesi.com/projects/colourmaps/
    ;

    tbl_name = 'spp_fld_colors.tbl'

    tbl_path = (file_search(dirs + slash + tbl_name))[0]

    if tbl_path NE '' then begin

      setenv, 'IDL_CT_FILE=' + tbl_path

    end

  end

  spd_graphics_config,colortable=colortable

  tvlct, 000, 204, 204, 3 ; darker cyan for white backgrounds
  tvlct, 000, 150, 000, 4 ; darker green for white backgrounds
  tvlct, 255, 200, 000, 5 ; darker yellow (orangeish) for white backgrounds

  usersym, cos(2*!PI*findgen(17)/16.), sin(2*!PI*findgen(17)/16.), /fill

end