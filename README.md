# Meta Crypton Test

## Setup

```bash
# Install Node.js & npm

# Install local node dependencies:
$ npm install

# Set private key:
$ echo -n "PRIVATE_KEY=0x9d3c762f8732713986756a11c52e6cb60eabc7c2e79d52876ca51425456f1616" > .env

# Run tests:
$ npm run test

# Deploy to $network (goerli/kovan/ropsten/bsc_testnet)
$ npx hardhat run scripts/deploy.js  --network $network
```

## Verify the output from the Retroactive Query

The file `bq-results.json` contains the full set of rows (ordered by address ascending) of the Retroactive Query. You can follow the steps in that project to generate this file.

In this repo the file `merkle-proof.generated.json` is generated from the BigQuery output and fed into the contract deployment script. You can generate the merkle proof file yourself using the steps below.

## Generate Merkle Proof

First pre-process the BigQuery results (the file is missing commas):

```sh
$ npx ts-node ./scripts/pre-process-json.ts -i bq-results.json > bq-results.processed.json
```

Now generate a merkle proof blob:

```sh
$ npx ts-node ./scripts/generate-merkle-root -i bq-results.processed.json > merkle-proof.generated.json
```
