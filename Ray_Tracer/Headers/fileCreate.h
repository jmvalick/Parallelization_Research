#pragma once

#define GLM_ENABLE_EXPERIMENTAL

#include <iostream>
#include <fstream>
#include <filesystem>
#include <string>

#include "vec3.h"

using namespace std;


void createPPMFile(vec3 *image, int image_width, int image_height, int samples);

void createTextFile(int (*image_dim_list)[2], int num_resolutions, int *samples_list, int num_samples, double**time_list);
