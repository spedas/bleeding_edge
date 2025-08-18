pro spp_fld_dfb_dbm_load_l1, file, prefix = prefix, varformat = varformat

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  dbm_number = fix(strmid(prefix,1,1,/rev))

  options, prefix + 'compression', 'yrange', [-0.25, 1.25]

  options, prefix + 'acdc', 'yrange', [-0.15, 1.15]
  options, prefix + 'acdc', 'ytickname', ['AC','DC']

  options, prefix + 'ftap', 'yrange', [-0.25, 6.25]

  options, prefix + 'src_sel', 'yrange', [-0.25, 14.25]

  options, prefix + 'gswapenb', 'yrange', [-0.25, 1.25]

  options, prefix + 'gswapped', 'yrange', [-0.25, 1.25]


  dbm_colors = [0, 144, 112, 16, 208, 128]
  
  dbm_symbols = [1,2,4,5,6,7]
  
  dbm_color = dbm_colors[dbm_number - 1]

  dbm_symbol = dbm_symbols[dbm_number - 1]

  if dbm_color EQ 5 then dbm_color = 0 ; can't see yellow

  dbm_meta = ['compression','acdc','ftap',$
    'src_sel','gswapenb','gswapped']

  options, prefix + dbm_meta, 'ystyle', 1
  options, prefix + dbm_meta, 'psym', dbm_symbol
  options, prefix + dbm_meta, 'symsize', 0.75
  options, prefix + dbm_meta, 'color_table', 12
  options, prefix + dbm_meta, 'colors', dbm_color
  options, prefix + dbm_meta, 'ysubtitle'
  options, prefix + dbm_meta, 'yticks', 1
  options, prefix + dbm_meta, 'ytickv', [0,1]
  options, prefix + dbm_meta, 'panel_size', 0.35
  options, prefix + dbm_meta, 'yticklen', 1
  options, prefix + dbm_meta, 'ygridstyle', 1

  ; From the DFB spec
  ; 0 = AC: 150KS/s, DC: 18.75S/s 
  ; 1 = AC: 75KS/s, DC: 9372S/s
  ; 2 = AC: 37.5KS/s, DC: 4687S/s 
  ; 3 = AC: 18.75KS/s DC: 2343S/s 
  ; 4 = AC: 9372S/s, DC: 1171S/s 
  ; 5 = AC: 4687S/s, DC: 586S/s
  ; 6 = AC: 2343S/s, DC: 293S/s 
  ; 7 = Undefined

  options, prefix + 'ftap', 'yticks', 6
  options, prefix + 'ftap', 'ytickv', indgen(7)
  options, prefix + 'ftap', 'panel_size', 3
  options, prefix + 'ftap', 'ysubtitle', '[kS/s]'
  options, prefix + 'ftap', 'ytitle', 'DFB DBM' + dbm_number + ' tap!CAC / DC'
  options, prefix + 'ftap', 'ytickname', $
    ['150.00!C18.75','75.00!C9.37','37.50!C4.69','18.75!C2.34','9.37!C1.17','4.69!C0.59','2.34!C0.29']


  ; When DC_ENB = 0 
  ; 0x0 = V1_AC
  ; 0x1 = V2_AC
  ; 0x2 = V3_AC
  ; 0x3 = V4_AC
  ; 0x4 = V5_AC
  ; 0x5 = E12_AC  
  ; 0x6 = E34_AC 
  ; 0x7 = EZ_AC
  ; 0x8 = BX_LF_LG 
  ; 0x9 = BX_LF_HG 
  ; 0xA = BY_LF_LG 
  ; 0xB = BY_LF_HG 
  ; 0xC = BZ_LF_LG 
  ; 0xD = BZ_LF_HG 
  ; 0xE = BX_MF_HG 
  ; 0xF = Unused
  
  ; When DC_ENB = 1 
  ; 0x0 = V1_DC
  ; 0x1 = V2_DC
  ; 0x2 = V3_DC
  ; 0x3 = V4_DC
  ; 0x4 = V5_DC
  ; 0x5 = VAVG_DC 
  ; 0x6 = E12_DC 
  ; 0x7 = E34_DC
  ; 0x8 = EZ_DC
  ; 0x9 = BX_LF_LG 
  ; 0xA = BX_LF_HG 
  ; 0xB = BY_LF_LG 
  ; 0xC = BY_LF_HG 
  ; 0xD = BZ_LF_LG 
  ; 0xE = BZ_LF_HG
  ; 0xF = Unused

  options, prefix + 'src_sel', 'yticks', 14
  options, prefix + 'src_sel', 'ytickv', indgen(15)
  options, prefix + 'src_sel', 'panel_size', 7
  options, prefix + 'ftap', 'ytitle', 'DFB DBM' + dbm_number + ' src_sel!CAC / DC'

  options, prefix + 'src_sel', 'ytickname', $
    ['V1','V2','V3','V4','V5','E12!CVAVG','E34!CE12','EZ!CE34',$
    'BXL!CEZ','BXH!CBXL','BYL!CBXH','BYH!CBYL','BZL!CBYH', 'BZH!CBZL','BXMF!CBZH']

  options, prefix + dbm_meta, $
    'labels', strmid('      ',0,dbm_number) + $
    strcompress(string(dbm_number),/rem)

  for i = 0, n_elements(dbm_meta) - 1 do begin

    items = tnames('spp_fld_dfb_dbm*' + dbm_meta[i])

    if items[0] NE '' then begin

      store_data, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        data = items

      get_data, items[0], al = al

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'ytitle', 'DFB!CDBM!C' + dbm_meta[i]

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'ystyle', 1
        
      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'ysubtitle', ''

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'yrange', al.yrange

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'panel_size', al.panel_size
        
        
      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'yticks', al.yticks

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'ytickv', al.ytickv

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'ygridstyle', al.ygridstyle

      options, 'spp_fld_dfb_dbm_ftap_all', 'ytitle', 'DFB DBM tap!CAC / DC'
      options, 'spp_fld_dfb_dbm_ftap_all', 'ysubtitle', '[kS/s]'

      options, 'spp_fld_dfb_dbm_src_sel_all', 'ytitle', 'DFB DBM src_sel!CAC / DC'


      options, 'spp_fld_dfb_dbm_gswapenb_all', 'ytitle', 'DFB!CDBM!Cgswp!Cena'
      options, 'spp_fld_dfb_dbm_gswapped_all', 'ytitle', 'DFB!CDBM!Cgswp!Cswp'


    endif

  endfor



end