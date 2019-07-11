#include <vector>

std::vector<uint8_t> LoadImageFromFile(const char* file_name,
						 int* out_width,
						 int* out_height,
						 int* out_channels);

std::vector<std::vector<uint8_t>> LoadImageFromFile2(const char* file_name,
                                                     int scale_side_len,
                                                     int corps);


std::vector<std::vector<uint8_t>> LoadImageFromData(uint8_t* in, int orientation,
                                                    int width, int height, int channels,
                                                    int scale_side_len, int corps);
