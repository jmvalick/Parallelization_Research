#pragma once

#include "hitable.cuh"


class hitable_list : public hitable {
	public:
		__device__ hitable_list() {}
		__device__ hitable_list(hitable **l, int n) { list = l; list_size = n; }

		__device__ bool hit(const ray& r, float tmin, float tmax, hit_record& rec) const;

		hitable **list;
		int list_size;
};