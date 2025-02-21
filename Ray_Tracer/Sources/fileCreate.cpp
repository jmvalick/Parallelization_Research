#include "fileCreate.h"

void createPPMFile(vec3 *image, int image_width, int image_height, int samples) {

    // Define the PPM header
    const string ppmHeader = "P3\n" + to_string(image_width) + " " + to_string(image_height) + "\n255\n";

    // Open the output file
    string folder = "Results/";
    string fileName = "image_" + to_string(image_height) + "p_" + to_string(samples) + ".ppm";
    filesystem::path filePath = folder + fileName;
    ofstream outFile(filePath);

    // Write the PPM header to the file
    outFile << ppmHeader;

    // Write the pixel data to the file
    for (int j = image_height - 1; j >= 0; j--) {
        for (int i = 0; i < image_width; i++) {
            int pixelIndex = j * image_width + i;
            string pixel = to_string(static_cast<int>(image[pixelIndex].r())) + " " + to_string(static_cast<int>(image[pixelIndex].g())) + " " + to_string(static_cast<int>(image[pixelIndex].b())) + " ";
            outFile << pixel + "\n";
        }
        
    }

    // Close the file
    outFile.close();

    cout << "PPM file created at: " << filesystem::absolute(filePath) << "\n" << endl;

    return;
}

void createTextFile(int (*image_dim_list)[2], int num_resolutions, int *samples_list, int num_samples, double**time_list) {
    filesystem::path filePath = "Results/output.txt";
    ofstream file(filePath);

    if (!file.is_open()) {
        cerr << "Error opening file for writing." << std::endl;
        return;
    }

    // Write the header row with sample numbers
    file << setw(10) << " ";
    file << left << setw(10) << "Samples";
    for (int j = 0; j < num_samples; ++j) {
        file << setw(10) << samples_list[j];
    }
    file << "\n";
    file << setw(10) << "Resolution";
    file << "\n";

    // Write each row of resolutions with corresponding run times
    for (int i = 0; i < num_resolutions; ++i) {
        file << right << setw(10) << to_string(image_dim_list[i][1]) + "p";
        file << left << setw(10) << " ";
        for (int j = 0; j < num_samples; ++j) {
            file << setw(10) << time_list[i][j];
        }
        file << "\n";
    }

    file.close();

    cout << "Results file created at: " << filesystem::absolute(filePath) << "\n" << endl;

    return;
}