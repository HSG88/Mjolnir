include "../../node_modules/circomlib/circuits/comparators.circom"
include "../../node_modules/circomlib/circuits/babyjub.circom"
include "../../node_modules/circomlib/circuits/gates.circom"
include "../../node_modules/circomlib/circuits/bitify.circom"
include "../../node_modules/circomlib/circuits/escalarmulany.circom"

template MulPoint() {
    signal private input in; 
    signal input G[2];
    signal output Ax;
    signal output Ay;

    component pvkBits = Num2Bits(253);
    pvkBits.in <== in;
    component mulAny = EscalarMulAny(253);
    mulAny.p[0] <== G[0];
    mulAny.p[1] <== G[1];

    var i;
    for (i=0; i<253; i++) {
        mulAny.e[i] <== pvkBits.out[i];
    }
    Ax <== mulAny.out[0];
    Ay <== mulAny.out[1];
}

template EqualElement() {
    signal input in[4];
    signal output out; 
    component eqx = IsEqual();
    component eqy = IsEqual();
    component and = AND();
    eqx.in[0] <== in[0];
    eqx.in[1] <== in[2];
    eqy.in[0] <== in[1];
    eqy.in[1] <== in[3];
    and.a <== eqx.out;
    and.b <== eqy.out;
    out <== and.out;
}