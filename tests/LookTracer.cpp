#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <vector>
#include "Ray.h"
#include "RayTracer.h"

using namespace cv;
using namespace std;

int main() {
    const int width = 500;
    const int height = 500;

    const int latency = 5;

    const int timeout = 500000000;
    const int frameAddress = 4096;
    const int materialAddress = 0;
    const int treeAddress = 256;

    RayTracer dut = RayTracer(timeout);
    
    // Maps material index to greyscale color
    MemoryArray material = MemoryArray(materialAddress, 256, latency);
    material.loadFile("generate/chr_old.mat");    
    material.write(0, 0xaa0000);

    MemoryArray tree = MemoryArray(treeAddress, 1024, latency);
    tree.loadFile("generate/chr_old.oc");

    MemoryArray frame = MemoryArray(frameAddress, width * height);
    
    dut.attach(&tree);
    dut.attach(&material);
    dut.attach(&frame);
    
    const double right = 50;
    const double down = 13;

    Ray q = Ray(0, 25000, 30000);
    Ray v = Ray(0, 0, 30000).rotx(down).roty(right);
    Ray x = Ray(75, 0, 0).rotx(down).roty(right);
    Ray y = Ray(0, 75, 0).rotx(down).roty(right);
    
    dut.setCamera(q, v, x, y);
    dut.setScene(materialAddress, treeAddress);
    dut.setFrame(width, height, frameAddress);

    //int value = dut.readRegister(RayTracer::CONFIG);
    //dut.writeRegister(RayTracer::CONFIG, value | 1<<5);

    dut.start();

    dut.waitForInterrupt();

    Mat image = Mat(width, height, CV_8UC3);
    for(int i = 0; i < image.rows; i++){
        for(int j = 0; j < image.cols; j++){
            unsigned int val = frame.read(i*width + j);
            unsigned int mask = 0xFF;
            uint8_t r = val & mask;
            uint8_t g = (val>>8) & mask;
            uint8_t b = (val>>16) & mask;
            image.at<cv::Vec3b>(i,j) = {b, g, r};
        }
    }

    printf("completed %i pixels in %ld cycles!\n", width*height, dut.getCycles());

    namedWindow("Display Window", WINDOW_AUTOSIZE);
    imshow("Display Window", image);

    waitKey(0);
    return 0;
}
