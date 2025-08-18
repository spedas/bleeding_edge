;+
;pro mvn_lpw_cdf_produce_l2, varlist,dir_cdf=dir_cdf,revision=revision
;
;This routine checks that the tplot variables given as inputs are in IDL memory. If so, they are turned into CDF files, and saved in the
;user specified directory. 
;
;
;INPUTS:         
; - varlist: a string or string array of tplot variables (already in IDL memory) to be saved as CDF files.
;   
;KEYWORDS:
;    dir_cdf: A string, of the full path to the CDF save directory.
;    revision: A string, of the revision number. If not set, todays date is used as default for now.
; 
;EXAMPLE:
; mvn_lpw_prd_w_E12
;  mvn_lpw_cdf_produce_l2, 'mvn_lpw_calib_w_e12',revision='r2',dir_cdf=dir_cdf
;
;CREATED BY:   Laila Andersson  April 2014
;FILE:         mvn_lpw_cdf_produce_l2.pro
;VERSION:      1.0
;LAST MODIFICATION: 
;05/02/2014 CF: added several checks for the keywords and inputs to avoid crashes. Tidied up routine.
;;140718 clean up for check out L. Andersson
;
;-

pro mvn_lpw_cdf_produce_l2 , varlist_names,revision=revision,dir_cdf=dir_cdf

;======================
;--- Check keywords ---
;======================
;Check varlist_names is a string:
if (size(varlist_names, /type) ne 7) then begin
    print, "### WARNING ###: Argument varlist_name must be a string or string array containing tplot variables which are in IDL memory."
    print, "For example: mvn_lpw_cdf_produce_l2, 'tplot_variable_to_save', dir_cdf='/Full/path/to/CDF/files/'. Exiting."
    return
endif

;Check dir_cdf:
if not keyword_set(dir_cdf) then begin
    print, "### WARNING ###: Keyword dir_cdf not set. This must be set as a string, as the full save directory for the CDF files."
    print, "For example, dir_cdf = '/Full/path/to/CDF/files/'. Exiting."
    return 
endif else begin
    if (size(dir_cdf, /type) ne 7) then begin
        print, "### WARNING ###: Keyword dir_cdf must be set as a string, as the full save directory for the CDF files."
        print, "For example, dir_cdf = '/Full/path/to/CDF/files/'. Exiting."
        return
    endif
endelse

;Check if revision is set:
if not keyword_set(revision) then begin
    revision = '##'+systime(/utc)+'##'
    print, "### WARNING ###: Keyword revision not set. Setting to todays date: ", revision
endif else begin
    if (size(revision, /type) ne 7) then begin
        print, "### WARNING ###: Keyword revision must be a string. Exiting."  ;otherwise it won't combine with the filename if a float
        return
    endif
endelse
;======================

nele_names = n_elements(varlist_names)

 print,'mvn_lpw_cdf_produce_l2','inne',nele_names-1
 print, nele_names

tplotnames = tnames()  ;list of tplot variables loaded

for ii=0,nele_names-1 do begin
    
    ;===================================
    ;--- Check tplot variables exist ---
    ;===================================
    if total(strmatch(tplotnames, varlist_names[ii])) eq 1 then begin

        print,'mvn_lpw_cdf_produce_l2','loop'
     
        get_data,varlist_names[ii],dlimit=dlimit
    
         tmp=strsplit(dlimit.L0_DATAFILE,' # ',/extract)
         nele_tmp = n_elements(tmp)
         If nele_tmp GT 1 THEN BEGIN
           tmp_sub=strarr(nele_tmp)
           for i=0,nele_tmp-1 do begin 
                tmp1=strsplit(tmp[i],'_',/extract)
                tmp_sub[i]=tmp1[0]
                print,i,' ## ',tmp1[0]
           endfor 
           ;check that all uses the same day data. Compare L0 file names for this.
           
           print,'mvn_lpw_cdf_produce_l2', ' should be stopped here'
         ENDIF  ELSE tmp1=strsplit(tmp,'_',/extract)
    
        tmp2=strsplit(tmp1[5],'.',/extract)
       
        print,tmp1
        filedate=tmp1[4]+'T'+'000000'+'_'+tmp2[0]+'_'+revision  ;filedate goes onto the end of the CDF filename
        print,'####',filedate,'####'
    
    stop
        mvn_lpw_cdf_write, varlist=varlist_name[ii], dir=dir_cdf, cdf_filename=filedate
    endif else print, "#### WARNING ###: Tplot variable ", varlist_names[ii], " not found in IDL memory. Skipping variable."

endfor ; ii - loop over each variable

;  mvn_lpw_cdf_write, varlist='mvn_lpw_calib_mgr_sc_pot'    ,cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_calib_w_e12'         ,cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_calib_w_e12_burst_lf',cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_calib_w_e12_burst_mf',cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_calib_w_e12_burst_hf',cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_calib_w_spec_pas'    ,cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_calib_w_spec_act'    ,cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_derived_w_n'         ,cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_calib_lp_IV'         ,cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_derived_lp_n_T'      ,cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_derived_mrg_ExB'     ,cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
;  mvn_lpw_cdf_write, varlist='mvn_lpw_calib_euv_irr'      ,cdf_filename='_20140105T120505_v01_r01', dir=dir_cdf
    

end