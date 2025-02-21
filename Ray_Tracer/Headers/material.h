#pragma once

#include "ray.h"
#include "hitable.h"


struct hit_record;

vec3 random_in_unit_sphere();

vec3 reflect(const vec3& v, const vec3& n);

bool refract(const vec3& v, const vec3& n, float ni_over_nt, vec3& refracted);

float schlick(float cosine, float ref_idx);

class material {
	public:
		virtual bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered) const = 0;
};

class lambertian : public material {
	public:
		lambertian(const vec3& a) : albedo(a) {}

		vec3 albedo;

		virtual bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered) const;
};

class metal : public material {
	public:
		metal(const vec3& a, float f) : albedo(a) {if (f < 1) fuzz = f; else fuzz = 1;}

		vec3 albedo;
		float fuzz;

		virtual bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered) const;
};

class dielectric : public material {
	public:
		dielectric(const vec3& a, float ri) : albedo(a), ref_idx(ri) {}

		vec3 albedo;
		float ref_idx;

		virtual bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered) const;
};