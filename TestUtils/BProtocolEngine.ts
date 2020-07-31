import * as t from "../types/index";
import { buildComptrollerImpl } from "compound-protocol/scenario/src/Builder/ComptrollerImplBuilder";
import { CompoundUtils } from "./CompoundUtils";

const shell = require("shelljs");

// Compound contracts
const Comp: t.CompContract = artifacts.require("Comp");
const Comptroller: t.ComptrollerContract = artifacts.require("Comptroller");
const PriceOracle: t.PriceOracleContract = artifacts.require("PriceOracle");

// BProtocol contracts
const Pool: t.PoolContract = artifacts.require("Pool");
const BComptroller: t.BComptrollerContract = artifacts.require("BComptroller");
const Registry: t.RegistryContract = artifacts.require("Registry");
const BEther: t.BEtherContract = artifacts.require("BEther");
const BErc20: t.BErc20Contract = artifacts.require("BErc20");
const Avatar: t.AvatarContract = artifacts.require("Avatar");

// Compound class to store all Compound deployed contracts
export class Compound {
    public comptroller!: t.ComptrollerInstance;
    public comp!: t.CompInstance;
    public priceOracle!: t.PriceOracleInstance;
}

// BProtocol Class to store all BProtocol deployed contracts
export class BProtocol {
    public pool!: t.PoolInstance;
    public bComptroller!: t.BComptrollerInstance;
    public registry!: t.RegistryInstance;
    public bTokens: Map<string, t.BTokenInstance> = new Map();

    // variable to hold all Compound contracts
    public compound!: Compound;
}

// BProtocol System Engine to manage and deploy BProtocol contracts
export class BProtocolEngine {
    public bProtocol!: BProtocol;

    private compoundUtil = new CompoundUtils();
    private accounts!: Truffle.Accounts;

    constructor(_accounts: Truffle.Accounts) {
        this.accounts = _accounts;
    }

    // Deploy Compound contracts
    public async deployCompound() {
        const deployCommand = "npm run deploy-compound";

        console.log("Executing command:" + deployCommand);
        const log = shell.exec(deployCommand, { async: false });
    }

    // Deploy BProtocol contracts
    public async deployBProtocol(): Promise<BProtocol> {
        this.bProtocol = new BProtocol();
        const _bProtocol = this.bProtocol;
        _bProtocol.pool = await this.deployPool();
        _bProtocol.bComptroller = await this.deployBComptroller();
        _bProtocol.registry = await this.deployRegistry();

        await _bProtocol.bComptroller.setRegistry(_bProtocol.registry.address);

        _bProtocol.compound = new Compound();
        _bProtocol.compound.comptroller = await Comptroller.at(this.compoundUtil.getComptroller());
        _bProtocol.compound.comp = await Comp.at(this.compoundUtil.getComp());
        _bProtocol.compound.priceOracle = await PriceOracle.at(this.compoundUtil.getPriceOracle());

        // console.log("Pool: " + _bProtocol.pool.address);
        // console.log("BComptroller: " + _bProtocol.bComptroller.address);
        // console.log("Registry: " + _bProtocol.registry.address);

        return this.bProtocol;
    }

    // Deploy Pool contract
    private async deployPool(): Promise<t.PoolInstance> {
        return await Pool.new();
    }

    // Deploy BComptroller contract
    private async deployBComptroller(): Promise<t.BComptrollerInstance> {
        return await BComptroller.new();
    }

    // Deploy Registry contract
    private async deployRegistry(): Promise<t.RegistryInstance> {
        const comptroller = this.compoundUtil.getComptroller();
        const comp = this.compoundUtil.getComp();
        const cETH = this.compoundUtil.getContracts("cETH");
        const priceOracle = this.compoundUtil.getPriceOracle();
        const pool = this.bProtocol.pool.address;
        const bComptroller = this.bProtocol.bComptroller.address;
        return await Registry.new(comptroller, comp, cETH, priceOracle, pool, bComptroller);
    }

    public getBProtocol(): BProtocol {
        return this.bProtocol;
    }

    // Child Contract Creation
    // ========================

    // Deploy BErc20
    public async deployNewBErc20(symbol: string): Promise<t.BErc20Instance> {
        const bToken_addr = await this._newBToken(symbol);
        const bToken: t.BErc20Instance = await BErc20.at(bToken_addr);
        this.bProtocol.bTokens.set(symbol, bToken);
        return bToken;
    }

    // Deploy BEther
    public async deployNewBEther(symbol: string): Promise<t.BEtherInstance> {
        const bToken_addr = await this._newBToken(symbol);
        const bToken: t.BEtherInstance = await BEther.at(bToken_addr);
        this.bProtocol.bTokens.set(symbol, bToken);
        return bToken;
    }

    // Deploy BToken
    private async _newBToken(symbol: string): Promise<string> {
        const cToken: string = this.compoundUtil.getContracts(symbol);
        const bToken_addr = await this.bProtocol.bComptroller.newBToken.call(cToken);
        await this.bProtocol.bComptroller.newBToken(cToken);
        return bToken_addr;
    }

    // Deploy Avatar
    public async deployNewAvatar(_from: string = this.accounts[0]): Promise<t.AvatarInstance> {
        const avatar_addr = await this.bProtocol.registry.newAvatar.call({ from: _from });
        await this.bProtocol.registry.newAvatar({ from: _from });
        const avatar: t.AvatarInstance = await Avatar.at(avatar_addr);
        return avatar;
    }
}
