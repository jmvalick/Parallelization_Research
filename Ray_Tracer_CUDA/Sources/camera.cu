#include "camera.cuh"


__device__ vec3 random_in_unit_disk(curandState  *local_rand_state) {
	vec3 p;
	do {
		p = 2.0f * vec3(curand_uniform(local_rand_state), curand_uniform(local_rand_state), 0.0f) - vec3(1.0f, 1.0f, 0.0f);
	} while (dot(p, p) >= 1.0f);
	return p;
}

__device__ camera::camera(vec3 lookfrom, vec3 lookat, vec3 vup, float vfov, float aspect, float aperture, float focus_dist) {
	lens_radius = aperture / 2.0f;
	float theta = vfov * M_PI / 180.0f;
	float half_height = tan(theta / 2.0f);
	float half_width = aspect * half_height;

	origin = lookfrom;
	w = unit_vector(lookfrom - lookat);
	u = unit_vector(cross(vup, w));
	v = cross(w, u);

	lower_left_corner = origin - half_width * focus_dist * u - half_height * focus_dist * v - focus_dist * w;
	horizontal = 2.0f * half_width * focus_dist * u;
	vertical = 2.0f * half_height * focus_dist * v;
}

__device__ ray camera::get_ray(float s, float t, curandState *local_rand_state) {
	vec3 rd = lens_radius * random_in_unit_disk(local_rand_state);
	vec3 offset = u * rd.x() + v * rd.y();
	return ray(origin + offset, lower_left_corner + s * horizontal + t * vertical - origin - offset);
}