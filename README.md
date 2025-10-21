# KipuBankv2: Smart Contract Multi-Token

## Descripción General

`KipuBankV2.sol` es una versión mejorada del contrato `KipuBank`, que ofrece un sistema de depósito y retiro multi-token con control de acceso, integración de oráculos de Chainlink, y manejo de decimales entre diferentes activos ERC-20 y Ether.  

Esta versión se enfoca en **seguridad, extensibilidad y eficiencia de gas**, utilizando librerías de OpenZeppelin y buenas prácticas de smart contracts.

---

## 1. Mejoras en esta versión

### Control de Acceso
- Se implementa el patrón de **roles** mediante `AccessControl` de OpenZeppelin.  
- El rol `ADMIN_ROLE` permite:
  - Registrar tokens admitidos.
  - Establecer oráculos de precios.
  - Actualizar el límite global de depósitos (bank cap).
- El rol `OPERATOR_ROLE` será para futuras operaciones automatizadas/de mantenimiento.

**Motivo:**  
El control de acceso refuerza la seguridad operativa, porque evita que cualquier usuario modifique parámetros críticos.

---

### Declaraciones de Tipos y Variables Constant
- Se introducen constantes `USDC_DECIMALS = 6` y `ADMIN_ROLE = 0x00` para más claridad y eficiencia de gas.  
- Se usa `immutable` para `USDC_ADDRESS`, porque no cambia tras el deploy.  

**Motivo:**  
Se mejora la legibilidad y optimiza la ejecución.

---

### Instancia del Oráculo Chainlink
- Cada token soportado puede asociarse a un **feed de precios** externo (Chainlink o mock).
- Se utiliza una **interfaz genérica `IOracle`**, que define `latestAnswer()` para permitir compatibilidad con feeds Chainlink y mocks.  
- Se aplica `try/catch` para manejar feeds que puedan fallar o devolver datos inválidos.

**Motivo:**  
Hace posible calcular montos equivalentes en USD, y evita fallas de transacción por algún error de tiempo en el oráculo.

---

### Mappings Anidados
```solidity
mapping(address => mapping(address => uint256)) public balances;
```
- Estructura que permite llevar una **contabilidad multi-token** por usuario.  
- Ejemplo: `balances[DAI][usuario]` o `balances[address(0)][usuario]` para Ether.

**Motivo:**  
Hace posible escalar a múltiples activos sin desplegar nuevos contratos.

---

### Conversión de Decimales y Valores
- Se introdujo la función `_toUsd6()` que:
  - Convierte montos desde diferentes decimales de tokens (p.ej., 18, 8, 6).
  - Aplica el precio del feed (en 8 decimales típicos de Chainlink).
  - Retorna el valor estandarizado en **decimales USDC (6)** para la contabilidad interna.

**Motivo:**  
Estandarizar la contabilidad en USD hace más simple la auditoría y control del límite global (`bankCapUsd6`).

---

## 2. Instrucciones de Despliegue e Interacción

### Parámetros del constructor
```solidity
constructor(address admin, address usdcAddress, uint256 initialCapUsd6)
```

| Parámetro | Descripción |
|------------|--------------|
| `admin` | Dirección del administrador inicial (normalmente la wallet propia) |
| `usdcAddress` | Dirección del contrato USDC (real o mock si es mainnet o testnet) |
| `initialCapUsd6` | Límite total permitido del banco en USD (6 decimales) |

### Ejemplo (red de pruebas Sepolia):
- `admin`: la dirección de la wallet propia de MetaMask  
- `usdcAddress`: `0x07865c6e87b9f70255377e024ace6630c1eaa37f` (USDC Sepolia)  
- `initialCapUsd6`: `100000000` (equivale a 100 dólares US)

---

### Despliegue (Remix y MetaMask)

1. Abrir **Remix IDE** → `Deploy & Run Transactions`.
2. Seleccionar:
   - **Environment:** `Injected Provider - MetaMask`
   - **Network:** `Sepolia`
3. Seleccionar `KipuBankV2.sol`.
4. Ingresar los parámetros del constructor.
5. Hacer clic en **Deploy**.
6. Confirmar en MetaMask.

---

### Interacción Básica

| Función | Descripción |
|----------|-------------|
| `setTokenSupported(token, bool)` | Habilita o deshabilita un token ERC-20 |
| `setPriceFeed(token, feed)` | Asocia un feed de precios al token |
| `depositETH()` | Deposita Ether (requiere `msg.value > 0`) |
| `depositToken(token, amount)` | Deposita un token ERC-20 aprobado |
| `withdrawETH(amount)` | Retira Ether disponible |
| `withdrawToken(token, amount)` | Retira tokens depositados |
| `balanceOf(token, user)` | Consulta el saldo individual |

---

## 3. Notas sobre Decisiones de Diseño o Trade-offs

### Seguridad vs. Flexibilidad
- Se prefirió el uso de **roles explícitos** sobre `onlyOwner` para facilitar la descentralización futura.
- Cada token ha de registrarse manualmente antes de usarse: así se evita interacciones con contratos maliciosos.

### Uso de Oráculos
- Se implementó compatibilidad genérica vía `IOracle` en lugar de acoplar directamente a Chainlink. Esto permite mayor flexibilidad y testeo en entornos locales.

### Eficiencia
- Se evita el uso de bucles sobre balances.
- Se marcan variables `immutable` y `constant` donde sea aplicable.
- Como en la versión anterior, se siguen los patrones `checks-effects-interactions` para mitigar ataques de reentrada.

### Gas y Precisión
- Toda la contabilidad se mantiene en dólares USD con 6 decimales, simplificando comparaciones.
- Se utilizan conversiones de decimales dinámicas para tokens con distinta precisión.

---

## Conclusión

KipuBankV2 es un smart contract modular, seguro y extensible que podría servir, entre otros, como base para bóvedas multi-token.  
Las mejoras implementadas priorizan **la seguridad, la trazabilidad y la interoperabilidad con oráculos externos.**

---

© 2025 KipuBank Project — Licencia MIT
