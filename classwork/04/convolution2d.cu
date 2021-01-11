#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>

__global__ void convolution_2D_basic_kernel(float* in, float* mask, float* out, int mask_width, int width, int height) {

    int row = blockIdx.x * blockDim.x + threadIdx.x;
    int col = blockIdx.y * blockDim.y + threadIdx.y;

    if (row < height && col < width) {
        int curr_row, curr_col;
        float val = 0.0;
        int n_start_row = row - (mask_width / 2);
        int n_start_col = col - (mask_width / 2);
        for (int i = 0; i < mask_width; i++) { // row
            for (int j = 0; j < mask_width; j++) { // col
                curr_row = n_start_row + i;
                curr_col = n_start_col + j;
                if (curr_row >= 0 && curr_row < height && curr_col >= 0 && curr_col < width) {
                    val += in[curr_row * width + curr_col] * mask[mask_width * i + j];
                    __syncthreads();
                }
            }
        }
        out[row * width + col] = val;
    }
}



int main() {
    int mask_width = 3, width = 7, height = 7;
    int size = width * height * sizeof(float);
    float in[49] = { 193, 245, 178, 215, 64,  234, 13,
                     70,  87,  228, 65,  157, 73,  135,
                     174, 149, 245, 208, 121, 193, 199,
                     167, 57,  140, 62,  90,  192, 239,
                     41,  192, 35,  237, 212, 97,  33,
                     30,  65,  38,  89,  149, 145, 145,
                     127, 129, 65,  50,  140, 19,  120 };
    float mask[9] = { 1, 2, 1,
                      2, 3, 2,
                      1, 2, 1 };
    float* out = (float*)malloc(size);

    float* device_in, * device_out, * device_mask;
    cudaMalloc((void**)&device_in, size);
    cudaMalloc((void**)&device_out, size);
    cudaMalloc((void**)&device_mask, mask_width * mask_width * sizeof(float));
    cudaMemcpy(device_in, in, size, cudaMemcpyHostToDevice);
    cudaMemcpy(device_mask, mask, mask_width * mask_width * sizeof(float), cudaMemcpyHostToDevice);

    dim3 threadsPerBlock(width, height);
    dim3 blocksPerGrid(1);

    convolution_2D_basic_kernel << < blocksPerGrid, threadsPerBlock >> > (device_in, device_mask, device_out, mask_width, width, height);
    cudaDeviceSynchronize();

    cudaMemcpy(out, device_out, size, cudaMemcpyDeviceToHost);
    for (int i = 0; i < height; ++i) {
        for (int j = 0; j < width; j++) {
            printf("%.f\t", out[i * width + j]);
        }
        printf("\n");
    }
    printf("\n");

    free(out);
    cudaFree(device_in);
    cudaFree(device_out);
    cudaFree(device_mask);
    return 0;
}

