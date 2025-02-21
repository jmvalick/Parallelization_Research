#pragma once

#include <random>

// Function to generate a random double between 0 and 1
inline float random_f() {
    // Create a random number generator
    static std::random_device rd;  // Obtain a random seed from hardware
    static std::mt19937 generator(rd());  // Seed the generator
    static std::uniform_real_distribution<float> distribution(0.0f, 1.0f);  // Define the range

    // Generate a random number between 0 and 1
    return distribution(generator);
}