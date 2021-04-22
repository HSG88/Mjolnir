include "../../node_modules/circomlib/circuits/babyjub.circom"
include "./Utils.circom"

template OneOutOfMany(n) {
    signal input in;
    signal input elements[n][2];
    signal output out;
    component eq[n];
    component or[n];
    component pk = BabyPbk();
    pk.in <== in;
    for(var i=0; i<n; i++) {
        eq[i] = EqualElement();
        or[i] = OR();        
        eq[i].in[0] <== pk.Ax;
        eq[i].in[1] <== pk.Ay;
        eq[i].in[2] <== elements[i][0];
        eq[i].in[3] <== elements[i][1];
        or[i].b <== eq[i].out;
        if(i==0) {
            or[i].a <== 0;
        }
        if(i>0) {
            or[i].a <== or[i-1].out;
        }
    }
    or[n-1].out ==> out;
}