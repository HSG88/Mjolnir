include "./base/ElGamal.circom"
include "./base/OneOutOfMany.circom"

template Mjolnir(n) {
    signal private input x;  //doctor secret key
    signal private input r;
    signal input pk[2];     //patient's public key
    signal input elements[n][2];
    signal input ciphertext[4];

    component oneOutOfMany = OneOutOfMany(n);
    oneOutOfMany.in <== x;
    for(var i =0; i<n; i++) {
        oneOutOfMany.elements[i][0] <== elements[i][0];
        oneOutOfMany.elements[i][1] <== elements[i][1];
    }
    oneOutOfMany.out === 1
    
    component xG = BabyPbk();
    xG.in <== x;
    
    component elGamal = ElGamal();
    elGamal.m[0] <== xG.Ax;
    elGamal.m[1] <== xG.Ay;
    elGamal.r <== r;
    elGamal.pk[0] <== pk[0];
    elGamal.pk[1] <== pk[1];

    for(var i=0; i<4; i++) {
        elGamal.c[i] === ciphertext[i];
    }
}
component main = Mjolnir(25)