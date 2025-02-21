#pragma once

#include <curand_kernel.h>

#include "ray.cuh"
#include "hitable.cuh"


struct hit_record;

class material {
	public:
		__device__ virtual bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, curandState *local_rand_state) const = 0;
};

class lambertian : public material {
	public:
		__device__ lambertian(const vec3& a) { albedo = a; }
		__device__ virtual bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, curandState* local_rand_state) const;

		vec3 albedo;
};

class metal : public material {
	public:
		__device__ metal(const vec3& a, float f) { if (f < 1) fuzz = f; else fuzz = 1; albedo = a; }
		__device__ virtual bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, curandState* local_rand_state) const;

		vec3 albedo;
		float fuzz;
};

class dielectric : public material {
	public:
		__device__ dielectric(const vec3& a, float ri) { albedo = a; ref_idx = ri; }
		__device__ virtual bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, curandState* local_rand_state) const;

		vec3 albedo;
		float ref_idx;
};