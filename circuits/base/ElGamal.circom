include "../../node_modules/circomlib/circuits/babyjub.circom"
include "./Utils.circom"
template ElGamal() {
    
    signal input m[2];
    signal input r;
    signal input pk[2];
    signal output c[4];
 
    //rG
    component rG = BabyPbk();
    rG.in <== r;
    c[0] <== rG.Ax;
    c[1] <== rG.Ay;

    //rPK
    component rY = MulPoint();
    rY.in <== r;
    rY.G[0] <== pk[0];
    rY.G[1] <== pk[1];
    
    component add = BabyAdd();
    add.x1 <== m[0];
    add.y1 <== m[1];
    add.x2 <== rY.Ax;
    add.y2 <== rY.Ay;
    c[2] <== add.xout;
    c[3] <== add.yout;
}