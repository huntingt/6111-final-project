#ifndef _OCTREE
#define _OCTREE

#include <tuple>

using namespace std;

template <class T, int B>
class Octree{
    public:
    virtual T at(vector<int> location) = 0;
    virtual int depth(vector<int> location) = 0;
};

template <class T, int B>
class Branch: public Octree<T,B>{
    public:
    Branch(vector<Octree<T,B-1>> children){
        this->children = children;
    }

    T at(vector<int> location){
        const bool x = 1<<(B-1) & location.at(0);
        const bool y = 1<<(B-1) & location.at(1);
        const bool z = 1<<(B-1) & location.at(2);

        int index = x + 2*y + 4*z;

        return children.at(index).at(location);
    }

    int depth(vector<int> location){
        int maxDepth = 0;

        for(auto child: children){
            const int depth = child.depth();
            if(depth > maxDepth){
                maxDepth = depth;
            }
        }

        return maxDepth + 1;
    }

    private:
    vector<Octree<T,B-1>> children;
};

template <class T, int B>
class Leaf: public Octree<T,B>{
    public:
    Leaf(T value){
        this->value = value;
    }

    T at(vector<int> location){
        return value;
    }

    int depth(){
        return 0;
    }

    private:
    T value;
}

#endif
