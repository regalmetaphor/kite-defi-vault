// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title KiteAuthorizationVault
/// @notice A narrow EIP-712 authorization layer for an agent spending budget.
contract KiteAuthorizationVault {
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address agent,address asset,uint256 limit,uint256 deadline,uint256 nonce)");
    bytes32 private immutable DOMAIN_SEPARATOR;
    bytes32 private constant HALF_ORDER = 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;
    struct Budget { uint256 remaining; uint256 deadline; }
    mapping(address => mapping(address => Budget)) public budgets;
    mapping(address => uint256) public nonces;
    event BudgetAuthorized(address indexed owner, address indexed agent, address indexed asset, uint256 limit, uint256 deadline, uint256 nonce);
    event BudgetConsumed(address indexed owner, address indexed agent, address indexed asset, uint256 amount, uint256 remaining);
    event BudgetRevoked(address indexed owner, address indexed agent, address indexed asset);

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"), keccak256(bytes("Kite Authorization Vault")), keccak256(bytes("1")), block.chainid, address(this)));
    }

    function permit(address owner, address agent, address asset, uint256 limit, uint256 deadline, bytes calldata signature) external {
        require(block.timestamp <= deadline, "permit expired");
        uint256 nonce = nonces[owner]++;
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, owner, agent, asset, limit, deadline, nonce))));
        require(_recover(digest, signature) == owner, "invalid permit");
        budgets[agent][asset] = Budget(limit, deadline);
        emit BudgetAuthorized(owner, agent, asset, limit, deadline, nonce);
    }

    function consume(address owner, address asset, uint256 amount) external {
        Budget storage budget = budgets[msg.sender][asset];
        require(block.timestamp <= budget.deadline, "budget expired");
        require(amount <= budget.remaining, "budget exceeded");
        budget.remaining -= amount;
        emit BudgetConsumed(owner, msg.sender, asset, amount, budget.remaining);
    }

    function revoke(address agent, address asset) external { delete budgets[agent][asset]; emit BudgetRevoked(msg.sender, agent, asset); }

    function _recover(bytes32 digest, bytes calldata signature) private pure returns (address) {
        require(signature.length == 65, "bad signature length");
        bytes32 r; bytes32 s; uint8 v;
        assembly { r := calldataload(signature.offset) s := calldataload(add(signature.offset, 32)) v := byte(0, calldataload(add(signature.offset, 64))) }
        require(v == 27 || v == 28, "bad recovery id");
        require(uint256(s) <= uint256(HALF_ORDER), "high-s signature");
        return ecrecover(digest, v, r, s);
    }
}
