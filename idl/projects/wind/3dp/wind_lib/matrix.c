#include <math.h>

#include "matrix.h"

int get_rot_mat(double (*R)[3],double *v);
double dot_prod(double *v1,double *v2);
double normalize_vector(double *v);
void cross_prod(double *a,double *b,double *c);
void transpose_matrix(double *T,double *M);
void mult_matrix(double *M,double *A,double *B,int r,int l,int c);
void rotate(double *x,double (*R)[3]);
double smatinv(double *R,int N);
void mvmult(double *R,double *V,double *A,int N);

int get_rot_mat(double R[3][3],double v[3])  /* creates a rotation matrix that transforms v into z' */
{                                        /* with  (y' dot x)==0  */
	double xp[3],yp[3],zp[3];
	double mag;

	int i;
	for(i=0;i<3;i++)
		zp[i] = v[i];

	mag = normalize_vector(zp);
	if(mag==0) return(0);
	for(i=0;i<3;i++)
		R[2][i] = zp[i];

	xp[0]=1; xp[1]=0; xp[2]=0;
	cross_prod(yp,zp,xp);              /* yp = zp cross x */
	mag = normalize_vector(yp);
	if(mag==0){  yp[1]=yp[0]=0;  yp[2]=1; }

	for(i=0;i<3;i++)
		R[1][i] = yp[i];

	cross_prod(xp,yp,zp);
/*	mag = normalize_vector(xp);      this step should not be nec.  */
	for(i=0;i<3;i++)
		R[0][i] = xp[i];
	return(1);
}

double dot_prod(double v1[3],double v2[3])
{
	return(v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2]);
}

double normalize_vector(double v[3])  /* returns magnitude */
{
	double mag;

	mag = sqrt(dot_prod(v,v));
	if(mag!=0){
		v[0] /= mag;
		v[1] /= mag;
		v[2] /= mag;
	}
	return(mag);
}

void cross_prod(double a[3],double b[3],double c[3])  /* a = b x c */
{
	a[0] = b[1]*c[2] - b[2]*c[1];
	a[1] = b[2]*c[0] - b[0]*c[2];
	a[2] = b[0]*c[1] - b[1]*c[0];
}

void transpose_matrix(double *T,double *M)
{
	int i,j;
	for(i=0;i<3;i++)
		for(j=0;j<3;j++)
			T[i*3+j] = M[j*3+i];
}



void mult_matrix(double *M,double *A,double *B,int r,int l,int c)  /* M = A*B */
{                    /* M[r][c] = A[r][l] * B[l][c]     (sum over l)     */ 
	int i,j,k;
	double x;
	for(i=0;i<r;i++){
		for(j=0;j<c;j++){
			x=0;
			for(k=0;k<l;k++)
				x+= A[i*l+k] * B[k*c+j];
			M[i*c+j] = x;
		}
	}
}

void rotate(double x[3],double R[3][3])
{
	double y[3];
	int i,j;

	for(i=0; i<3; i++) {		/* Rotate cartesian vector */
		y[i] = 0.;
		for(j=0; j<3; j++)
			y[i] += R[i][j]*x[j];
	}
	for(i=0; i<3; i++) x[i] = y[i];
}

#define abs(X)  (X < 0. ? -X : X)
#define NUMFITVAR 10

double smatinv(double R[],int N)
{
        double det,amax,save;
        int i,j,k,l,l1,l2;
        int ikk,jkk;
        int ik[NUMFITVAR],jk[NUMFITVAR];

        det = 1.;
        for(k=0; k<N; k++) {
                amax = 0.;                      /* Find largest remaining element */
                for(i=k; i<N; i++) {
                        l1 = i*N + k;
                        for(j=k; j<N; j++) {
                                if(abs(amax) <= abs(R[l1])) {
                                        amax = R[l1];
                                        ik[k] = ikk = i;
                                        jk[k] = jkk = j;
                                }
                                l1++;
                        }
                }
                if(amax == 0.) return(0.);

/* Now swap rows,cols to get amax to R[k,k] */
                if(ikk > k) {
                        l1 = ikk*N;
                        l2 = k*N;
                        for(j=0; j<N; j++) {
                                save = R[l2];
                                R[l2++] = R[l1];
                                R[l1++] = -save;
                        }
                }
                if(jkk > k) for(i=0; i<N; i++) {
                        l1 = i*N;
                        save = R[l1+k];
                        R[l1+k] = R[l1+jkk];
                        R[l1+jkk] = -save;
                }

/* Accumulate elements of inverse matrix */
                for(i=0; i<N; i++) if(i != k) R[i*N+k] /= -amax;
                l2 = k*N;
                for(i=0; i<N; i++) if(i != k) {
                        l1 = i*N;
                        for(j=0; j<N; j++) if(j != k)
                                R[l1+j] += R[l1+k]*R[l2+j];
                }
                for(j=0; j<N; j++) if(j != k) R[l2+j] /= amax;
                R[l2+k] = 1./amax;
                det *= amax;
        }

/* Restore ordering of matrix */

        for(l=0; l<N; l++) {
                k = N-l-1;
                if((j = ik[k]) > k) for(i=0; i<N; i++) {
                        l1 = i*N;
                        save = R[l1+k];
                        R[l1+k] = -R[l1+j];
                        R[l1+j] = save;
                }
                if((i = jk[k]) > k) {
                        l1 = i*N;
                        l2 = k*N;
                        for(j=0; j<N; j++) {
                                save = R[l2];
                                R[l2++] = -R[l1];
                                R[l1++] = save;
                        }
                }
        }

        return(det);
}

/*
        Matrix functions:
                det = smatinv(A,N)              Matrix inversion
                        A = NxN symetric matrix to invert
                        det is the determinant (0. -> singular)

                mvmult(R,V,A,N)                 Matrix - vector multiply
                        A = R x V;
                        R = NxN matrix
                        A,V = N vectors
*/


void mvmult(double *R,double V[],double *A,int N)
{
        int i,j;
        double sum;

        for(i=0; i<N; i++) {
                sum=0.;
                for(j=0; j<N; j++) sum += V[j] * *R++;
                *A++ = sum;
        }
}

