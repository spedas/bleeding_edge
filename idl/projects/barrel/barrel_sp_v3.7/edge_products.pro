;+
; Name: edge_products
;
; Purpose: From a vector of contiguous channel boundaries return the
;   commonly used quantities for plotting and scaling.
;
; Category:
;   GEN, SPECTRA
;
; Input: Edges -if 1d, contiguous channel boundaries, n+1 values for n channels
;               if 2d, 2xn, [lo(i),hi(i)], etc., assumed contiguous for
;     calculating edges_1
;
; Output:
;   Mean - arithmetic mean of boundaries
;       Gmean - geometric mean
;   width - absolute difference between upper and lower edges
;   edges_2 - 2xn array of edges [lo(i), hi(i)], etc.
;       edges_1 - array of n+1 edges of n contiguous channels
;
;       Keyword Input
;       EPSILON - If the absolute relative difference is less than epsilon
;       then two numbers are considered to be equal and a new bin is not required under
;   the contiguous requirement.  If epsilon isn't passed but CONTIGOUS is set it
;       attempts to construct an epsilon based on the average relative difference between
;       adjacent bins, it takes that value and multiplies it by 1e-5 and limits that to
;       1e-6
;   CONTIGUOUS - force all edges to be contiguous, including edges_1
;
; Mod. History:
; ras, 21-oct-93
; 8-dec-2001, richard.schwartz@gsfc.nasa.gov, added CONTIGUOUS
; added protection against degenerate entry of single value for edges,
; clearly edges_2 and width have no meaning, but are set to edges and 0.0 respectively
; 25-aug-2006, ras, added epsilon and default epsilon as test
;       to differentiate real numbers. If the absolute relative difference is less than epsilon
;       then two numbers are considered to be equal and a new bin is not required under
;   the contiguous requirement
;-
pro edge_products, edges, mean=mean, gmean=gmean, width=width, $
    edges_2=edges_2, edges_1=edges_1, contiguous=contiguous, epsilon=epsilon


;Set up defaults for degenerate case of single value
width = 0.0
mean = edges
gmean = edges
edges_2 = edges
edges_1 = edges
if n_elements( edges )  eq 1 then return

dims = size( edges )

if dims(0) eq 2 and dims(1) eq 2 then begin
    n = dims(2)
    edges_2 = edges
    edges_1 = [(edges_2(0,*))(*), edges_2(1,n-1)]
endif else begin
    n = n_elements(edges)-1
    edges_2 = reform( transpose( [ [edges(0:n-1)],[edges(1:*)]]),2,n)
    edges_1 = edges
endelse

if keyword_set( contiguous ) then begin
        diff = (f_div(edges[1:*]-edges,edges))
        resistant_mean, diff, 2.0, av_diff

        default, epsilon, av_diff gt 0 ? (av_diff*1e-5 > 1e-6) : 1e-5

    edges_1 =get_uniq(edges, epsilon=epsilon) ;edges(uniq( edges, sort(edges)))
    n = n_elements( edges_1 ) -1
    edges_2 = transpose( [ [edges_1(0:n-1)],[edges_1(1:*)]])
    endif

mean = total( edges_2,1 )/2.
gmean = ( ((edges_2(0,*)*edges_2(1,*))>0.0)^0.5 )(*)

width = abs(( edges_2(1,*)-edges_2(0,*) )(*))

end
