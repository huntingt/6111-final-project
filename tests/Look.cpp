#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <iostream>
#include <vector>
#include "Octree.h"
#include "RayStepper.h"

using namespace cv;
using namespace std;

int main() {
    vector<Octree<bool>*> children = {
        new Leaf<bool>(false),
        new Leaf<bool>(false),
        new Leaf<bool>(false),
        new Leaf<bool>(false),

        new Leaf<bool>(false),
        new Leaf<bool>(false),
        new Leaf<bool>(false),
        new Leaf<bool>(true)
    };
    Octree<bool>* tree = new Branch<bool>(children);

    RayStepper dut;

    const vector<int> camera_q = {0, 0, 0};
    const vector<int> camera_v = {0, 0, 1000};
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

    namedWindow("Display Window", WINDOW_AUTOSIZE);
    imshow("Display Window", image);

    waitKey(0);
    return 0;
}
