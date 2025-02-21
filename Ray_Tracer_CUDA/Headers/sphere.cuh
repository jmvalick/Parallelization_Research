#pragma once

#include "hitable.cuh"


class sphere : public hitable {
	public:
		__device__ sphere() {}
		__device__ sphere(vec3 cen, float r, material* m) : center(cen), radius(r), mat_ptr(m) {}
		__device__ virtual bool hit(const ray& r, float tmin, float tmax, hit_record& rec) const;

		vec3 center;
		float radius;
		material* mat_ptr;
};