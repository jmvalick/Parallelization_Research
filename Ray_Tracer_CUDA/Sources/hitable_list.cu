#include "hitable_list.cuh"


__device__ bool hitable_list::hit(const ray& r, float tmin, float tmax, hit_record& rec) const {
	hit_record temp_rec;
	bool hit_anything = false;
	float closest = tmax;
	for (int i = 0; i < list_size; i++) {
		if (list[i]->hit(r, tmin, closest, temp_rec)) {
			hit_anything = true;
			closest = temp_rec.t;
			rec = temp_rec;
		}
	}
	return hit_anything;
}