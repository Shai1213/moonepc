# MoonEPC

中文文档：[README.zh-CN.md](README.zh-CN.md)。

MoonEPC 是一个纯 MoonBit 的 GS1 EPC 标识与 RFID tag-memory 编解码库和命令行工具。它把严格校验的 EPC tag URI、pure-identity URI 与 SGTIN-96、SSCC-96、SGLN-96、GRAI-96、GIAI-96、GDTI-96 的 96 位十六进制表示互相转换，适用于读写器适配层、供应链标识服务和协议测试工具。

当前范围限于 SGTIN-96、SSCC-96、SGLN-96、GRAI-96、数字型 GIAI-96 与 GDTI-96。项目不实现通用 GS1 Application Identifier/条码解析、GS1 Digital Link、EPCIS 事件、RFID 空口帧、CRC、硬件读写器驱动，也不声称覆盖完整 GS1 Tag Data Standard / Tag Data Translation。

## 环境与安装

- MoonBit CLI：使用支持 `moon.mod` 模块的近期稳定版。
- 已验证目标：WebAssembly 与 JavaScript；Native 测试需要本机 C 编译器。
- 包坐标：`Shai1213/moonepc@0.1.0`（发布完成前不能从公共 MoonCakes 安装）。
- 通用入口：`parse_epc96_tag_uri` 按 tag URI 前缀识别编码；`parse_epc96_identity_uri` 解析身份 URI 并要求调用方提供 tag filter；`decode_epc96` 按 EPC header 识别 hex 输入。

将下列依赖加入 MoonBit 模块：

```toml
"Shai1213/moonepc" = "0.1.0"
```

在包中导入 `Shai1213/moonepc`，使用各 scheme 对应的 `parse_*_tag_uri` 构造校验过的值，再调用 `encode_hex`；`decode_sgtin96`、`decode_sscc96`、`decode_sgln96`、`decode_grai96`、`decode_giai96` 与 `decode_gdti96` 负责反向解码。所有可预期输入错误通过 `Result[..., EpcError]` 返回。

## 快速开始

```sh
moon run --target wasm cmd/main -- sgtin-encode urn:epc:tag:sgtin-96:3.0614141.812345.6789
# 3074257bf7194e4000001a85

moon run --target wasm cmd/main -- sgtin-decode 3074257bf7194e4000001a85
# urn:epc:tag:sgtin-96:3.0614141.812345.6789

moon run --target wasm cmd/main -- sscc-encode urn:epc:tag:sscc-96:0.123456789012.12345

moon run --target wasm cmd/main -- sgln-encode urn:epc:tag:sgln-96:3.0614141.00123.456
moon run --target wasm cmd/main -- grai-encode urn:epc:tag:grai-96:5.0614141.81234.123456
# 33b4257bf44f54800001e240

moon run --target wasm cmd/main -- giai-encode urn:epc:tag:giai-96:6.999999.123456789
# 34dbd08fc0000000075bcd15

moon run --target wasm cmd/main -- gdti-encode urn:epc:tag:gdti-96:3.0614141.12345.6789
# 2c74257bf460720000001a85
```

命令为 `sgtin-encode/decode`、`sscc-encode/decode`、`sgln-encode/decode`、`grai-encode/decode`、`giai-encode/decode`、`gdti-encode/decode`。URI 必须使用 tag URI 形式；解码器要求恰好 96 位（24 个 hex 字符），接受大小写十六进制输入。

不知道具体 scheme 时可使用统一 CLI 分派：

```sh
moon run --target wasm cmd/main -- encode urn:epc:tag:gdti-96:3.0614141.12345.6789
# 2c74257bf460720000001a85

moon run --target wasm cmd/main -- decode 2c74257bf460720000001a85
# urn:epc:tag:gdti-96:3.0614141.12345.6789

moon run --target wasm cmd/main -- identity-encode 3 urn:epc:id:gdti:0614141.12345.6789
# 2c74257bf460720000001a85

moon run --target wasm cmd/main -- bits-encode urn:epc:tag:sgtin-96:3.0614141.812345.6789
# 001100000111010000100101011110111111011100011001010011100100000000000000000000000001101010000101
```

`bits-encode` 输出恰好 96 个按网络位序排列的 `0`/`1` 字符；`bits-decode` 接受该表示并根据 header 分派。字节接口为 12 字节网络序，不包含读写器协议头或 CRC。

## API 示例

```mbt
let epc = @moonepc.parse_sgtin_tag_uri(
  "urn:epc:tag:sgtin-96:3.0614141.812345.6789",
).unwrap()
let encoded = epc.encode_hex().unwrap()
let decoded = @moonepc.decode_sgtin96(encoded).unwrap()
assert_eq(decoded.to_tag_uri(), epc.to_tag_uri())
```

pure-identity URI 不含物理标签 filter。`parse_epc96_identity_uri` 与各 scheme 的 `parse_*_identity_uri` 都要求调用者显式提供 filter，避免把身份标识和标签用途混为一谈。SSCC 提供相同的 identity/tag 转换 API。

对位级适配可用 `encode_bit_string` 和 `decode_epc96_bit_string` 在 96 字符二进制表示与 EPC 值之间转换。固定长度读写器记录可用 `encode_epc96_records` 与 `decode_epc96_records` 指定记录步长和 EPC 在记录内的偏移；编码时周边字节使用指定填充值，解码时每条记录独立返回结果。批量 URI 解析 API 保留输入顺序，identity 批量解析要求 URI 与 filter 数组长度相同。

## 开发与验证

```sh
moon info
moon fmt
moon check --target all --deny-warn
moon test --target wasm --deny-warn
moon test --target js --deny-warn
moon run --target wasm cmd/main -- sgtin-decode 3074257bf7194e4000001a85
```

GitHub Actions 在 push、pull request 和手动触发时运行全目标检查、WASM/JS 测试及 CLI smoke tests。Native 本地运行需安装 C 编译器。

## 验证与限制

测试包含已知编码向量、六种 scheme 的分区边界 round-trip、scheme 自动分派、identity/tag URI 转换、SSCC 分区往返，以及非法 filter、分区、hex 长度、字符和未知 header 的拒绝路径。测试覆盖不等同于 GS1 全套兼容性认证；目前没有宣称完成官方测试套件或所有 EPC scheme 的互操作验证。

当前不支持 SGTIN-198、GRAI-170、字母数字型 GIAI、CPI、GID 等其他 scheme，以及 EPC URI 通用解析。遇到未知 header、错误长度、非法字符或字段越界时返回错误，而不是猜测或修复输入。

## 标准、来源与许可

位布局以 GS1 EPC Tag Data Standard (TDS) 与 Tag Data Translation (TDT) 的公开定义为行为依据；本项目为独立 MoonBit 实现，不复制上游实现代码或生成数据。格式及官方参考链接见 [GS1 TDS](https://ref.gs1.org/standards/tds/) 与 [GS1 TDT](https://github.com/gs1/TDT)。

代码按 Apache-2.0 许可发布，详见 [LICENSE](LICENSE)。本项目使用 AI 辅助编写与审阅代码、测试及文档；协议行为仍须以标准来源和可复现测试验证。
