include "../node_modules/circomlib/circuits/mimc.circom";
include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "../node_modules/circomlib/circuits/babyjub.circom"

template VerifiableEncrypt(N) {
    // Where N is the length of the message
    signal input ciphertext[N+1];
    signal input ecdhPK1[2];
    signal input ecdhSK1;
    signal input ecdhPK2[2];  
    signal input commit;

    //verify relation between sk1 and pk1
    component sk1ToPK1 = BabyPbk();
    sk1ToPK1.in <== ecdhSK1;
    sk1ToPK1.Ax === ecdhPK1[0];
    sk1ToPK1.Ay === ecdhPK1[1];

    //generate ECDH shared key
    component sk1Bits = Num2Bits(253);
    sk1Bits.in <== ecdhSK1;

    component mulFix = EscalarMulAny(253);
    mulFix.p[0] <== ecdhPK2[0];
    mulFix.p[1] <== ecdhPK2[1];
    for (var i = 0; i < 253; i++) {
      mulFix.e[i] <== sk1Bits.out[i];
    }

    //mimc encryption and poseidon hash 
    component hasher = MiMCSponge(N, 220, 1);
    hasher.k <== 0;
    component decrypter[N];

    for(var j=0; j<N; j++){      
      decrypter[j] = MiMC7(91);      
      decrypter[j].x_in <== mulFix.out[0]; //ECDH shared key 
      decrypter[j].k <== ciphertext[0] + j;
      hasher.ins[j] <== ciphertext[j+1] - decrypter[j].out; //hash decrypted value
    }

    //verify valid commitment of decrypted plaintext
    hasher.outs[0] === commit;
}
component main = VerifiableEncrypt(128);