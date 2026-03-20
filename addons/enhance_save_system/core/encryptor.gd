class_name Encryptor
extends RefCounted
## 存档加密/解密子系统
##
## 支持三种模式：
##   XOR     — 向后兼容旧存档（不推荐新项目使用）
##   AES_CBC — AES-128-CBC + HMAC-SHA256 完整性验证
##   AES_GCM — AES-128-CTR + GHASH 认证加密（推荐）
##
## 用法：
##   var result := Encryptor.encrypt(plaintext_bytes, "my-key", Encryptor.Mode.AES_GCM)
##   # result: { "ciphertext", "iv", "tag"/"hmac", "mode" }
##   var plain := Encryptor.decrypt(result, "my-key")

enum Mode { XOR, AES_CBC, AES_GCM }

## 错误码：完整性验证失败
const ERR_INTEGRITY := -1

# ──────────────────────────────────────────────
# 公开 API
# ──────────────────────────────────────────────

## 加密明文字节数组
## 返回包含所有必要字段的 Dictionary，供写入 _meta
## {
##   "ciphertext": PackedByteArray,
##   "iv":         PackedByteArray,   # AES 模式使用
##   "tag":        PackedByteArray,   # AES_GCM 认证标签
##   "hmac":       PackedByteArray,   # AES_CBC 完整性签名
##   "mode":       String,            # "xor" / "aes_cbc" / "aes_gcm"
## }
static func encrypt(plaintext: PackedByteArray, key: String, mode: Mode = Mode.AES_GCM) -> Dictionary:
	match mode:
		Mode.XOR:
			return _encrypt_xor(plaintext, key)
		Mode.AES_CBC:
			return _encrypt_aes_cbc(plaintext, key)
		Mode.AES_GCM:
			return _encrypt_aes_gcm(plaintext, key)
	push_error("Encryptor.encrypt: unknown mode %d" % mode)
	return {}

## 解密：根据 meta["mode"] 自动选择算法
## meta 为 encrypt() 返回的 Dictionary（或从 _meta 中读取的对应字段）
## 返回明文字节数组；完整性验证失败时返回空数组
static func decrypt(meta: Dictionary, key: String) -> PackedByteArray:
	var mode_str: String = meta.get("mode", "xor")
	match mode_str:
		"xor":
			var ct: PackedByteArray = _bytes_from_meta(meta, "ciphertext")
			return decrypt_xor(ct, key)
		"aes_cbc":
			return _decrypt_aes_cbc(meta, key)
		"aes_gcm":
			return _decrypt_aes_gcm(meta, key)
	push_error("Encryptor.decrypt: unknown mode '%s'" % mode_str)
	return PackedByteArray()

## 向后兼容：XOR 解密（读取旧存档）
static func decrypt_xor(data: PackedByteArray, key: String) -> PackedByteArray:
	return _xor_bytes(data, key)

## 验证 HMAC-SHA256（AES-CBC 模式）
## 返回 true 表示完整性验证通过
static func verify_hmac(data: PackedByteArray, expected_hmac: PackedByteArray, key: String) -> bool:
	var computed := _compute_hmac(data, key)
	if computed.size() != expected_hmac.size():
		return false
	# 常数时间比较，防止时序攻击
	var diff: int = 0
	for i in range(computed.size()):
		diff |= computed[i] ^ expected_hmac[i]
	return diff == 0

## 将模式枚举转为字符串
static func mode_to_string(mode: Mode) -> String:
	match mode:
		Mode.XOR:     return "xor"
		Mode.AES_CBC: return "aes_cbc"
		Mode.AES_GCM: return "aes_gcm"
	return "xor"

## 将字符串转为模式枚举
static func mode_from_string(s: String) -> Mode:
	match s:
		"aes_cbc": return Mode.AES_CBC
		"aes_gcm": return Mode.AES_GCM
	return Mode.XOR

# ──────────────────────────────────────────────
# XOR
# ──────────────────────────────────────────────

static func _encrypt_xor(plaintext: PackedByteArray, key: String) -> Dictionary:
	return {
		"ciphertext": _xor_bytes(plaintext, key),
		"iv":         PackedByteArray(),
		"tag":        PackedByteArray(),
		"hmac":       PackedByteArray(),
		"mode":       "xor",
	}

static func _xor_bytes(data: PackedByteArray, key: String) -> PackedByteArray:
	var key_bytes := key.to_utf8_buffer()
	var klen := key_bytes.size()
	if klen == 0:
		return data.duplicate()
	var result := PackedByteArray()
	result.resize(data.size())
	for i in range(data.size()):
		result[i] = data[i] ^ key_bytes[i % klen]
	return result

# ──────────────────────────────────────────────
# AES-CBC + HMAC-SHA256
# ──────────────────────────────────────────────

static func _encrypt_aes_cbc(plaintext: PackedByteArray, key: String) -> Dictionary:
	var derived_key := _derive_key(key)
	var iv := _random_iv()
	var padded := _pkcs7_pad(plaintext, 16)

	var ctx := AESContext.new()
	var err := ctx.start(AESContext.MODE_CBC_ENCRYPT, derived_key, iv)
	if err != OK:
		push_error("Encryptor: AES-CBC encrypt start failed (err=%d)" % err)
		return {}
	var ciphertext := ctx.update(padded)
	ctx.finish()

	var hmac := _compute_hmac(ciphertext, key)
	return {
		"ciphertext": ciphertext,
		"iv":         iv,
		"tag":        PackedByteArray(),
		"hmac":       hmac,
		"mode":       "aes_cbc",
	}

static func _decrypt_aes_cbc(meta: Dictionary, key: String) -> PackedByteArray:
	var ciphertext: PackedByteArray = _bytes_from_meta(meta, "ciphertext")
	var iv: PackedByteArray         = _bytes_from_meta(meta, "iv")
	var expected_hmac: PackedByteArray = _bytes_from_meta(meta, "hmac")

	if not verify_hmac(ciphertext, expected_hmac, key):
		push_error("Encryptor: AES-CBC HMAC verification failed — data may be tampered")
		return PackedByteArray()

	var derived_key := _derive_key(key)
	var ctx := AESContext.new()
	var err := ctx.start(AESContext.MODE_CBC_DECRYPT, derived_key, iv)
	if err != OK:
		push_error("Encryptor: AES-CBC decrypt start failed (err=%d)" % err)
		return PackedByteArray()
	var padded := ctx.update(ciphertext)
	ctx.finish()
	return _pkcs7_unpad(padded)

# ──────────────────────────────────────────────
# AES-GCM（CTR 模式 + GHASH 认证）
# Godot 4 原生不支持 GCM，使用 CTR + GHASH 模拟
# ──────────────────────────────────────────────

static func _encrypt_aes_gcm(plaintext: PackedByteArray, key: String) -> Dictionary:
	var derived_key := _derive_key(key)
	var iv := _random_iv()  # 16 字节 nonce

	# CTR 加密
	var ciphertext := _aes_ctr(plaintext, derived_key, iv)

	# GHASH 认证标签（使用 HMAC-SHA256 模拟 GCM 认证）
	var tag := _compute_gcm_tag(ciphertext, iv, key)

	return {
		"ciphertext": ciphertext,
		"iv":         iv,
		"tag":        tag,
		"hmac":       PackedByteArray(),
		"mode":       "aes_gcm",
	}

static func _decrypt_aes_gcm(meta: Dictionary, key: String) -> PackedByteArray:
	var ciphertext: PackedByteArray = _bytes_from_meta(meta, "ciphertext")
	var iv: PackedByteArray         = _bytes_from_meta(meta, "iv")
	var expected_tag: PackedByteArray = _bytes_from_meta(meta, "tag")

	# 验证认证标签：直接比较两个 tag 字节，不能再套一层 HMAC
	var computed_tag := _compute_gcm_tag(ciphertext, iv, key)
	if not _bytes_equal(computed_tag, expected_tag):
		push_error("Encryptor: AES-GCM tag verification failed — data may be tampered")
		return PackedByteArray()

	var derived_key := _derive_key(key)
	# CTR 解密（与加密相同操作）
	return _aes_ctr(ciphertext, derived_key, iv)

## AES-CTR 模式加密/解密（对称操作）
static func _aes_ctr(data: PackedByteArray, key: PackedByteArray, iv: PackedByteArray) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(data.size())
	var block_count := (data.size() + 15) / 16

	for block_idx in range(block_count):
		# 构造计数器块：IV + 块序号（大端序）
		var counter_block := iv.duplicate()
		# 将块序号加到计数器的最后 4 字节
		var n := block_idx
		for i in range(3, -1, -1):
			counter_block[12 + i] = (counter_block[12 + i] + (n & 0xFF)) & 0xFF
			n >>= 8

		# 用 ECB 模式加密计数器块，得到密钥流
		var ctx := AESContext.new()
		ctx.start(AESContext.MODE_ECB_ENCRYPT, key)
		var keystream := ctx.update(counter_block)
		ctx.finish()

		# XOR 数据与密钥流
		var start := block_idx * 16
		var end := mini(start + 16, data.size())
		for i in range(end - start):
			result[start + i] = data[start + i] ^ keystream[i]

	return result

## GCM 认证标签（使用 HMAC-SHA256 模拟）
static func _compute_gcm_tag(ciphertext: PackedByteArray, iv: PackedByteArray, key: String) -> PackedByteArray:
	# 将 IV 和密文拼接后计算 HMAC，作为认证标签
	var auth_data := iv.duplicate()
	auth_data.append_array(ciphertext)
	return _compute_hmac(auth_data, key)

# ──────────────────────────────────────────────
# 内部工具
# ──────────────────────────────────────────────

## 从密钥字符串派生 16 字节 AES 密钥
static func _derive_key(key: String) -> PackedByteArray:
	var hash_bytes := key.sha256_buffer()
	# 取前 16 字节（AES-128）
	var derived := PackedByteArray()
	derived.resize(16)
	for i in range(16):
		derived[i] = hash_bytes[i]
	return derived

## 生成随机 16 字节 IV
static func _random_iv() -> PackedByteArray:
	var iv := PackedByteArray()
	iv.resize(16)
	for i in range(16):
		iv[i] = randi() % 256
	return iv

## PKCS#7 填充（块大小 16）
static func _pkcs7_pad(data: PackedByteArray, block_size: int) -> PackedByteArray:
	var pad_len := block_size - (data.size() % block_size)
	var padded := data.duplicate()
	for _i in range(pad_len):
		padded.append(pad_len)
	return padded

## PKCS#7 去填充
static func _pkcs7_unpad(data: PackedByteArray) -> PackedByteArray:
	if data.is_empty():
		return data
	var pad_len := int(data[data.size() - 1])
	if pad_len <= 0 or pad_len > 16:
		return data
	return data.slice(0, data.size() - pad_len)

## 计算 HMAC-SHA256
static func _compute_hmac(data: PackedByteArray, key: String) -> PackedByteArray:
	var ctx := HMACContext.new()
	ctx.start(HashingContext.HASH_SHA256, key.to_utf8_buffer())
	ctx.update(data)
	return ctx.finish()

## 常数时间字节比较（防时序攻击）
static func _bytes_equal(a: PackedByteArray, b: PackedByteArray) -> bool:
	if a.size() != b.size():
		return false
	var diff: int = 0
	for i in range(a.size()):
		diff |= a[i] ^ b[i]
	return diff == 0

## 从 meta 字典中安全读取 PackedByteArray
## 支持 PackedByteArray 直接存储或 base64 字符串
static func _bytes_from_meta(meta: Dictionary, field: String) -> PackedByteArray:
	var val = meta.get(field, PackedByteArray())
	if val is PackedByteArray:
		return val
	if val is String and not (val as String).is_empty():
		return Marshalls.base64_to_raw(val)
	return PackedByteArray()
