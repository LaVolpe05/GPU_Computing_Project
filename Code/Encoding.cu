#include <stdlib.h>
#include <stdio.h>
#include <cusparse.h>
#include <math.h>


/*** A new type representing an Hybrid matrix***/
typedef struct{
    int cut_off;
    float * ell_data;
    int * ell_col;
    int ell_size;
    float * coo_data;
    int * coo_col;
    int * coo_row;
    int coo_size;
}Hyb;


/*** Input : Two matrices on Hybrid format 

    Output : Return 2 array ; one is the ELL values of the multiplication and the other one is the COO values of the multiplication 
***/


__global__ void HYB_multiplication(float * ell_data , int * ell_col_ids,int size_of_ell,int cut_off ,float * coo_data,int * col_ids,int * rows_ids, int size_of_coo , float *inELL, float * inCOO ,float * outEll , float * outCoo ){
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int nbRow = size_of_ell/cut_off;
    //ELL multiplication
    if (idx < nbRow){
        int row = idx ;
        float dot = 0;
        for (int element = 0; element < cut_off ; element++){ //elements_in_rows
            int element_offset = row + element * nbRow;
            dot += ell_data[element_offset]* inELL[ell_col_ids[element_offset]];

        }
        atomicAdd(outEll + row, dot);

    }
    //COO multiplication
    for (int element = idx ; element < size_of_coo; element += blockDim.x * gridDim.x){
        float dot = coo_data[element] * inCOO[col_ids[element]];
        atomicAdd(outCoo+ rows_ids[element],dot);
    }
}
/*** Input : A matrix on Hybrid format composed of(Ell : values and siz ; COO :values and size ) plus a scalar we multiply it with .

    Output : Return a matrix in Hybrid format 

***/
__global__ void HYB_multiplication_scalar(float * ell_data ,int size_of_ell,float * coo_data, int size_of_coo , float scalar ){
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int nbRow = size_of_ell/cut_off;
    //ELL multiplication with scalar
    if (idx < nbRow){
        for (int element = 0; element < cut_off ; element++){
            ell_data[element] = ell_data[element] * scalar;
        }

    }
    //COO multiplication with scalar
    for (int element = idx ; element < size_of_coo; element += blockDim.x * gridDim.x){
        coo_data[element]  = coo_data[element] * scalar;
    }
    
}


/*** Input : Two matrices on Hybrid format 

    Output : Return the first matrix with the addition performed with the second one 
    ***/
__global__ void HYB_addition(float * ell_data , int * ell_col_ids,int size_of_ell,int cut_off ,float * coo_data,int * col_ids, int size_of_coo , float *inELL, float * inCOO  ){
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int nbRow = size_of_ell/cut_off;
    //ELL addition
    if (idx < nbRow){
        int row = idx ;
        for (int element = 0; element < cut_off ; element++){ //elements_in_rows
            int element_offset = row + element * nbRow;
            ell_data[element_offset]= ell_data[element_offset] + inELL[ell_col_ids[element_offset]];

        }
    }
    //COO addition
    for (int element = idx ; element < size_of_coo; element += blockDim.x * gridDim.x){
        coo_data[element] = coo_data[element] + inCOO[col_ids[element]];
    }
    
}t

/*** Input : 

    Output : A 2-Dimensional array , each rows is the list of index of the matrices to be multiply 
***/
int **getCombinaison(int start ,int end , int length , int dimension){
    int size = length-1 ;
    //int arr_size = pow(dimension,size);
    char arr[2][3] = {{11, 22, 33},{11, 22, 33}};
    int indices[size];
    int new_arr[dimension*dimension*size];
    for (int i = 0; i < dimension*dimension*size; i++){
        new_arr[i] = 0;
    }
    //printf("here");
    for (int i = 0; i < size; i++){
        indices[i] = 0;
    }
    //printf("here");
    while (1) {
    
        // print current combination
        for (int i = 0; i < size; i++){
            if(i != 0 && i != size-1){
                printf("%d",arr[i][indices[i]]);
            }else{
                if(i == 0){
                    printf("%d ",arr[i][indices[i]]+(start*100));
                }
                if(i == size-1){
                    printf("%d ",arr[i][indices[i]]*10+(end));
                }
            }
            
            //new_arr[i] = arr[i][indices[i]];
            //printf("%d ",new_arr[i]);
            
        }
        printf("\n");
 
        // find the rightmost array that has more
        // elements left after the current element
        // in that array
        int next = size - 1;
       // printf("%d , %d , %d \n", next,indices[next],dimension);
        while (next >= 0 && (indices[next] + 1 >= dimension)){
            next--;
        }
        // no such array is found so no more
        // combinations left
        if (next < 0){
            return;
        }
        // if found move to next element in that
        // array
        indices[next]++;
 
        // for all arrays to the right of this
        // array current index again points to
        // first element
        for (int i = next + 1; i < size; i++){
            indices[i] = 0;
        }
    }
     /*for (int i = 0; i < dimension*dimension; i++){
        for (int j = 0; j < size; j++){
        printf("%d ",new_arr[i][indices[i]]);
    }
    printf("\n");
    }*/
        
    
}
    

    
    return arr;
}
/*** Input : The multiplex starting and ending , the length of the path , the SupraMatrix dimension (a squared matrix ) ,
 the combinnaison which conduct the matrix mutlpilication 


    Output : Return a matrix on Hybrid format 
***/
__global__ void getMatrixFromCombinaison(int start ,int end , int length , int dimension, HYB * SupraMatrix, int * combinaison  ){

    


}

/*** Intput : cut_off value , the COO structure size , the rows array of the COO structure

    Output : Return the size of the new COO structure for the COOToHybrid transformation
***/

int size_of_new_coo(int * rows, int COO_size , int cut_off){
    int size = 0;
    int count = 0;
    for (int i = 0 ; i < COO_size; i++){
        if (i == 0){
            count++;
        }else{
            if( rows[i-1] == rows[i]){
                count++;
            }else{
                count = 1;
            }
        }
        if (count > cut_off){
            size++;
        }
    }
    return size;
}

/*** Input : A COO structure composed of (values , columns , rows and the size of the arrays), the dimension of the original matrix , the value of the cut_off,
    a pre-composed hybrid structure composed of (Ell : values and columns ; COO :values , columns , rows)

    Output : An Hybrid structure composed of (Ell : values and columns ; COO :values , columns , rows)
***/

int cooToHyb(int* values,int * columns, int * rows ,int COO_size , int nbCol , int nbRow,int cut_off,int ** ELL_Values, int ** ELL_Indexes,int ** COO_Values, int ** COO_Col , int ** COO_Row){
  int size_of_coo = size_of_new_coo(rows,COO_size,cut_off);
  int size_of_ell = nbRow*cut_off;
  int temp_COO_values[size_of_coo];
  int temp_COO_row[size_of_coo];
  int temp_COO_col[size_of_coo];
  int temp_ELL_values[size_of_ell];
  int temp_ELL_indexes[size_of_ell];
  int elements_in_the_row = 0 ; 
  int current_row = 0;
  int index_ELL = 0;
  int index_COO = 0;
  for (int i = 0 ; i < COO_size ; i++){
      if(rows[i] == current_row ){
          //ELL format if we are below the cut-off 
          if(elements_in_the_row < cut_off){
              temp_ELL_values[index_ELL] = values[i];
              temp_ELL_indexes[index_ELL] = columns[i];
              //printf("ELL value : %d and columns %d \n",temp_ELL_values[index_ELL],temp_ELL_indexes[index_ELL]);
              index_ELL++;
          }else{// COO format if we are above the cut-off
                temp_COO_values[index_COO] = values[i];
                temp_COO_col[index_COO] = columns[i];
                temp_COO_row[index_COO] = rows[i];
                //printf("COO value : %d and columns %d and row %d  \n",temp_COO_values[index_COO],temp_COO_col[index_COO],temp_COO_row[index_COO]);
                index_COO++;
          }
          elements_in_the_row++;
          
      }else{
          //Handle with rows fill with zero
          if((rows[i]-current_row) != 1){
            for(int j = 0 ; j < (cut_off*(rows[i]-current_row-1));j++){
                temp_ELL_values[index_ELL] = -1 ;
                temp_ELL_indexes[index_ELL] = -1;
                //printf("ELL(fill_line) value : %d and columns %d \n",temp_ELL_values[index_ELL],temp_ELL_indexes[index_ELL]);
                index_ELL++;
            }
            

          }
          //Complete line of ELL format
          if (elements_in_the_row < cut_off){
                for(int j = 0 ; j < (cut_off-elements_in_the_row);j++){
                    temp_ELL_values[index_ELL] = -1 ;
                    temp_ELL_indexes[index_ELL] = -1;
                    //printf("ELL(complete) value : %d and columns %d\n",temp_ELL_values[index_ELL],temp_ELL_indexes[index_ELL]);
                    index_ELL++;
                }

          }
          current_row = rows[i];
          temp_ELL_values[index_ELL] = values[i];
          temp_ELL_indexes[index_ELL] = columns[i];
          //printf("ELL(new line) value : %d and columns %d   \n",temp_ELL_values[index_ELL],temp_ELL_indexes[index_ELL]);
          index_ELL++;
          elements_in_the_row = 1;


      }
    
  }
  printf("Actualise ! \n");
  *ELL_Values = temp_ELL_values;
  *ELL_Indexes = temp_ELL_indexes;
  *COO_Values = temp_COO_values;
  *COO_Col = temp_COO_col;
  *COO_Row = temp_COO_row;
  return index_ELL;
}

void Katz_Similarity(int theta ,int pathLength,int start,int end){
    int * temp_COO_values;
    int * temp_COO_row;
    int * temp_COO_col;
    int * temp_ELL_values;
    int * temp_ELL_indexes;
    dim3 dimBlock( RowA/cut_off, RowA/cut_off);
	dim3 dimGrid( 1, 1 );
    
    for(int k = 0 ; k < pathLength ; k++){
        HYB_addition<<<dimGrid,dimBlock>>>(temp_COO_values,temp_COO_row,temp_COO_col,temp_ELL_values,temp_ELL_indexes,(matrixFactorMultiplication(pow(theta,k),getMatrixFromCombinaison(start,end,k,dimension,HYB supraAdjacency,combination))));
    }
Impl



}










int main()
{



   /* int COO_size_MatriceA = 10;
    int Row_size_MatriceA = 5;
    int Col_size_MatriceA = 5;
    int cut_off_MatriceA = 2;

    int valueMatA[COO_size_MatriceA]=  {1,5,8,2,3,8,1,4,5,6};
    int colMatA[COO_size_MatriceA] = {0,0,1,2,0,0,1,0,3,4};
    int rowMatA[COO_size_MatriceA] = {0,1,1,1,2,3,3,4,4,4};


    int * ELL_Values_MatriceA;
    int * ELL_Indexes_MatriceA;
    int * COO_Values_MatriceA;
    int * COO_Col_MatriceA;
    int * COO_Row_MatriceA;

    
    
    
    int size_of_coo_MatriceA = size_of_new_coo(rowMatA,COO_size_MatriceA,cut_off_MatriceA);
    int size_ELL_MatriceA = cooToHyb(valueMatA,colMatA,rowMatA,COO_size_MatriceA,Col_size_MatriceA,Row_size_MatriceA,cut_off_MatriceA,&ELL_Values_MatriceA,&ELL_Indexes_MatriceA,&COO_Values_MatriceA,&COO_Col_MatriceA,&COO_Row_MatriceA);

    /*** Printing result of COO to HYB format ***//*
   printf("The ELL part of the sparse format is :\n");
    printf("|| Values | Indexes ||\n");
    for (int i = 0 ; i < size_ELL_MatriceA;i++){
        printf("|| %d | %d ||\n",*(ELL_Values_MatriceA+i),*(ELL_Indexes_MatriceA+i));
    }
    printf("The COO part of the sparse format is :\n");
    printf("|| Values | Columns | Rows ||\n");
    for (int i = 0 ; i < size_of_coo_MatriceA;i++){
        printf("|| %d | %d | %d ||\n",*(COO_Values_MatriceA+i),*(COO_Col_MatriceA+i),*(COO_Row_MatriceA+i));
    }*/
    //int size = 840058;
    //float *mypointer =(float*) 2914545049664;
    //printf("%f",*(mypointer));
    /*for (int i = 0 ; i < size ; i++){
        printf("%f ",*(mypointer + (i*sizeof(float))));
    }*/





    /*** TEST Hybrid Multiplication Kernel***/
    int cut_off = 2;
    /*****************************************************/
    /*int MatriceA[16] = {5,6,7,8,
                        1,2,3,4,
                        9,10,11,12,
                        0,0,1,0};
     int ColA = 4;*/int RowA = 4 ;
    int ELL_ValuesA[cut_off*RowA] ={ 5,6,
                                     1,2,
                                     9,10,
                                     1,-1};
    int ELL_Col_idsA[cut_off*RowA] ={ 0,1,
                                      0,1,
                                      0,1,
                                      2,-1};
    int Coo_ValuesA[6] = {7,8,3,4,11,12};
    int Coo_ColA[6] = {2,3,2,3,2,3};
    int Coo_RowA[6] = {0,0,1,1,2,2};


    int ell_sizeA = cut_off*RowA*sizeof(int);
    int *cuda_Ell_Val_A;
    int *cuda_Ell_Col_A;
    cudaMalloc( (void**)&cuda_Ell_Val_A, ell_sizeA );
    cudaMalloc( (void**)&cuda_Ell_Col_A, ell_sizeA );
    cudaMemcpy( cuda_Ell_Val_A, &ELL_ValuesA, ell_sizeA, cudaMemcpyHostToDevice ); 
    cudaMemcpy( cuda_Ell_Col_A, &ELL_Col_idsA, ell_sizeA, cudaMemcpyHostToDevice ); 

    int coo_sizeA = 6*sizeof(int);
    int *cuda_Coo_Val_A;
    int *cuda_Coo_Col_A;
    int *cuda_Coo_Row_A;
    cudaMalloc( (void**)&cuda_Coo_Val_A, coo_sizeA );
    cudaMalloc( (void**)&cuda_Coo_Col_A, coo_sizeA );
    cudaMalloc( (void**)&cuda_Coo_Row_A, coo_sizeA );
    cudaMemcpy( cuda_Coo_Val_A, &Coo_ValuesA, coo_sizeA, cudaMemcpyHostToDevice ); 
    cudaMemcpy( cuda_Coo_Col_A, &Coo_ColA, coo_sizeA, cudaMemcpyHostToDevice ); 
    cudaMemcpy( cuda_Coo_Row_A, &Coo_RowA, coo_sizeA, cudaMemcpyHostToDevice ); 

    /*****************************************************/
    /*int MatriceB[16] = {5,0,0,8,
                        2,4,5,0,
                        6,0,0,0,
                        7,8,0,0};
    int ColB = 4; */int RowB = 4 ;
    int ELL_ValuesB[cut_off*RowB] ={ 5,8,
                                    2,4,
                                    6,-1,
                                    7,8};
    int ELL_Col_idsB[cut_off*RowB] ={ 0,3,
                                      0,1,
                                      0,-1,
                                      0,1};
    int Coo_ValuesB[1] = {5};
    int Coo_ColB[1] = {2};
    int Coo_RowB[1] = {1};


    int ell_sizeB = cut_off*RowB*sizeof(int);
    int *cuda_Ell_Val_B;
    int *cuda_Ell_Col_B;
    cudaMalloc( (void**)&cuda_Ell_Val_B, ell_sizeB );
    cudaMalloc( (void**)&cuda_Ell_Col_B, ell_sizeB );
    cudaMemcpy( cuda_Ell_Val_B, &ELL_ValuesB, ell_sizeB, cudaMemcpyHostToDevice ); 
    cudaMemcpy( cuda_Ell_Col_B, &ELL_Col_idsB, ell_sizeB, cudaMemcpyHostToDevice );
     

    int coo_sizeB = sizeof(int);
    int *cuda_Coo_Val_B;
    int *cuda_Coo_Col_B;
    int *cuda_Coo_Row_B;
    cudaMalloc( (void**)&cuda_Coo_Val_B, coo_sizeA );
    cudaMalloc( (void**)&cuda_Coo_Col_B, coo_sizeA );
    cudaMalloc( (void**)&cuda_Coo_Row_B, coo_sizeA );
    cudaMemcpy( cuda_Coo_Val_B, &Coo_ValuesB, coo_sizeB, cudaMemcpyHostToDevice ); 
    cudaMemcpy( cuda_Coo_Col_B, &Coo_ColB, coo_sizeB, cudaMemcpyHostToDevice ); 
    cudaMemcpy( cuda_Coo_Row_B, &Coo_RowB, coo_sizeB, cudaMemcpyHostToDevice ); 
    /*****************************************************/
    int size_output = 16;
    int * cudaoutELL;
    int * cudaoutCOO ;
    int outELL[size_output];
    int outCOO[size_output];
    

    cudaMalloc( (void**)&cudaoutELL, size_output*sizeof(int) );
    cudaMalloc( (void**)&cudaoutCOO, size_output*sizeof(int) );
    
    
    
    /*****************************************************/

    dim3 dimBlock( RowA/cut_off, RowA/cut_off);
	dim3 dimGrid( 1, 1 );
    
    HYB_multiplication<<<dimGrid, dimBlock>>>( cuda_Ell_Val_A , cuda_Ell_Col_A,cut_off*RowA,cut_off ,cuda_Coo_Val_A,cuda_Coo_Col_A,cuda_Coo_Row_A, 6 ,  cuda_Ell_Val_B ,  cuda_Coo_Val_B ,cudaoutELL , cudaoutCOO);
    cudaDeviceSynchronize();
    cudaMemcpy( outELL, &cudaoutELL, coo_sizeB, cudaMemcpyDeviceToHost ); 
    cudaMemcpy( outCOO, &cudaoutCOO, coo_sizeB, cudaMemcpyDeviceToHost ); 
    printf("ELL");
    for (int i = 0 ; i < size_output ; i++){
        printf("%d ",outELL[i]);
        
    }
    printf("\nCOO");
    for (int i = 0 ; i < size_output ; i++){
        printf("%d ",outCOO[i] );
    }
    

}
