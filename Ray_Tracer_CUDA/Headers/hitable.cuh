#pragma once

#include "ray.cuh"


class material;

struct hit_record {
	float t;
	vec3 p;
	vec3 normal;
	material *mat_ptr;
};

class hitable {
	public:
		__device__ virtual bool hit(const ray& r, float tmin, float tmax, hit_record& rec) const = 0;
};