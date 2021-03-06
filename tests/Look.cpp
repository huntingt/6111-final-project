#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <vector>
#include "Octree.h"
#include "RayStepper.h"

using namespace cv;
using namespace std;

int main() {
    vector<Octree<bool>*> children = {
        new Leaf<bool>(false),//0,0,0
        new Leaf<bool>(false),//1,0,0
        new Leaf<bool>(false),//...
        new Leaf<bool>(false),

        new Leaf<bool>(false),
        new Leaf<bool>(true),
        new Leaf<bool>(true),
        new Leaf<bool>(false)
    };
    Octree<bool>* tree = new Branch<bool>(children);

    RayStepper dut;

    const vector<int> camera_q = {40000, 40000, 0};
    const vector<int> camera_v = {0, 0, 400};
    const vector<int> xstep = {1, 0, 0};
    const vector<int> ystep = {0, 1, 0};

    Mat image = Mat(500, 500, CV_8U);
    for(int i = 0; i < image.rows; i++){
        for(int j = 0; j < image.cols; j++){
            // generate the appropriate vector
            vector<int> preray;
            for (int k = 0; k < 3; k++){
                preray.push_back(camera_v.at(k)
                        - (i-image.rows/2)*ystep.at(k)
                        + (j-image.cols/2)*xstep.at(k));
            }

            auto ray = RayStepper::normalize(preray, RayStepper::bitWidth);
            image.at<uchar>(i,j) = dut.propagate(camera_q, ray, tree)? 0 : 255;
        }
    }

    printf("completed %i pixels in %ld cycles!\n", image.rows*image.cols, dut.getCycles());

    namedWindow("Display Window", WINDOW_AUTOSIZE);
    imshow("Display Window", image);

    waitKey(0);
    return 0;
}
