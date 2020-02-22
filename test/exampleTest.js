const etherlime = require('etherlime-lib');
const LimeFactory = require('../build/LimeFactory.json');


describe('Example', () => {
    let aliceAccount = accounts[3];
    let deployer;
    let limeFactoryInstance;

    before(async () => {
        deployer = new etherlime.EtherlimeGanacheDeployer(aliceAccount.secretKey);
        limeFactoryInstance = await deployer.deploy(LimeFactory);
    });

    it('should have valid deployer private key', async () => {
        assert.strictEqual(deployer.signer.privateKey, aliceAccount.secretKey);
    });

    it('should be valid private key', async () => {
        assert.isPrivateKey(aliceAccount.secretKey);
    });

    it('should be valid address', async () => {
        assert.isAddress(limeFactoryInstance.contractAddress, "The contract was not deployed");
    })

    it('should be valid hash', async () => {
        let hash = '0x5024924b629bbc6a32e3010ad738989f3fb2adf2b2c06f0cceeb17f6da6641b3';
        assert.isHash(hash)
    })


    it('should create lime', async () => {
        const createTransaction = await limeFactoryInstance.createLime("newLime", 6, 8, 2);
        let lime = await limeFactoryInstance.limes(0);
        assert.equal(lime.name, 'newLime', '"newLime" was not created');
    });

    it('should revert if try to create lime with 0 carbohydrates', async () => {
        let carbohydrates = 0;
        await assert.revert(limeFactoryInstance.createLime("newLime2", carbohydrates, 8, 2), "Carbohydrates are not set to 0");
    });

    it('should revert with expected revert message', async () => {
        let expectedRevertMessage = "The carbohydrates cannot be 0";
        let carbohydrates = 0;
        await assert.revertWith(limeFactoryInstance.createLime("newLime2", carbohydrates, 8, 2), expectedRevertMessage)
    })

    it('should assert that function not revert and is executed successfully', async () => {
        await assert.notRevert(limeFactoryInstance.createLime("newLime3", 6, 8, 2))
    })

    it('should create lime from another account', async () => {
        let bobsAccount = accounts[4].signer;
        const transaction = await limeFactoryInstance.from(bobsAccount /* Could be address or just index in accounts like 4 */).createLime("newLime3", 6, 8, 2);
        // check sender
        assert.equal(transaction.from, bobsAccount.address, "The account that created lime was not bobs");

        //check created lime
        let lime = await limeFactoryInstance.limes(1);
        assert.equal(lime.name, 'newLime3', '"newLime3" was not created');
    })

    it('should emit event', async () => {
        let expectedEvent = "FreshLime"
        await assert.emit(limeFactoryInstance.createLime("newLime", 6, 8, 2), expectedEvent)
    })

    it('should emit event with certain arguments', async () => {
        await assert.emitWithArgs(limeFactoryInstance.createLime("newLime", 6, 8, 2), ["newLime"])
    })

    it('should change balance on ethers sent', async () => {
        let bobsAccount = accounts[4].signer
        await assert.balanceChanged(bobsAccount.sendTransaction({
            to: aliceAccount.signer.address,
            value: 200
        }), bobsAccount, '-200')
    })

    it('should change multiple balances on ethers sent', async () => {
        let sender = accounts[1].signer
        let receiver = accounts[2].signer

        await assert.balancesChanged(sender.sendTransaction({
                    to: receiver.address,
                    value: 200
                }), [sender, receiver], ['-200', 200])
    })

});