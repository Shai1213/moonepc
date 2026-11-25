# GS1 TDS 2.3.0 对照范围与可复现案例

## 规范版本与项目终点

本项目将 **GS1 EPC Tag Data Standard (TDS) Release 2.3.0** 定为规范基线；该版本于 2025-10-31 发布。Tag Data Translation (TDT) **2.2.0** 作为机器可读定义/参考转换资料。版本固定，避免“遵循 GS1 标准”而没有可核对版本。

项目终点不是实现整个 TDS/TDT，而是对下列六种 **96-bit EPC binary encoding scheme**，完整实现并逐项验证它们在 TDS 2.3.0 中适用的标识字段、filter、partition、header、96 位布局、tag URI / pure-identity URI 映射及规范化输入输出：SGTIN-96、SSCC-96、SGLN-96、GRAI-96、数字型 GIAI-96、GDTI-96。验证还应覆盖所有合法 partition 选择、字段位宽/数值边界、filter 范围、96 位字节序、非法输入拒绝和 URI↔编码往返。规范条款范围锁定为 TDS 2.3.0 的 EPC 身份/Tag URI 定义（相关 §§6、10、12.3），EPC Binary Encoding 通用与 scheme-specific 规则（§§14、14.6 中六种对应子节），以及翻译组件符合性要求（§18.2.3）中与上述转换直接相关的条款。该“项目终点”是限定范围的完整符合性目标，不等同于已获得 GS1 认证，也不代表完整 TDS/TDT 支持。

TDS 2.3.0 新增的 “++” schemes、其他 EPC schemes/编码长度、TDS 中与本库 API 无关的 EPC/UII 内存组织及额外 AIDC 数据均不在本项目目标中。GS1 Digital Link、AI/条码、EPCIS、空口协议/CRC 和硬件读写器也不支持。对应范围说明见 [TDS](https://ref.gs1.org/standards/tds/2.3.0/) 与 [TDT 2.2.0](https://ref.gs1.org/standards/tdt/2.2.0/)。

## 六种编码的覆盖矩阵

| Scheme | 已实现的输入/输出 | 仓库中的主要验证 | 当前官方差分证据 |
| --- | --- | --- | --- |
| SGTIN-96 | tag URI、identity URI+显式 filter、96-bit hex/bytes/bits | known vector、七个 partition 往返、字段/filter/hex 边界拒绝 | TDT 向量 1 条 |
| SSCC-96 | 同上 | 七个 partition 往返、header、identity/filter 往返 | TDT 向量 1 条 |
| SGLN-96 | 同上，含空 extension | 七个 partition 往返、location extension、header | TDT 向量 1 条 |
| GRAI-96 | 同上，含可空 serial | 七个 partition 往返、serial 上界、header | TDT 向量 1 条 |
| 数字型 GIAI-96 | 同上 | 七个 company-prefix 长度边界、identity/filter 往返 | TDT 向量 1 条 |
| GDTI-96 | 同上 | 七个 partition 往返、41-bit serial 上界、header | TDT 向量 1 条 |

每个 partition 的回归测试验证可解析输入在 encode→decode 后保持 tag URI；这是分区边界/往返覆盖，不是对全部十进制输入值的穷举。当前已留存的官方 TDT 差分为每种 scheme 一条，共 6/6；不能将其描述成整个官方语料库或所有边界值均已差分验证。输入拒绝路径由本地单元测试覆盖。要把项目终点宣称为已达到，仍应持续补充 TDT 2.2.0 可复现的全 partition/reference-vector 对照，并将生成的固定样本与测试输出纳入仓库。

## 六条可复现的代表性输入/输出

下列是仓库 `moonepc_test.mbt` 的官方 TDT 参考向量，方向为 tag URI → EPC-96 网络序十六进制，再解码回相同 tag URI（hex 书写形式为高位字节在前）：

| Scheme | Tag URI | 96-bit hex |
| --- | --- | --- |
| SGTIN-96 | `urn:epc:tag:sgtin-96:3.0614141.812345.6789` | `3074257bf7194e4000001a85` |
| SSCC-96 | `urn:epc:tag:sscc-96:0.123456789012.12345` | `310072fa6468503039000000` |
| SGLN-96 | `urn:epc:tag:sgln-96:3.0614141.00123.456` | `3274257bf400f600000001c8` |
| GRAI-96 | `urn:epc:tag:grai-96:5.0614141.81234.123456` | `33b4257bf44f54800001e240` |
| 数字型 GIAI-96 | `urn:epc:tag:giai-96:6.999999.123456789` | `34dbd08fc0000000075bcd15` |
| GDTI-96 | `urn:epc:tag:gdti-96:3.0614141.12345.6789` | `2c74257bf460720000001a85` |

可在项目根目录复现一个端到端例子：

```sh
moon run --target wasm cmd/main -- sgtin-encode urn:epc:tag:sgtin-96:3.0614141.812345.6789
# 3074257bf7194e4000001a85
moon run --target wasm cmd/main -- sgtin-decode 3074257bf7194e4000001a85
# urn:epc:tag:sgtin-96:3.0614141.812345.6789
```

Caveat：表中 6 条官方参考差分样本不单独证明“完整规范符合性”；完整性目标由上面的显式范围和回归测试矩阵定义，当前证据边界必须与目标区分。
