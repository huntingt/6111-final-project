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

    const int timeout = 512;
    const int pixelAddress = 4096;
    const int materialAddress = 0;
    const int treeAddress = 256;

    RayUnit dut = RayUnit(timeout);
    
    // Maps material index to greyscale color
    MemoryArray material = MemoryArray(materialAddress, 256, 5);
    for (int i = 0; i < 256; i++) {
        int color = i + (i << 8) + (i << 16);
        material.write(i, color);
    }

    MemoryArray tree = MemoryArray(treeAddress, 1024, 5);
    tree.loadFile("tests/cube.oc");

    MemoryArray frame = MemoryArray(pixelAddress, 512);
    
    dut.attach(&tree);
    dut.attach(&material);
    dut.attach(&frame);
    
    dut.setRender(materialAddress, treeAddress);

    const double right = -60;
    const double down = 35;

    const vector<int> camera_q = Ray(60000, 58000, 0).vec();
    const vector<int> camera_v = Ray(0, 0, 400000).rotx(down).roty(right).vec();
    const vector<int> xstep = Ray(1000, 0, 0).rotx(down).roty(right).vec();
    const vector<int> ystep = Ray(0, 1000, 0).rotx(down).roty(right).vec();
    
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
