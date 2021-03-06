#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>

#include "common.h"

void stopwatch_start(stopwatch *sw){
    if (sw == NULL)
        return;

    bzero(&sw->begin, sizeof(struct timeval));
    bzero(&sw->end  , sizeof(struct timeval));

    gettimeofday(&sw->begin, NULL);
}

void stopwatch_stop(stopwatch *sw){
    if (sw == NULL)
        return;

    gettimeofday(&sw->end, NULL);
}

double
get_interval_by_sec(stopwatch *sw){
    if (sw == NULL)
        return 0;
    return ((double)(sw->end.tv_sec-sw->begin.tv_sec)+(double)(sw->end.tv_usec-sw->begin.tv_usec)/1000000);
}

long int
get_interval_by_usec(stopwatch *sw){
    if (sw == NULL)
        return 0;
    return ((sw->end.tv_sec-sw->begin.tv_sec)*1000000+(sw->end.tv_usec-sw->begin.tv_usec));
}

func_ret_t
create_matrix_from_file(double **mp, const char* filename, int *size_p){
  int i, j, size;
  double *m;
  FILE *fp = NULL;

  fp = fopen(filename, "rb");
  if ( fp == NULL) {
      return RET_FAILURE;
  }

  if (fscanf(fp, "%d\n", &size) <= 0) {
    return RET_FAILURE;
  }

  m = (double*) malloc(sizeof(double)*size*size);
  if ( m == NULL) {
      fclose(fp);
      return RET_FAILURE;
  }

  for (i=0; i < size; i++) {
      for (j=0; j < size; j++) {
        if (fscanf(fp, "%lf ", m+i*size+j) <= 0) {
          return RET_FAILURE;
        }
      }
  }

  fclose(fp);

  *size_p = size;
  *mp = m;

  return RET_SUCCESS;
}

void
matrix_multiply(double *inputa, double *inputb, double *output, int size){
  int i, j, k;

  for (i=0; i < size; i++)
    for (k=0; k < size; k++)
      for (j=0; j < size; j++)
        output[i*size+j] = inputa[i*size+k] * inputb[k*size+j];

}

void lud_verify(double *m, double *lu, int matrix_dim){
  int i,j,k;
  double *tmp = (double*)malloc(matrix_dim*matrix_dim*sizeof(double));

  for (i=0; i < matrix_dim; i ++) {
    for (j=0; j< matrix_dim; j++) {
        double sum = 0;
        double l,u;
        for (k=0; k <= MIN(i,j); k++){
            if ( i==k)
              l=1;
            else
              l=lu[i*matrix_dim+k];
            u=lu[k*matrix_dim+j];
            sum+=l*u;
        }
        tmp[i*matrix_dim+j] = sum;
    }
  }

  for (i=0; i<matrix_dim; i++){
      for (j=0; j<matrix_dim; j++){
          if ( fabs(m[i*matrix_dim+j]-tmp[i*matrix_dim+j]) > 0.0001)
            printf("dismatch at (%d, %d): (o)%f (n)%f\n", i, j, m[i*matrix_dim+j], tmp[i*matrix_dim+j]);
      }
  }

  free(tmp);
}

void
matrix_duplicate(double *src, double **dst, int matrix_dim) {
   size_t s = matrix_dim*matrix_dim*sizeof(double);
   double *p = (double *) malloc (s);
   memcpy(p, src, s);
   *dst = p;
}

void
print_matrix(double *m, int matrix_dim) {
    int i, j;
    for (i=0; i<matrix_dim;i++) {
      for (j=0; j<matrix_dim;j++)
        printf("%f ", m[i*matrix_dim+j]);
      printf("\n");
    }
}


// Generate well-conditioned matrix internally  by Ke Wang 2013/08/07 22:20:06

func_ret_t
create_matrix(double **mp, int size){
  double *m;
  int i,j;
  double lamda = -0.001;
  double coe[2*size-1];
  double coe_i =0.0;

  for (i=0; i < size; i++)
    {
      coe_i = 10*exp(lamda*i);
      j=size-1+i;
      coe[j]=coe_i;
      j=size-1-i;
      coe[j]=coe_i;
    }

  m = (double*) malloc(sizeof(double)*size*size);
  if ( m == NULL) {
      return RET_FAILURE;
  }

  for (i=0; i < size; i++) {
      for (j=0; j < size; j++) {
	m[i*size+j]=coe[size-1-i+j];
      }
  }

  *mp = m;

  return RET_SUCCESS;
}
