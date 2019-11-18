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

    const int latency = 1;

    const int timeout = 500000000;
    const int frameAddress = 4096;
    const int materialAddress = 0;
    const int treeAddress = 256;

    RayTracer dut = RayTracer(timeout);
    
    // Maps material index to greyscale color
    MemoryArray material = MemoryArray(materialAddress, 256, latency);
    for (int i = 0; i < 256; i++) {
        int color = i + (i << 8) + (i << 16);
        material.write(i, color);
    }

    MemoryArray tree = MemoryArray(treeAddress, 1024, latency);
    tree.loadFile("tests/cube.oc");

    MemoryArray frame = MemoryArray(frameAddress, width * height);
    
    dut.attach(&tree);
    dut.attach(&material);
    dut.attach(&frame);
    
    const double right = -60;
    const double down = 35;

    Ray q = Ray(60000, 58000, 0);
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

    Mat image = Mat(width, height, CV_8U);
    for(int i = 0; i < image.rows; i++){
        for(int j = 0; j < image.cols; j++){
            image.at<uchar>(i,j) = frame.read(i*width + j);
        }
    }

    printf("completed %i pixels in %ld cycles!\n", width*height, dut.getCycles());

    namedWindow("Display Window", WINDOW_AUTOSIZE);
    imshow("Display Window", image);

    waitKey(0);
    return 0;
}
