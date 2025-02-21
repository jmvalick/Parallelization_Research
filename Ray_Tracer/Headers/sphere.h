#pragma once

#include "hitable.h"


class sphere: public hitable {
	public:
		sphere() {}
		sphere(vec3 cen, float r, material  *m) : center(cen), radius(r), mat_ptr(m) {}

		vec3 center;
		float radius;
		material* mat_ptr;

		virtual bool hit(const ray& r, float tmin, float tmax, hit_record& rec) const;
};