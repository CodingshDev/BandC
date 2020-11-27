pragma solidity 0.5.16;

import { Avatar } from "./avatar/Avatar.sol";

/**
 * @dev Registry contract to maintain Compound addresses and other details.
 */
contract Registry {

    // Compound Contracts
    address public comptroller;
    address public comp;
    address public cEther;
    address public priceOracle;

    // BProtocol Contracts
    address public pool;
    address public bComptroller;
    address public score;
    address public jar;

    // Owner => Avatar
    mapping (address => address) public ownerToAvatar;

    // Avatar => Owner
    mapping (address => address) public avatarToOwner;

    // An Avatar can have multiple Delegatee
    // Avatar => Delegatee => bool
    mapping (address => mapping(address => bool)) public isAvatarHasDelegatee;

    // A Delegatee can have multiple Avatar
    // Delegatee => Avatar => bool
    mapping (address => mapping(address => bool)) public isDelegateeHasAvatar;

    event NewAvatar(address indexed avatar, address owner);
    event AvatarTransferOwnership(address indexed avatar, address oldOwner, address newOwner);
    event Delegate(address indexed delegator, address avatar, address delegatee);
    event RevokeDelegate(address indexed delegator, address avatar, address delegatee);

    constructor(
        address _comptroller,
        address _comp,
        address _cEther,
        address _priceOracle,
        address _pool,
        address _bComptroller,
        address _score,
        address _jar
    )
        public
    {
        comptroller = _comptroller;
        comp = _comp;
        cEther = _cEther;
        priceOracle = _priceOracle;
        pool = _pool;
        bComptroller = _bComptroller;
        score = _score;
        jar = _jar;
    }

    function newAvatar() external returns (address) {
        return _newAvatar(msg.sender);
    }

    function newAvatarOnBehalfOf(address user) external returns (address) {
        return _newAvatar(user);
    }

    /**
     * @dev Get the user's avatar if exists otherwise create one for him
     * @param user Address of the user
     * @return The existing/new Avatar contract address
     */
    function getAvatar(address user) external returns (address) {
        // TODO find avatar of user/delegatee
        address avatar = ownerToAvatar[user];
        if(avatar == address(0)) {
            avatar = _newAvatar(user);
        }
        return avatar;
    }

    function transferAvatarOwnership(address newOwner) external {
        require(newOwner != address(0), "Registry: newOwner-is-zero-address");
        address avatar = ownerToAvatar[msg.sender];
        require(avatar != address(0), "Registry: avatar-not-found");

        delete ownerToAvatar[msg.sender];
        delete avatarToOwner[avatar];

        ownerToAvatar[newOwner] = avatar;
        avatarToOwner[avatar] = newOwner;
        emit AvatarTransferOwnership(avatar, msg.sender, newOwner);
    }

    function delegateAvatar(address delegatee) external {
        address avatar = ownerToAvatar[msg.sender];
        require(avatar != address(0), "Registry: avatar-not-found");

        isAvatarHasDelegatee[avatar][delegatee] = true;
        isDelegateeHasAvatar[delegatee][avatar] = true;
        emit Delegate(msg.sender, avatar, delegatee);
    }

    function revokeDelegateAvatar(address delegatee) external {
        address avatar = ownerToAvatar[msg.sender];
        require(avatar != address(0), "Registry: avatar-not-found");
        require(isAvatarHasDelegatee[avatar][delegatee], "Registry: not-delegated");

        isAvatarHasDelegatee[avatar][delegatee] = false;
        isDelegateeHasAvatar[delegatee][avatar] = false;
        emit RevokeDelegate(msg.sender, avatar, delegatee);
    }

    /**
     * @dev Create a new Avatar contract for the given user
     * @param user Address of the user
     * @return The address of the newly deployed Avatar contract
     */
    function _newAvatar(address user) internal returns (address) {
        require(!isAvatarExistFor(user), "avatar-already-exits-for-user");
        address avatar = _deployNewAvatar(user);
        ownerToAvatar[user] = avatar;
        avatarToOwner[avatar] = user;
        emit NewAvatar(avatar, user);
        return avatar;
    }

    /**
     * @dev Deploys a new instance of Avatar contract
     * @param user Owner address of Avatar contract
     * @return Returns the address of the newly deployed Avatar contract
     */
    function _deployNewAvatar(address user) internal returns (address) {
        return address(new Avatar(user, pool, bComptroller, comptroller, comp, cEther, address(this)));
    }

    function isAvatarExist(address avatar) public view returns (bool) {
        return avatarToOwner[avatar] != address(0);
    }

    function isAvatarExistFor(address user) public view returns (bool) {
        return ownerToAvatar[user] != address(0);
    }

    function userOf(address avatar) public view returns (address) {
        return avatarToOwner[avatar];
    }

    function avatarOf(address owner) public view returns (address) {
        return avatarToOwner[owner];
    }
}