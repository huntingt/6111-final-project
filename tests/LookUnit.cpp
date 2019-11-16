#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <vector>
#include "Ray.h"
#include "RayUnit.h"

using namespace cv;
using namespace std;

int main() {
    Mat image = Mat(500, 500, CV_8U);

    const int timeout = 256;
    const int pixelAddress = 4096;
    const int materialAddress = 0;
    const int treeAddress = 256;

    RayUnit dut = RayUnit(timeout);
    
    // Maps material index to greyscale color
    MemoryArray material = MemoryArray(materialAddress, 256);
    for (int i = 0; i < 256; i++) {
        int color = i + (i << 8) + (i << 16);
        material.write(i, color);
    }

    MemoryArray tree = MemoryArray(treeAddress, 1024);
    tree.loadFile("tests/diagonal.oc");

    MemoryArray frame = MemoryArray(pixelAddress, 512);
    
    dut.attach(&tree);
    dut.attach(&material);
    dut.attach(&frame);
    
    dut.setRender(materialAddress, treeAddress);

    const vector<int> camera_q = {40000, 40000, 0};
    const vector<int> camera_v = {0, 0, 400};
    const vector<int> xstep = {1, 0, 0};
    const vector<int> ystep = {0, 1, 0};

    for(int i = 0; i < image.rows; i++){
        for(int j = 0; j < image.cols; j++){
            // generate the appropriate vector
            vector<int> preray;
            for (int k = 0; k < 3; k++){
                preray.push_back(camera_v.at(k)
                        - (i-image.rows/2)*ystep.at(k)
                        + (j-image.cols/2)*xstep.at(k));
            }

            auto ray = Ray::normalize(preray, 16);
            dut.render(camera_q, ray, pixelAddress + 0);
            image.at<uchar>(i,j) = frame.read(0);
        }
    }

    printf("completed %i pixels in %ld cycles!\n", image.rows*image.cols, dut.getCycles());

    namedWindow("Display Window", WINDOW_AUTOSIZE);
    imshow("Display Window", image);

    waitKey(0);
    return 0;
}
