;+
; FUNCTION: GET_SOURCE_URL_LIST
;   url_out=get_source_url_list(url_in, xmldir, xmlfile)
;
; PURPOSE:
;   Gets URLs of data files from the metadata database.
;
; KEYWORDS:
;   url_in = Query in the OpenSearch format
;   xmldir = Directory where XML file will be downloaded to.
;   xmlfile = Returned XML file for search result
;   url_out = URLs of data files returned by the Metadata databese
;
; EXAMPLE:
;   url_in='http://search.iugonet.org/iugonet/open-search/request?'+$
;          'query=nipr_1sec_fmag_syo_20100101_v02.cdf'
;   url_out=get_source_url_list(url_in, './', 'tmp.xml')
;
; Written by Y.-M. Tanaka, Sep. 15, 2011 (ytanaka at nipr.ac.jp)
;-


FUNCTION get_source_url_list, url_in, xmldir, xmlfile

  ;----- keyword check -----;
  IF ~KEYWORD_SET(xmldir) THEN xmldir=root_data_dir()
  IF ~KEYWORD_SET(xmlfile) THEN xmlfile='tmp.xml'
  
  url_out=''
  
  ;----- download xmlfile -----;
  file_http_copy, xmlfile, serverdir=url_in, localdir=xmldir
  
  ;----- parse XML and get URL -----;
  oDoc = OBJ_NEW('IDLffXMLDOMDocument', filename=xmldir+xmlfile, $
                 schema_checking=0)  ; Create IDLffXMLLOM objects
  ; oPlugin = oDoc->GetFirstChild()
  ; oNodeList = oPlugin->GetElementsByTagname('dc:identifier')
  oNodeList = oDoc->GetElementsByTagname('dc:identifier')
  n = oNodeList->GetLength()
  
  IF n GT 0 THEN BEGIN
    url_out=STRARR(n)
    FOR i=0, n-1 DO BEGIN
      oName = oNodeList->Item(i)
      
      IF OBJ_VALID(oName) THEN BEGIN
        oNameText = oName->GetFirstChild()
        url_out(i)=oNameText->GetNodeValue()
      ENDIF
    ENDFOR
  ENDIF
  
  OBJ_DESTROY, oDoc
  
  RETURN, url_out
  
END


