# 🏦 KipuBank_v9 – Contrato Inteligente Multi-Token con Oráculo de Precios

## 📘 Descripción General

`KipuBank_v9.sol` es una versión mejorada del contrato `KipuBank`, diseñada para ofrecer un sistema de depósito y retiro multi-token con control de acceso, integración de oráculos de Chainlink, y manejo de decimales entre diferentes activos ERC-20 y Ether.  

Esta versión está enfocada en **seguridad, extensibilidad y eficiencia de gas**, utilizando librerías probadas de OpenZeppelin y buenas prácticas de ingeniería de contratos inteligentes.

---

## 🚀 1. Mejoras Introducidas

### 🔐 Control de Acceso
- Se implementa el patrón de **roles jerárquicos** mediante `AccessControl` de OpenZeppelin.  
- El rol `ADMIN_ROLE` (equivalente a `DEFAULT_ADMIN_ROLE`) permite:
  - Registrar tokens admitidos.
  - Establecer oráculos de precios.
  - Actualizar el límite global de depósitos (bank cap).
- El rol `OPERATOR_ROLE` se reserva para futuras operaciones automatizadas o de mantenimiento.

**Motivo:**  
Esto refuerza la seguridad operativa, evitando que cualquier usuario modifique parámetros críticos del contrato.

---

### 🧩 Declaraciones de Tipos y Variables Constant
- Se introducen constantes `USDC_DECIMALS = 6` y `ADMIN_ROLE = 0x00` para mayor claridad y eficiencia de gas.  
- Se usa `immutable` para `USDC_ADDRESS`, ya que no cambia tras el despliegue.  

**Motivo:**  
Esto mejora la legibilidad, optimiza la ejecución y evita errores por reasignación accidental.

---

### 🔮 Instancia del Oráculo Chainlink
- Cada token soportado puede asociarse a un **feed de precios** externo (Chainlink o mock compatible).
- Se utiliza una **interfaz genérica `IOracle`**, que define `latestAnswer()` para permitir compatibilidad con feeds Chainlink y mocks.  
- Se aplica `try/catch` para manejar feeds que puedan fallar o devolver datos inválidos.

**Motivo:**  
Permite calcular equivalentes en USD de forma confiable, y evita fallos de toda la transacción por errores temporales en el oráculo.

---

### 🗂️ Mappings Anidados
```solidity
mapping(address => mapping(address => uint256)) public balances;
```
- Estructura que permite llevar una **contabilidad multi-token** por usuario.  
- Ejemplo: `balances[DAI][usuario]` o `balances[address(0)][usuario]` para Ether.

**Motivo:**  
Permite escalar a múltiples activos sin necesidad de desplegar nuevos contratos.

---

### ⚖️ Conversión de Decimales y Valores
- Se introdujo la función `_toUsd6()` que:
  - Convierte montos desde diferentes decimales de tokens (p.ej., 18, 8, 6).
  - Aplica el precio del feed (en 8 decimales típicos de Chainlink).
  - Retorna el valor normalizado en **decimales USDC (6)** para la contabilidad interna.

**Motivo:**  
Estandarizar todas las operaciones contables en USD simplifica la auditoría y control del límite global (`bankCapUsd6`).

---

## ⚙️ 2. Instrucciones de Despliegue e Interacción

### 📍 Parámetros del constructor
```solidity
constructor(address admin, address usdcAddress, uint256 initialCapUsd6)
```

| Parámetro | Descripción |
|------------|--------------|
| `admin` | Dirección del administrador inicial (normalmente tu wallet) |
| `usdcAddress` | Dirección del contrato USDC (real o mock según red) |
| `initialCapUsd6` | Límite total permitido del banco en USD (6 decimales) |

### Ejemplo (red de pruebas Sepolia):
- `admin`: tu dirección de MetaMask  
- `usdcAddress`: `0x07865c6e87b9f70255377e024ace6630c1eaa37f` (USDC Sepolia)  
- `initialCapUsd6`: `100000000` (equivale a 100 USD)

---

### 🔧 Despliegue (Remix + MetaMask)

1. Abrí **Remix IDE** → `Deploy & Run Transactions`.
2. Seleccioná:
   - **Environment:** `Injected Provider - MetaMask`
   - **Network:** `Sepolia`
3. Seleccioná `KipuBank_v9.sol`.
4. Ingresá los parámetros del constructor.
5. Hacé clic en **Deploy**.
6. Confirmá en MetaMask.

---

### 💬 Interacción Básica

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

## 💡 3. Decisiones de Diseño y Trade-offs

### 🔸 Seguridad vs. Flexibilidad
- Se prefirió el uso de **roles explícitos** sobre `onlyOwner` para facilitar la descentralización futura.
- Cada token debe registrarse manualmente antes de usarse: esto evita interacciones con contratos maliciosos.

### 🔸 Uso de Oráculos
- Se implementó compatibilidad genérica vía `IOracle` en lugar de acoplar directamente a Chainlink, permitiendo mayor flexibilidad y testeo en entornos locales.

### 🔸 Eficiencia
- Se evita el uso de bucles sobre balances.
- Se marcan variables inmutables (`immutable`) y constantes (`constant`) donde corresponde.
- Se siguen los patrones `checks-effects-interactions` para mitigar ataques de reentrada.

### 🔸 Gas y Precisión
- Toda la contabilidad se mantiene en USD con 6 decimales, simplificando comparaciones.
- Se utilizan conversiones de decimales dinámicas para tokens con distinta precisión.

---

## 🧠 Conclusión

`KipuBank_v9` es un contrato modular, seguro y extensible que puede servir como base para bancos descentralizados, bóvedas multi-token o sistemas de garantía colateralizada.  
Las mejoras implementadas priorizan **la seguridad, la trazabilidad y la interoperabilidad con oráculos externos.**

---

© 2025 KipuBank Project — Licencia MIT
