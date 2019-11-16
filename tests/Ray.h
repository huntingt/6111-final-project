#ifndef _RAY
#define _RAY

#include <math.h>
#include <vector>

using namespace std;

class Ray {
    public:
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
};

#endif