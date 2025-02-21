#define MAXFLOAT 9999999

#include <iostream>
#include <string>
#include <float.h>
#include <omp.h>
#include <random>
#include <stdlib.h>

#include "fileCreate.h"
#include "hitable_list.h"
#include "sphere.h"
#include "camera.h"
#include "random.h"
#include "material.h"
#include "vec3.h"

using namespace std;



hitable* random_scene() {
    int n = 500;
    hitable** list = new hitable * [n + 1];
    list[0] = new sphere(vec3(0.0f, -1000.0f, 0.0f), 1000.0f, new lambertian(vec3(0.5f, 0.5f, 0.5f)));
    int i = 1;
    for (int a = -11; a < 11; a++) {
        for (int b = -11; b < 11; b++) {
            float choose_mat = random_f();
            vec3 center(a + 0.9f * random_f(), 0.2f, b + 0.9f * random_f());
            if ((center - vec3(4.0f, 0.2f, 0.0f)).length() > 0.9f) {
                if (choose_mat < 0.3f) {  // diffuse
                    list[i++] = new sphere(center, 0.2f, new lambertian(vec3(random_f(), random_f(), random_f())));
                }
                else if (choose_mat < 0.60) { // metal
                    list[i++] = new sphere(center, 0.2f, new metal(vec3(random_f(), random_f(), random_f()), 0.5f * random_f()));
                }
                else {  // glass
                    list[i++] = new sphere(center, 0.2f, new dielectric(vec3(random_f(), random_f(), random_f()), 1.5f));
                }
            }
        }
    }

    list[i++] = new sphere(vec3(0.0f, 1.0f, 0.0f), 1.0f, new dielectric(vec3(random_f(), random_f(), random_f()), 1.5f));
    list[i++] = new sphere(vec3(-4.0f, 1.0f, 0.0f), 1.0f, new lambertian(vec3(random_f(), random_f(), random_f())));
    list[i++] = new sphere(vec3(4.0f, 1.0f, 0.0f), 1.0f, new metal(vec3(random_f(), random_f(), random_f()), 0.5f * random_f()));

    return new hitable_list(list, i);
}


vec3 color(const ray& r, hitable *world, int depth) {
    hit_record rec;
    if (world->hit(r, 0.001f, MAXFLOAT, rec)) {
        ray scattered;
        vec3 attenuation;
        if (depth < 50 && rec.mat_ptr->scatter(r, rec, attenuation, scattered)) {
            return attenuation * color(scattered, world, depth + 1);
        }
        else {
            return vec3(0.0f, 0.0f, 0.0f);
        }
    }
    else {
        vec3 unit_direction = unit_vector(r.direction());
        float t = 0.5f * (unit_direction.y() + 1.0f);
        return (1.0f - t) * vec3(1.0f, 1.0f, 1.0f) + t * vec3(0.5f, 0.7f, 1.0f);
    }
}


int main() {

    // Screen size and samples data
    int image_dim_list[8][2] = { {256, 144}, {426, 240}, {640, 360}, {854, 480}, {1280, 720}, {1920, 1080}, {2560, 1440}, {3840, 2160} };
    int samples_list[8] = { 1, 2, 4, 8, 16, 32, 64, 128 };

    //int image_dim_list[3][2] = { {256, 144}, {426, 240}, {640, 360} };
    //int samples_list[4] = { 1, 2, 4, 8};

    const int num_resolutions = sizeof(image_dim_list) / sizeof(image_dim_list[0]);
    const int num_samples = sizeof(samples_list) / sizeof(samples_list[0]);


    double** time_list = (double**)malloc(num_resolutions * sizeof(double*));
    for (int i = 0; i < num_resolutions; ++i) {
        time_list[i] = (double*)malloc(num_samples * sizeof(double));
    }


    int count = 0;
    for (int i = 0; i < (num_resolutions); i++) {
        for (int j = 0; j < (num_samples); j++) {

            const int image_width = image_dim_list[i][0];
            const int image_height = image_dim_list[i][1];
            const int samples = samples_list[j];

            std::cout << "\nImage Number: " << count << endl;
            std::cout << "Image size: " << image_width << "x" << image_height << endl;
            std::cout << "Samples per pixel: " << samples << endl;
            std::cout << "Device: CPU\n" << endl;

            // Image storage
            size_t image_size = image_width * image_height;
            vec3* image = (vec3*)calloc(image_size, sizeof(vec3));

            // Initialize Camera
            vec3 lookfrom(13.0f, 2.0f, 3.0f);
            vec3 lookat(0.0f, 0.0f, 0.0f);
            float dist_to_focus = 10.0f;
            float aperture = 0.1f;
            camera cam(lookfrom, lookat, vec3(0.0f, 1.0f, 0.0f), 30.0f, float(image_width) / float(image_height), aperture, dist_to_focus);

            // Initialize Scene
            hitable* world = random_scene();

            // Timer
            double start, stop;
            start = omp_get_wtime();

            // Render image
#pragma omp parallel for schedule(dynamic)
            for (int y = image_height - 1; y >= 0; y--) {
                for (int x = 0; x < image_width; x++) {
                    vec3 col(0, 0, 0);

                    for (int sample = 0; sample < samples; sample++) {
                        float u = float(x + random_f()) / float(image_width);
                        float v = float(y + random_f()) / float(image_height);
                        ray r = cam.get_ray(u, v);
                        vec3 p = r.point_at_parameter(2.0);
                        col += color(r, world, 0);
                    }
                    col /= float(samples);
                    col = vec3(sqrt(col[0]), sqrt(col[1]), sqrt(col[2]));
                    image[y * image_width + x] = col * 255.99f;
                }
                if ((image_height - y) % 25 == 0) {
                    cout << "Current Vertical Pixel: " << (image_height - y) << endl;
                }
            }

            stop = omp_get_wtime();
            double timer_seconds = ((double)(stop - start));
            time_list[i][j] = timer_seconds;
            std::cout << "\nRender time: " << timer_seconds << " seconds\n\n";

            // Export to ppm
            createPPMFile(image, image_width, image_height, samples);

            // Clean up
            free(image);

            count += 1;
        }
    }

    createTextFile(image_dim_list, num_resolutions, samples_list, num_samples, time_list);

    return 0;
}