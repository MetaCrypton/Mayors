const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { deploy, getIndexedEventArgsRAW, getAllIndexedEventsArgsRAW, config, coder } = require("./utils");

describe("Token contract", function() {
    this.timeout(20000);

    let admin, alice, bob, charlie;

    let token;
    let totalSupply = 0;
    let aliceTotalBalance = 0;

    const tokensCount = 10;

    before(async function(){
        [admin, alice, bob, charlie] = await ethers.getSigners();
    });

    it("Is deployed with empty name and symbol", async function(){
        token = await deploy("Token", admin, "", "", admin.address);
        assert.equal(await token.name(), "");
        assert.equal(await token.symbol(), "");
    });

    it("Is deployed with not deployer owner", async function(){
        token = await deploy("Token", admin, "Test token", "TST", charlie.address);
        assert.equal(await token.name(), "Test token");
        assert.equal(await token.symbol(), "TST");
    });

    it("Doesn't transfer ownership to the same address", async function(){
        await expect(token.connect(charlie).transferOwnership(charlie.address)).to.be.revertedWith("SameOwner()");
    });

    it("Transfers ownership to the another address", async function(){
        await expect(token.connect(charlie).transferOwnership(bob.address)).to.emit(token, "OwnershipTransferred").withArgs(bob.address);
    });

    it("Is deployed with not empty name and symbol", async function(){
        token = await deploy("Token", admin, "Test token", "TST", admin.address);
        assert.equal(await token.name(), "Test token");
        assert.equal(await token.symbol(), "TST");
    });

    it("Mints tokens by the owner", async function(){
        await expect(token.mint(charlie.address, tokensCount)).to.emit(token, "Transfer").withArgs(config.ZEROADDRESS, charlie.address, tokensCount);
        totalSupply += tokensCount;
        assert.equal(await token.balanceOf(charlie.address), tokensCount);
    });

    it("Doesn't mint by a non-owner", async function(){
        await expect(token.connect(alice).mint(alice.address, tokensCount)).to.be.revertedWith("NotOwner()");
        assert.equal(await token.balanceOf(alice.address), 0);
    });

    it("Doesn't mint to the zero address", async function(){
        await expect(token.mint(config.ZEROADDRESS, tokensCount)).to.be.revertedWith("ERC20: mint to the zero address");
    });

    it("Mints a batch to several addresses", async function(){
        await expect(token.batchMint([alice.address, bob.address], tokensCount)).to.emit(token, "Transfer");
        totalSupply += tokensCount * 2;
        aliceTotalBalance += tokensCount;
        assert.equal(await token.balanceOf(alice.address), tokensCount);
        assert.equal(await token.balanceOf(bob.address), tokensCount);
    });

    it("Mints a batch to one address", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        await token.batchMint([alice.address], tokensCount);
        totalSupply += tokensCount;
        aliceTotalBalance += tokensCount;
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber() + tokensCount);
    });

    it("Accepts a batch with no addresses", async function(){
        await token.batchMint([], tokensCount);
    });

    it("Mints a batch with same addresses", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        await token.batchMint([alice.address, alice.address], tokensCount);
        totalSupply += tokensCount * 2;
        aliceTotalBalance += tokensCount * 2;
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber() + tokensCount * 2);
    });

    it("Doesn't mint a batch by a non-owner", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        await expect(token.connect(alice).batchMint([alice.address], tokensCount)).to.be.revertedWith("NotOwner()");
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber());
    });

    it("Transfers zero tokens", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        let bobBalance = await token.balanceOf(bob.address);
        await expect(token.connect(alice).transfer(bob.address, 0)).to.emit(token, "Transfer").withArgs(alice.address, bob.address, 0);
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber());
        assert.equal(await token.balanceOf(bob.address), bobBalance.toNumber());
    });

    it("Transfers tokens", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        let bobBalance = await token.balanceOf(bob.address);
        await expect(token.connect(alice).transfer(bob.address, tokensCount)).to.emit(token, "Transfer").withArgs(alice.address, bob.address, tokensCount);
        aliceTotalBalance -= tokensCount;
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber() - tokensCount);
        assert.equal(await token.balanceOf(bob.address), bobBalance.toNumber() + tokensCount);
    });

    it("Doesn't transfer tokens to the zero address", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        await expect(token.connect(alice).transfer(config.ZEROADDRESS, tokensCount)).to.be.revertedWith("ERC20: transfer to the zero address");
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber());
    });

    it("Doesn't transfer tokens more than balance", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        let bobBalance = await token.balanceOf(bob.address);
        await expect(token.connect(alice).transfer(bob.address, aliceBalance.toNumber() + 1)).to.be.revertedWith("ERC20: transfer amount exceeds balance");
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber());
        assert.equal(await token.balanceOf(bob.address), bobBalance.toNumber());
    });

    it("Approves tokens", async function(){
        assert.equal(await token.allowance(alice.address, bob.address), 0);
        await expect(token.connect(alice).approve(bob.address, tokensCount * 2)).to.emit(token, "Approval").withArgs(alice.address, bob.address, tokensCount * 2);
        assert.equal(await token.allowance(alice.address, bob.address), tokensCount * 2);
    });

    it("Approves new amount of tokens", async function(){
        assert.equal(await token.allowance(alice.address, bob.address), tokensCount * 2);
        await expect(token.connect(alice).approve(bob.address, tokensCount)).to.emit(token, "Approval").withArgs(alice.address, bob.address, tokensCount);
        assert.equal(await token.allowance(alice.address, bob.address), tokensCount);
    });

    it("Implements infinite approval", async function(){
        let maxUint256 = 2n ** 256n - 1n;
        assert.equal(await token.allowance(bob.address, charlie.address), 0);
        await token.connect(bob).approve(charlie.address, maxUint256);
        assert.equal(await token.allowance(bob.address, charlie.address), maxUint256);
        let bobBalance = await token.balanceOf(bob.address);
        await token.connect(charlie).transferFrom(bob.address, alice.address, bobBalance);
        aliceTotalBalance += bobBalance.toNumber();
        assert.equal(await token.allowance(bob.address, charlie.address), maxUint256);
    });

    it("Doesn't approve tokens to the zero address", async function(){
        await expect(token.connect(alice).approve(config.ZEROADDRESS, tokensCount)).to.be.revertedWith("ERC20: approve to the zero address");
    });

    it("Transfers approved tokens", async function(){
        let approvedBalance = await token.allowance(alice.address, bob.address);
        let aliceBalance = await token.balanceOf(alice.address);
        let charlieBalance = await token.balanceOf(charlie.address);
        let amountToTransfer = approvedBalance.toNumber() - 1;
        await token.connect(bob).transferFrom(alice.address, charlie.address, amountToTransfer);
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber() - amountToTransfer);
        assert.equal(await token.balanceOf(charlie.address), charlieBalance.toNumber() + amountToTransfer);
        assert.equal(await token.allowance(alice.address, bob.address), 1);
        await token.connect(bob).transferFrom(alice.address, charlie.address, 1);
        aliceTotalBalance -= approvedBalance.toNumber();
    });

    it("Doesn't transfer not approved tokens", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        let charlieBalance = await token.balanceOf(charlie.address);
        assert.equal(await token.allowance(alice.address, bob.address), 0);
        await expect(token.connect(bob).transferFrom(alice.address, charlie.address, tokensCount)).to.be.revertedWith("ERC20: insufficient allowance");
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber());
        assert.equal(await token.balanceOf(charlie.address), charlieBalance.toNumber());
    });

    it("Doesn't transfer from zero address", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        await expect(token.connect(bob).transferFrom(config.ZEROADDRESS, alice.address, tokensCount)).to.be.revertedWith("ERC20: insufficient allowance");
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber());
    });

    it("Doesn't transfer to zero address", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        await token.connect(alice).approve(bob.address, aliceBalance.toNumber() + tokensCount);
        await expect(token.connect(bob).transferFrom(alice.address, config.ZEROADDRESS, aliceBalance)).to.be.revertedWith("ERC20: transfer to the zero address");
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber());
    });

    it("Doesn't transfer more than balance", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        await expect(token.connect(bob).transferFrom(alice.address, charlie.address, aliceBalance.toNumber() + tokensCount)).to.be.revertedWith("ERC20: transfer amount exceeds balance");
        assert.equal(await token.balanceOf(alice.address), aliceBalance.toNumber());
    });

    it("Increases the allowance", async function(){
        let approvedBalance = await token.allowance(alice.address, bob.address);
        await token.connect(alice).increaseAllowance(bob.address, tokensCount);
        assert.equal(await token.allowance(alice.address, bob.address), approvedBalance.toNumber() + tokensCount);
    });

    it("Increases the allowance with no previous approval", async function(){
        assert.equal(await token.allowance(alice.address, charlie.address), 0);
        await token.connect(alice).increaseAllowance(charlie.address, tokensCount);
        assert.equal(await token.allowance(alice.address, charlie.address), tokensCount);
    });

    it("Increases the allowance more than balance ", async function(){
        let aliceBalance = await token.balanceOf(alice.address);
        let approvedBalance = await token.allowance(alice.address, charlie.address);
        await token.connect(alice).increaseAllowance(charlie.address, aliceBalance.toNumber() + tokensCount);
        assert.equal(await token.allowance(alice.address, charlie.address), approvedBalance.toNumber() + aliceBalance.toNumber() + tokensCount);
    });

    it("Doesn't increase the allowance of the zero address", async function(){
        await expect(token.connect(alice).increaseAllowance(config.ZEROADDRESS, tokensCount)).to.be.revertedWith("ERC20: approve to the zero address");
    });

    it("Doesn't increase the allowance", async function(){
        let approvedBalance = await token.allowance(bob.address, charlie.address);
        await token.connect(bob).decreaseAllowance(charlie.address, approvedBalance);
        assert.equal(await token.allowance(bob.address, charlie.address), 0);
    });

    it("Doesn't decrease the allowance of the zero address", async function(){
        await expect(token.connect(alice).decreaseAllowance(config.ZEROADDRESS, tokensCount)).to.be.revertedWith("ERC20: decreased allowance below zero");
    });

    it("Doesn't decrease the allowance on more than allowance value", async function(){
        let approvedBalance = await token.allowance(alice.address, bob.address);
        await expect(token.connect(alice).decreaseAllowance(bob.address, approvedBalance + tokensCount)).to.be.revertedWith("ERC20: decreased allowance below zero");
        assert.equal(await token.allowance(alice.address, bob.address), approvedBalance.toNumber());
    });

    it("Returns decimals", async function(){
        assert.equal(await token.decimals(), 18);
    });

    it("Returns total supply", async function(){
        assert.equal(await token.totalSupply(), totalSupply);
    });

    it("Returns balance", async function(){
        assert.equal(await token.balanceOf(alice.address), aliceTotalBalance);
    });

    it("Supports IERC20 interface", async function(){
        let abi = [
            "function transfer(address,uint256)", "function approve(address,uint256)", "function transferFrom(address,address,uint256)",
            "function totalSupply()", "function balanceOf(address)", "function allowance(address,address)"
        ];
        let interface = new ethers.utils.Interface(abi)
        let interfaceId = ethers.BigNumber.from(0);
        let functions = ["transfer", "approve", "transferFrom", "totalSupply", "balanceOf", "allowance"];
        for (let i=0; i < functions.length; i++) {
            interfaceId = interfaceId.xor(ethers.BigNumber.from(interface.getSighash(functions[i])));
        }
        assert.equal(await token.supportsInterface(interfaceId.toHexString()), true);
    });

    it("Supports IERC20Mintable interface", async function(){
        let abi = ["function mint(address,uint256)"];
        let interface = new ethers.utils.Interface(abi)
        let interfaceId = interface.getSighash("mint");
        assert.equal(await token.supportsInterface(interfaceId), true);
    });

    it("Supports IERC20Metadata interface", async function(){
        let abi = ["function name()", "function symbol()", "function decimals()"];
        let interface = new ethers.utils.Interface(abi)
        let interfaceId = ethers.BigNumber.from(0);
        let functions = ["name", "symbol", "decimals"];
        for (let i=0; i < functions.length; i++) {
            interfaceId = interfaceId.xor(ethers.BigNumber.from(interface.getSighash(functions[i])));
        }
        assert.equal(await token.supportsInterface(interfaceId.toHexString()), true);
    });

    it("Supports IERC165 interface", async function(){
        let abi = ["function supportsInterface(bytes4)"];
        let interface = new ethers.utils.Interface(abi)
        let interfaceId = interface.getSighash("supportsInterface");
        assert.equal(await token.supportsInterface(interfaceId), true);
    });
    
    it("Doesn't ssupport invalid interface", async function(){
        let abi = [ "function randomFunction()"]
        let interface = new ethers.utils.Interface(abi)
        let interfaceId = interface.getSighash('randomFunction');
        assert.equal(await token.supportsInterface(interfaceId), false);
    });
});