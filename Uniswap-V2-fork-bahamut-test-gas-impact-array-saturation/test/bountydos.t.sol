// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function allPairsLength() external view returns (uint256);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract ArraySaturationGasImpactTest is Test {
    address public factoryAddress; // Endereço do contrato
    address public user = address(0x123); // Conta simulada
    uint256 constant MAX_PAIRS_TO_TEST = 250; // Máximo de pares para teste

    IUniswapV2Factory factory; // Instância do contrato

    function setUp() public {
        factoryAddress = 0xd0C5d23290d63E06a0c4B87F14bD2F7aA551a895;
        factory = IUniswapV2Factory(factoryAddress);
        require(address(factory) != address(0), "Factory contract address is invalid.");
    }

    function testGasImpactAndSaturation() public {
        uint256 initialGas = gasleft(); // Gás inicial
        uint256 gasUsedTotal = 0; // Total de gás usado

        for (uint256 i = 0; i < MAX_PAIRS_TO_TEST; i++) {
            address tokenA = address(uint160(i + 1));
            address tokenB = address(uint160(i + 2));

            // Verifica se o par já existe
            address existingPair = factory.getPair(tokenA, tokenB);
            if (existingPair != address(0)) {
                console.log("Pair already exists at index", i, "with address:", existingPair);
                continue;
            }

            uint256 gasBefore = gasleft(); // Gás antes

            // Tenta criar um par
            vm.prank(user);
            try factory.createPair(tokenA, tokenB) returns (address pair) {
                require(pair != address(0), "Pair creation failed unexpectedly.");
            } catch (bytes memory reason) {
                console.log("Pair creation failed at index", i, "with tokenA:", tokenA, "and tokenB:", tokenB);
                console.logBytes(reason);
                break; // Interrompe se falhar
            }

            uint256 gasAfter = gasleft(); // Gás após criação
            gasUsedTotal += gasBefore - gasAfter;

            console.log("Gas used for pair", i, ":", gasBefore - gasAfter);
        }

        uint256 allPairsLength = factory.allPairsLength();
        console.log("Total pairs created:", allPairsLength);
        console.log("Expected pairs:", MAX_PAIRS_TO_TEST);

        console.log("Total gas used for all pairs:", gasUsedTotal);

        // Validação do total de pares criados
        assertEq(allPairsLength, MAX_PAIRS_TO_TEST, "Mismatch in number of created pairs.");

        // Teste após saturação
        address tokenA2 = address(uint160(MAX_PAIRS_TO_TEST + 1));
        address tokenB2 = address(uint160(MAX_PAIRS_TO_TEST + 2));

        uint256 gasBeforeSaturation = gasleft();
        vm.prank(user);
        try factory.createPair(tokenA2, tokenB2) returns (address pair2) {
            require(pair2 != address(0), "Pair creation failed after saturation.");
        } catch (bytes memory reason) {
            console.log("Post-saturation pair creation failed.");
            console.logBytes(reason);
        }

        uint256 gasUsedForOnePair = gasBeforeSaturation - gasleft();
        console.log("Gas used after saturation:", gasUsedForOnePair);
    }
}
