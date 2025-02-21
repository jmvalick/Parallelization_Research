#define MAXFLOAT 9999999

#include <stdlib.h>
#include <iostream>
#include <time.h>

#include <cuda.h>
#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <device_launch_parameters.h>
#include <curand_kernel.h>

#include "fileCreate.h"
#include "hitable_list.cuh"
#include "sphere.cuh"
#include "camera.cuh"
#include "material.cuh"
#include "vec3.cuh"

using namespace std;



///     *** CUDA Version ***    ///
#define checkCudaErrors(val) check_cuda( (val), #val, __FILE__, __LINE__ )
void check_cuda(cudaError_t result, char const *const func, const char *const file, int const line) {
    if (result) {
        std::cerr << "CUDA error = " << static_cast<unsigned int>(result) << " at " << file << ":" << line << " '" << func << "' \n";
        cudaDeviceReset();
        exit(99);
    }
}

__global__ void rand_init(curandState* rand_state) {
    if (threadIdx.x == 0 && blockIdx.x == 0) {
        curand_init(1984, 0, 0, rand_state);
    }
}

__device__ vec3 color_cu(const ray& r, hitable **world, curandState *local_rand_state) {
    ray cur_ray = r;
    vec3 cur_attenuation = vec3(1.0, 1.0, 1.0);
    for (int i = 0; i < 50; i++) {
        hit_record rec;
        if ((*world)->hit(cur_ray, 0.001f, FLT_MAX, rec)) {
            ray scattered;
            vec3 attenuation;
            if (rec.mat_ptr->scatter(cur_ray, rec, attenuation, scattered, local_rand_state)) {
                cur_attenuation *= attenuation;
                cur_ray = scattered;
            }
            else {
                return vec3(0.0f, 0.0f, 0.0f);
            }
        }
        else {
            vec3 unit_direction = unit_vector(cur_ray.direction());
            float t = 0.5f * (unit_direction.y() + 1.0f);
            vec3 c = (1.0f - t) * vec3(1.0f, 1.0f, 1.0f) + t * vec3(0.5f, 0.7f, 1.0f);
            return cur_attenuation * c;
        }
    }
    return vec3(0.0, 0.0, 0.0); // exceeded recursion
}

__global__ void render_init(int max_x, int max_y, curandState *rand_state) {
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int j = threadIdx.y + blockIdx.y * blockDim.y;
    if ((i >= max_x) || (j >= max_y)) return;
    int pixel_index = j * max_x + i;
    // Original: Each thread gets same seed, a different sequence number, no offset
    // curand_init(1984, pixel_index, 0, &rand_state[pixel_index]);
    // BUGFIX, see Issue#2: Each thread gets different seed, same sequence for
    // performance improvement of about 2x!
    curand_init(1984 + pixel_index, 0, 0, &rand_state[pixel_index]);
}

__global__ void render(vec3 *image, int max_x, int max_y, int samples, camera **cam, hitable **world, curandState *rand_state) {
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int j = threadIdx.y + blockIdx.y * blockDim.y;
    if ((i >= max_x) || (j >= max_y)) return;
    int pixel_index = j * max_x + i;
    curandState local_rand_state = rand_state[pixel_index];
    vec3 col(0, 0, 0);
    for (int s = 0; s < samples; s++) {
        float u = float(i + curand_uniform(&local_rand_state)) / float(max_x);
        float v = float(j + curand_uniform(&local_rand_state)) / float(max_y);
        ray r = (*cam)->get_ray(u, v, &local_rand_state);
        col += color_cu(r, world, &local_rand_state);
    }
    rand_state[pixel_index] = local_rand_state;
    col /= float(samples);
    col = vec3( sqrt(col[0]), sqrt(col[1]), sqrt(col[2]));
    image[pixel_index] = 255.99f * col;

    /*if ((max_y - j) % 25 == 0) {
        printf("Current Vertical Pixel: %d\n", max_y - j);
    }*/
}

#define RND (curand_uniform(&local_rand_state))

__global__ void create_world(hitable **d_list, hitable **d_world, camera **d_camera, int image_width, int image_height, curandState *rand_state) {
    if (threadIdx.x == 0 && blockIdx.x == 0) {
        curandState local_rand_state = *rand_state;
        d_list[0] = new sphere(vec3(0, -1000.0, -1), 1000, new lambertian(vec3(0.5, 0.5, 0.5)));
        int i = 1;
        for (int a = -11; a < 11; a++) {
            for (int b = -11; b < 11; b++) {
                float choose_mat = RND;
                vec3 center(a + 0.9f * RND, 0.2, b + 0.9f * RND);
                if (choose_mat < 0.3f) {  // diffuse
                    d_list[i++] = new sphere(center, 0.2f, new lambertian(vec3(RND, RND, RND)));
                }
                else if (choose_mat < 0.60f) {
                    d_list[i++] = new sphere(center, 0.2f, new metal(vec3(RND, RND, RND), 0.5f * RND));
                }
                else {
                    d_list[i++] = new sphere(center, 0.2f, new dielectric(vec3(RND, RND, RND), 1.5f));
                }
            }
        }
        d_list[i++] = new sphere(vec3(0.0f, 1.0f, 0.0f), 1.0f, new dielectric(vec3(RND, RND, RND), 1.5f));
        d_list[i++] = new sphere(vec3(-4.0f, 1.0f, 0.0f), 1.0f, new lambertian(vec3(RND, RND, RND)));
        d_list[i++] = new sphere(vec3(4.0f, 1.0f, 0.0f), 1.0f, new metal(vec3(RND, RND, RND), 0.5f * RND));
        *rand_state = local_rand_state;
        *d_world = new hitable_list(d_list, 22 * 22 + 1 + 3);

        // Initialize Camera
        vec3 lookfrom(13.0f, 2.0f, 3.0f);
        vec3 lookat(0.0f, 0.0f, 0.0f);
        float dist_to_focus = 10.0f;
        float aperture = 0.1f;
        *d_camera = new camera(lookfrom, lookat, vec3(0.0f, 1.0f, 0.0f), 30.0f, float(image_width)/float(image_height), aperture, dist_to_focus);
    }
}


__global__ void free_world(hitable **d_list, hitable **d_world, camera **d_camera) {
    for (int i = 0; i < 22 * 22 + 1 + 3; i++) {
        delete ((sphere*)d_list[i])->mat_ptr;
        delete d_list[i];
    }
    delete* d_world;
    delete* d_camera;
}


int main() {

    
    // Screen size and samples data
    int image_dim_list[8][2] = { {256, 144}, {426, 240}, {640, 360}, {854, 480}, {1280, 720}, {1920, 1080}, {2560, 1440}, {3840, 2160} };
    int samples_list[8] = { 1, 2, 4, 8, 16, 32, 64, 128 };

    //int image_dim_list[3][2] = { {256, 144}, {426, 240}, {640, 360} };
    //int samples_list[4] = { 1, 2, 4, 8 };

    const int num_resolutions = sizeof(image_dim_list) / sizeof(image_dim_list[0]);
    const int num_samples = sizeof(samples_list) / sizeof(samples_list[0]);


    double** time_list = (double**)malloc(num_resolutions * sizeof(double*));
    for (int i = 0; i < num_resolutions; ++i) {
        time_list[i] = (double*)malloc(num_samples * sizeof(double));
    }

    const int block_width = 16;
    const int block_height = 16;


    int count = 0;
    for (int i = 0; i < (num_resolutions); i++) {
        for (int j = 0; j < (num_samples); j++) {

            const int image_width = image_dim_list[i][0];
            const int image_height = image_dim_list[i][1];
            const int samples = samples_list[j];

            std::cout << "Image size: " << image_width << "x" << image_height << endl;
            std::cout << "Samples per pixel: " << samples << endl;
            std::cout << "Device: GPU" << endl;
            std::cout << "Block width: " << block_width << endl;
            std::cout << "Block height: " << block_height << endl;

            // Allocate frame buffer
            int num_pixels = image_width * image_height;
            size_t image_size = num_pixels * sizeof(vec3);
            vec3* image;
            checkCudaErrors(cudaMallocManaged((void**)&image, image_size));

            // Allocate Random State
            curandState* d_rand_state;
            checkCudaErrors(cudaMalloc((void**)&d_rand_state, num_pixels * sizeof(curandState)));
            curandState* d_rand_state2;
            checkCudaErrors(cudaMalloc((void**)&d_rand_state2, 1 * sizeof(curandState)));

            rand_init <<<1, 1 >>> (d_rand_state2);
            checkCudaErrors(cudaGetLastError());
            checkCudaErrors(cudaDeviceSynchronize());

            // Allocate scene
            hitable** d_list;
            int num_hitables = 22 * 22 + 1 + 3;
            checkCudaErrors(cudaMalloc((void**)&d_list, num_hitables * sizeof(hitable*)));
            hitable** d_world;
            checkCudaErrors(cudaMalloc((void**)&d_world, sizeof(hitable*)));
            camera** d_camera;
            checkCudaErrors(cudaMalloc((void**)&d_camera, sizeof(camera*)));
            create_world <<<1, 1 >>> (d_list, d_world, d_camera, image_width, image_height, d_rand_state2);
            checkCudaErrors(cudaGetLastError());
            checkCudaErrors(cudaDeviceSynchronize());

            // Timer
            clock_t start, stop;
            start = clock();

            // Render image
            dim3 blocks(image_width / block_width + 1, image_height / block_height + 1);
            dim3 threads(block_width, block_height);
            render_init <<<blocks, threads >>> (image_width, image_height, d_rand_state);
            checkCudaErrors(cudaGetLastError());
            checkCudaErrors(cudaDeviceSynchronize());
            render <<<blocks, threads >>> (image, image_width, image_height, samples, d_camera, d_world, d_rand_state);
            checkCudaErrors(cudaGetLastError());
            checkCudaErrors(cudaDeviceSynchronize());

            stop = clock();
            double timer_seconds = ((double)(stop - start)) / CLOCKS_PER_SEC;
            time_list[i][j] = timer_seconds;
            std::cout << "\nRendered time: " << timer_seconds << " seconds\n\n";


            // Export to ppm
            createPPMFile(image, image_width, image_height, samples);

            // Clean up
            checkCudaErrors(cudaDeviceSynchronize());
            free_world <<<1, 1 >>> (d_list, d_world, d_camera);
            checkCudaErrors(cudaGetLastError());
            checkCudaErrors(cudaFree(d_camera));
            checkCudaErrors(cudaFree(d_world));
            checkCudaErrors(cudaFree(d_list));
            checkCudaErrors(cudaFree(d_rand_state));
            checkCudaErrors(cudaFree(d_rand_state2));
            checkCudaErrors(cudaFree(image));

            cudaDeviceReset();
        }
    }

    createTextFile(image_dim_list, num_resolutions, samples_list, num_samples, time_list);

    return 0;
}