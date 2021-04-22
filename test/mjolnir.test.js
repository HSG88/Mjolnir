const { expect } = require("chai");
const { BigNumber } = require("ethers");
const snarkjs = require("snarkjs");
const {babyJub} = require('circomlib')
const fs = require("fs");
const {
  genRandomSalt,
  genKeypair,
  genEcdhSharedKey,
  encrypt,
  stringifyBigInts,
  hash,
  formatPrivKeyForBabyJub,
} = require("../src/Crypto");
const { getSignalByName, compileAndLoadCircuit, executeCircuit } = require("../src/CircuitHelper");

describe("Mjolnir using zkSNARK", function () {
  it("Deploy the contract", async function () {
    const VerifierM = await ethers.getContractFactory("VerifierM");
    verifierM = await VerifierM.deploy();
  });
  it("Verify zkSNARK proof for Mjolnir with 25 members per group", async function () {

    index = 1;
    const patientPK = genKeypair();
    group = [];
    const n = 25;
    for (let i = 0; i < n; i++) 
      group.push(genKeypair());
    rG = genKeypair();
    c1 = rG.pubKey;
    c2 = babyJub.mulPointEscalar(patientPK.pubKey, formatPrivKeyForBabyJub(rG.privKey))
    c2 = babyJub.addPoint(group[index].pubKey,c2);
    ciphertext = [c1,c2].flat();
    elements = group.map(x=> x.pubKey)
    const inputs = stringifyBigInts({"x":formatPrivKeyForBabyJub(group[index].privKey), "r":formatPrivKeyForBabyJub(rG.privKey), "pk":patientPK.pubKey, "elements":elements, "ciphertext":ciphertext});

    fs.writeFileSync("./build/input.json", JSON.stringify(inputs));
    publicInputs = Object.values(inputs).flat(6);
    fs.writeFileSync("./build/public.json", JSON.stringify(publicInputs));
    
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
      inputs,
      "./build/Mjolnir.wasm",
      "./build/circuitMfinal.pkey"
    );
    const a = [proof.pi_a[0], proof.pi_a[1]];
    const b = [
      [proof.pi_b[0][1], proof.pi_b[0][0]],
      [proof.pi_b[1][1], proof.pi_b[1][0]],
    ];
    const c = [proof.pi_c[0], proof.pi_c[1]];
    tx = await verifierM.verifyProof(a, b, c, publicSignals);
    state = await verifierM.state();
    expect(state).to.equal(true);
  });
});

describe("Verifiable Encryption", function () {
  it("Deploy the contract", async function () {
    const VerifierV = await ethers.getContractFactory("VerifierV");
    verifierV = await VerifierV.deploy();
  });

  it("Verify zkSNARK proof for Verifiable Encryption of 4K-bytes", async function () {
    len = 128;
    doctor = genKeypair();
    mjolnir = genKeypair();
    plainText = [];
    for (i = 0; i < len; i++) plainText.push(genRandomSalt()); //just any random data as EHR of the patient
    sharedKey = genEcdhSharedKey(mjolnir.privKey, doctor.pubKey);
    ct = encrypt(plainText, sharedKey);
    ciphertext = [ct.iv, ...ct.data];
    commitment = hash(plainText);
    var inputs = stringifyBigInts({
      ciphertext: ciphertext,
      ecdhPK1: mjolnir.pubKey,
      ecdhSK1: formatPrivKeyForBabyJub(mjolnir.privKey),
      ecdhPK2: doctor.pubKey,
      commit: commitment,
    });

    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
      inputs,
      "./build/VerifiableEncrypt.wasm",
      "./build/circuitVfinal.pkey"
    );
    const a = [proof.pi_a[0], proof.pi_a[1]];
    const b = [
      [proof.pi_b[0][1], proof.pi_b[0][0]],
      [proof.pi_b[1][1], proof.pi_b[1][0]],
    ];
    const c = [proof.pi_c[0], proof.pi_c[1]];
    tx = await verifierV.verifyProof(a, b, c, publicSignals);
    state = await verifierV.state();
    expect(state).to.equal(true);
  });
});