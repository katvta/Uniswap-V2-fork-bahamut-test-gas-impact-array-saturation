# Uniswap V2 Fork - Teste de Impacto de Gás e Saturação de Arrays

Este repositório contém um teste que avalia o impacto de gás e a saturação de arrays no contrato `UniswapV2Factory` em um fork da rede Bahamut. O teste cria múltiplos pares de tokens e mede o consumo de gás em cada operação, além de verificar o comportamento do contrato após a saturação do array de pares.

## Descrição do Teste

O teste `ArraySaturationGasImpactTest` tem como objetivo:

1. **Criar Múltiplos Pares de Tokens**: O teste cria até 250 pares de tokens no contrato `UniswapV2Factory`, medindo o consumo de gás em cada operação.
2. **Avaliar o Impacto de Gás**: O teste calcula o total de gás consumido para criar todos os pares e verifica se o consumo de gás aumenta ou se mantém consistente à medida que mais pares são criados.
3. **Testar a Saturação do Array**: Após a criação dos 250 pares, o teste tenta criar um par adicional para verificar o comportamento do contrato em um estado de saturação.

### Objetivos

- **Avaliar o Desempenho**: Medir o impacto de gás ao criar múltiplos pares de tokens.
- **Verificar a Robustez**: Testar como o contrato lida com a criação de pares após atingir um número elevado de pares existentes.
- **Identificar Possíveis Problemas**: Detectar possíveis problemas de escalabilidade ou consumo excessivo de gás.

## Como Executar o Teste

### Pré-requisitos

1. **Foundry**: Certifique-se de que o Foundry está instalado no seu sistema. Siga o [guia de instalação do Foundry](https://book.getfoundry.sh/getting-started/installation.html) se necessário.
2. **Anvil**: O Anvil é necessário para simular uma blockchain local. Ele já está incluído no Foundry.

### Passos para Execução

1. **Clone o Repositório**:
   ```bash
   git clone https://github.com/seu-usuario/Uniswap-V2-fork-bahamut-test-gas-impact-array-saturation.git
   cd Uniswap-V2-fork-bahamut-test-gas-impact-array-saturation
   ```

2. **Inicie o Anvil**:
   Abra um terminal e execute o seguinte comando para iniciar o Anvil com um fork da rede Bahamut:
   ```bash
   anvil --fork-url https://bahamut-rpc.publicnode.com
   ```

3. **Execute o Teste**:
   Em outro terminal, execute o seguinte comando para rodar o teste:
   ```bash
   forge test --fork-url https://bahamut-rpc.publicnode.com
   ```

### Resultados Esperados

- **Logs de Consumo de Gás**: O teste exibirá o consumo de gás para cada par criado e o total de gás usado.
- **Validação de Pares Criados**: O teste verificará se o número de pares criados corresponde ao esperado (250 pares).
- **Comportamento Pós-Saturação**: O teste tentará criar um par adicional após a saturação e registrará o consumo de gás e o resultado da operação.

## Código do Teste

O teste está implementado no arquivo `ArraySaturationGasImpactTest.sol`. Abaixo está um resumo do código:

```solidity
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
```

## Conclusão

Este teste é útil para avaliar o desempenho e a robustez do contrato `UniswapV2Factory` em cenários de alta demanda, onde múltiplos pares de tokens são criados. Ele ajuda a identificar possíveis problemas de escalabilidade e consumo excessivo de gás, fornecendo insights valiosos para otimizações futuras.

Para mais detalhes, consulte o código-fonte e os logs de execução incluídos neste repositório.
