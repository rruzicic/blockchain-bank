/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { Gateway, Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const path = require('path');
const { buildCAClient, registerAndEnrollUser, enrollAdmin } = require('./util/CAUtil.js');
const { buildCCPOrg, buildWallet } = require('./util/AppUtil.js');

const channelName = 'channel1';
const chaincodeName = 'basic-5';
const walletPath = path.join(__dirname, 'wallets');
const org1UserId = 'appUser004';

function prettyJSONString(inputString) {
	return JSON.stringify(JSON.parse(inputString), null, 2);
}

// pre-requisites:
// - fabric-sample two organization test-network setup with two peers, ordering service,
//   and 2 certificate authorities
//         ===> from directory /fabric-samples/test-network
//         ./network.sh up createChannel -ca
// - Use any of the asset-transfer-basic chaincodes deployed on the channel "mychannel"
//   with the chaincode name of "basic". The following deploy command will package,
//   install, approve, and commit the javascript chaincode, all the actions it takes
//   to deploy a chaincode to a channel.
//         ===> from directory /fabric-samples/test-network
//         ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-javascript/ -ccl javascript
// - Be sure that node.js is installed
//         ===> from directory /fabric-samples/asset-transfer-basic/application-javascript
//         node -v
// - npm installed code dependencies
//         ===> from directory /fabric-samples/asset-transfer-basic/application-javascript
//         npm install
// - to run this test application
//         ===> from directory /fabric-samples/asset-transfer-basic/application-javascript
//         node app.js

// NOTE: If you see  kind an error like these:
/*
	2020-08-07T20:23:17.590Z - error: [DiscoveryService]: send[mychannel] - Channel:mychannel received discovery error:access denied
	******** FAILED to run the application: Error: DiscoveryService: mychannel error: access denied

   OR

   Failed to register user : Error: fabric-ca request register failed with errors [[ { code: 20, message: 'Authentication failure' } ]]
   ******** FAILED to run the application: Error: Identity not found in wallet: appUser
*/
// Delete the /fabric-samples/asset-transfer-basic/application-javascript/wallet directory
// and retry this application.
//
// The certificate authority must have been restarted and the saved certificates for the
// admin and application user are not valid. Deleting the wallet store will force these to be reset
// with the new certificate authority.
//

/**
 *  A test application to show basic queries operations with any of the asset-transfer-basic chaincodes
 *   -- How to submit a transaction
 *   -- How to query and check the results
 *
 * To see the SDK workings, try setting the logging to show on the console before running
 *        export HFC_LOGGING='{"debug":"console"}'
 */
async function main() {
	try {
		// Create a new gateway instance for interacting with the fabric network.
		// In a real application this would be done as the backend server session is setup for
		// a user that has been verified.
		const gateway = new Gateway();

		try {
			// setup the gateway instance
			// The user will now be able to create connections to the fabric network and be able to
			// submit transactions and query. All transactions submitted by this gateway will be
			// signed by this user using the credentials stored in the wallet.
			await gateway.connect(ccp, {
				wallet,
				identity: org1UserId,
				discovery: { enabled: true, asLocalhost: true } // using asLocalhost as this gateway is using a fabric network deployed locally
			});

			// Build a network instance based on the channel where the smart contract is deployed
			const network = await gateway.getNetwork(channelName);

			// Get the contract from the network.
			const contract = network.getContract(chaincodeName);

			// Initialize a set of asset data on the channel using the chaincode 'InitLedger' function.
			// This type of transaction would only be run once by an application the first time it was started after it
			// deployed the first time. Any updates to the chaincode deployed later would likely not need to run
			// an "init" type function.
			console.log('\n--> Submit Transaction: InitLedger, function creates the initial set of assets on the ledger');
			await contract.submitTransaction('InitLedger');
			console.log('*** Result: committed');

			// Let's try a query type operation (function).
			// This will be sent to just one peer and the results will be shown.
			console.log('\n--> Evaluate Transaction: GetAllAssets, function returns all the current assets on the ledger');
			let result = await contract.evaluateTransaction('GetAllBanks');
			console.log(`*** Result: ${prettyJSONString(result.toString())}`);

			// Now let's try to submit a transaction.
			// This will be sent to both peers and if both peers endorse the transaction, the endorsed proposal will be sent
			// to the orderer to be committed by each of the peer's to the channel ledger.
			console.log('\n--> Submit Transaction: CreateAsset, creates new asset with ID, color, owner, size, and appraisedValue arguments');
			result = await contract.submitTransaction('CreateAsset', 'asset13', 'yellow', '5', 'Tom', '1300');
			console.log('*** Result: committed');
			if (`${result}` !== '') {
				console.log(`*** Result: ${prettyJSONString(result.toString())}`);
			}

			console.log('\n--> Evaluate Transaction: ReadAsset, function returns an asset with a given assetID');
			result = await contract.evaluateTransaction('ReadAsset', 'asset13');
			console.log(`*** Result: ${prettyJSONString(result.toString())}`);

			console.log('\n--> Evaluate Transaction: AssetExists, function returns "true" if an asset with given assetID exist');
			result = await contract.evaluateTransaction('AssetExists', 'asset1');
			console.log(`*** Result: ${prettyJSONString(result.toString())}`);

			console.log('\n--> Submit Transaction: UpdateAsset asset1, change the appraisedValue to 350');
			await contract.submitTransaction('UpdateAsset', 'asset1', 'blue', '5', 'Tomoko', '350');
			console.log('*** Result: committed');

			console.log('\n--> Evaluate Transaction: ReadAsset, function returns "asset1" attributes');
			result = await contract.evaluateTransaction('ReadAsset', 'asset1');
			console.log(`*** Result: ${prettyJSONString(result.toString())}`);

			try {
				// How about we try a transactions where the executing chaincode throws an error
				// Notice how the submitTransaction will throw an error containing the error thrown by the chaincode
				console.log('\n--> Submit Transaction: UpdateAsset asset70, asset70 does not exist and should return an error');
				await contract.submitTransaction('UpdateAsset', 'asset70', 'blue', '5', 'Tomoko', '300');
				console.log('******** FAILED to return an error');
			} catch (error) {
				console.log(`*** Successfully caught the error: \n    ${error}`);
			}

			console.log('\n--> Submit Transaction: TransferAsset asset1, transfer to new owner of Tom');
			await contract.submitTransaction('TransferAsset', 'asset1', 'Tom');
			console.log('*** Result: committed');

			console.log('\n--> Evaluate Transaction: ReadAsset, function returns "asset1" attributes');
			result = await contract.evaluateTransaction('ReadAsset', 'asset1');
			console.log(`*** Result: ${prettyJSONString(result.toString())}`);
		} finally {
			// Disconnect from the gateway when the application is closing
			// This will close all connections to the network
			gateway.disconnect();
		}
	} catch (error) {
		console.error(`******** FAILED to run the application: ${error}`);
	}
}

async function enrollUser(orgId) {
	const ccpOrg = buildCCPOrg(orgId);

	// build an instance of the fabric ca services client based on
	// the information in the network configuration
	const caClient = buildCAClient(FabricCAServices, ccpOrg, 'ca.org' + orgId + '.example.com');

	// setup the wallet to hold the credentials of the application user
	const wallet = await buildWallet(Wallets, path.join(walletPath, 'wallet' + orgId));

	// in a real application this would be done on an administrative flow, and only once
	await enrollAdmin(caClient, wallet, 'Org' + orgId + 'MSP');

	// in a real application this would be done only when a new user was required to be added
	// and would be part of an administrative flow
	await registerAndEnrollUser(caClient, wallet, 'Org' + orgId + 'MSP', org1UserId, 'org' + orgId + '.department1');
	const gateway = new Gateway();

	try {
		await gateway.connect(ccpOrg, {
			wallet,
			identity: org1UserId,
			discovery: { enabled: true, asLocalhost: true } // using asLocalhost as this gateway is using a fabric network deployed locally
		});
		const network = await gateway.getNetwork(channelName);

		// Get the contract from the network.
		return network.getContract(chaincodeName);
	}
	catch (error) {
		console.error(`******** FAILED to run the application: ${error}`);
	}
}

async function addClient(contract) {
	// id, firstName, lastName, email
	const prompt = require("prompt-sync")({ sigint: true });
	const id = prompt('ID: ');
	const firstName = prompt('First name: ');
	const lastName = prompt('Last name: ');
	const email = prompt('Email: ');

	try {
		// How about we try a transactions where the executing chaincode throws an error
		// Notice how the submitTransaction will throw an error containing the error thrown by the chaincode
		console.log('\n--> Submit Transaction: CreateClient');
		await contract.submitTransaction('CreateClient', id, firstName, lastName, email);
		console.log('******** SUCCESS: added client');


	} catch (error) {
		console.log(`*** FAILED with error: \n    ${error}`);
	}
}

async function readClient(contract) {
	const prompt = require("prompt-sync")({ sigint: true });
	const id = prompt('ID: ');
	console.log('\n--> Evaluate Transaction: ReadClient');
	const result = await contract.evaluateTransaction('ReadClient', id);
	console.log(`*** Result: ${prettyJSONString(result.toString())}`);
}

async function initLedger(contract) {
	console.log('\n--> Submit Transaction: InitLedger, function creates the initial set of assets on the ledger');
	await contract.submitTransaction('InitLedger');
	console.log('*** Result: committed');
}

async function queryClientsByFirstName(contract) {
	const prompt = require("prompt-sync")({ sigint: true });
	const id = prompt('Name: ');
	console.log('\n--> Evaluate Transaction: QueryClientsByFirstName');
	const result = await contract.evaluateTransaction('QueryClientsByFirstName', id);
	console.log(`*** Result: ${result.toString()}`);
}

async function queryGetMiddleClassAccounts(contract) {

	console.log('\n--> Evaluate Transaction: QueryGetMiddleClassAccounts');
	const result = await contract.evaluateTransaction('QueryGetMiddleClassAccounts', 100, 900);
	console.log(`*** Result: ${result.toString()}`);
}

async function depositMoney(contract) {
	const prompt = require("prompt-sync")({ sigint: true });
	const id = prompt('ID: ');
	const amount = prompt('Amount: ');

	try {
		// How about we try a transactions where the executing chaincode throws an error
		// Notice how the submitTransaction will throw an error containing the error thrown by the chaincode
		console.log('\n--> Submit Transaction: DepositMoney');
		await contract.submitTransaction('DepositMoney', id, amount);
		console.log('******** SUCCESS: deposited money');

	} catch (error) {
		console.log(`*** FAILED with error: \n    ${error}`);
	}
}

async function withdrawMoney(contract) {
	const prompt = require("prompt-sync")({ sigint: true });
	const id = prompt('ID: ');
	const amount = prompt('Amount: ');

	try {
		// How about we try a transactions where the executing chaincode throws an error
		// Notice how the submitTransaction will throw an error containing the error thrown by the chaincode
		console.log('\n--> Submit Transaction: WithdrawMoney');
		await contract.submitTransaction('WithdrawMoney', id, amount);
		console.log('******** SUCCESS: withdrawed money');

	} catch (error) {
		console.log(`*** FAILED with error: \n    ${error}`);
	}
}

async function transferMoney(contract) {
	const prompt = require("prompt-sync")({ sigint: true });
	const from = prompt('From: ');
	const to = prompt('To: ');
	const amount = prompt('Amount: ');
	console.log('\n--> Submit Transaction: TransferMoney');
	await contract.submitTransaction('TransferMoney', from, to, amount);
	console.log('*** Result: committed');
}

async function readAccount(contract) {
	const prompt = require("prompt-sync")({ sigint: true });
	const id = prompt('ID: ');
	console.log('\n--> Evaluate Transaction: ReadAccount');
	const result = await contract.evaluateTransaction('ReadAccount', id);
	console.log(`*** Result: ${prettyJSONString(result.toString())}`);

}
async function consoleApp() {
	const prompt = require("prompt-sync")({ sigint: true });
	console.log("First lets get you signed in!");
	const orgId = prompt('What organization do you belong? Enter org ID:');
	const contract = await enrollUser(orgId);

	while (true) {
		console.log("Choose an option:");
		console.log("1 - Init ledger");
		console.log("2 - Add client");
		console.log("3 - Read client with ID");
		console.log("4 - QueryClientsByFirstName");
		console.log("5 - Deposit money");
		console.log("6 - Withdraw money");
		console.log("7 - Transfer money");
		console.log("8 - Read account");
		console.log("9 - QueryGetMiddleClassAccounts");

		console.log("Press any other key to exit");

		const option = prompt("> ");
		if (option == 1) {
			await initLedger(contract);
		} else if (option == 2) {
			await addClient(contract);
		} else if (option == 3) {
			await readClient(contract);
		} else if (option == 4) {
			await queryClientsByFirstName(contract);
		} else if (option == 5) {
			await depositMoney(contract);
		} else if (option == 6) {
			await withdrawMoney(contract);
		} else if (option == 7) {
			await transferMoney(contract);
		} else if (option == 8) {
			await readAccount(contract);
		} else if (option == 9) {
			await queryGetMiddleClassAccounts(contract);
		}
		else {
			break;
		}
	}

}


// main();
consoleApp()


