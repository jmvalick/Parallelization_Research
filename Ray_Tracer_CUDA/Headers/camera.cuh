#pragma once

#define M_PI 3.14159265358979323846

#include <curand_kernel.h>

#include "ray.cuh"


class camera {
	public:
		__device__ camera(vec3 lookfrom, vec3 lookat, vec3 vup, float vfov, float aspect, float aperture, float focus_dist);
		
		vec3 lower_left_corner;
		vec3 horizontal;
		vec3 vertical;
		vec3 origin;
		vec3 u, v, w;
		float lens_radius;

		__device__ virtual ray get_ray(float s, float t, curandState* local_rand_state);
};