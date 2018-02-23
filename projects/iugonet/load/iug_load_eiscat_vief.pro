;+
; PROCEDURE: IUG_LOAD_EISCAT_VIEF
;   iug_load_eiscat_vief, site=site, $
;                         get_support_data=get_support_data, $
;                         trange=trange, $
;                         verbose=verbose, $
;                         downloadonly=downloadonly, $
;                         no_download=no_download
;
; PURPOSE:
;   loads the EISCAT vector Vi and E field data.
;
; KEYWORDS:
;   site  = site code, example, 
;           iug_load_eiscat_vief, site='kst',
;           the default is 'all', i.e., load all available sites.
;           Available sites: 'kst' (kst means Kiruna, Sodankyla, Tromso.)
;   trange = (Optional) Time range of interest  (2 element array).
;   /get_support_data : turn this on to load the supporting data.
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it 
;           into variables.
;   /no_download: use only files which are online locally.
;
; OUTPUT
;   Vi and E vectors have 3 components, i.e.,
;   Vi = [Ve, Vn, Vu] and E = [Ee, En, Eu], where
;   [e, n, u] corresponds to [eastward, n:northward, u:upward].
;
; EXAMPLE:
;   iug_load_eiscat_vief, site='kst', $
;                 trange=['2011-2-1/00:00:00','2011-2-3/00:00:00']
;
;   For more information, see http://www.iugonet.org/en/ 
;                         and http://polaris.nipr.ac.jp/~eiscat/eiscatdata/
;
; Written by: Y.-M. Tanaka, August 16, 2013 (ytanaka at nipr.ac.jp)
;-

;************************************************************
;*** Load procedure for EISCAT Vi and E field vector data ***
;************************************************************
pro iug_load_eiscat_vief, site=site,  $
        trange=trange, get_support_data=get_support_data, $
	verbose=verbose, downloadonly=downloadonly, no_download=no_download

;===== Keyword check =====
;----- all codes -----;
site_code_all = strsplit('kst', $
			/extract)

;----- verbose -----;
if ~keyword_set(verbose) then verbose=0

;----- site -----;
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return
print, 'site_code = ',site_code

;===== Download files, read data, and create tplot vars at each site =====
ack_flg=0

for i=0,n_elements(site_code)-1 do begin
    site=site_code[i]
    
    ;----- Set parameters for file_retrieve and download data files -----;
    source = file_retrieve(/struct)
    source.verbose = verbose
    source.local_data_dir  = root_data_dir() + 'iugonet/nipr/eiscat/'
    source.remote_data_dir = 'http://polaris.nipr.ac.jp/~eiscat/eiscatdata/cdf/'
;    source.remote_data_dir = 'http://polaris.nipr.ac.jp/~ytanaka/data/'
    if keyword_set(no_download) then source.no_download = 1

    relpathnames1 = file_dailynames(file_format='YYYY', trange=trange)
    relpathnames2 = file_dailynames(file_format='YYYYMMDD', trange=trange)
    relpathnames  = 'vief/'+site+'/'+relpathnames1+$
                    '/eiscat_kn_'+site+'_vief_'+relpathnames2+'_v??.cdf'

    files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

    ;----- Print PI info and rules of the road -----;
    if(file_test(files[0]) and (ack_flg eq 0)) then begin
        ack_flg=1
        gatt = cdf_var_atts(files[0])
        print, '**************************************************************************************'
        print, 'Information about EISCAT radar data'
        print, 'PI: ', gatt.PI_name
        print, ''
        print, 'Rules of the Road for EISCAT Radar Data:'
        print, ''
	print_str_maxlet, gatt.Rules_of_use
        print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
        print, '**************************************************************************************'
    endif

    ;----- Load data into tplot variables -----;
    if(not keyword_set(downloadonly)) then downloadonly=0
    if(downloadonly eq 0) then begin
        prefix='eiscat_'
        cdf2tplot, file=files, verbose=source.verbose, prefix=prefix, $
            get_support_data=get_support_data

        len=strlen(tnames(prefix+'vi_0'))
        if len eq 0 then begin
            ;--- Quit if no data have been loaded
            print, 'No tplot var loaded for '+site_code[i]+'.'
        endif else begin
            ;----- Loop for params -----;
            tplot_name_all=tnames(prefix+'*_0')
	    for itname=0, n_elements(tplot_name_all)-1 do begin
	        tplot_name_tmp=tplot_name_all[itname]

                ;----- Get_data of tplot_name_tmp -----;
                get_data, tplot_name_tmp, data=d, dl=dl, lim=lim 

                ;----- Find param -----;
                len=strlen(tplot_name_tmp)
                pos=strpos(tplot_name_tmp,'_')
                param=strmid(tplot_name_tmp,pos+1,len-pos-3)

                ;----- Rename tplot variables -----;
                case param of
                    'pulse_code_id' : paramstr='pulse'
                    'int_time_nominal' : paramstr='inttim'
                    'vi_err'        : paramstr='vierr'
                    'E_err'         : paramstr='Eerr'
                    'quality'       : paramstr='q'
                    'int_time_real' : paramstr='inttimr'
                    else            : paramstr=param
                endcase

                tplot_name_new='eiscat_'+site+'_'+paramstr
                copy_data, tplot_name_tmp, tplot_name_new
                store_data, tplot_name_tmp, /delete

                ;----- Set options -----;
                titlehead=site+'!C'
                case param of
	            'pulse_code_id' : begin
		        options, tplot_name_new, labels='Pulse code ID', $
		          ytitle=titlehead+'Pulse code ID'
		      end
	            'int_time_nominal' : begin
		        options, tplot_name_new, labels='int.time!C(nominal)', $
		          ytitle=titlehead+'Int. time (nominal)', ysubtitle = '[s]'
		        tclip, tplot_name_new, 0, 1e+4, /overwrite
                        ylim, tplot_name_new, -50, 350
		      end
	            'lat' : begin
		        options, tplot_name_new, labels='Lat', $
		          ytitle=titlehead+'Latitude', ysubtitle = '[deg]'
                      end
	            'long' : begin
		        options, tplot_name_new, labels='Lon', $
		          ytitle=titlehead+'Longitude', ysubtitle = '[deg]'
                      end
	            'alt' : begin
		        options, tplot_name_new, labels='Alt', $
		          ytitle=titlehead+'Altitude', ysubtitle = '[km]'
                      end
	            'vi' : begin
		        options, tplot_name_new, labels=['Ve', 'Vn', 'Vu'], $
		          ytitle=titlehead+'Vi', ysubtitle = '[m/s]', colors=[2,4,6]
			ylim, tplot_name_new, -1000., 1000.
		      end
	            'vi_err' : begin
		        options, tplot_name_new, labels=['Ve_err', 'Vn_err', 'Vu_err'], $
		          ytitle=titlehead+'Vi err.', ysubtitle = '[m/s]', colors=[2,4,6]
                        ylim, tplot_name_new, 0., 1000.
		      end
	            'E' : begin
		        options, tplot_name_new, labels=['Ee', 'En', 'Eu'], $
		          ytitle=titlehead+'E', ysubtitle = '[mV/m]', colors=[2,4,6]
                        ylim, tplot_name_new, -50., 50.
		      end
	            'E_err' : begin
		        options, tplot_name_new, labels=['Ee_err', 'En_err', 'Eu_err'], $
		          ytitle=titlehead+'E err.', ysubtitle = '[mV/m]', colors=[2,4,6]
                        ylim, tplot_name_new, 0., 50.
		      end
	            'quality' : begin
		        options, tplot_name_new, labels=['q1','q2','q3'], $
		          ytitle=titlehead+'Quality'
		      end
	            'int_time_real' : begin
		        options, tplot_name_new, labels='int.time!C   (real)', $
		          ytitle=titlehead+'Int. time (real)', ysubtitle = '[s]'
		        tclip, tplot_name_new, 0, 1e+4, /overwrite
                        ylim, tplot_name_new, -50, 350
		      end
                    else : dumm=0
                endcase
            endfor
        endelse
    endif
endfor

return
end


