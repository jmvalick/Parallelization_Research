#pragma once
#define _USE_MATH_DEFINES
#define GLM_FORCE_CUDA

#include <math.h>

#include "vec3.h"
#include "random.h"



class ray
{
	public:
		ray() {}
		ray(const vec3& a, const vec3& b) { A = a; B = b; }

		vec3 A; // origin
		vec3 B;	// direction

		vec3 origin() const { return A; };
		vec3 direction() const { return B; };
		vec3 point_at_parameter(float t) const { return A + t * B; }

};