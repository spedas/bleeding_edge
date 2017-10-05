
/******  Function prototypes for the Matrix.c library  *******/

/*  all the following routines assume vectors have 3 components */


int get_rot_mat(double (*R)[3],double *v);
/*  Produces a rotation matrix R[3][3] that will transform the
    vector v[3] into z'.  ie. V' = R V;  V'=[v,0,0]  */



double dot_prod(double *v1,double *v2);
/*  returns the dot product of two vectors  */


double normalize_vector(double *v);
/*  normalizes a vector to unit length and returns magnitude */


void cross_prod(double *a,double *b,double *c);
/*  computes the cross product a = b x c  */


void transpose_matrix(double *T,double *M);
/*  produces the matrix T[3][3]  which is the transpose of M[3][3]  */


void mult_matrix(double *M,double *A,double *B,int r,int l,int c);
/*     Matrix multiplication                                 */
/*          M[r][c] = A[r][l] * B[l][c]     (sum over l)     */ 



void rotate(double *x,double (*R)[3]);
/*  rotates the vector x.   x' = R x  */


double smatinv(double *R,int N);
/*   inverts a symmetric matrix R[N][N] and returns the determinant  */



void mvmult(double *R,double *V,double *A,int N);
