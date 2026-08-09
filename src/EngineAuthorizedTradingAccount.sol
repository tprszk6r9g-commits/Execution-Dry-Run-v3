// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC721OwnerV371 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IERC1271OwnerV371 {
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4);
}

interface IERC6551AccountV371 {
    function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId);
    function state() external view returns (uint256);
    function isValidSigner(address signer, bytes calldata context) external view returns (bytes4 magicValue);
}

interface IERC6551ExecutableV371 {
    function execute(address to, uint256 value, bytes calldata data, uint8 operation)
        external
        payable
        returns (bytes memory);
}

/// @title EngineAuthorizedTradingAccount
/// @notice ERC-6551 Trading account generation with dual authority:
///         - current NFT holder keeps unrestricted recovery/owner execution;
///         - one configured Rustee Trading Engine receives only a narrow engine-call path.
/// @dev Designed to be used behind the canonical ERC-6551 registry proxy format.
contract EngineAuthorizedTradingAccount {
    error NotOwner();
    error NotEngine();
    error InvalidOperation();
    error EnginePaused();
    error ZeroAddress();
    error TargetNotAllowed();
    error TargetHasNoCode();
    error CallFailed();
    error InvalidSignatureLength();

    bytes4 internal constant ERC1271_MAGIC = 0x1626ba7e;
    bytes4 internal constant ERC1271_FAIL = 0xffffffff;
    bytes4 internal constant ERC6551_SIGNER_MAGIC = bytes4(keccak256("isValidSigner(address,bytes)"));
    uint256 internal constant SECP256K1N_DIV_2 = 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    uint256 public state;
    address public engine;
    bool public enginePaused = true;
    mapping(address => bool) public allowedEngineTargets;

    event OwnerExecuted(address indexed owner, address indexed target, uint256 value, bytes32 dataHash, uint256 state);
    event EngineChanged(address indexed oldEngine, address indexed newEngine);
    event EnginePauseChanged(bool paused, address indexed actor);
    event EngineTargetAuthorization(address indexed target, bool allowed);
    event EngineExecuted(address indexed engine, address indexed target, bytes32 dataHash, uint256 state);

    receive() external payable {}

    modifier onlyOwner() {
        if (msg.sender != owner()) revert NotOwner();
        _;
    }

    function token() public view returns (uint256 chainId, address tokenContract, uint256 tokenId) {
        bytes memory footer = new bytes(0x60);
        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }
        return abi.decode(footer, (uint256, address, uint256));
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);
        return IERC721OwnerV371(tokenContract).ownerOf(tokenId);
    }

    /// @notice Owner recovery/general-purpose execution path.
    /// @dev Preserves ultimate NFT-holder control. Only CALL operation is supported.
    function execute(address to, uint256 value, bytes calldata data, uint8 operation)
        external
        payable
        onlyOwner
        returns (bytes memory result)
    {
        if (operation != 0) revert InvalidOperation();
        if (to == address(0)) revert ZeroAddress();
        unchecked {
            ++state;
        }
        (bool ok, bytes memory ret) = to.call{value: value}(data);
        if (!ok) _bubble(ret);
        emit OwnerExecuted(msg.sender, to, value, keccak256(data), state);
        return ret;
    }

    /// @notice Narrow autonomous execution path used only by the configured Trading Engine.
    /// @dev Native value is intentionally disabled in v3.7.1. Engine target must also be independently allowlisted here.
    function executeEngineCall(address target, uint256 value, bytes calldata data)
        external
        returns (bytes memory result)
    {
        if (msg.sender != engine) revert NotEngine();
        if (enginePaused) revert EnginePaused();
        if (value != 0) revert InvalidOperation();
        if (!allowedEngineTargets[target]) revert TargetNotAllowed();
        if (target.code.length == 0) revert TargetHasNoCode();
        unchecked {
            ++state;
        }
        (bool ok, bytes memory ret) = target.call(data);
        if (!ok) _bubble(ret);
        emit EngineExecuted(msg.sender, target, keccak256(data), state);
        return ret;
    }

    function setEngine(address next) external onlyOwner {
        if (next == address(0) || next.code.length == 0) revert ZeroAddress();
        address old = engine;
        engine = next;
        enginePaused = true;
        emit EngineChanged(old, next);
        emit EnginePauseChanged(true, msg.sender);
    }

    function setEnginePaused(bool value) external onlyOwner {
        enginePaused = value;
        emit EnginePauseChanged(value, msg.sender);
    }

    function setEngineTarget(address target, bool allowed) external onlyOwner {
        if (target == address(0)) revert ZeroAddress();
        if (allowed && target.code.length == 0) revert TargetHasNoCode();
        allowedEngineTargets[target] = allowed;
        emit EngineTargetAuthorization(target, allowed);
    }

    /// @notice ERC-6551 signer surface. Only current NFT holder is a valid signer.
    function isValidSigner(address signer, bytes calldata) external view returns (bytes4) {
        return signer == owner() ? ERC6551_SIGNER_MAGIC : bytes4(0);
    }

    /// @notice ERC-1271 verification against current NFT holder.
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {
        address currentOwner = owner();
        if (currentOwner == address(0)) return ERC1271_FAIL;

        if (currentOwner.code.length != 0) {
            (bool ok, bytes memory ret) = currentOwner.staticcall(
                abi.encodeWithSelector(IERC1271OwnerV371.isValidSignature.selector, hash, signature)
            );
            if (ok && ret.length >= 32 && bytes4(ret) == ERC1271_MAGIC) return ERC1271_MAGIC;
            return ERC1271_FAIL;
        }

        return _recover(hash, signature) == currentOwner ? ERC1271_MAGIC : ERC1271_FAIL;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // IERC165
            || interfaceId == type(IERC6551AccountV371).interfaceId
            || interfaceId == type(IERC6551ExecutableV371).interfaceId;
    }

    function _recover(bytes32 digest, bytes calldata sig) internal pure returns (address signer) {
        if (sig.length != 65) return address(0);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }
        if (uint256(s) > SECP256K1N_DIV_2) return address(0);
        if (v < 27) v += 27;
        if (v != 27 && v != 28) return address(0);
        signer = ecrecover(digest, v, r, s);
    }

    function _bubble(bytes memory ret) private pure {
        if (ret.length == 0) revert CallFailed();
        assembly {
            revert(add(ret, 32), mload(ret))
        }
    }
}
