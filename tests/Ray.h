#ifndef _RAY
#define _RAY

#include <math.h>
#include <vector>

#define PI 3.14159265

using namespace std;

class Ray {
    public:
    Ray(int x, int y, int z) {
        this->x = x;
        this->y = y;
        this->z = z;
    }

    vector<int> vec() {
        return {x, y, z};
    }

    Ray rotx(double theta) {
        double a = theta * PI / 180;
        return Ray(x, y*cos(a) - z*sin(a), z*cos(a) + y*sin(a));
    }

    Ray roty(double theta) {
        double a = theta * PI / 180;
        return Ray(x*cos(a) + z*sin(a), y, z*cos(a) - x*sin(a));
    }

    Ray rotz(double theta) {
        double a = theta * PI / 180;
        return Ray(x*cos(a) - y*sin(a), y*cos(a) + x*sin(a), z);
    }

    static vector<int> normalize(vector<int> v, int bitWidth) {
        const double unit = 0.9 * pow(2, bitWidth-1) - 1.0;
        
        double norm = 0;
        for(int vi : v){
            norm += pow(vi, 2);
        }

        norm = pow(norm, 0.5);

        vector<int> result;
        for(int vi : v){
            result.push_back(vi / norm * unit);
        }

        return result;
    }
    
    int X() { return x; }
    int Y() { return y; }
    int Z() { return z; }

    int norm() {
        double sum = (double(x))*x + (double(y))*y + (double(z))*z;
        return pow(sum, 0.5);
    }
    private:
    int x;
    int y;
    int z;
};

#endif
