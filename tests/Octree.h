#ifndef _OCTREE
#define _OCTREE

#include <tuple>

using namespace std;

template <class T>
class Octree{
    public:
    virtual T at(vector<int> location, int bits) = 0;
    virtual int depth(vector<int> location) = 0;
};

template <class T>
class Branch: public Octree<T>{
    public:
    Branch(vector<Octree<T>*> children){
        this->children = children;
    }

    T at(vector<int> location, int bits){
        const bool x = 1<<(bits-1) & location.at(0);
        const bool y = 1<<(bits-1) & location.at(1);
        const bool z = 1<<(bits-1) & location.at(2);

        int index = x + 2*y + 4*z;

        return children.at(index)->at(location, bits - 1);
    }

    int depth(vector<int> location){
        int maxDepth = 0;

        for(auto child: children){
            const int depth = child->depth(location);
            if(depth > maxDepth){
                maxDepth = depth;
            }
        }

        return maxDepth + 1;
    }
    
    //TODO: fix memory leak conditions for this class
    private:
    vector<Octree<T>*> children;
};

template <class T>
class Leaf: public Octree<T>{
    public:
    Leaf(T value){
        this->value = value;
    }

    T at(vector<int> location, int bits){
        return value;
    }

    int depth(vector<int> location){
        return 0;
    }

    private:
    T value;
};

#endif
