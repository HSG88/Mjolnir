#! /bin/bash
if [ ! -f "potfinal.ptau" ]; then
snarkjs powersoftau new bn128 16 pot0.ptau -v
snarkjs powersoftau contribute pot0.ptau pot1.ptau --name="First contribution" -v -e="random text"
snarkjs powersoftau contribute pot1.ptau pot2.ptau --name="Second contribution" -v -e="some random text"
snarkjs powersoftau beacon pot2.ptau potbeacon.ptau 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon"
snarkjs powersoftau prepare phase2 potbeacon.ptau potfinal.ptau -v
fi

circom ../circuits/Mjolnir.circom --r1cs --wasm
snarkjs zkey new Mjolnir.r1cs potfinal.ptau circuitM0.zkey
snarkjs zkey contribute circuitM0.zkey circuitM1.zkey --name="1st Contributor Name" -v -e="more random text"
snarkjs zkey contribute circuitM1.zkey circuitM2.zkey --name="Second contribution Name" -v -e="Another random entropy"
snarkjs zkey beacon circuitM2.zkey circuitMfinal.pkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"
snarkjs zkey export verificationkey circuitMfinal.pkey verification_keyM.json
snarkjs zkey export solidityverifier circuitMfinal.pkey verifierM.sol

circom ../circuits/VerifiableEncrypt.circom --r1cs --wasm
snarkjs zkey new VerifiableEncrypt.r1cs potfinal.ptau circuitV0.zkey
snarkjs zkey contribute circuitV0.zkey circuitV1.zkey --name="1st Contributor Name" -v -e="more random text"
snarkjs zkey contribute circuitV1.zkey circuitV2.zkey --name="Second contribution Name" -v -e="Another random entropy"
snarkjs zkey beacon circuitV2.zkey circuitVfinal.pkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"
snarkjs zkey export verificationkey circuitVfinal.pkey verification_keyV.json
snarkjs zkey export solidityverifier circuitVfinal.pkey verifierV.sol

rm *.zkey 

sed -i 's/pragma solidity ^0.6.11;/pragma solidity ^0.8.0;/gi' ./verifierM.sol
sed -i 's/contract Verifier {/contract VerifierM {\n bool public state;\n/gi' ./verifierM.sol
sed -i 's/@return r  bool true if proof is valid//gi' ./verifierM.sol
sed -i 's/return true;/state = true;/gi' ./verifierM.sol
sed -i 's/return false;/state = false;/gi' ./verifierM.sol
sed -i 's/view returns (bool r)//gi' ./verifierM.sol

sed -i 's/pragma solidity ^0.6.11;/pragma solidity ^0.8.0;/gi' ./verifierV.sol
sed -i 's/contract Verifier {/contract VerifierV {\n bool public state;\n/gi' ./verifierV.sol
sed -i 's/@return r  bool true if proof is valid//gi' ./verifierV.sol
sed -i 's/return true;/state = true;/gi' ./verifierV.sol
sed -i 's/return false;/state = false;/gi' ./verifierV.sol
sed -i 's/view returns (bool r)//gi' ./verifierV.sol

mv *.sol ../contracts